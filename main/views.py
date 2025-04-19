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
from collections import defaultdict
from django.views.decorators.http import require_GET
from django.core.cache import cache  # Import Django's caching framework
import hashlib  # Import hashlib for sanitizing cache keys

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
                        SELECT t.teacher_id, t.name, d.department_name, t.phone, t.email, t.date_of_joining, t.password
                        FROM teachers t
                        JOIN departments d ON t.department_id = d.department_id
                        WHERE t.email = %s
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
                        # Calculate dropout risk and update weak subjects
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
    """Fetch playlists from YouTube API and courses from Coursera API with caching."""
    # Sanitize the cache key to avoid invalid characters
    raw_cache_key = f"courses_{course_name}_{page_token}"
    cache_key = hashlib.md5(raw_cache_key.encode()).hexdigest()  # Use MD5 hash for a valid cache key
    cached_courses = cache.get(cache_key)  # Check if the data is already cached

    if cached_courses:
        print(f"Cache hit for {raw_cache_key}")  # Debugging log
        return cached_courses, None  # Return cached data

    print(f"Cache miss for {raw_cache_key}. Fetching from APIs...")  # Debugging log
    courses = []
    next_page_token = None

    # Fetch playlists from YouTube API
    api_key = os.getenv("YOUTUBE_API_KEY")
    youtube_search_url = "https://www.googleapis.com/youtube/v3/search"

    try:
        if not api_key:
            print("YouTube API key is missing. Please check your .env file.")
            return courses, next_page_token

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
        elif response.status_code == 403 and "quotaExceeded" in response.text:
            print("YouTube API quota exceeded. Please wait until the quota resets or use a different API key.")
        else:
            print(f"Error fetching playlists from YouTube: {response.status_code} - {response.text}")
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
        else:
            print(f"Error fetching courses from Coursera: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"Error fetching courses from Coursera: {e}")

    # Cache the fetched data for 1 hour (3600 seconds)
    cache.set(cache_key, courses, timeout=3600)
    print(f"Data cached for {raw_cache_key}")  # Debugging log

    return courses, next_page_token

def recommend_courses(student_id):
    """Recommend courses for a student based on low marks or failed subjects."""
    print(f"Starting course recommendation for student {student_id}")  # Debugging log
    recommendations = []

    try:
        with connection.cursor() as cursor:
            # Fetch weak courses based on academic performance
            cursor.execute("""
                SELECT subject_id, subject_name
                FROM weak_subjects
                WHERE student_id = %s
            """, [student_id])
            weak_courses = cursor.fetchall()
            print(f"Weak courses for student {student_id}: {weak_courses}")  # Debugging log

            if not weak_courses:
                print(f"No weak courses found for student {student_id}")  # Debugging log
                return recommendations

            # For each weak course, fetch and store recommendations
            for weak_course in weak_courses:
                weak_subject_id, course_name = weak_course
                print(f"Fetching API courses for weak course: {course_name}")  # Debugging log

                # Fetch courses and videos from external APIs
                api_courses, _ = fetch_courses_from_api(course_name)
                print(f"API courses for {course_name}: {api_courses}")  # Debugging log

                if not api_courses:
                    print(f"No API courses found for {course_name}")  # Debugging log
                    continue

                # Insert API data into the `online_courses` table
                for course in api_courses:
                    try:
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
                            course_name,  # Use the weak course name as the subject category
                            course.get('difficulty_level', 'N/A'),
                            course.get('price', 0.0),
                            course.get('is_free', True)
                        ])
                        connection.commit()
                        print(f"Inserted course: {course['course_title']} into online_courses")  # Debugging log
                    except Exception as e:
                        print(f"Error inserting course into online_courses: {e}")

                # Insert recommendations into `student_course_recommendations` table
                for course in api_courses:
                    try:
                        cursor.execute("""
                            INSERT INTO student_course_recommendations (student_id, weak_subject_id, online_course_id, recommendation_date)
                            SELECT %s, %s, oc.online_course_id, NOW()
                            FROM online_courses oc
                            WHERE oc.course_title = %s AND oc.platform = %s
                            ON DUPLICATE KEY UPDATE recommendation_date = NOW()
                        """, [
                            student_id,
                            weak_subject_id,
                            course['course_title'],
                            course['platform']
                        ])
                        connection.commit()
                        print(f"Inserted recommendation for course: {course['course_title']} into student_course_recommendations")  # Debugging log
                    except Exception as e:
                        print(f"Error inserting recommendation into student_course_recommendations: {e}")

                # Fetch stored courses from the database for display
                cursor.execute("""
                    SELECT platform, course_title, course_url, description, subject_category, difficulty_level, price, is_free
                    FROM online_courses
                    WHERE subject_category = %s
                """, [course_name])
                stored_courses = cursor.fetchall()

                # Add stored courses to recommendations
                for stored_course in stored_courses:
                    recommendations.append({
                        'platform': stored_course[0],
                        'course_title': stored_course[1],
                        'course_url': stored_course[2],
                        'description': stored_course[3],
                        'subject_category': stored_course[4],
                        'difficulty_level': stored_course[5],
                        'price': stored_course[6],
                        'is_free': stored_course[7],
                    })

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
    semesters = []

    try:
        with connection.cursor() as cursor:
            # Fetch student details
            cursor.execute("""
                SELECT name, branch, current_semester, batch_year, phone, email, address
                FROM students
                WHERE student_id = %s
            """, [student_id])
            student_data['details'] = cursor.fetchone()

            # Fetch all semesters for the student
            cursor.execute("""
                SELECT DISTINCT semester_id
                FROM academic_records
                WHERE student_id = %s
                ORDER BY semester_id
            """, [student_id])
            semesters = [row[0] for row in cursor.fetchall()]

            # Fetch dropout risk
            cursor.execute("""
                SELECT risk_score, risk_level, confidence_score, contributing_factors
                FROM dropout_risk
                WHERE student_id = %s
                ORDER BY prediction_date DESC
                LIMIT 1
            """, [student_id])
            dropout_risk = cursor.fetchone()

            # Fetch weak subjects and recommend courses
            cursor.execute("""
                SELECT subject_name
                FROM weak_subjects
                WHERE student_id = %s
            """, [student_id])
            weak_subjects = [row[0] for row in cursor.fetchall()]

            for subject_name in weak_subjects:
                api_courses, _ = fetch_courses_from_api(subject_name)
                course_recommendations.extend(api_courses)

    except Exception as e:
        print(f"Error fetching student data: {e}")

    return render(request, 'main/student_dashboard.html', {
        'student_data': student_data,
        'dropout_risk': dropout_risk,
        'course_recommendations': course_recommendations,
        'semesters': semesters,
    })

@require_GET
def fetch_records(request):
    """Fetch academic and attendance records dynamically based on semester."""
    if request.session.get('role') != 'student':
        return JsonResponse({"error": "Unauthorized access."}, status=403)

    student_id = request.session.get('user_id')
    semester_id = request.GET.get('semester_id')

    if not semester_id:
        # Default to the current semester if no semester_id is provided
        semester_id = request.session.get('current_semester')

    academic_records = []
    attendance_records = []

    try:
        with connection.cursor() as cursor:
            # Fetch academic records
            cursor.execute("""
                SELECT c.course_name, ar.marks
                FROM academic_records ar
                JOIN courses c ON ar.course_id = c.course_id
                WHERE ar.student_id = %s AND ar.semester_id = %s
            """, [student_id, semester_id])
            academic_records = cursor.fetchall()

            # Fetch attendance records
            cursor.execute("""
                SELECT c.course_name, ar.attendance
                FROM attendance_records ar
                JOIN courses c ON ar.course_id = c.course_id
                WHERE ar.student_id = %s AND ar.semester_id = %s
            """, [student_id, semester_id])
            attendance_records = cursor.fetchall()

    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

    return JsonResponse({
        "academic_records": academic_records,
        "attendance_records": attendance_records,
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
    """Calculate dropout risk for a specific student and update weak subjects."""
    try:
        with connection.cursor() as cursor:
            # Fetch academic records with marks less than 40
            cursor.execute("""
                SELECT ar.course_id, c.course_name, ar.marks
                FROM academic_records ar
                JOIN courses c ON ar.course_id = c.course_id
                WHERE ar.student_id = %s AND ar.marks < 40
            """, [student_id])
            failed_subjects = cursor.fetchall()

            # Calculate dropout risk based on failed subjects
            risk_score = 0
            risk_level = 'None'
            if failed_subjects:
                risk_score = 80  # High risk if the student has failed subjects
                risk_level = 'High'

            # Insert or update dropout risk in the database
            cursor.execute("""
                INSERT INTO dropout_risk (student_id, risk_score, risk_level, confidence_score, contributing_factors)
                VALUES (%s, %s, %s, %s, %s)
                ON DUPLICATE KEY UPDATE
                    risk_score = VALUES(risk_score),
                    risk_level = VALUES(risk_level),
                    confidence_score = VALUES(confidence_score),
                    contributing_factors = VALUES(contributing_factors)
            """, [
                student_id, risk_score, risk_level, 0.9, json.dumps([sub[1] for sub in failed_subjects])
            ])
            connection.commit()

            # Update weak subjects table
            cursor.execute("DELETE FROM weak_subjects WHERE student_id = %s", [student_id])
            for subject in failed_subjects:
                cursor.execute("""
                    INSERT INTO weak_subjects (student_id, subject_code, subject_name)
                    VALUES (%s, %s, %s)
                """, [student_id, subject[0], subject[1]])
            connection.commit()

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
                        INSERT INTO student_course_recommendations (student_id, weak_subject_id, online_course_id, recommendation_date)
                        SELECT %s, ws.subject_id, oc.online_course_id, NOW()
                        FROM weak_subjects ws
                        JOIN online_courses oc ON oc.course_title = %s AND oc.platform = %s
                        WHERE ws.student_id = %s AND ws.subject_name = %s
                        ON DUPLICATE KEY UPDATE recommendation_date = NOW()
                    """, [
                        student_id, course['course_title'], course['platform'], student_id, course_name
                    ])
                    connection.commit()
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
