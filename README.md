# Student Management System

## Overview
The **Student Management System** is a comprehensive platform designed to manage and analyze student data, academic performance, attendance, and more. It provides personalized recommendations for courses, videos, and scholarships to help students improve their academic journey.

---

## Features

### 1. **User Roles**
- **Student**: Access personalized dashboards, view academic and attendance records, and receive recommendations.
- **Teacher**: Manage courses, view student performance, and provide feedback.
- **Parent**: Monitor the academic progress and dropout risk of their children.

---

### 2. **Academic Records**
- Store and manage student academic performance for each semester.
- View detailed academic records for individual courses.

---

### 3. **Attendance Management**
- Track attendance records for each student and course.
- Generate attendance summaries, including attendance percentages, days present, and days absent.

---

### 4. **Dropout Risk Prediction**
- Predict dropout risk for students using machine learning models.
- Display risk scores, risk levels (High, Medium, Low, None), and contributing factors.

---

### 5. **Course and Video Recommendations**
- Identify weak subjects for students based on academic performance.
- Recommend online courses (e.g., Coursera) and YouTube playlists for weak subjects.
- Store recommendations in the database and display them on the student dashboard.

---

### 6. **Feedback Management**
- Collect and analyze student feedback for courses.
- Calculate sentiment scores for feedback to assess course quality.

---

### 7. **Scholarship Recommendations**
- Recommend external scholarships based on student profiles and eligibility criteria.
- Track scholarship applications and match scores.

---

### 8. **Financial Assessment**
- Assess students' financial needs and eligibility for financial aid.
- Categorize students based on income levels and household size.

---

### 9. **Study Resources**
- Provide additional study resources (e.g., PDFs, videos, interactive tools) for weak subjects.

---

### 10. **API Integration**
- Integrate with external APIs (e.g., YouTube, Coursera) to fetch course and video data.
- Log API requests and responses for monitoring and debugging.

---

### 11. **Machine Learning Models**
- Train and deploy machine learning models for dropout prediction.
- Track model versions, performance metrics, and training history.

---

## Database Schema
The system uses a normalized relational database with the following key tables:
- `students`, `teachers`, `parents`: Store user information.
- `academic_records`, `attendance_records`: Manage academic and attendance data.
- `dropout_risk`: Store dropout risk predictions.
- `online_courses`, `student_course_recommendations`: Manage course and video recommendations.
- `external_scholarships`, `student_scholarship_recommendations`: Manage scholarship data.
- `model_versions`, `model_performance_metrics`: Track machine learning models and their performance.

---

## How It Works
1. **Login**: Users log in based on their roles (Student, Teacher, Parent).
2. **Dashboard**: Students access a personalized dashboard with academic, attendance, and recommendation data.
3. **Recommendations**:
   - Weak subjects are identified based on academic performance.
   - Online courses and videos are fetched from external APIs and stored in the database.
   - Recommendations are displayed on the dashboard.
4. **Dropout Risk**:
   - Dropout risk is calculated using machine learning models.
   - Risk scores and contributing factors are displayed for students and parents.
5. **Scholarships**:
   - Scholarships are recommended based on student profiles and eligibility.
   - Students can view and apply for scholarships.

---

## Technologies Used
- **Backend**: Django (Python)
- **Frontend**: HTML, CSS, JavaScript, Bootstrap
- **Database**: MySQL
- **Machine Learning**: Scikit-learn
- **APIs**: YouTube API, Coursera API
- **Environment Management**: Python `dotenv`

---

## Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/your-repo-url.git
   ```
2. Navigate to the project directory:
   ```bash
   cd SEM6Miniproject
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Set up the database:
   - Import the `test_db.sql` file into your MySQL server.
5. Run the development server:
   ```bash
   python manage.py runserver
   ```

---

## Future Enhancements
- Add real-time notifications for recommendations and updates.
- Implement advanced analytics for teachers and administrators.
- Integrate additional APIs for more diverse recommendations.

---

## Contributors
- **Your Name** - Developer
- **Team Member 1** - Contributor
- **Team Member 2** - Contributor

---

## License
This project is licensed under the MIT License.