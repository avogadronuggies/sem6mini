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
from django.contrib import messages  # Import for displaying success/error messages
from django.views.decorators.csrf import csrf_exempt  # Import for handling CSRF in admin forms

# Load environment variables from .env file
load_dotenv()

def index(request):
    if request.session.get('role') == 'student':
        return redirect('student_dashboard')
    elif request.session.get('role') == 'teacher':
        return redirect('teacher_dashboard')
    elif request.session.get('role') == 'parent':
        return redirect('parent_dashboard')
    elif request.session.get('role') == 'admin':
        return redirect('admin_dashboard')
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

        if role not in ['student', 'teacher', 'parent', 'admin']:
            error_message = 'Invalid role selected'
            return render(request, 'main/login.html', {'error_message': error_message})

        try:
            with connection.cursor() as cursor:
                # Query based on role
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
                elif role == 'admin':  # Handle admin login
                    cursor.execute("""
                        SELECT admin_id, name, email, password
                        FROM admin
                        WHERE email = %s
                    """, [email])

                user = cursor.fetchone()

                if user:
                    # Check if the entered password matches the password in the database
                    if user[-1] == password:  # Compare plain-text password
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
                            calculate_dropout_risk_for_parent(user[0])

                        elif role == 'admin':  # Admin login
                            request.session.update({
                                'user_id': user[0],
                                'role': role,
                                'name': user[1],
                                'email': user[2],
                            })

                        # Set session expiry based on "Remember Me"
                        if remember_me:
                            request.session.set_expiry(30 * 24 * 60 * 60)  # 30 days
                        else:
                            request.session.set_expiry(0)  # Until browser closes

                        # Redirect based on role
                        if role == 'admin':
                            return redirect('admin_dashboard')
                        else:
                            return redirect(f'{role}_dashboard')
                    else:
                        error_message = 'Incorrect password'
                        return render(request, 'main/login.html', {'error_message': error_message})
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

def fetch_courses_from_api(course_name, student_id, page_token=None):
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
                course = {
                    'platform': 'YouTube',
                    'course_title': playlist['snippet']['title'],
                    'course_url': f"https://www.youtube.com/playlist?list={playlist['id']['playlistId']}",
                    'description': playlist['snippet']['description'],
                    'difficulty_level': 'N/A',
                }
                courses.append(course)

                # Insert into `online_courses` table
                with connection.cursor() as cursor:
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
                        course_name,
                        course['difficulty_level'],
                        0.0,  # Default price
                        True  # Default is_free
                    ])
                    connection.commit()

                    # Insert into `student_course_recommendations` table
                    cursor.execute("""
                        INSERT INTO student_course_recommendations (student_id, weak_subject_id, online_course_id, recommendation_date)
                        SELECT %s, ws.subject_id, oc.online_course_id, NOW()
                        FROM online_courses oc
                        JOIN weak_subjects ws ON ws.subject_name = %s
                        WHERE oc.course_title = %s
                        ON DUPLICATE KEY UPDATE recommendation_date = NOW()
                    """, [student_id, course_name, course['course_title']])
                    connection.commit()
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
                course_data = {
                    'platform': 'Coursera',
                    'course_title': course.get('name'),
                    'course_url': f"https://www.coursera.org/learn/{course.get('slug')}",
                    'description': course.get('description', ''),
                    'difficulty_level': 'N/A',
                }
                courses.append(course_data)

                # Insert into `online_courses` table
                with connection.cursor() as cursor:
                    cursor.execute("""
                        INSERT INTO online_courses (platform, course_title, course_url, description, subject_category, difficulty_level, price, is_free)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                        ON DUPLICATE KEY UPDATE
                            description = VALUES(description),
                            last_updated = CURRENT_TIMESTAMP
                    """, [
                        course_data['platform'],
                        course_data['course_title'],
                        course_data['course_url'],
                        course_data['description'],
                        course_name,
                        course_data['difficulty_level'],
                        0.0,  # Default price
                        True  # Default is_free
                    ])
                    connection.commit()

                    # Insert into `student_course_recommendations` table
                    cursor.execute("""
                        INSERT INTO student_course_recommendations (student_id, weak_subject_id, online_course_id, recommendation_date)
                        SELECT %s, ws.subject_id, oc.online_course_id, NOW()
                        FROM online_courses oc
                        JOIN weak_subjects ws ON ws.subject_name = %s
                        WHERE oc.course_title = %s
                        ON DUPLICATE KEY UPDATE recommendation_date = NOW()
                    """, [student_id, course_name, course_data['course_title']])
                    connection.commit()
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
                print(f"Fetching courses for weak course: {course_name}")  # Debugging log

                # Check if courses for the subject already exist in the `online_courses` table
                cursor.execute("""
                    SELECT online_course_id, platform, course_title, course_url, description, difficulty_level
                    FROM online_courses
                    WHERE subject_category = %s
                """, [course_name])
                existing_courses = cursor.fetchall()

                if existing_courses:
                    print(f"Found {len(existing_courses)} courses in the database for subject: {course_name}")  # Debugging log
                    # Insert recommendations into `student_course_recommendations` table
                    for course in existing_courses:
                        try:
                            cursor.execute("""
                                INSERT INTO student_course_recommendations (student_id, weak_subject_id, online_course_id, recommendation_date)
                                VALUES (%s, %s, %s, NOW())
                                ON DUPLICATE KEY UPDATE recommendation_date = NOW()
                            """, [student_id, weak_subject_id, course[0]])
                            connection.commit()
                            print(f"Inserted recommendation for course: {course[2]} into student_course_recommendations")  # Debugging log
                        except Exception as e:
                            print(f"Error inserting recommendation for course {course[2]}: {e}")
                else:
                    print(f"No courses found in the database for subject: {course_name}. Fetching from API...")  # Debugging log
                    # Fetch courses from the API
                    api_courses, _ = fetch_courses_from_api(course_name, student_id)
                    print(f"API courses fetched for {course_name}: {api_courses}")  # Debugging log

                    for course in api_courses:
                        try:
                            # Insert the fetched course into the `online_courses` table
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
                                course_name,
                                course.get('difficulty_level', 'N/A'),
                                course.get('price', 0.0),
                                course.get('is_free', True)
                            ])
                            connection.commit()
                            print(f"Inserted course: {course['course_title']} into online_courses")  # Debugging log

                            # Get the `online_course_id` of the newly inserted course
                            cursor.execute("""
                                SELECT online_course_id
                                FROM online_courses
                                WHERE platform = %s AND course_title = %s
                            """, [course['platform'], course['course_title']])
                            online_course_id = cursor.fetchone()
                            if online_course_id:
                                online_course_id = online_course_id[0]

                                # Insert the recommendation into `student_course_recommendations`
                                cursor.execute("""
                                    INSERT INTO student_course_recommendations (student_id, weak_subject_id, online_course_id, recommendation_date)
                                    VALUES (%s, %s, %s, NOW())
                                    ON DUPLICATE KEY UPDATE recommendation_date = NOW()
                                """, [student_id, weak_subject_id, online_course_id])
                                connection.commit()
                                print(f"Inserted recommendation for course: {course['course_title']} into student_course_recommendations")  # Debugging log
                            else:
                                print(f"Failed to retrieve online_course_id for course: {course['course_title']}")
                        except Exception as e:
                            print(f"Error inserting course or recommendation for {course['course_title']}: {e}")

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
            
            # Fetch student feedback
            cursor.execute("""
                SELECT c.course_name, sf.feedback_text, sf.sentiment_score
                FROM student_feedback sf
                JOIN courses c ON sf.course_id = c.course_id
                WHERE sf.student_id = %s
            """, [student_id])
            student_data['feedback'] = cursor.fetchall()

            # Fetch weak subjects and recommend courses
            cursor.execute("""
                SELECT subject_name
                FROM weak_subjects
                WHERE student_id = %s
            """, [student_id])
            weak_subjects = [row[0] for row in cursor.fetchall()]

            for subject_name in weak_subjects:
                api_courses, _ = fetch_courses_from_api(subject_name, student_id)
                course_recommendations.extend(api_courses)
                
            # Recalculate dropout risk with updated feedback
            calculate_dropout_risk_for_student(student_id)
            
            # Fetch the updated dropout risk
            cursor.execute("""
                SELECT risk_score, risk_level, confidence_score, contributing_factors
                FROM dropout_risk
                WHERE student_id = %s
                ORDER BY prediction_date DESC
                LIMIT 1
            """, [student_id])
            dropout_risk = cursor.fetchone()

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
    course_list = []

    try:
        with connection.cursor() as cursor:
            # Fetch all courses for the semester first
            cursor.execute("""
                SELECT DISTINCT c.course_id, c.course_name
                FROM courses c
                JOIN academic_records ar ON c.course_id = ar.course_id
                WHERE ar.student_id = %s AND ar.semester_id = %s
            """, [student_id, semester_id])
            course_list = cursor.fetchall()
            
            # Fetch academic records
            cursor.execute("""
                SELECT c.course_id, c.course_name, ar.marks
                FROM academic_records ar
                JOIN courses c ON ar.course_id = c.course_id
                WHERE ar.student_id = %s AND ar.semester_id = %s
            """, [student_id, semester_id])
            academic_records = cursor.fetchall()

            # Fetch attendance records
            cursor.execute("""
                SELECT c.course_id, c.course_name, ar.attendance
                FROM attendance_records ar
                JOIN courses c ON ar.course_id = c.course_id
                WHERE ar.student_id = %s AND ar.semester_id = %s
            """, [student_id, semester_id])
            attendance_records = cursor.fetchall()
            
            # Fetch existing feedback for these courses
            cursor.execute("""
                SELECT sf.course_id, sf.feedback_text, sf.sentiment_score 
                FROM student_feedback sf
                WHERE sf.student_id = %s AND sf.course_id IN (
                    SELECT DISTINCT c.course_id
                    FROM courses c
                    JOIN academic_records ar ON c.course_id = ar.course_id
                    WHERE ar.student_id = %s AND ar.semester_id = %s
                )
            """, [student_id, student_id, semester_id])
            existing_feedback = cursor.fetchall()
            
            # Convert to dictionary for easy lookup
            feedback_dict = {feedback[0]: (feedback[1], feedback[2]) for feedback in existing_feedback}

    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

    return JsonResponse({
        "academic_records": academic_records,
        "attendance_records": attendance_records,
        "course_list": course_list,
        "existing_feedback": feedback_dict
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

@csrf_exempt
def admin_dashboard(request):
    """Admin dashboard to add students, parents, teachers, and their data."""
    if request.session.get('role') != 'admin':
        return redirect('login')

    message = None

    if request.method == 'POST':
        action = request.POST.get('action')

        try:
            with connection.cursor() as cursor:
                if action == 'add_student_and_parent':
                    # Add Parent
                    parent_name = request.POST.get('parent_name')
                    parent_phone = request.POST.get('parent_phone')
                    parent_email = request.POST.get('parent_email')
                    parent_password = request.POST.get('parent_password')
                    parent_occupation = request.POST.get('parent_occupation')
                    parent_address = request.POST.get('parent_address')
                    relation_to_student = request.POST.get('relation_to_student')

                    try:
                        # Insert parent into the database
                        cursor.execute("""
                            INSERT INTO parents (name, phone, email, password, occupation, address, relation_to_student)
                            VALUES (%s, %s, %s, %s, %s, %s, %s)
                        """, [parent_name, parent_phone, parent_email, parent_password, parent_occupation, parent_address, relation_to_student])
                        connection.commit()
                        print("Parent inserted successfully.")
                    except Exception as e:
                        print(f"Error inserting parent: {e}")
                        raise

                    try:
                        # Retrieve the parent_id of the newly inserted parent
                        cursor.execute("SELECT parent_id FROM parents WHERE email = %s", [parent_email])
                        parent_id = cursor.fetchone()
                        if not parent_id:
                            raise ValueError("Parent ID not found after insertion.")
                        parent_id = parent_id[0]
                        print(f"Retrieved parent_id: {parent_id}")
                    except Exception as e:
                        print(f"Error retrieving parent_id: {e}")
                        raise

                    # Add Student
                    student_name = request.POST.get('student_name')
                    branch = request.POST.get('branch')
                    current_semester = request.POST.get('current_semester')
                    batch_year = request.POST.get('batch_year')
                    student_phone = request.POST.get('student_phone')
                    student_email = request.POST.get('student_email')
                    student_password = request.POST.get('student_password')
                    student_address = request.POST.get('student_address')

                    try:
                        # Insert student into the database with the retrieved parent_id
                        cursor.execute("""
                            INSERT INTO students (name, branch, current_semester, batch_year, phone, email, password, address, parent_id)
                            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                        """, [student_name, branch, current_semester, batch_year, student_phone, student_email, student_password, student_address, parent_id])
                        connection.commit()
                        print("Student inserted successfully.")
                        message = "Student and Parent added successfully!"
                    except Exception as e:
                        print(f"Error inserting student: {e}")
                        raise
        except Exception as e:
            message = f"Error: {e}"
            print(f"Error in add_student_and_parent: {e}")

    # Fetch data for dropdowns
    parents = []
    teachers = []
    departments = []
    courses = []
    semesters = []

    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT parent_id, name FROM parents")
            parents = cursor.fetchall()

            cursor.execute("SELECT teacher_id, name FROM teachers")
            teachers = cursor.fetchall()

            cursor.execute("SELECT department_id, department_name FROM departments")
            departments = cursor.fetchall()

            cursor.execute("SELECT course_id, course_name FROM courses")
            courses = cursor.fetchall()

            cursor.execute("SELECT semester_id, year FROM semesters")
            semesters = cursor.fetchall()

    except Exception as e:
        message = f"Error fetching data: {e}"

    return render(request, 'main/admin_dashboard.html', {
        'message': message,
        'parents': parents,
        'teachers': teachers,
        'departments': departments,
        'courses': courses,
        'semesters': semesters,
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
            
            # Fetch feedback sentiment scores
            cursor.execute("""
                SELECT AVG(sentiment_score) 
                FROM student_feedback
                WHERE student_id = %s
            """, [student_id])
            avg_sentiment = cursor.fetchone()[0] or 0
            
            # Calculate dropout risk based on failed subjects and sentiment
            risk_score = 0
            risk_level = 'None'
            contributing_factors = [sub[1] for sub in failed_subjects]
            
            if failed_subjects:
                risk_score = 80  # High risk if the student has failed subjects
                risk_level = 'High'
            
            # Adjust risk based on sentiment
            if avg_sentiment < -0.5:  # Very negative sentiment
                risk_score += 10
                contributing_factors.append("Negative course feedback")
            elif avg_sentiment > 0.5:  # Very positive sentiment
                risk_score -= 10
                
            # Ensure risk score stays within 0-100
            risk_score = max(0, min(100, risk_score))
            
            # Update risk level based on final score
            if risk_score > 75:
                risk_level = 'High'
            elif risk_score > 40:
                risk_level = 'Medium'
            elif risk_score > 15:
                risk_level = 'Low'
            else:
                risk_level = 'None'

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
                student_id, risk_score, risk_level, 0.9, json.dumps(contributing_factors)
            ])
            connection.commit()

            # Delete related rows in `study_resources` before modifying `weak_subjects`
            cursor.execute("""
                DELETE FROM study_resources
                WHERE subject_id IN (
                    SELECT subject_id
                    FROM weak_subjects
                    WHERE student_id = %s
                )
            """, [student_id])
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
        with connection.cursor() as cursor:
            # Check if courses for the subject already exist in the database
            cursor.execute("""
                SELECT online_course_id, platform, course_title, course_url, description, difficulty_level
                FROM online_courses
                WHERE subject_category = %s
            """, [course_name])
            existing_courses = cursor.fetchall()

            if existing_courses:
                print(f"Found {len(existing_courses)} courses in the database for subject: {course_name}")  # Debugging log
                # Insert recommendations into `student_course_recommendations` table
                for course in existing_courses:
                    try:
                        cursor.execute("""
                            SELECT subject_id
                            FROM weak_subjects
                            WHERE student_id = %s AND subject_name = %s
                        """, [student_id, course_name])
                        weak_subject = cursor.fetchone()

                        if not weak_subject:
                            print(f"No matching weak subject found for student {student_id} and subject {course_name}")  # Debugging log
                            continue

                        cursor.execute("""
                            INSERT INTO student_course_recommendations (student_id, weak_subject_id, online_course_id, recommendation_date)
                            VALUES (%s, %s, %s, NOW())
                            ON DUPLICATE KEY UPDATE recommendation_date = NOW()
                        """, [
                            student_id, weak_subject[0], course[0]
                        ])
                        connection.commit()
                        print(f"Inserted recommendation for course: {course[2]} into student_course_recommendations")  # Debugging log
                    except Exception as e:
                        print(f"Error inserting recommendation for course {course[2]}: {e}")
            else:
                print(f"No courses found in the database for subject: {course_name}. Fetching from API...")  # Debugging log
                # Fetch courses from the API
                api_courses, _ = fetch_courses_from_api(course_name, student_id)
                print(f"API courses fetched for {course_name}: {api_courses}")  # Debugging log

                for course in api_courses:
                    try:
                        # Insert the fetched course into the `online_courses` table
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
                            course_name,
                            course.get('difficulty_level', 'N/A'),
                            course.get('price', 0.0),
                            course.get('is_free', True)
                        ])
                        connection.commit()
                        print(f"Inserted course: {course['course_title']} into online_courses")  # Debugging log

                        # Get the `online_course_id` of the newly inserted course
                        cursor.execute("""
                            SELECT online_course_id
                            FROM online_courses
                            WHERE platform = %s AND course_title = %s
                        """, [course['platform'], course['course_title']])
                        online_course_id = cursor.fetchone()[0]

                        # Insert the recommendation into `student_course_recommendations`
                        cursor.execute("""
                            SELECT subject_id
                            FROM weak_subjects
                            WHERE student_id = %s AND subject_name = %s
                        """, [student_id, course_name])
                        weak_subject = cursor.fetchone()

                        if not weak_subject:
                            print(f"No matching weak subject found for student {student_id} and subject {course_name}")  # Debugging log
                            continue

                        cursor.execute("""
                            INSERT INTO student_course_recommendations (student_id, weak_subject_id, online_course_id, recommendation_date)
                            VALUES (%s, %s, %s, NOW())
                            ON DUPLICATE KEY UPDATE recommendation_date = NOW()
                        """, [
                            student_id, weak_subject[0], online_course_id
                        ])
                        connection.commit()
                        print(f"Inserted recommendation for course: {course['course_title']} into student_course_recommendations")  # Debugging log
                    except Exception as e:
                        print(f"Error inserting course or recommendation for {course['course_title']}: {e}")

    except Exception as e:
        print(f"Error recommending courses for subject {course_name}: {e}")

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
        courses, next_page_token = fetch_courses_from_api(course_name, None, page_token)
        return JsonResponse({
            "courses": courses,
            "next_page_token": next_page_token
        })
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

def edit_profile(request):
    """Allow students, teachers, and parents to update their profile information and change their password."""
    if request.method == 'POST':
        role = request.session.get('role')
        # Check if the request is for updating profile or changing password
        if 'change_password' in request.POST:
            current_password = request.POST.get('current_password')
            new_password = request.POST.get('new_password')
            confirm_password = request.POST.get('confirm_password')

            if not all([current_password, new_password, confirm_password]):
                messages.error(request, 'All password fields are required.')
            elif new_password != confirm_password:
                messages.error(request, 'New password and confirm password do not match.')
            else:
                try:
                    with connection.cursor() as cursor:
                        # Fetch the current password from the database
                        if role == 'student':
                            cursor.execute("SELECT password FROM students WHERE student_id = %s", [user_id])
                        elif role == 'teacher':
                            cursor.execute("SELECT password FROM teachers WHERE teacher_id = %s", [user_id])
                        elif role == 'parent':
                            cursor.execute("SELECT password FROM parents WHERE parent_id = %s", [user_id])
                        current_password_db = cursor.fetchone()[0]

                        if current_password != current_password_db:
                            messages.error(request, 'Current password is incorrect.')
                        else:
                            # Update the password in the database
                            if role == 'student':
                                cursor.execute("UPDATE students SET password = %s WHERE student_id = %s", [new_password, user_id])
                            elif role == 'teacher':
                                cursor.execute("UPDATE teachers SET password = %s WHERE teacher_id = %s", [new_password, user_id])
                            elif role == 'parent':
                                cursor.execute("UPDATE parents SET password = %s WHERE parent_id = %s", [new_password, user_id])
                            connection.commit()
                            messages.success(request, 'Password updated successfully!')
                except Exception as e:
                    messages.error(request, f'Error updating password: {e}')
        else:
            # Handle profile update
            name = request.POST.get('name')
            phone = request.POST.get('phone')
            email = request.POST.get('email')
            address = request.POST.get('address')

            try:
                with connection.cursor() as cursor:
                    if role == 'student':
                        cursor.execute("""
                            UPDATE students
                            SET name = %s, phone = %s, email = %s, address = %s
                            WHERE student_id = %s
                        """, [name, phone, email, address, user_id])
                    elif role == 'teacher':
                        cursor.execute("""
                            UPDATE teachers
                            SET name = %s, phone = %s, email = %s
                            WHERE teacher_id = %s
                        """, [name, phone, email, user_id])
                    elif role == 'parent':
                        cursor.execute("""
                            UPDATE parents
                            SET name = %s, phone = %s, email = %s, address = %s
                            WHERE parent_id = %s
                        """, [name, phone, email, address, user_id])
                    connection.commit()
                    messages.success(request, 'Profile updated successfully!')
            except Exception as e:
                messages.error(request, f'Error updating profile: {e}')

    # Fetch current user data to pre-fill the form
    role = request.session.get('role')
    user_id = request.session.get('user_id')
    user_data = {}

    try:
        with connection.cursor() as cursor:
            if role == 'student':
                cursor.execute("""
                    SELECT name, phone, email, address
                    FROM students
                    WHERE student_id = %s
                """, [user_id])
            elif role == 'teacher':
                cursor.execute("""
                    SELECT name, phone, email
                    FROM teachers
                    WHERE teacher_id = %s
                """, [user_id])
            elif role == 'parent':
                cursor.execute("""
                    SELECT name, phone, email, address
                    FROM parents
                    WHERE parent_id = %s
                """, [user_id])
            user_data = cursor.fetchone()
    except Exception as e:
        messages.error(request, f'Error fetching profile data: {e}')

    return render(request, 'main/edit_profile.html', {'user_data': user_data})

def submit_feedback(request):
    """Handle student feedback submission."""
    if request.session.get('role') != 'student':
        return JsonResponse({"error": "Unauthorized access."}, status=403)
    
    if request.method != 'POST':
        return JsonResponse({"error": "Method not allowed."}, status=405)
    
    student_id = request.session.get('user_id')
    course_id = request.POST.get('course_id')
    feedback_text = request.POST.get('feedback_text')
    
    if not all([student_id, course_id, feedback_text]):
        return JsonResponse({"error": "Missing required fields."}, status=400)
    
    try:
        with connection.cursor() as cursor:
            # Insert feedback into the database
            cursor.execute("""
                INSERT INTO student_feedback (student_id, course_id, feedback_text)
                VALUES (%s, %s, %s)
            """, [student_id, course_id, feedback_text])
            connection.commit()
            
            # Get the last inserted ID
            feedback_id = cursor.lastrowid
            
            # Basic sentiment analysis (you might want to use a more sophisticated approach)
            # For now, simple scoring based on presence of positive/negative words
            positive_words = ['good', 'great', 'excellent', 'helpful', 'enjoy', 'like', 'love']
            negative_words = ['bad', 'poor', 'difficult', 'unhelpful', 'confusing', 'dislike', 'hate']
            
            feedback_lower = feedback_text.lower()
            positive_count = sum(1 for word in positive_words if word in feedback_lower)
            negative_count = sum(1 for word in negative_words if word in feedback_lower)
            
            # Calculate simple sentiment score (-1 to 1)
            sentiment_score = 0
            if positive_count > 0 or negative_count > 0:
                sentiment_score = (positive_count - negative_count) / (positive_count + negative_count)
            
            # Update the sentiment score
            cursor.execute("""
                UPDATE student_feedback 
                SET sentiment_score = %s
                WHERE feedback_id = %s
            """, [sentiment_score, feedback_id])
            connection.commit()
            
            # Recalculate dropout risk after feedback submission
            calculate_dropout_risk_for_student(student_id)
            
        return JsonResponse({"success": True, "message": "Feedback submitted successfully."})
    
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)