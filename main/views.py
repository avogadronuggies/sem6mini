from django.shortcuts import redirect, render
from django.contrib.auth import authenticate, login as auth_login, logout as auth_logout
from django.db import connection
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.model_selection import train_test_split
import requests

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

def fetch_courses_from_api(subject_name):
    """Fetch courses from external APIs like Coursera and Udemy."""
    courses = []

    # Example API call to Coursera (replace with actual API details)
    try:
        coursera_response = requests.get(
            f"https://api.coursera.org/api/courses.v1?q=search&query={subject_name}"
        )
        if coursera_response.status_code == 200:
            coursera_courses = coursera_response.json().get('elements', [])
            for course in coursera_courses:
                courses.append({
                    'platform': 'Coursera',
                    'course_title': course.get('name'),
                    'course_url': f"https://www.coursera.org/learn/{course.get('slug')}",
                    'description': course.get('description', ''),
                    'difficulty_level': course.get('level', 'Unknown'),
                })
    except Exception as e:
        print(f"Error fetching courses from Coursera: {e}")

    # Example API call to Udemy (replace with actual API details)
    try:
        udemy_response = requests.get(
            f"https://www.udemy.com/api-2.0/courses/?search={subject_name}",
            headers={"Authorization": "Bearer YOUR_UDEMY_API_KEY"}
        )
        if udemy_response.status_code == 200:
            udemy_courses = udemy_response.json().get('results', [])
            for course in udemy_courses:
                courses.append({
                    'platform': 'Udemy',
                    'course_title': course.get('title'),
                    'course_url': course.get('url'),
                    'description': course.get('headline', ''),
                    'difficulty_level': course.get('level', 'Unknown'),
                })
    except Exception as e:
        print(f"Error fetching courses from Udemy: {e}")

    return courses

def recommend_courses(student_id):
    """Recommend courses for a student based on low marks or failed subjects."""
    recommendations = []

    try:
        with connection.cursor() as cursor:
            # Fetch subjects where the student has marks less than 50
            cursor.execute("""
                SELECT ar.subject_id, s.subject_name, s.department
                FROM academic_records ar
                JOIN subjects s ON ar.subject_id = s.subject_id
                WHERE ar.student_id = %s AND ar.marks < 50
            """, [student_id])
            weak_subjects = cursor.fetchall()

            # For each weak subject, find recommended courses
            for subject in weak_subjects:
                subject_id, subject_name, department = subject

                # Fetch courses from external APIs
                api_courses = fetch_courses_from_api(subject_name)

                for course in api_courses:
                    # Insert the recommended course into the database
                    cursor.execute("""
                        INSERT INTO student_course_recommendations (student_id, weak_subject_id, course_id, recommendation_date)
                        SELECT %s, %s, oc.course_id, NOW()
                        FROM online_courses oc
                        WHERE oc.platform = %s AND oc.course_title = %s
                        ON DUPLICATE KEY UPDATE recommendation_date = NOW()
                    """, [
                        student_id, subject_id, course['platform'], course['course_title']
                    ])

                    # Add to recommendations list
                    recommendations.append({
                        'subject_name': subject_name,
                        'course_title': course['course_title'],
                        'platform': course['platform'],
                        'course_url': course['course_url'],
                        'description': course['description'],
                        'difficulty_level': course['difficulty_level'],
                    })

    except Exception as e:
        print(f"Error recommending courses for student {student_id}: {e}")

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

            # Fetch academic records
            cursor.execute("""
                SELECT semester_id, department, course_name, marks
                FROM academic_records
                WHERE student_id = %s
            """, [student_id])
            student_data['academic_records'] = cursor.fetchall()

            # Fetch attendance records
            cursor.execute("""
                SELECT semester_id, department, course_name, attendance
                FROM attendance_records
                WHERE student_id = %s
            """, [student_id])
            student_data['attendance_records'] = cursor.fetchall()

            # Fetch feedback
            cursor.execute("""
                SELECT course_name, feedback_text, sentiment_score
                FROM student_feedback
                WHERE student_id = %s
            """, [student_id])
            student_data['feedback'] = cursor.fetchall()

            # Fetch the most recent dropout risk data
            cursor.execute("""
                SELECT risk_score, risk_level, confidence_score, contributing_factors
                FROM dropout_risk
                WHERE student_id = %s
                ORDER BY prediction_date DESC
                LIMIT 1
            """, [student_id])
            dropout_risk = cursor.fetchone()

            # Fetch recommended courses from the database
            cursor.execute("""
                SELECT s.subject_name, oc.course_title, oc.platform, oc.course_url, oc.description, oc.difficulty_level
                FROM student_course_recommendations scr
                JOIN subjects s ON scr.weak_subject_id = s.subject_id
                JOIN online_courses oc ON scr.course_id = oc.course_id
                WHERE scr.student_id = %s
            """, [student_id])
            course_recommendations = cursor.fetchall()

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
                JOIN dropout_risk d ON s.student_id = d.student_id
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
            contributing_factors = [subject[0] for subject in failed_subjects]  # List of failed subjects

            # Update the database with dropout risk
            with connection.cursor() as cursor:
                cursor.execute("""
                    INSERT INTO dropout_risk (student_id, risk_score, risk_level, confidence_score, contributing_factors)
                    VALUES (%s, %s, %s, %s, %s)
                    ON DUPLICATE KEY UPDATE
                        risk_score = VALUES(risk_score),
                        risk_level = VALUES(risk_level),
                        confidence_score = VALUES(confidence_score),
                        contributing_factors = VALUES(contributing_factors)
                """, [
                    student_id, risk_score, risk_level, 0.9, str(contributing_factors)
                ])

            # Recommend courses for failed subjects
            for subject in failed_subjects:
                subject_name = subject[0]
                recommend_courses_for_subject(student_id, subject_name)

    except Exception as e:
        print(f"Error calculating dropout risk for student {student_id}: {e}")

def recommend_courses_for_subject(student_id, subject_name):
    """Fetch and recommend courses for a specific subject."""
    try:
        # Fetch courses from external APIs
        api_courses = fetch_courses_from_api(subject_name)

        with connection.cursor() as cursor:
            for course in api_courses:
                # Insert the recommended course into the database
                cursor.execute("""
                    INSERT INTO student_course_recommendations (student_id, weak_subject_id, course_id, recommendation_date)
                    SELECT %s, s.subject_id, oc.course_id, NOW()
                    FROM subjects s
                    JOIN online_courses oc ON oc.platform = %s AND oc.course_title = %s
                    WHERE s.subject_name = %s
                    ON DUPLICATE KEY UPDATE recommendation_date = NOW()
                """, [
                    student_id, course['platform'], course['course_title'], subject_name
                ])
    except Exception as e:
        print(f"Error recommending courses for subject {subject_name}: {e}")

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
