-- Create database
CREATE DATABASE test_db;
USE test_db;

-- Create normalization tables first
CREATE TABLE departments (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(50) NOT NULL,
    UNIQUE KEY (department_name)
);

CREATE TABLE courses (
    course_id INT AUTO_INCREMENT PRIMARY KEY,
    course_code VARCHAR(20) NOT NULL,
    course_name VARCHAR(100) NOT NULL,
    department_id INT NOT NULL,
    UNIQUE KEY (course_code),
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

CREATE TABLE semesters (
    semester_id INT AUTO_INCREMENT PRIMARY KEY,
    year YEAR NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    UNIQUE KEY (year, start_date)
);

CREATE TABLE tests (
    test_id INT AUTO_INCREMENT PRIMARY KEY,
    test_name VARCHAR(100) NOT NULL,
    test_type ENUM('quiz', 'midterm', 'final', 'assignment', 'project') NOT NULL,
    course_id INT,
    semester_id INT,
    max_score DECIMAL(5,2) NOT NULL,
    FOREIGN KEY (course_id) REFERENCES courses(course_id),
    FOREIGN KEY (semester_id) REFERENCES semesters(semester_id)
);

-- Main tables
CREATE TABLE parents (
    parent_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(15) NOT NULL,
    email VARCHAR(100),
    password VARCHAR(255) NOT NULL,
    occupation VARCHAR(100),
    address TEXT NOT NULL,
    relation_to_student ENUM('father', 'mother', 'guardian') NOT NULL
);

CREATE TABLE students (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    branch VARCHAR(50) NOT NULL,
    current_semester INT NOT NULL,
    batch_year YEAR NOT NULL,
    phone VARCHAR(15) NOT NULL,
    email VARCHAR(100) NOT NULL,
    password VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    parent_id INT,
    FOREIGN KEY (parent_id) REFERENCES parents(parent_id)
);

CREATE TABLE teachers (
    teacher_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    department_id INT NOT NULL,
    phone VARCHAR(15) NOT NULL,
    email VARCHAR(100) NOT NULL,
    password VARCHAR(255) NOT NULL,
    date_of_joining DATE NOT NULL,
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

CREATE TABLE academic_records (
    record_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    semester_id INT NOT NULL,
    course_id INT NOT NULL,
    marks INT NOT NULL,
    UNIQUE KEY (student_id, semester_id, course_id),
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (semester_id) REFERENCES semesters(semester_id),
    FOREIGN KEY (course_id) REFERENCES courses(course_id)
);

CREATE TABLE attendance_records (
    record_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    semester_id INT NOT NULL,
    course_id INT NOT NULL,
    attendance INT NOT NULL,
    UNIQUE KEY (student_id, semester_id, course_id),
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (semester_id) REFERENCES semesters(semester_id),
    FOREIGN KEY (course_id) REFERENCES courses(course_id)
);

CREATE TABLE student_feedback (
    feedback_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    course_id INT NOT NULL,
    feedback_text TEXT NOT NULL,
    sentiment_score FLOAT,
    submission_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (course_id) REFERENCES courses(course_id)
);

CREATE TABLE dropout_risk (
    risk_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    risk_score DECIMAL(5,2) NOT NULL,
    risk_level ENUM('High', 'Medium', 'Low', 'None') NOT NULL,
    prediction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    confidence_score DECIMAL(5,2),
    contributing_factors TEXT,
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

CREATE TABLE student_test_results (
    result_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    test_id INT NOT NULL,
    test_date DATE NOT NULL,
    score DECIMAL(5,2) NOT NULL,
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (test_id) REFERENCES tests(test_id)
);

CREATE TABLE online_courses (
    online_course_id INT AUTO_INCREMENT PRIMARY KEY,
    platform VARCHAR(50) NOT NULL,
    course_title VARCHAR(255) NOT NULL,
    course_url VARCHAR(255) NOT NULL,
    description TEXT,
    subject_category VARCHAR(100),
    difficulty_level VARCHAR(50),
    price DECIMAL(8,2),
    is_free BOOLEAN DEFAULT FALSE,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY (platform, course_title)
);

CREATE TABLE weak_subjects (
    subject_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    subject_code VARCHAR(20) NOT NULL,
    subject_name VARCHAR(100) NOT NULL,
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

CREATE TABLE student_course_recommendations (
    recommendation_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    weak_subject_id INT NOT NULL,
    online_course_id INT NOT NULL,
    recommendation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_viewed BOOLEAN DEFAULT FALSE,
    is_enrolled BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (weak_subject_id) REFERENCES weak_subjects(subject_id),
    FOREIGN KEY (online_course_id) REFERENCES online_courses(online_course_id)
);

CREATE TABLE external_scholarships (
    scholarship_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    provider VARCHAR(100) NOT NULL,
    category VARCHAR(100),
    eligibility_criteria TEXT,
    application_url VARCHAR(255) NOT NULL,
    amount_range VARCHAR(100),
    deadline DATE,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE student_scholarship_recommendations (
    recommendation_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    scholarship_id INT NOT NULL,
    match_score DECIMAL(4,2) NOT NULL,
    recommendation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_viewed BOOLEAN DEFAULT FALSE,
    is_applied BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (scholarship_id) REFERENCES external_scholarships(scholarship_id)
);

CREATE TABLE student_financial_assessment (
    assessment_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    income_category ENUM('high', 'middle', 'low') NOT NULL,
    needs_financial_aid BOOLEAN DEFAULT FALSE,
    eligible_for_aid_categories VARCHAR(255),
    household_size INT,
    assessment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

CREATE TABLE attendance_summary (
    summary_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    semester_id INT NOT NULL,
    attendance_percentage DECIMAL(5,2) NOT NULL,
    days_present INT NOT NULL,
    days_absent INT NOT NULL,
    late_arrivals INT DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (semester_id) REFERENCES semesters(semester_id),
    UNIQUE KEY (student_id, semester_id)
);

CREATE TABLE model_versions (
    model_version_id INT AUTO_INCREMENT PRIMARY KEY,
    model_name VARCHAR(50) NOT NULL,
    model_version VARCHAR(20) NOT NULL,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description TEXT,
    UNIQUE KEY (model_name, model_version)
);

CREATE TABLE model_performance_metrics (
    metric_id INT AUTO_INCREMENT PRIMARY KEY,
    model_version_id INT NOT NULL,
    training_date TIMESTAMP NOT NULL,
    accuracy DECIMAL(5,4),
    precision_score DECIMAL(5,4),
    recall_score DECIMAL(5,4),
    f1_score DECIMAL(5,4),
    auc_roc DECIMAL(5,4),
    feature_importance TEXT,
    hyperparameters TEXT,
    FOREIGN KEY (model_version_id) REFERENCES model_versions(model_version_id)
);

CREATE TABLE model_training_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    model_version_id INT NOT NULL,
    training_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    accuracy DECIMAL(5,4),
    parameters TEXT,
    features_used TEXT,
    FOREIGN KEY (model_version_id) REFERENCES model_versions(model_version_id)
);

CREATE TABLE api_integration_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    service_name VARCHAR(50) NOT NULL,
    request_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    response_status INT,
    records_processed INT,
    error_message TEXT,
    processing_time_ms INT
);

CREATE TABLE self_evaluation_score (
    eval_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    test_id INT NOT NULL,
    test_score INT NOT NULL,
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (test_id) REFERENCES tests(test_id)
);

CREATE TABLE study_resources (
    resource_id INT AUTO_INCREMENT PRIMARY KEY,
    resource_name VARCHAR(100) NOT NULL,
    resource_link VARCHAR(255) NOT NULL,
    resource_type VARCHAR(50),
    subject_id INT,
    FOREIGN KEY (subject_id) REFERENCES weak_subjects(subject_id)
);

CREATE TABLE dropout_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    dropout_date DATE,
    dropout_reason TEXT,
    semester_id INT,
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (semester_id) REFERENCES semesters(semester_id)
);

CREATE TABLE admin (
    admin_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL
);

-- Insert departments
INSERT INTO departments (department_name) VALUES 
('Computer Science'),
('Electronics & Communication'),
('Mechanical Engineering'),
('Civil Engineering'),
('Electrical Engineering');

-- Insert semester data
INSERT INTO semesters (year, start_date, end_date) VALUES
(2023, '2023-08-01', '2023-12-15'),   -- Semester 1
(2024, '2024-01-10', '2024-05-20'),   -- Semester 2
(2024, '2024-08-01', '2024-12-15'),   -- Semester 3
(2025, '2025-01-10', '2025-05-20'),   -- Semester 4
(2025, '2025-08-01', '2025-12-15'),   -- Semester 5
(2026, '2026-01-10', '2026-05-20');   -- Semester 6

-- Insert courses for each department
INSERT INTO courses (course_code, course_name, department_id) VALUES
-- Computer Science courses
('CS101', 'Introduction to Programming', 1),
('CS102', 'Computer Architecture', 1),
('CS103', 'Discrete Mathematics', 1),
('CS104', 'Digital Logic Design', 1),
('CS105', 'Professional Ethics', 1),
('CS106', 'Communication Skills', 1),

('CS201', 'Data Structures', 1),
('CS202', 'Object-Oriented Programming', 1),
('CS203', 'Computer Networks', 1),
('CS204', 'Theory of Computation', 1),
('CS205', 'Web Development', 1),
('CS206', 'Database Management Systems', 1),

('CS301', 'Algorithms', 1),
('CS302', 'Operating Systems', 1),
('CS303', 'Software Engineering', 1),
('CS304', 'Computer Graphics', 1),
('CS305', 'Mobile Application Development', 1),
('CS306', 'Artificial Intelligence', 1),

('CS401', 'Machine Learning', 1),
('CS402', 'Cloud Computing', 1),
('CS403', 'Cyber Security', 1),
('CS404', 'Natural Language Processing', 1),
('CS405', 'Big Data Analytics', 1),
('CS406', 'Internet of Things', 1),

('CS501', 'Advanced Databases', 1),
('CS502', 'Distributed Systems', 1),
('CS503', 'Deep Learning', 1),
('CS504', 'Blockchain Technology', 1),
('CS505', 'Human-Computer Interaction', 1),
('CS506', 'Information Retrieval', 1),

('CS601', 'Project Management', 1),
('CS602', 'Data Mining', 1),
('CS603', 'Quantum Computing', 1),
('CS604', 'Edge Computing', 1),
('CS605', 'Computer Vision', 1),
('CS606', 'Capstone Project', 1),

-- Electronics & Communication courses
('EC101', 'Basic Electronics', 2),
('EC102', 'Circuit Theory', 2),
('EC103', 'Electronic Devices', 2),
('EC104', 'Signals and Systems', 2),
('EC105', 'Digital Electronics', 2),
('EC106', 'Mathematics for Electronics', 2),

('EC201', 'Analog Electronics', 2),
('EC202', 'Digital Signal Processing', 2),
('EC203', 'Communication Systems', 2),
('EC204', 'Microprocessors and Microcontrollers', 2),
('EC205', 'Electromagnetic Theory', 2),
('EC206', 'Control Systems', 2),

-- Mechanical Engineering courses
('ME101', 'Engineering Mechanics', 3),
('ME102', 'Engineering Drawing', 3),
('ME103', 'Material Science', 3),
('ME104', 'Thermodynamics', 3),
('ME105', 'Manufacturing Processes', 3),
('ME106', 'Workshop Practice', 3),

-- Civil Engineering courses
('CE101', 'Engineering Drawing', 4),
('CE102', 'Surveying', 4),
('CE103', 'Building Materials', 4),
('CE104', 'Mechanics of Solids', 4),
('CE105', 'Fluid Mechanics', 4),
('CE106', 'Environmental Engineering', 4),

-- Electrical Engineering courses
('EE101', 'Basic Electrical Engineering', 5),
('EE102', 'Electric Circuits', 5),
('EE103', 'Electromagnetic Fields', 5),
('EE104', 'Electrical Measurements', 5),
('EE105', 'Power System Generation', 5),
('EE106', 'Electrical Machines', 5);

-- Insert test data
INSERT INTO tests (test_name, test_type, course_id, semester_id, max_score) VALUES
-- CS1xx tests for semester 1
('CS101 Mid-Term', 'midterm', 1, 1, 50.00),
('CS101 Final', 'final', 1, 1, 100.00),
('CS102 Mid-Term', 'midterm', 2, 1, 50.00),
('CS102 Final', 'final', 2, 1, 100.00),
('CS103 Mid-Term', 'midterm', 3, 1, 50.00),
('CS103 Final', 'final', 3, 1, 100.00),
('CS104 Mid-Term', 'midterm', 4, 1, 50.00),
('CS104 Final', 'final', 4, 1, 100.00),
('CS105 Mid-Term', 'midterm', 5, 1, 50.00),
('CS105 Final', 'final', 5, 1, 100.00),
('CS106 Mid-Term', 'midterm', 6, 1, 50.00),
('CS106 Final', 'final', 6, 1, 100.00),

-- CS2xx tests for semester 2
('CS201 Mid-Term', 'midterm', 7, 2, 50.00),
('CS201 Final', 'final', 7, 2, 100.00),
('CS202 Mid-Term', 'midterm', 8, 2, 50.00),
('CS202 Final', 'final', 8, 2, 100.00),
('CS203 Mid-Term', 'midterm', 9, 2, 50.00),
('CS203 Final', 'final', 9, 2, 100.00),
('CS204 Mid-Term', 'midterm', 10, 2, 50.00),
('CS204 Final', 'final', 10, 2, 100.00),
('CS205 Mid-Term', 'midterm', 11, 2, 50.00),
('CS205 Final', 'final', 11, 2, 100.00),
('CS206 Mid-Term', 'midterm', 12, 2, 50.00),
('CS206 Final', 'final', 12, 2, 100.00),

-- EC1xx tests for semester 1
('EC101 Mid-Term', 'midterm', 37, 1, 50.00),
('EC101 Final', 'final', 37, 1, 100.00),
('EC102 Mid-Term', 'midterm', 38, 1, 50.00),
('EC102 Final', 'final', 38, 1, 100.00),
('EC103 Mid-Term', 'midterm', 39, 1, 50.00),
('EC103 Final', 'final', 39, 1, 100.00),
('EC104 Mid-Term', 'midterm', 40, 1, 50.00),
('EC104 Final', 'final', 40, 1, 100.00),
('EC105 Mid-Term', 'midterm', 41, 1, 50.00),
('EC105 Final', 'final', 41, 1, 100.00),
('EC106 Mid-Term', 'midterm', 42, 1, 50.00),
('EC106 Final', 'final', 42, 1, 100.00),

-- ME1xx tests for semester 1
('ME101 Mid-Term', 'midterm', 49, 1, 50.00),
('ME101 Final', 'final', 49, 1, 100.00),
('ME102 Mid-Term', 'midterm', 50, 1, 50.00),
('ME102 Final', 'final', 50, 1, 100.00),
('ME103 Mid-Term', 'midterm', 51, 1, 50.00),
('ME103 Final', 'final', 51, 1, 100.00),
('ME104 Mid-Term', 'midterm', 52, 1, 50.00),
('ME104 Final', 'final', 52, 1, 100.00),
('ME105 Mid-Term', 'midterm', 53, 1, 50.00),
('ME105 Final', 'final', 53, 1, 100.00),
('ME106 Mid-Term', 'midterm', 54, 1, 50.00),
('ME106 Final', 'final', 54, 1, 100.00);

-- Insert parent data
INSERT INTO parents (name, phone, email, password, occupation, address, relation_to_student) VALUES
('Rajesh Kumar', '9876543210', 'rajesh@example.com', 'password123', 'Engineer', '123 Main Street, Mumbai', 'father'),
('Sita Sharma', '9876543211', 'sita@example.com', 'password123', 'Teacher', '456 Park Avenue, Delhi', 'mother'),
('Vijay Singh', '9876543212', 'vijay@example.com', 'password123', 'Business Owner', '789 Villa Road, Bangalore', 'father'),
('Priya Patel', '9876543213', 'priya@example.com', 'password123', 'Doctor', '101 Hospital Lane, Chennai', 'mother'),
('Suresh Gupta', '9876543214', 'suresh@example.com', 'password123', 'Lawyer', '202 Court Road, Hyderabad', 'father'),
('Anita Joshi', '9876543215', 'anita@example.com', 'password123', 'Accountant', '303 Finance Street, Pune', 'mother'),
('Manoj Verma', '9876543216', 'manoj@example.com', 'password123', 'Professor', '404 University Ave, Kolkata', 'father'),
('Neha Reddy', '9876543217', 'neha@example.com', 'password123', 'Architect', '505 Design Blvd, Ahmedabad', 'mother'),
('Rahul Malhotra', '9876543218', 'rahul@example.com', 'password123', 'Government Officer', '606 Civil Lines, Jaipur', 'father'),
('Sunita Kapoor', '9876543219', 'sunita@example.com', 'password123', 'Entrepreneur', '707 Startup Hub, Lucknow', 'mother');

-- Insert student data
INSERT INTO students (name, branch, current_semester, batch_year, phone, email, password, address, parent_id) VALUES
('Amit Kumar', 'Computer Science', 6, 2023, '8765432101', 'amit@example.com', 'password123', '123 College Hostel, Mumbai', 1),
('Sneha Sharma', 'Electronics & Communication', 6, 2023, '8765432102', 'sneha@example.com', 'password123', '456 Girls Hostel, Delhi', 2),
('Rahul Singh', 'Mechanical Engineering', 5, 2023, '8765432103', 'rahul@example.com', 'password123', '789 Boys Hostel, Bangalore', 3),
('Pooja Patel', 'Civil Engineering', 5, 2023, '8765432104', 'pooja@example.com', 'password123', '101 Campus Housing, Chennai', 4),
('Vikram Gupta', 'Electrical Engineering', 4, 2023, '8765432105', 'vikram@example.com', 'password123', '202 Student Apartment, Hyderabad', 5),
('Deepa Joshi', 'Computer Science', 4, 2023, '8765432106', 'deepa@example.com', 'password123', '303 PG Housing, Pune', 6),
('Rajat Verma', 'Electronics & Communication', 3, 2023, '8765432107', 'rajat@example.com', 'password123', '404 College Lodge, Kolkata', 7),
('Meera Reddy', 'Mechanical Engineering', 3, 2023, '8765432108', 'meera@example.com', 'password123', '505 Residence Hall, Ahmedabad', 8),
('Sanjay Malhotra', 'Civil Engineering', 3, 2023, 'sanjay@example.com', 'password123', '606 Student Housing, Jaipur', 9),
('Priya Kapoor', 'Electrical Engineering', 3, 2023, 'priyak@example.com', 'password123', '707 Campus Dorm, Lucknow', 10);

-- Insert teacher data
INSERT INTO teachers (name, department_id, phone, email, password, date_of_joining) VALUES
('Dr. Anil Kumar', 1, '9876543220', 'anil@example.com', 'password123', '2018-07-15'),
('Prof. Meena Sharma', 2, '9876543221', 'meena@example.com', 'password123', '2017-08-10'),
('Dr. Ravi Verma', 3, '9876543222', 'ravi@example.com', 'password123', '2019-06-22'),
('Prof. Shikha Gupta', 4, 'shikha@example.com', 'password123', '2016-09-05'),
('Dr. Ajay Singh', 5, '9876543224', 'ajay@example.com', 'password123', '2020-01-15');

-- Insert academic_records for CS students
-- Student 1 (Amit Kumar): CS student with 6 semesters, consistently good performance
-- Semester 1
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
(1, 1, 1, 85),  -- CS101
(1, 1, 2, 82),  -- CS102
(1, 1, 3, 78),  -- CS103
(1, 1, 4, 81),  -- CS104
(1, 1, 5, 88),  -- CS105
(1, 1, 6, 90);  -- CS106

-- Semester 2
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
(1, 2, 7, 83),  -- CS201
(1, 2, 8, 86),  -- CS202
(1, 2, 9, 80),  -- CS203
(1, 2, 10, 79), -- CS204
(1, 2, 11, 85), -- CS205
(1, 2, 12, 82); -- CS206

-- Semester 3
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
(1, 3, 13, 84), -- CS301
(1, 3, 14, 78), -- CS302
(1, 3, 15, 82), -- CS303
(1, 3, 16, 77), -- CS304
(1, 3, 17, 85), -- CS305
(1, 3, 18, 81); -- CS306

-- Semester 4
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
(1, 4, 19, 79), -- CS401
(1, 4, 20, 80), -- CS402
(1, 4, 21, 85), -- CS403
(1, 4, 22, 83), -- CS404
(1, 4, 23, 78), -- CS405
(1, 4, 24, 82); -- CS406

-- Semester 5
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
(1, 5, 25, 84), -- CS501
(1, 5, 26, 86), -- CS502
(1, 5, 27, 79), -- CS503
(1, 5, 28, 81), -- CS504
(1, 5, 29, 85), -- CS505
(1, 5, 30, 87); -- CS506

-- Semester 6
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
(1, 6, 31, 82), -- CS601
(1, 6, 32, 85), -- CS602
(1, 6, 33, 88), -- CS603
(1, 6, 34, 83), -- CS604
(1, 6, 35, 80), -- CS605
(1, 6, 36, 89); -- CS606

-- Student 2 (Sneha Sharma): EC student with 6 semesters, good but declining performance
-- Semester 1
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
(2, 1, 37, 88), -- EC101
(2, 1, 38, 90), -- EC102
(2, 1, 39, 85), -- EC103
(2, 1, 40, 82), -- EC104
(2, 1, 41, 86), -- EC105
(2, 1, 42, 89); -- EC106

-- Semester 2
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
(2, 2, 43, 82), -- EC201
(2, 2, 44, 79), -- EC202
(2, 2, 45, 80), -- EC203
(2, 2, 46, 85), -- EC204
(2, 2, 47, 83), -- EC205
(2, 2, 48, 78); -- EC206

-- Student 3 (Rahul Singh): ME student with 5 semesters, inconsistent performance
-- Semester 1
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
(3, 1, 49, 72), -- ME101
(3, 1, 50, 68), -- ME102
(3, 1, 51, 75), -- ME103
(3, 1, 52, 70), -- ME104
(3, 1, 53, 73), -- ME105
(3, 1, 54, 71); -- ME106

-- Insert weak_subjects for the students having poor performances
INSERT INTO weak_subjects (student_id, subject_code, subject_name) VALUES
(3, 'ME102', 'Engineering Drawing'),
(4, 'CE201', 'Structural Analysis'),
(4, 'CE401', 'Transportation Engineering'),
(5, 'EE401', 'Power Systems'),
(7, 'EC201', 'Analog Electronics'),
(7, 'EC301', 'Communication Theory'),
(10, 'EE201', 'Circuit Theory'),
(10, 'EE301', 'Electrical Machines');

-- Insert attendance_records for CS students (first semester only as example)
-- Student 1: Good attendance
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(1, 1, 1, 90), -- CS101
(1, 1, 2, 92), -- CS102
(1, 1, 3, 88), -- CS103
(1, 1, 4, 91), -- CS104
(1, 1, 5, 94), -- CS105
(1, 1, 6, 89); -- CS106

-- Student 2: Good attendance
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(2, 1, 37, 94), -- EC101
(2, 1, 38, 92), -- EC102
(2, 1, 39, 90), -- EC103
(2, 1, 40, 93), -- EC104
(2, 1, 41, 91), -- EC105
(2, 1, 42, 89); -- EC106

-- Insert attendance_summary for the first semester for all students
INSERT INTO attendance_summary (student_id, semester_id, attendance_percentage, days_present, days_absent, late_arrivals) VALUES
(1, 1, 92.5, 74, 6, 2),
(1, 2, 91.3, 73, 7, 1),
(1, 3, 90.0, 72, 8, 3),
(1, 4, 91.3, 73, 7, 2),
(1, 5, 90.0, 72, 8, 1),
(1, 6, 93.8, 75, 5, 0),

(2, 1, 93.8, 75, 5, 1),
(2, 2, 90.0, 72, 8, 2),
(2, 3, 86.3, 69, 11, 3),
(2, 4, 83.8, 67, 13, 4),
(2, 5, 81.3, 65, 15, 5),
(2, 6, 78.8, 63, 17, 6),

(3, 1, 82.5, 66, 14, 3),
(3, 2, 80.0, 64, 16, 4),
(3, 3, 83.8, 67, 13, 2),
(3, 4, 81.3, 65, 15, 3),
(3, 5, 78.8, 63, 17, 4),

(4, 1, 78.8, 63, 17, 5),
(4, 2, 56.3, 45, 35, 8),
(4, 3, 68.8, 55, 25, 7),
(4, 4, 60.0, 48, 32, 9),
(4, 5, 70.0, 56, 24, 6),

(5, 1, 85.0, 68, 12, 3),
(5, 2, 80.0, 64, 16, 4),
(5, 3, 75.0, 60, 20, 5),
(5, 4, 61.3, 49, 31, 7),

(6, 1, 87.5, 70, 10, 2),
(6, 2, 88.8, 71, 9, 1),
(6, 3, 86.3, 69, 11, 3),
(6, 4, 88.8, 71, 9, 2),

(7, 1, 81.3, 65, 15, 4),
(7, 2, 46.3, 37, 43, 9),
(7, 3, 57.5, 46, 34, 8),

(8, 1, 88.8, 71, 9, 2),
(8, 2, 90.0, 72, 8, 1),
(8, 3, 88.8, 71, 9, 2),

(9, 1, 76.3, 61, 19, 5),
(9, 2, 77.5, 62, 18, 4),
(9, 3, 80.0, 64, 16, 3),

(10, 1, 68.8, 55, 25, 6),
(10, 2, 52.5, 42, 38, 10),
(10, 3, 56.3, 45, 35, 9);

-- Insert attendance records for Student 1 (all semesters)
-- Semester 1 already inserted above
-- Semester 2
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(1, 2, 7, 92),  -- CS201
(1, 2, 8, 90),  -- CS202
(1, 2, 9, 91),  -- CS203
(1, 2, 10, 89), -- CS204
(1, 2, 11, 93), -- CS205
(1, 2, 12, 94); -- CS206

-- Semester 3
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(1, 3, 13, 88), -- CS301
(1, 3, 14, 90), -- CS302
(1, 3, 15, 89), -- CS303
(1, 3, 16, 91), -- CS304
(1, 3, 17, 92), -- CS305
(1, 3, 18, 90); -- CS306

-- Semester 4
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(1, 4, 19, 91), -- CS401
(1, 4, 20, 93), -- CS402
(1, 4, 21, 90), -- CS403
(1, 4, 22, 92), -- CS404
(1, 4, 23, 89), -- CS405
(1, 4, 24, 91); -- CS406

-- Semester 5
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(1, 5, 25, 89), -- CS501
(1, 5, 26, 92), -- CS502
(1, 5, 27, 90), -- CS503
(1, 5, 28, 88), -- CS504
(1, 5, 29, 91), -- CS505
(1, 5, 30, 90); -- CS506

-- Semester 6
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(1, 6, 31, 94), -- CS601
(1, 6, 32, 93), -- CS602
(1, 6, 33, 95), -- CS603
(1, 6, 34, 92), -- CS604
(1, 6, 35, 94), -- CS605
(1, 6, 36, 95); -- CS606

-- Insert attendance records for Student 2 (Sneha Sharma) - declining attendance over semesters
-- Semester 1 already inserted above
-- Semester 2
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(2, 2, 43, 90), -- EC201
(2, 2, 44, 88), -- EC202
(2, 2, 45, 91), -- EC203
(2, 2, 46, 89), -- EC204
(2, 2, 47, 90), -- EC205
(2, 2, 48, 92); -- EC206

-- Semester 3
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(2, 3, 43, 86), -- EC201
(2, 3, 44, 85), -- EC202
(2, 3, 45, 87), -- EC203
(2, 3, 46, 88), -- EC204
(2, 3, 47, 85), -- EC205
(2, 3, 48, 87); -- EC206

-- Semester 4
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(2, 4, 43, 83), -- EC201
(2, 4, 44, 85), -- EC202
(2, 4, 45, 82), -- EC203
(2, 4, 46, 84), -- EC204
(2, 4, 47, 86), -- EC205
(2, 4, 48, 83); -- EC206

-- Semester 5
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(2, 5, 43, 80), -- EC201
(2, 5, 44, 82), -- EC202
(2, 5, 45, 79), -- EC203
(2, 5, 46, 83), -- EC204
(2, 5, 47, 81), -- EC205
(2, 5, 48, 82); -- EC206

-- Semester 6
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(2, 6, 43, 77), -- EC201
(2, 6, 44, 79), -- EC202
(2, 6, 45, 78), -- EC203
(2, 6, 46, 80), -- EC204
(2, 6, 47, 76), -- EC205
(2, 6, 48, 82); -- EC206

-- Insert attendance records for Student 3 (Rahul Singh) - inconsistent attendance
-- Semester 1
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(3, 1, 49, 82), -- ME101
(3, 1, 50, 80), -- ME102
(3, 1, 51, 84), -- ME103
(3, 1, 52, 83), -- ME104
(3, 1, 53, 81), -- ME105
(3, 1, 54, 85); -- ME106

-- Semester 2
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(3, 2, 49, 79), -- ME101
(3, 2, 50, 77), -- ME102
(3, 2, 51, 82), -- ME103
(3, 2, 52, 80), -- ME104
(3, 2, 53, 78), -- ME105
(3, 2, 54, 84); -- ME106

-- Semester 3
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(3, 3, 49, 84), -- ME101
(3, 3, 50, 82), -- ME102
(3, 3, 51, 86), -- ME103
(3, 3, 52, 83), -- ME104
(3, 3, 53, 85), -- ME105
(3, 3, 54, 83); -- ME106

-- Semester 4
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(3, 4, 49, 81), -- ME101
(3, 4, 50, 79), -- ME102
(3, 4, 51, 83), -- ME103
(3, 4, 52, 80), -- ME104
(3, 4, 53, 82), -- ME105
(3, 4, 54, 83); -- ME106

-- Semester 5
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(3, 5, 49, 78), -- ME101
(3, 5, 50, 76), -- ME102
(3, 5, 51, 80), -- ME103
(3, 5, 52, 79), -- ME104
(3, 5, 53, 77), -- ME105
(3, 5, 54, 82); -- ME106

-- Insert attendance records for Student 4 (Pooja Patel) - poor attendance in problem subjects
-- Semester 1
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(4, 1, 19, 78), -- CE101
(4, 1, 20, 80), -- CE102
(4, 1, 21, 79), -- CE103
(4, 1, 22, 77), -- CE104
(4, 1, 23, 81), -- CE105
(4, 1, 24, 78); -- CE106

-- Semester 2
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(4, 2, 19, 55), -- CE101
(4, 2, 20, 58), -- CE102
(4, 2, 21, 57), -- CE103
(4, 2, 22, 54), -- CE104
(4, 2, 23, 59), -- CE105
(4, 2, 24, 56); -- CE106

-- Insert student_test_results for the first few students
-- Student 1 results for semester 1 tests
INSERT INTO student_test_results (student_id, test_id, test_date, score) VALUES
(1, 1, '2023-10-15', 42.50),  -- CS101 Mid-Term
(1, 2, '2023-12-10', 85.00),  -- CS101 Final
(1, 3, '2023-10-16', 43.00),  -- CS102 Mid-Term
(1, 4, '2023-12-11', 82.00),  -- CS102 Final
(1, 5, '2023-10-17', 40.00),  -- CS103 Mid-Term
(1, 6, '2023-12-12', 78.00),  -- CS103 Final
(1, 7, '2023-10-18', 42.00),  -- CS104 Mid-Term
(1, 8, '2023-12-13', 81.00),  -- CS104 Final
(1, 9, '2023-10-19', 45.00),  -- CS105 Mid-Term
(1, 10, '2023-12-14', 88.00), -- CS105 Final
(1, 11, '2023-10-20', 46.00), -- CS106 Mid-Term
(1, 12, '2023-12-15', 90.00); -- CS106 Final

-- Student 2 results for semester 1 tests
INSERT INTO student_test_results (student_id, test_id, test_date, score) VALUES
(2, 25, '2023-10-15', 45.00), -- EC101 Mid-Term
(2, 26, '2023-12-10', 88.00), -- EC101 Final
(2, 27, '2023-10-16', 46.00), -- EC102 Mid-Term
(2, 28, '2023-12-11', 90.00), -- EC102 Final
(2, 29, '2023-10-17', 43.00), -- EC103 Mid-Term
(2, 30, '2023-12-12', 85.00), -- EC103 Final
(2, 31, '2023-10-18', 42.00), -- EC104 Mid-Term
(2, 32, '2023-12-13', 82.00), -- EC104 Final
(2, 33, '2023-10-19', 44.00), -- EC105 Mid-Term
(2, 34, '2023-12-14', 86.00), -- EC105 Final
(2, 35, '2023-10-20', 45.50), -- EC106 Mid-Term
(2, 36, '2023-12-15', 89.00); -- EC106 Final

-- Student 3 results for semester 1 tests
INSERT INTO student_test_results (student_id, test_id, test_date, score) VALUES
(3, 37, '2023-10-15', 36.00), -- ME101 Mid-Term
(3, 38, '2023-12-10', 72.00), -- ME101 Final
(3, 39, '2023-10-16', 34.00), -- ME102 Mid-Term
(3, 40, '2023-12-11', 68.00), -- ME102 Final
(3, 41, '2023-10-17', 38.00), -- ME103 Mid-Term
(3, 42, '2023-12-12', 75.00), -- ME103 Final
(3, 43, '2023-10-18', 35.00), -- ME104 Mid-Term
(3, 44, '2023-12-13', 70.00), -- ME104 Final
(3, 45, '2023-10-19', 37.00), -- ME105 Mid-Term
(3, 46, '2023-12-14', 73.00), -- ME105 Final
(3, 47, '2023-10-20', 35.50), -- ME106 Mid-Term
(3, 48, '2023-12-15', 71.00); -- ME106 Final

-- Insert self_evaluation_score data
INSERT INTO self_evaluation_score (student_id, test_id, test_score) VALUES
(1, 1, 40),   -- CS101 Mid-Term
(1, 2, 82),   -- CS101 Final
(1, 3, 41),   -- CS102 Mid-Term
(1, 4, 80),   -- CS102 Final
(2, 25, 43),  -- EC101 Mid-Term
(2, 26, 85),  -- EC101 Final
(3, 37, 32),  -- ME101 Mid-Term
(3, 38, 65);  -- ME101 Final

-- Insert study_resources data
INSERT INTO study_resources (resource_name, resource_link, resource_type, subject_id) VALUES
('Engineering Drawing Tutorial', 'https://example.com/eng-drawing', 'Video', 1),
('Structural Analysis Guide', 'https://example.com/struct-analysis', 'PDF', 2),
('Transportation Engineering Notes', 'https://example.com/transport-engg', 'PDF', 3),
('Power Systems Tutorial', 'https://example.com/power-systems', 'Interactive', 4),
('Electronics Circuit Design', 'https://example.com/circuit-design', 'Video', 5),
('Communication Theory Course', 'https://example.com/comm-theory', 'Course', 6),
('Circuit Theory Fundamentals', 'https://example.com/circuit-theory', 'eBook', 7),
('Electrical Machines Guide', 'https://example.com/electrical-machines', 'Interactive', 8);

-- Insert student_feedback data
INSERT INTO student_feedback (student_id, course_id, feedback_text, sentiment_score, submission_date) VALUES
(1, 1, 'The course material was well-structured and the professor explained concepts clearly.', 0.8, '2023-12-20 15:30:00'),
(1, 2, 'Enjoyed the practical sessions but would like more hands-on exercises.', 0.6, '2023-12-20 16:15:00'),
(2, 37, 'The course was challenging but interesting. Labs were very helpful.', 0.7, '2023-12-21 10:45:00'),
(3, 49, 'Had difficulty following some concepts. More examples would be helpful.', 0.2, '2023-12-21 14:20:00'),
(4, 19, 'The course content was outdated. Need more modern case studies.', -0.3, '2023-12-22 09:15:00'),
(5, 25, 'Excellent teaching but the pace was too fast for complex topics.', 0.4, '2023-12-22 11:30:00');

-- Insert model_versions data
INSERT INTO model_versions (model_name, model_version, description) VALUES
('DropoutPredictor', 'v1.0.0', 'Initial model using academic and attendance data'),
('DropoutPredictor', 'v1.1.0', 'Improved model with feedback sentiment analysis'),
('DropoutPredictor', 'v2.0.0', 'Advanced model including behavioral factors');

-- Insert model_performance_metrics
INSERT INTO model_performance_metrics (model_version_id, training_date, accuracy, precision_score, recall_score, f1_score, auc_roc, feature_importance, hyperparameters) VALUES
(1, '2024-01-15 09:00:00', 0.8240, 0.7856, 0.8102, 0.7977, 0.8356, 'attendance:0.35,marks:0.30,test_scores:0.25,feedback:0.10', '{"learning_rate": 0.01, "max_depth": 5, "n_estimators": 100}'),
(2, '2024-03-20 10:30:00', 0.8572, 0.8245, 0.8390, 0.8317, 0.8691, 'attendance:0.32,marks:0.28,test_scores:0.22,feedback:0.18', '{"learning_rate": 0.01, "max_depth": 6, "n_estimators": 150}'),
(3, '2024-06-10 11:45:00', 0.8925, 0.8617, 0.8754, 0.8685, 0.9038, 'attendance:0.30,marks:0.25,test_scores:0.20,feedback:0.15,behavior:0.10', '{"learning_rate": 0.005, "max_depth": 7, "n_estimators": 200}');

-- Insert model_training_history
INSERT INTO model_training_history (model_version_id, accuracy, parameters, features_used) VALUES
(1, 0.8240, '{"iterations": 100, "early_stopping": true}', 'attendance,marks,test_scores'),
(2, 0.8572, '{"iterations": 150, "early_stopping": true}', 'attendance,marks,test_scores,feedback_sentiment'),
(3, 0.8925, '{"iterations": 200, "early_stopping": true}', 'attendance,marks,test_scores,feedback_sentiment,behavioral_factors');

-- Insert api_integration_log
INSERT INTO api_integration_log (service_name, response_status, records_processed, error_message, processing_time_ms) VALUES
('LMS_Integration', 200, 150, NULL, 1250),
('Attendance_System', 200, 200, NULL, 980),
('Feedback_API', 200, 50, NULL, 750),
('Financial_System', 500, 0, 'Connection timeout', 3000),
('Course_Catalog', 200, 75, NULL, 1100);

-- Insert external_scholarships data
INSERT INTO external_scholarships (name, provider, category, eligibility_criteria, application_url, amount_range, deadline) VALUES
('Merit Scholarship', 'National Education Foundation', 'Academic Excellence', 'Minimum 85% in academics, family income below 8 LPA', 'https://example.com/merit-scholarship', '50,000 - 1,00,000 INR', '2025-03-15'),
('Tech Talent Award', 'TechCorp Foundation', 'STEM', 'Outstanding performance in CS, Electronics or related fields', 'https://example.com/tech-talent', '75,000 - 1,50,000 INR', '2025-04-10'),
('Women in Engineering', 'WE Foundation', 'Gender-specific', 'Female students pursuing engineering with minimum 75% marks', 'https://example.com/women-engg', '60,000 - 1,20,000 INR', '2025-03-30'),
('Rural Development Scholarship', 'Rural Welfare Trust', 'Economic Background', 'Students from rural areas with family income below 5 LPA', 'https://example.com/rural-dev', '40,000 - 80,000 INR', '2025-05-20'),
('Future Leaders Grant', 'Corporate Leadership Council', 'All-rounder', 'Academic excellence with leadership qualities and extracurricular achievements', 'https://example.com/future-leaders', '1,00,000 - 2,00,000 INR', '2025-02-28');

-- Insert student_financial_assessment data
INSERT INTO student_financial_assessment (student_id, income_category, needs_financial_aid, eligible_for_aid_categories, household_size) VALUES
(1, 'middle', FALSE, NULL, 4),
(2, 'middle', FALSE, NULL, 3),
(3, 'low', TRUE, 'merit-based,need-based', 5),
(4, 'low', TRUE, 'need-based,gender-specific', 4),
(5, 'middle', FALSE, NULL, 4),
(6, 'low', TRUE, 'merit-based,gender-specific', 3),
(7, 'high', FALSE, NULL, 3),
(8, 'middle', FALSE, 'gender-specific', 4),
(9, 'low', TRUE, 'need-based', 6),
(10, 'low', TRUE, 'need-based,gender-specific', 5);

-- Insert student_scholarship_recommendations
INSERT INTO student_scholarship_recommendations (student_id, scholarship_id, match_score, is_viewed, is_applied) VALUES
(3, 1, 85.5, TRUE, TRUE),
(4, 3, 92.8, TRUE, TRUE),
(4, 4, 78.3, TRUE, FALSE),
(6, 1, 88.0, TRUE, TRUE),
(6, 3, 95.2, TRUE, TRUE),
(9, 4, 91.5, TRUE, FALSE),
(10, 3, 89.7, TRUE, FALSE),
(10, 4, 83.5, FALSE, FALSE);

-- Insert dropout_history data (for demonstration only)
INSERT INTO dropout_history (student_id, dropout_date, dropout_reason, semester_id) VALUES
(7, '2024-05-15', 'Financial difficulties and poor academic performance', 3);

-- Insert admin data
INSERT INTO admin (name, email, password) VALUES
('Admin User', 'admin@example.com', 'adminpassword');