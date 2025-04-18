from django.shortcuts import redirect, render
from django.contrib.auth import authenticate, login as auth_login, logout as auth_logout
from django.db import connection
from django.http import JsonResponse
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.model_selection import train_test_split
import requests
import json
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

def index(request):
    if request.session.get('role') == 'student':
        return redirect('student_dashboard')
    elif request.session.get('role') == 'teacher':
        return redirect('teacher_dashboard')
    elif request.session.get('role') == 'parent':
        return redirect('parent_dashboard')
    return render(request, 'main/index.html')

def login(request):
    request.session.flush()
    error_message = None  # Initialize error message variable

    if request.method == 'POST':
        # Get form data
        email = request.POST.get('email')
        password = request.POST.get('password')
        role = request.POST.get('role')
        remember_me = request.POST.get('remember', False)

        # Basic validation
        if not all([email, password, role]):
            error_message = 'All fields are required'
            return render(request, 'main/login.html', {'error_message': error_message})

        if role not in ['student', 'teacher', 'parent']:
            error_message = 'Invalid role selected'
            return render(request, 'main/login.html', {'error_message': error_message})

        try:
            with connection.cursor() as cursor:
                if role == 'student':
                    cursor.execute("""
                        SELECT student_id, name, branch, current_semester, batch_year, phone, email, address, parent_id, password
                        FROM students
                        WHERE email = %s
                    """, [email])
                elif role == 'teacher':
                    cursor.execute("""
                        SELECT teacher_id, name, department, phone, email, date_of_joining, password
                        FROM teachers
                        WHERE email = %s
                    """, [email])
                elif role == 'parent':
                    cursor.execute("""
                        SELECT parent_id, name, phone, email, occupation, address, relation_to_student, password
                        FROM parents
                        WHERE email = %s
                    """, [email])

                user = cursor.fetchone()

                if user and user[-1] == password:  # Compare password (last column)
                    # Set session data based on role
                    if role == 'student':
                        request.session.update({
                            'user_id': user[0],
                            'role': role,
                            'name': user[1],
                            'branch': user[2],
                            'current_semester': user[3],
                            'batch_year': user[4],
                            'phone': user[5],
                            'email': user[6],
                            'address': user[7],
                            'parent_id': user[8],
                        })
                        # Automatically calculate and add dropout risk for the student
                        calculate_dropout_risk_for_student(user[0])

                    elif role == 'teacher':
                        request.session.update({
                            'user_id': user[0],
                            'role': role,
                            'name': user[1],
                            'department': user[2],
                            'phone': user[3],
                            'email': user[4],
                            'date_of_joining': user[5].isoformat(),
                        })

                    elif role == 'parent':
                        request.session.update({
                            'user_id': user[0],
                            'role': role,
                            'name': user[1],
                            'phone': user[2],
                            'email': user[3],
                            'occupation': user[4],
                            'address': user[5],
                            'relation_to_student': user[6],
                        })
                        # Automatically calculate and add dropout risk for all children of the parent
                        calculate_dropout_risk_for_parent(user[0])

                    # Set session expiry based on "Remember Me"
                    if remember_me:
                        request.session.set_expiry(30 * 24 * 60 * 60)  # 30 days
                    else:
                        request.session.set_expiry(0)  # Until browser closes

                    return redirect(f'{role}_dashboard')
                else:
                    error_message = 'Invalid credentials'
                    return render(request, 'main/login.html', {'error_message': error_message})

        except Exception as e:
            error_message = f'Login error: {str(e)}'
            return render(request, 'main/login.html', {'error_message': error_message})

    return render(request, 'main/login.html')

def logout(request):
    auth_logout(request)
    return redirect('login')

def fetch_courses_from_api(course_name, page_token=None):
    """Fetch playlists from YouTube API and courses from Coursera API for a given course with pagination."""
    courses = []
    next_page_token = None

    # Fetch playlists from YouTube API
    api_key = os.getenv("YOUTUBE_API_KEY")
    youtube_search_url = "https://www.googleapis.com/youtube/v3/search"

    try:
        params = {
            "part": "snippet",
            "q": course_name,
            "type": "playlist",
            "maxResults": 4,  # Limit to 4 results per page
            "key": api_key
        }
        if page_token:
            params["pageToken"] = page_token

        response = requests.get(youtube_search_url, params=params)
        if response.status_code == 200:
            playlists = response.json().get("items", [])
            for playlist in playlists:
                courses.append({
                    'platform': 'YouTube',
                    'course_title': playlist['snippet']['title'],
                    'course_url': f"https://www.youtube.com/playlist?list={playlist['id']['playlistId']}",
                    'description': playlist['snippet']['description'],
                    'difficulty_level': 'N/A',
                })
            next_page_token = response.json().get("nextPageToken")
    except Exception as e:
        print(f"Error fetching playlists from YouTube: {e}")

    # Fetch courses from Coursera API
    coursera_search_url = "https://api.coursera.org/api/courses.v1"

    try:
        response = requests.get(
            coursera_search_url,
            params={"q": "search", "query": course_name}
        )
        if response.status_code == 200:
            coursera_courses = response.json().get("elements", [])[:4]  # Limit to 4 results
            for course in coursera_courses:
                courses.append({
                    'platform': 'Coursera',
                    'course_title': course.get('name'),
                    'course_url': f"https://www.coursera.org/learn/{course.get('slug')}",
                    'description': course.get('description', ''),
                    'difficulty_level': 'N/A',
                })
    except Exception as e:
        print(f"Error fetching courses from Coursera: {e}")

    return courses, next_page_token

def recommend_courses(student_id):
    """Recommend courses for a student based on low marks or failed subjects."""
    print(f"Starting course recommendation for student {student_id}")  # Debugging log
    recommendations = []

    try:
        with connection.cursor() as cursor:
            # Fetch courses from academic records where marks are less than 50
            cursor.execute("""
                SELECT course_name
                FROM academic_records
                WHERE student_id = %s AND marks < 50
            """, [student_id])
            weak_courses = cursor.fetchall()
            print(f"Weak courses for student {student_id}: {weak_courses}")  # Debugging log

            if not weak_courses:
                print(f"No weak courses found for student {student_id}")  # Debugging log

            # For each weak course, find recommended videos
            for course in weak_courses:
                course_name = course[0]
                print(f"Fetching API courses for weak course: {course_name}")  # Debugging log

                # Fetch videos from external APIs
                api_courses, _ = fetch_courses_from_api(course_name)
                print(f"API courses for {course_name}: {api_courses}")  # Debugging log

                if not api_courses:
                    print(f"No API courses found for {course_name}")  # Debugging log

                # Convert JSON data to a DataFrame before inserting
                api_courses_df = pd.DataFrame(api_courses)
                print("Converted API courses to DataFrame:")
                print(api_courses_df)

                # Iterate over the DataFrame rows and insert into the database
                for _, course in api_courses_df.iterrows():
                    try:
                        print(f"Attempting to insert course: {course['course_title']} into online_courses")  # Debugging log
                        cursor.execute("""
                            INSERT INTO online_courses (platform, course_title, course_url, description, subject_category, difficulty_level, price, is_free)
                            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                            ON DUPLICATE KEY UPDATE
                                description = VALUES(description),
                                last_updated = CURRENT_TIMESTAMP
                        """, [
                            course['platform'],
                            course['course_title'],
                            course['course_url'],
                            course['description'],
                            course.get('subject_category', 'General'),
                            course.get('difficulty_level', 'N/A'),
                            course.get('price', 0.0),
                            course.get('is_free', True)
                        ])
                        connection.commit()  # Explicit commit to ensure data persistence
                        print(f"Successfully inserted course: {course['course_title']}")  # Debugging log
                    except Exception as e:
                        print(f"Error inserting course into online_courses: {e}")

                # Fetch data from the online_courses table to display
                cursor.execute("""
                    SELECT platform, course_title, course_url, description, subject_category, difficulty_level, price, is_free
                    FROM online_courses
                    WHERE subject_category = %s
                """, [course_name])
                fetched_courses = cursor.fetchall()
                print(f"Fetched courses for display: {fetched_courses}")

                for video in api_courses:
                    # Add to recommendations list
                    recommendations.append({
                        'course_name': course_name,
                        'video_title': video['course_title'],
                        'platform': video['platform'],
                        'video_url': video['course_url'],
                        'description': video['description'],
                        'difficulty_level': video['difficulty_level'],
                    })

            # Convert course recommendations to JSON format
            recommendations_json = json.dumps([
                {
                    'course_name': rec['course_name'],
                    'video_title': rec['video_title'],
                    'platform': rec['platform'],
                    'video_url': rec['video_url'],
                    'description': rec['description'],
                    'difficulty_level': rec['difficulty_level']
                }
                for rec in recommendations
            ])

            # Store JSON data in a DataFrame (for demonstration purposes)
            df = pd.DataFrame(json.loads(recommendations_json))
            print(df)  # Debugging log to verify DataFrame content

            # Pass JSON data to the template
            course_recommendations = json.loads(recommendations_json)

    except Exception as e:
        print(f"Error recommending courses for student {student_id}: {e}")

    print(f"Final recommendations for student {student_id}: {recommendations}")  # Debugging log
    return recommendations

def student_dashboard(request):
    if request.session.get('role') != 'student':
        return redirect('login')

    student_id = request.session.get('user_id')
    student_data = {}
    dropout_risk = None
    course_recommendations = []

    try:
        with connection.cursor() as cursor:
            # Fetch student details
            cursor.execute("""
                SELECT name, branch, current_semester, batch_year, phone, email, address
                FROM students
                WHERE student_id = %s
            """, [student_id])
            student_data['details'] = cursor.fetchone()
            print(f"Student details: {student_data['details']}")  # Debugging log

            # Fetch academic records
            cursor.execute("""
                SELECT semester_id, department, course_name, marks
                FROM academic_records
                WHERE student_id = %s
            """, [student_id])
            student_data['academic_records'] = cursor.fetchall()
            print(f"Academic records: {student_data['academic_records']}")  # Debugging log

            # Fetch attendance records
            cursor.execute("""
                SELECT semester_id, department, course_name, attendance
                FROM attendance_records
                WHERE student_id = %s
            """, [student_id])
            student_data['attendance_records'] = cursor.fetchall()
            print(f"Attendance records: {student_data['attendance_records']}")  # Debugging log

            # Fetch feedback
            cursor.execute("""
                SELECT course_name, feedback_text, sentiment_score
                FROM student_feedback
                WHERE student_id = %s
            """, [student_id])
            student_data['feedback'] = cursor.fetchall()
            print(f"Feedback: {student_data['feedback']}")  # Debugging log

            # Fetch the most recent dropout risk data
            cursor.execute("""
                SELECT risk_score, risk_level, confidence_score, contributing_factors
                FROM dropout_risk
                WHERE student_id = %s
                ORDER BY prediction_date DESC
                LIMIT 1
            """, [student_id])
            dropout_risk = cursor.fetchone()
            print(f"Dropout risk: {dropout_risk}")  # Debugging log

            # Fetch recommended courses directly from the API
            weak_courses = [record[2] for record in student_data['academic_records'] if record[3] < 50]
            print(f"Weak courses: {weak_courses}")  # Debugging log

            for course_name in weak_courses:
                api_courses, next_page_token = fetch_courses_from_api(course_name)
                print(f"API courses for {course_name}: {api_courses}")  # Debugging log
                course_recommendations.extend(api_courses)

    except Exception as e:
        print(f"Error fetching student data: {e}")

    return render(request, 'main/student_dashboard.html', {
        'student_data': student_data,
        'dropout_risk': dropout_risk,
        'course_recommendations': course_recommendations,
    })

def teacher_dashboard(request):
    if request.session.get('role') != 'teacher':
        return redirect('login')
    return render(request, 'main/teacher_dashboard.html', {
        'name': request.session.get('name'),
        'department': request.session.get('department'),
        'date_of_joining': request.session.get('date_of_joining'),
    })

def parent_dashboard(request):
    if request.session.get('role') != 'parent':
        return redirect('login')

    parent_id = request.session.get('user_id')
    child_dropout_risks = []

    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT s.name, d.risk_score, d.risk_level, d.confidence_score, d.contributing_factors
                FROM students s
                JOIN (
                    SELECT student_id, MAX(prediction_date) AS latest_date
                    FROM dropout_risk
                    GROUP BY student_id
                ) latest_risk ON s.student_id = latest_risk.student_id
                JOIN dropout_risk d ON s.student_id = d.student_id AND d.prediction_date = latest_risk.latest_date
                WHERE s.parent_id = %s
            """, [parent_id])
            child_dropout_risks = cursor.fetchall()
    except Exception as e:
        child_dropout_risks = []

    return render(request, 'main/parent_dashboard.html', {
        'name': request.session.get('name'),
        'relation_to_student': request.session.get('relation_to_student'),
        'address': request.session.get('address'),
        'child_dropout_risks': child_dropout_risks,
    })

def calculate_dropout_risk():
    """Calculate dropout risk for all students and update the database."""
    try:
        # Fetch all student data from the database
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT student_id, branch, batch_year, current_semester, avg_marks, min_marks,
                       failed_courses, avg_attendance, min_attendance, low_attendance_count,
                       avg_sentiment
                FROM students
                LEFT JOIN (
                    SELECT student_id,
                           AVG(marks) AS avg_marks,
                           MIN(marks) AS min_marks,
                           COUNT(CASE WHEN marks < 40 THEN 1 END) AS failed_courses
                    FROM academic_records
                    GROUP BY student_id
                ) AS academic ON students.student_id = academic.student_id
                LEFT JOIN (
                    SELECT student_id,
                           AVG(attendance) AS avg_attendance,
                           MIN(attendance) AS min_attendance,
                           COUNT(CASE WHEN attendance < 60 THEN 1 END) AS low_attendance_count
                    FROM attendance_records
                    GROUP BY student_id
                ) AS attendance ON students.student_id = attendance.student_id
                LEFT JOIN (
                    SELECT student_id,
                           AVG(sentiment_score) AS avg_sentiment
                    FROM student_feedback
                    GROUP BY student_id
                ) AS feedback ON students.student_id = feedback.student_id
            """)
            student_data = cursor.fetchall()

        # Convert data to a DataFrame
        columns = [
            'student_id', 'branch', 'batch_year', 'current_semester', 'avg_marks', 'min_marks',
            'failed_courses', 'avg_attendance', 'min_attendance', 'low_attendance_count',
            'avg_sentiment'
        ]
        df = pd.DataFrame(student_data, columns=columns)

        # Handle missing values
        df.fillna({
            'avg_marks': 0, 'min_marks': 0, 'failed_courses': 0,
            'avg_attendance': 0, 'min_attendance': 0, 'low_attendance_count': 0,
            'avg_sentiment': 0
        }, inplace=True)

        # Prepare features and target
        X = df.drop(['student_id', 'current_semester'], axis=1)

        # Define categorical and numerical features
        categorical_features = ['branch']
        numeric_features = X.columns.difference(categorical_features)

        # Preprocessing pipeline
        preprocessor = ColumnTransformer(
            transformers=[
                ('num', StandardScaler(), numeric_features),
                ('cat', OneHotEncoder(handle_unknown='ignore'), categorical_features)
            ]
        )

        # Train a Random Forest model
        model = Pipeline(steps=[
            ('preprocessor', preprocessor),
            ('classifier', RandomForestClassifier(n_estimators=100, random_state=42))
        ])

        # Generate mock dropout status for training
        df['dropout_status'] = np.random.choice([0, 1], size=len(df), p=[0.8, 0.2])
        X_train, X_test, y_train, y_test = train_test_split(X, df['dropout_status'], test_size=0.2, random_state=42)
        model.fit(X_train, y_train)

        # Predict dropout risk for all students
        risk_probabilities = model.predict_proba(X)[:, 1]

        # Update the database with predictions
        with connection.cursor() as cursor:
            for i, student_id in enumerate(df['student_id']):
                risk_score = risk_probabilities[i] * 100
                risk_level = (
                    'High' if risk_score > 75 else
                    'Medium' if risk_score > 40 else
                    'Low' if risk_score > 15 else
                    'None'
                )
                cursor.execute("""
                    INSERT INTO dropout_risk (student_id, risk_score, risk_level, confidence_score, contributing_factors)
                    VALUES (%s, %s, %s, %s, %s)
                    ON DUPLICATE KEY UPDATE
                        risk_score = VALUES(risk_score),
                        risk_level = VALUES(risk_level),
                        confidence_score = VALUES(confidence_score),
                        contributing_factors = VALUES(contributing_factors)
                """, [
                    student_id, risk_score, risk_level, 0.8, '["Mock factors"]'
                ])
                connection.commit()  # Explicit commit to ensure data persistence
        print("Dropout risk predictions updated successfully.")

    except Exception as e:
        print(f"Error calculating dropout risk: {e}")

def calculate_dropout_risk_for_student(student_id):
    """Calculate dropout risk for a specific student based on database data."""
    try:
        with connection.cursor() as cursor:
            # Fetch student data and subjects with marks less than 35
            cursor.execute("""
                SELECT s.subject_name, ar.marks
                FROM academic_records ar
                JOIN subjects s ON ar.subject_id = s.subject_id
                WHERE ar.student_id = %s AND ar.marks < 35
            """, [student_id])
            failed_subjects = cursor.fetchall()

        if failed_subjects:
            # Calculate dropout risk based on failed subjects
            risk_score = 80  # High risk if the student has failed subjects
            risk_level = 'High'

            # Update the database with dropout risk
            with connection.cursor() as cursor:
                failed_courses = [subject[0] for subject in failed_subjects]  # List of failed course names
                cursor.execute("""
                    INSERT INTO dropout_risk (student_id, risk_score, risk_level, confidence_score, contributing_factors)
                    VALUES (%s, %s, %s, %s, %s)
                    ON DUPLICATE KEY UPDATE
                        risk_score = VALUES(risk_score),
                        risk_level = VALUES(risk_level),
                        confidence_score = VALUES(confidence_score),
                        contributing_factors = VALUES(contributing_factors)
                """, [
                    student_id, risk_score, risk_level, 0.9, str(failed_courses)
                ])
                connection.commit()  # Explicit commit to ensure data persistence

            # Recommend courses for failed subjects
            for subject in failed_subjects:
                subject_name = subject[0]
                recommend_courses_for_subject(student_id, subject_name)

    except Exception as e:
        print(f"Error calculating dropout risk for student {student_id}: {e}")

def recommend_courses_for_subject(student_id, course_name):
    """Fetch and recommend courses for a specific course."""
    print(f"Starting recommendation for subject: {course_name} for student: {student_id}")  # Debugging log
    try:
        # Fetch courses from external APIs
        api_courses, _ = fetch_courses_from_api(course_name)
        print(f"API courses fetched for {course_name}: {api_courses}")  # Debugging log

        with connection.cursor() as cursor:
            for course in api_courses:
                try:
                    print(f"Attempting to insert recommendation for course: {course['course_title']} into student_course_recommendations")  # Debugging log
                    # Insert the recommended course into the database
                    cursor.execute("""
                        INSERT INTO student_course_recommendations (student_id, weak_subject_id, course_id, recommendation_date)
                        SELECT %s, NULL, oc.course_id, NOW()
                        FROM online_courses oc
                        WHERE CONVERT(oc.platform USING utf8mb4) COLLATE utf8mb4_general_ci = CONVERT(%s USING utf8mb4) COLLATE utf8mb4_general_ci
                          AND CONVERT(oc.course_title USING utf8mb4) COLLATE utf8mb4_general_ci = CONVERT(%s USING utf8mb4) COLLATE utf8mb4_general_ci
                        ON DUPLICATE KEY UPDATE recommendation_date = NOW()
                    """, [
                        student_id, course['platform'], course['course_title']
                    ])
                    connection.commit()  # Explicit commit to ensure data persistence
                    print(f"Successfully inserted recommendation for course: {course['course_title']}")  # Debugging log
                except Exception as e:
                    print(f"Error inserting recommendation for course {course['course_title']}: {e}")
    except Exception as e:
        print(f"Error recommending courses for course {course_name}: {e}")

def calculate_dropout_risk_for_parent(parent_id):
    """Calculate dropout risk for all children of a parent."""
    try:
        with connection.cursor() as cursor:
            # Fetch all children of the parent
            cursor.execute("""
                SELECT student_id
                FROM students
                WHERE parent_id = %s 
            """, [parent_id])
            children = cursor.fetchall()

        for child in children:
            calculate_dropout_risk_for_student(child[0])
    except Exception as e:
        print(f"Error calculating dropout risk for parent {parent_id}: {e}")

def load_more_courses(request):
    course_name = request.GET.get('course_name')
    page_token = request.GET.get('page_token')

    if not course_name:
        return JsonResponse({"error": "Course name is required."}, status=400)

    try:
        courses, next_page_token = fetch_courses_from_api(course_name, page_token)
        return JsonResponse({
            "courses": courses,
            "next_page_token": next_page_token
        })
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)
