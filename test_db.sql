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
    end_date DATE NOT NULL
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
-- Insert departments
INSERT INTO departments (department_name) VALUES
('Computer Science'),
('Electronics'),
('Mechanical'),
('Civil'),
('Electrical');

-- Insert courses (6 subjects per semester for 8 semesters)
-- Semester 1 (common for all engineering branches)
INSERT INTO courses (course_code, course_name, department_id) VALUES
('MTH101', 'Engineering Mathematics I', 1),
('PHY101', 'Engineering Physics', 1),
('CHM101', 'Engineering Chemistry', 1),
('ENG101', 'Technical English', 1),
('MEC101', 'Engineering Mechanics', 3),
('CSE101', 'Introduction to Programming', 1);

-- Semester 2 (common for all engineering branches)
INSERT INTO courses (course_code, course_name, department_id) VALUES
('MTH102', 'Engineering Mathematics II', 1),
('PHY102', 'Applied Physics', 1),
('ELE101', 'Basic Electrical Engineering', 5),
('EVS101', 'Environmental Studies', 4),
('ENG102', 'Communication Skills', 1),
('CSE102', 'Object Oriented Programming', 1);

-- Semester 3 (Computer Science)
INSERT INTO courses (course_code, course_name, department_id) VALUES
('CSE201', 'Data Structures', 1),
('CSE202', 'Digital Logic Design', 1),
('CSE203', 'Discrete Mathematics', 1),
('CSE204', 'Computer Organization', 1),
('MTH201', 'Probability and Statistics', 1),
('HUM201', 'Economics for Engineers', 1);

-- Semester 4 (Computer Science)
INSERT INTO courses (course_code, course_name, department_id) VALUES
('CSE205', 'Algorithms Design', 1),
('CSE206', 'Database Management Systems', 1),
('CSE207', 'Operating Systems', 1),
('CSE208', 'Computer Networks', 1),
('MTH202', 'Numerical Methods', 1),
('HUM202', 'Professional Ethics', 1);

-- Semester 5 (Computer Science)
INSERT INTO courses (course_code, course_name, department_id) VALUES
('CSE301', 'Software Engineering', 1),
('CSE302', 'Web Technologies', 1),
('CSE303', 'Artificial Intelligence', 1),
('CSE304', 'Theory of Computation', 1),
('CSE305', 'Information Security', 1),
('CSE306', 'Machine Learning', 1);

-- Semester 6 (Computer Science)
INSERT INTO courses (course_code, course_name, department_id) VALUES
('CSE307', 'Compiler Design', 1),
('CSE308', 'Mobile Application Development', 1),
('CSE309', 'Cloud Computing', 1),
('CSE310', 'Data Mining', 1),
('CSE311', 'Internet of Things', 1),
('CSE312', 'Big Data Analytics', 1);

-- Semester 7 (Computer Science)
INSERT INTO courses (course_code, course_name, department_id) VALUES
('CSE401', 'Distributed Systems', 1),
('CSE402', 'Natural Language Processing', 1),
('CSE403', 'Computer Vision', 1),
('CSE404', 'Blockchain Technology', 1),
('CSE405', 'Deep Learning', 1),
('CSE406', 'Project Management', 1);

-- Semester 8 (Computer Science)
INSERT INTO courses (course_code, course_name, department_id) VALUES
('CSE407', 'Quantum Computing', 1),
('CSE408', 'Robotics', 1),
('CSE409', 'Human-Computer Interaction', 1),
('CSE410', 'Edge Computing', 1),
('CSE411', 'Cyber-Physical Systems', 1),
('CSE412', 'Major Project', 1);

-- Insert semesters
INSERT INTO semesters (year, start_date, end_date) VALUES
(2023, '2023-01-15', '2023-05-30'), -- Semester 1 for 2023 batch
(2023, '2023-07-15', '2023-12-15'), -- Semester 2 for 2023 batch
(2024, '2024-01-15', '2024-05-30'), -- Semester 3 for 2023 batch / Semester 1 for 2024 batch
(2024, '2024-07-15', '2024-12-15'), -- Semester 4 for 2023 batch / Semester 2 for 2024 batch
(2022, '2022-01-15', '2022-05-30'), -- Semester 1 for 2022 batch
(2022, '2022-07-15', '2022-12-15'), -- Semester 2 for 2022 batch
(2023, '2023-01-15', '2023-05-30'), -- Semester 3 for 2022 batch
(2023, '2023-07-15', '2023-12-15'), -- Semester 4 for 2022 batch
(2024, '2024-01-15', '2024-05-30'), -- Semester 5 for 2022 batch
(2024, '2024-07-15', '2024-12-15'), -- Semester 6 for 2022 batch
(2021, '2021-01-15', '2021-05-30'), -- Semester 1 for 2021 batch
(2021, '2021-07-15', '2021-12-15'), -- Semester 2 for 2021 batch
(2022, '2022-01-15', '2022-05-30'), -- Semester 3 for 2021 batch
(2022, '2022-07-15', '2022-12-15'), -- Semester 4 for 2021 batch
(2023, '2023-01-15', '2023-05-30'), -- Semester 5 for 2021 batch
(2023, '2023-07-15', '2023-12-15'), -- Semester 6 for 2021 batch
(2024, '2024-01-15', '2024-05-30'), -- Semester 7 for 2021 batch
(2024, '2024-07-15', '2024-12-15'); -- Semester 8 for 2021 batch

-- Insert parent data
INSERT INTO parents (name, phone, email, password, occupation, address, relation_to_student) VALUES
('Rajesh Kumar', '9876543210', 'rajesh@email.com', 'password123', 'Engineer', '123 Main Street, City', 'father'),
('Anita Sharma', '9876543211', 'anita@email.com', 'password123', 'Doctor', '456 Park Avenue, City', 'mother'),
('Vijay Singh', '9876543212', 'vijay@email.com', 'password123', 'Businessman', '789 New Road, City', 'father'),
('Priya Patel', '9876543213', 'priya@email.com', 'password123', 'Teacher', '321 Old Lane, City', 'mother'),
('Sanjay Gupta', '9876543214', 'sanjay@email.com', 'password123', 'Lawyer', '654 Hill View, City', 'father'),
('Deepa Verma', '9876543215', 'deepa@email.com', 'password123', 'Professor', '987 River Road, City', 'mother'),
('Rakesh Jain', '9876543216', 'rakesh@email.com', 'password123', 'Accountant', '159 Lake View, City', 'father'),
('Neha Agarwal', '9876543217', 'neha@email.com', 'password123', 'Architect', '753 Mountain View, City', 'mother'),
('Amit Khanna', '9876543218', 'amit@email.com', 'password123', 'Manager', '246 Green Park, City', 'father'),
('Meena Kapoor', '9876543219', 'meena@email.com', 'password123', 'Nurse', '135 Sun City, City', 'mother'),
('Rahul Mishra', '9876543220', 'rahul@email.com', 'password123', 'Businessman', '791 Moon Street, City', 'father'),
('Kavita Yadav', '9876543221', 'kavita@email.com', 'password123', 'Software Engineer', '842 Star Avenue, City', 'mother'),
('Suresh Tiwari', '9876543222', 'suresh@email.com', 'password123', 'Civil Servant', '953 Cloud Road, City', 'father'),
('Pooja Malhotra', '9876543223', 'pooja@email.com', 'password123', 'Scientist', '357 Rain Street, City', 'mother'),
('Vivek Choudhary', '9876543224', 'vivek@email.com', 'password123', 'Pharmacist', '468 Snow View, City', 'father'),
('Anjali Mehta', '9876543225', 'anjali@email.com', 'password123', 'Psychologist', '579 Sun Rise Lane, City', 'mother'),
('Dinesh Das', '9876543226', 'dinesh@email.com', 'password123', 'Professor', '680 Moon Light Road, City', 'father'),
('Sunita Bose', '9876543227', 'sunita@email.com', 'password123', 'Doctor', '791 Star Light Avenue, City', 'mother'),
('Manoj Chatterjee', '9876543228', 'manoj@email.com', 'password123', 'Banker', '802 Cloud Nine Road, City', 'father'),
('Savita Roy', '9876543229', 'savita@email.com', 'password123', 'Teacher', '913 Rain Drop Lane, City', 'mother'),
('Rajendra Trivedi', '9876543230', 'rajendra@email.com', 'password123', 'Engineer', '124 Snow Fall View, City', 'father'),
('Asha Nair', '9876543231', 'asha@email.com', 'password123', 'Writer', '235 Sun Set Street, City', 'mother'),
('Prakash Menon', '9876543232', 'prakash@email.com', 'password123', 'Civil Engineer', '346 Moon Rise Road, City', 'father'),
('Lakshmi Pillai', '9876543233', 'lakshmi@email.com', 'password123', 'Doctor', '457 Star Dust Avenue, City', 'mother'),
('Gopal Iyer', '9876543234', 'gopal@email.com', 'password123', 'Accountant', '568 Cloud Burst Lane, City', 'father');

-- Insert student data
INSERT INTO students (name, branch, current_semester, batch_year, phone, email, password, address, parent_id) VALUES
-- 2021 Batch (7th/8th Semester)
('Arjun Kumar', 'Computer Science', 7, 2021, '8765432101', 'arjun@email.com', 'student123', '123 College Road, City', 1),
('Sangeeta Sharma', 'Computer Science', 7, 2021, '8765432102', 'sangeeta@email.com', 'student123', '456 University Lane, City', 2),
('Rahul Singh', 'Electronics', 7, 2021, '8765432103', 'rahul.s@email.com', 'student123', '789 Campus Street, City', 3),
('Neha Patel', 'Electronics', 7, 2021, '8765432104', 'neha.p@email.com', 'student123', '321 College Avenue, City', 4),
('Karan Gupta', 'Mechanical', 7, 2021, '8765432105', 'karan@email.com', 'student123', '654 University Road, City', 5),

-- 2022 Batch (5th/6th Semester)
('Priyanka Verma', 'Computer Science', 5, 2022, '8765432106', 'priyanka@email.com', 'student123', '987 College Lane, City', 6),
('Amit Jain', 'Computer Science', 5, 2022, '8765432107', 'amit.j@email.com', 'student123', '159 University Street, City', 7),
('Deepika Agarwal', 'Computer Science', 5, 2022, '8765432108', 'deepika@email.com', 'student123', '753 Campus Avenue, City', 8),
('Vishal Khanna', 'Electronics', 5, 2022, '8765432109', 'vishal@email.com', 'student123', '246 College Road, City', 9),
('Anjali Kapoor', 'Electronics', 5, 2022, '8765432110', 'anjali.k@email.com', 'student123', '135 University Lane, City', 10),
('Vikram Mishra', 'Mechanical', 5, 2022, '8765432111', 'vikram@email.com', 'student123', '791 Campus Street, City', 11),
('Pooja Yadav', 'Mechanical', 5, 2022, '8765432112', 'pooja.y@email.com', 'student123', '842 College Avenue, City', 12),
('Rajesh Tiwari', 'Civil', 5, 2022, '8765432113', 'rajesh.t@email.com', 'student123', '953 University Road, City', 13),
('Kavita Malhotra', 'Civil', 5, 2022, '8765432114', 'kavita.m@email.com', 'student123', '357 Campus Lane, City', 14),
('Sunil Choudhary', 'Electrical', 5, 2022, '8765432115', 'sunil@email.com', 'student123', '468 College Street, City', 15),

-- 2023 Batch (3rd/4th Semester)
('Ananya Mehta', 'Computer Science', 3, 2023, '8765432116', 'ananya@email.com', 'student123', '579 University Avenue, City', 16),
('Rohit Das', 'Computer Science', 3, 2023, '8765432117', 'rohit@email.com', 'student123', '680 Campus Road, City', 17),
('Shweta Bose', 'Electronics', 3, 2023, '8765432118', 'shweta@email.com', 'student123', '791 College Lane, City', 18),
('Aditya Chatterjee', 'Electronics', 3, 2023, '8765432119', 'aditya@email.com', 'student123', '802 University Street, City', 19),
('Shreya Roy', 'Mechanical', 3, 2023, '8765432120', 'shreya@email.com', 'student123', '913 Campus Avenue, City', 20),

-- 2024 Batch (1st/2nd Semester)
('Vivek Trivedi', 'Computer Science', 1, 2024, '8765432121', 'vivek.t@email.com', 'student123', '124 College Road, City', 21),
('Ritu Nair', 'Computer Science', 1, 2024, '8765432122', 'ritu@email.com', 'student123', '235 University Lane, City', 22),
('Sanjay Menon', 'Electronics', 1, 2024, '8765432123', 'sanjay.m@email.com', 'student123', '346 Campus Street, City', 23),
('Divya Pillai', 'Mechanical', 1, 2024, '8765432124', 'divya@email.com', 'student123', '457 College Avenue, City', 24),
('Mohan Iyer', 'Civil', 1, 2024, '8765432125', 'mohan@email.com', 'student123', '568 University Road, City', 25);

-- Insert teacher data
-- Insert more detailed teacher data (expanding on the initial 5 teachers)
INSERT INTO teachers (name, department_id, phone, email, password, date_of_joining) VALUES
-- Computer Science Department (department_id = 1)
('Dr. Anil Kumar', 1, '9876543220', 'anil@example.com', 'password123', '2018-07-15'),
('Prof. Priya Sharma', 1, '9876543235', 'priya.sharma@example.com', 'password123', '2019-01-10'),
('Dr. Rajesh Patel', 1, '9876543236', 'rajesh.patel@example.com', 'password123', '2020-03-22'),
('Prof. Meena Gupta', 1, '9876543237', 'meena.gupta@example.com', 'password123', '2017-11-05'),
('Dr. Sanjay Verma', 1, '9876543238', 'sanjay.verma@example.com', 'password123', '2021-02-18'),

-- Electronics Department (department_id = 2)
('Prof. Meena Sharma', 2, '9876543221', 'meena@example.com', 'password123', '2017-08-10'),
('Dr. Vikram Singh', 2, '9876543239', 'vikram.singh@example.com', 'password123', '2019-05-15'),
('Prof. Anjali Reddy', 2, '9876543240', 'anjali.reddy@example.com', 'password123', '2018-09-20'),
('Dr. Arun Desai', 2, '9876543241', 'arun.desai@example.com', 'password123', '2020-01-12'),
('Prof. Neha Kapoor', 2, '9876543242', 'neha.kapoor@example.com', 'password123', '2021-07-30'),

-- Mechanical Department (department_id = 3)
('Dr. Ravi Verma', 3, '9876543222', 'ravi@example.com', 'password123', '2019-06-22'),
('Prof. Sunil Kumar', 3, '9876543243', 'sunil.kumar@example.com', 'password123', '2018-04-17'),
('Dr. Deepak Joshi', 3, '9876543244', 'deepak.joshi@example.com', 'password123', '2020-08-25'),
('Prof. Kavita Mishra', 3, '9876543245', 'kavita.mishra@example.com', 'password123', '2017-12-10'),
('Dr. Manoj Tiwari', 3, '9876543246', 'manoj.tiwari@example.com', 'password123', '2021-03-05'),

-- Civil Department (department_id = 4)
('Prof. Shikha Gupta', 4, '9876543223', 'shikha@example.com', 'password123', '2016-09-05'),
('Dr. Alok Choudhary', 4, '9876543247', 'alok.choudhary@example.com', 'password123', '2019-11-20'),
('Prof. Ritu Singh', 4, '9876543248', 'ritu.singh@example.com', 'password123', '2018-07-15'),
('Dr. Prakash Yadav', 4, '9876543249', 'prakash.yadav@example.com', 'password123', '2020-02-28'),
('Prof. Sneha Agarwal', 4, '9876543250', 'sneha.agarwal@example.com', 'password123', '2021-05-10'),

-- Electrical Department (department_id = 5)
('Dr. Ajay Singh', 5, '9876543224', 'ajay@example.com', 'password123', '2020-01-15'),
('Prof. Nisha Rao', 5, '9876543251', 'nisha.rao@example.com', 'password123', '2019-04-22'),
('Dr. Vivek Malhotra', 5, '9876543252', 'vivek.malhotra@example.com', 'password123', '2018-10-05'),
('Prof. Amit Khanna', 5, '9876543253', 'amit.khanna@example.com', 'password123', '2021-01-18'),
('Dr. Pooja Bhatia', 5, '9876543254', 'pooja.bhatia@example.com', 'password123', '2017-06-30');
-- Insert academic_records for CS students
-- Student 1 (Amit Kumar): CS student with 6 semesters, consistently good performance
-- Semester 1
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
(1, 1, 1, 85), (1, 1, 2, 82), (1, 1, 3, 88), (1, 1, 4, 90), (1, 1, 5, 78), (1, 1, 6, 92);

-- Student 2 (good student)
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
(2, 1, 1, 80), (2, 1, 2, 85), (2, 1, 3, 75), (2, 1, 4, 88), (2, 1, 5, 82), (2, 1, 6, 79);

-- Student 3 (average student with weakness in mathematics)
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
(3, 1, 1, 45), (3, 1, 2, 75), (3, 1, 3, 70), (3, 1, 4, 65), (3, 1, 5, 62), (3, 1, 6, 68);

-- Student 4 (weak student, potential dropout risk)
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
(4, 1, 1, 35), (4, 1, 2, 42), (4, 1, 3, 38), (4, 1, 4, 55), (4, 1, 5, 40), (4, 1, 6, 39);

-- Student 5 (average student)
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
(5, 1, 1, 65), (5, 1, 2, 62), (5, 1, 3, 70), (5, 1, 4, 75), (5, 1, 5, 68), (5, 1, 6, 72);

-- Student 6-10 (mixed performance)
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
(6, 5, 1, 75), (6, 5, 2, 70), (6, 5, 3, 72), (6, 5, 4, 68), (6, 5, 5, 74), (6, 5, 6, 71),
(7, 5, 1, 85), (7, 5, 2, 82), (7, 5, 3, 88), (7, 5, 4, 84), (7, 5, 5, 78), (7, 5, 6, 86),
(8, 5, 1, 55), (8, 5, 2, 35), (8, 5, 3, 40), (8, 5, 4, 48), (8, 5, 5, 52), (8, 5, 6, 43),
(9, 5, 1, 60), (9, 5, 2, 65), (9, 5, 3, 62), (9, 5, 4, 68), (9, 5, 5, 64), (9, 5, 6, 66),
(10, 5, 1, 78), (10, 5, 2, 75), (10, 5, 3, 80), (10, 5, 4, 76), (10, 5, 5, 73), (10, 5, 6, 77);

-- Student 11-15 (more mixed performance)
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
(11, 5, 1, 82), (11, 5, 2, 78), (11, 5, 3, 85), (11, 5, 4, 80), (11, 5, 5, 76), (11, 5, 6, 83),
(12, 5, 1, 30), (12, 5, 2, 35), (12, 5, 3, 28), (12, 5, 4, 40), (12, 5, 5, 32), (12, 5, 6, 38),
(13, 5, 1, 68), (13, 5, 2, 65), (13, 5, 3, 72), (13, 5, 4, 70), (13, 5, 5, 66), (13, 5, 6, 74),
(14, 5, 1, 58), (14, 5, 2, 55), (14, 5, 3, 62), (14, 5, 4, 60), (14, 5, 5, 56), (14, 5, 6, 64),
(15, 5, 1, 25), (15, 5, 2, 32), (15, 5, 3, 30), (15, 5, 4, 28), (15, 5, 5, 35), (15, 5, 6, 33);

-- Student 16-20 (2023 batch, 3rd semester)
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
(16, 3, 13, 72), (16, 3, 14, 68), (16, 3, 15, 75), (16, 3, 16, 70), (16, 3, 17, 66), (16, 3, 18, 73),
(17, 3, 13, 38), (17, 3, 14, 35), (17, 3, 15, 30), (17, 3, 16, 42), (17, 3, 17, 36), (17, 3, 18, 40),
(18, 3, 13, 58), (18, 3, 14, 55), (18, 3, 15, 62), (18, 3, 16, 60), (18, 3, 17, 56), (18, 3, 18, 64),
(19, 3, 13, 82), (19, 3, 14, 78), (19, 3, 15, 85), (19, 3, 16, 80), (19, 3, 17, 76), (19, 3, 18, 83),
(20, 3, 13, 28), (20, 3, 14, 25), (20, 3, 15, 35), (20, 3, 16, 30), (20, 3, 17, 32), (20, 3, 18, 27);

-- Student 21-25 (2024 batch, 1st semester - currently studying)
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
(21, 3, 1, 65), (21, 3, 2, 62), (21, 3, 3, 68), (21, 3, 4, 66), (21, 3, 5, 60), (21, 3, 6, 70),
(22, 3, 1, 35), (22, 3, 2, 30), (22, 3, 3, 40), (22, 3, 4, 38), (22, 3, 5, 32), (22, 3, 6, 36),
(23, 3, 1, 75), (23, 3, 2, 72), (23, 3, 3, 78), (23, 3, 4, 76), (23, 3, 5, 70), (23, 3, 6, 80),
(24, 3, 1, 55), (24, 3, 2, 52), (24, 3, 3, 58), (24, 3, 4, 56), (24, 3, 5, 50), (24, 3, 6, 60),
(25, 3, 1, 25), (25, 3, 2, 22), (25, 3, 3, 28), (25, 3, 4, 26), (25, 3, 5, 30), (25, 3, 6, 24);

-- Semester 2 records (All 25 students have completed this too)
-- Student 1
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
(1, 2, 7, 88), (1, 2, 8, 85), (1, 2, 9, 90), (1, 2, 10, 87), (1, 2, 11, 84), (1, 2, 12, 92);

-- Student 2
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
(2, 2, 7, 82), (2, 2, 8, 85), (2, 2, 9, 78), (2, 2, 10, 88), (2, 2, 11, 80), (2, 2, 12, 84);

-- Student 3 (continued weakness in math)
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
(3, 2, 7, 42), (3, 2, 8, 68), (3, 2, 9, 72), (3, 2, 10, 65), (3, 2, 11, 70), (3, 2, 12, 74);

-- Student 4 (continued poor performance, high dropout risk)
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
(4, 2, 7, 32), (4, 2, 8, 38), (4, 2, 9, 35), (4, 2, 10, 40), (4, 2, 11, 36), (4, 2, 12, 34);

-- Student 5
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
(5, 2, 7, 68), (5, 2, 8, 65), (5, 2, 9, 72), (5, 2, 10, 70), (5, 2, 11, 66), (5, 2, 12, 74);

-- Let's add some more records for student 1 to 5 (2021 batch) for semesters 3 to 7
-- Student 1 (Semesters 3-7)
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
-- Semester 3
(1, 13, 13, 86), (1, 13, 14, 82), (1, 13, 15, 88), (1, 13, 16, 84), (1, 13, 17, 80), (1, 13, 18, 90),
-- Semester 4
(1, 14, 19, 84), (1, 14, 20, 80), (1, 14, 21, 86), (1, 14, 22, 82), (1, 14, 23, 78), (1, 14, 24, 88),
-- Semester 5
(1, 15, 25, 88), (1, 15, 26, 84), (1, 15, 27, 90), (1, 15, 28, 86), (1, 15, 29, 82), (1, 15, 30, 92),
-- Semester 6
(1, 16, 31, 86), (1, 16, 32, 82), (1, 16, 33, 88), (1, 16, 34, 84), (1, 16, 35, 80), (1, 16, 36, 90),
-- Semester 7
(1, 17, 37, 90), (1, 17, 38, 86), (1, 17, 39, 92), (1, 17, 40, 88), (1, 17, 41, 84), (1, 17, 42, 94);

-- Student 2 (Semesters 3-7)
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
-- Semester 3
(2, 13, 13, 80), (2, 13, 14, 76), (2, 13, 15, 82), (2, 13, 16, 78), (2, 13, 17, 74), (2, 13, 18, 84),
-- Semester 4
(2, 14, 19, 78), (2, 14, 20, 74), (2, 14, 21, 80), (2, 14, 22, 76), (2, 14, 23, 72), (2, 14, 24, 82),
-- Semester 5
(2, 15, 25, 82), (2, 15, 26, 78), (2, 15, 27, 84), (2, 15, 28, 80), (2, 15, 29, 76), (2, 15, 30, 86),
-- Semester 6
(2, 16, 31, 80), (2, 16, 32, 76), (2, 16, 33, 82), (2, 16, 34, 78), (2, 16, 35, 74), (2, 16, 36, 84),
-- Semester 7
(2, 17, 37, 84), (2, 17, 38, 80), (2, 17, 39, 86), (2, 17, 40, 82), (2, 17, 41, 78), (2, 17, 42, 88);

-- Student 3 (Semesters 3-7, continued math weakness)
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
-- Semester 3
(3, 13, 13, 45), (3, 13, 14, 68), (3, 13, 15, 70), (3, 13, 16, 66), (3, 13, 17, 46), (3, 13, 18, 72),
-- Semester 4
(3, 14, 19, 48), (3, 14, 20, 70), (3, 14, 21, 72), (3, 14, 22, 68), (3, 14, 23, 47), (3, 14, 24, 74),
-- Semester 5
(3, 15, 25, 50), (3, 15, 26, 72), (3, 15, 27, 74), (3, 15, 28, 70), (3, 15, 29, 48), (3, 15, 30, 76),
-- Semester 6
(3, 16, 31, 45), (3, 16, 32, 70), (3, 16, 33, 73), (3, 16, 34, 69), (3, 16, 35, 47), (3, 16, 36, 75),
-- Semester 7
(3, 17, 37, 42), (3, 17, 38, 68), (3, 17, 39, 71), (3, 17, 40, 67), (3, 17, 41, 44), (3, 17, 42, 73);

-- Student 4 (Semesters 3-7, continued poor performance, high dropout risk)
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
-- Semester 3
(4, 13, 13, 30), (4, 13, 14, 35), (4, 13, 15, 32), (4, 13, 16, 36), (4, 13, 17, 31), (4, 13, 18, 34),
-- Semester 4
(4, 14, 19, 28), (4, 14, 20, 33), (4, 14, 21, 30), (4, 14, 22, 34), (4, 14, 23, 29), (4, 14, 24, 32),
-- Semester 5
(4, 15, 25, 25), (4, 15, 26, 30), (4, 15, 27, 28), (4, 15, 28, 32), (4, 15, 29, 27), (4, 15, 30, 29),
-- Semester 6
(4, 16, 31, 23), (4, 16, 32, 28), (4, 16, 33, 26), (4, 16, 34, 30), (4, 16, 35, 25), (4, 16, 36, 27),
-- Semester 7
(4, 17, 37, 20), (4, 17, 38, 26), (4, 17, 39, 24), (4, 17, 40, 28), (4, 17, 41, 22), (4, 17, 42, 25);

-- Student 5 (Semesters 3-7)
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
-- Semester 3
(5, 13, 13, 70), (5, 13, 14, 66), (5, 13, 15, 72), (5, 13, 16, 68), (5, 13, 17, 64), (5, 13, 18, 74),
-- Semester 4
(5, 14, 19, 68), (5, 14, 20, 64), (5, 14, 21, 70), (5, 14, 22, 66), (5, 14, 23, 62), (5, 14, 24, 72),
-- Semester 5
(5, 15, 25, 72), (5, 15, 26, 68), (5, 15, 27, 74), (5, 15, 28, 70), (5, 15, 29, 66), (5, 15, 30, 76),
-- Semester 6
(5, 16, 31, 70), (5, 16, 32, 66), (5, 16, 33, 72), (5, 16, 34, 68), (5, 16, 35, 64), (5, 16, 36, 74),
-- Semester 7
(5, 17, 37, 74), (5, 17, 38, 70), (5, 17, 39, 76), (5, 17, 40, 72), (5, 17, 41, 68), (5, 17, 42, 78);

-- Now let's add semester 3 and 4 for students 6-15 (2022 batch)
-- Student 6 (Semesters 3-4)
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
-- Semester 3
(6, 7, 13, 74), (6, 7, 14, 70), (6, 7, 15, 76), (6, 7, 16, 72), (6, 7, 17, 68), (6, 7, 18, 78),
-- Semester 4
(6, 8, 19, 72), (6, 8, 20, 68), (6, 8, 21, 74), (6, 8, 22, 70), (6, 8, 23, 66), (6, 8, 24, 76);

-- Student 7 (Semesters 3-4, good performance)
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
-- Semester 3
(7, 7, 13, 84), (7, 7, 14, 80), (7, 7, 15, 86), (7, 7, 16, 82), (7, 7, 17, 78), (7, 7, 18, 88),
-- Semester 4
(7, 8, 19, 86), (7, 8, 20, 82), (7, 8, 21, 88), (7, 8, 22, 84), (7, 8, 23, 80), (7, 8, 24, 90);

-- Student 8 (Semesters 3-4, very poor performance in multiple subjects)
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
-- Semester 3
(8, 7, 13, 38), (8, 7, 14, 42), (8, 7, 15, 35), (8, 7, 16, 40), (8, 7, 17, 36), (8, 7, 18, 39),
-- Semester 4
(8, 8, 19, 32), (8, 8, 20, 36), (8, 8, 21, 30), (8, 8, 22, 34), (8, 8, 23, 33), (8, 8, 24, 35);

-- Student 9 (Semesters 3-4)
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
-- Semester 3
(9, 7, 13, 64), (9, 7, 14, 60), (9, 7, 15, 66), (9, 7, 16, 62), (9, 7, 17, 58), (9, 7, 18, 68),
-- Semester 4
(9, 8, 19, 66), (9, 8, 20, 62), (9, 8, 21, 68), (9, 8, 22, 64), (9, 8, 23, 60), (9, 8, 24, 70);

-- Student 10 (Semesters 3-4)
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
-- Semester 3
(10, 7, 13, 76), (10, 7, 14, 72), (10, 7, 15, 78), (10, 7, 16, 74), (10, 7, 17, 70), (10, 7, 18, 80),
-- Semester 4
(10, 8, 19, 78), (10, 8, 20, 74), (10, 8, 21, 80), (10, 8, 22, 76), (10, 8, 23, 72), (10, 8, 24, 82);

-- Student 11 (Semesters 3-4)
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
-- Semester 3
(11, 7, 13, 80), (11, 7, 14, 76), (11, 7, 15, 82), (11, 7, 16, 78), (11, 7, 17, 74), (11, 7, 18, 84),
-- Semester 4
(11, 8, 19, 82), (11, 8, 20, 78), (11, 8, 21, 84), (11, 8, 22, 80), (11, 8, 23, 76), (11, 8, 24, 86);

-- Student 12 (Semesters 3-4, very poor performance, high dropout risk)
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
-- Semester 3
(12, 7, 13, 32), (12, 7, 14, 28), (12, 7, 15, 34), (12, 7, 16, 30), (12, 7, 17, 26), (12, 7, 18, 36),
-- Semester 4
(12, 8, 19, 30), (12, 8, 20, 26), (12, 8, 21, 32), (12, 8, 22, 28), (12, 8, 23, 24), (12, 8, 24, 34);

-- Student 13 (Semesters 3-4)
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
-- Semester 3
(13, 7, 13, 70), (13, 7, 14, 66), (13, 7, 15, 72), (13, 7, 16, 68), (13, 7, 17, 64), (13, 7, 18, 74),
-- Semester 4
(13, 8, 19, 72), (13, 8, 20, 68), (13, 8, 21, 74), (13, 8, 22, 70), (13, 8, 23, 66), (13, 8, 24, 76);

-- Student 14 (Semesters 3-4)
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
-- Semester 3
(14, 7, 13, 60), (14, 7, 14, 56), (14, 7, 15, 62), (14, 7, 16, 58), (14, 7, 17, 54), (14, 7, 18, 64),
-- Semester 4
(14, 8, 19, 62), (14, 8, 20, 58), (14, 8, 21, 64), (14, 8, 22, 60), (14, 8, 23, 56), (14, 8, 24, 66);

-- Student 15 (Semesters 3-4, very poor performance)
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
-- Semester 3
(15, 7, 13, 28), (15, 7, 14, 32), (15, 7, 15, 30), (15, 7, 16, 34), (15, 7, 17, 26), (15, 7, 18, 29),
-- Semester 4
(15, 8, 19, 25), (15, 8, 20, 30), (15, 8, 21, 28), (15, 8, 22, 32), (15, 8, 23, 27), (15, 8, 24, 26);

-- Let's add semester 2 for students 16-25 who should have completed at least 2 semesters
-- Student 16 (Semester 2)
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
(16, 4, 7, 70), (16, 4, 8, 66), (16, 4, 9, 72), (16, 4, 10, 68), (16, 4, 11, 64), (16, 4, 12, 74);

-- Student 17 (Semester 2, poor performance)
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
(17, 4, 7, 35), (17, 4, 8, 38), (17, 4, 9, 32), (17, 4, 10, 40), (17, 4, 11, 36), (17, 4, 12, 34);

-- Student 18 (Semester 2)
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
(18, 4, 7, 60), (18, 4, 8, 56), (18, 4, 9, 62), (18, 4, 10, 58), (18, 4, 11, 54), (18, 4, 12, 64);

-- Student 19 (Semester 2)
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
(19, 4, 7, 80), (19, 4, 8, 76), (19, 4, 9, 82), (19, 4, 10, 78), (19, 4, 11, 74), (19, 4, 12, 84);

-- Student 20 (Semester 2, poor performance)
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
(20, 4, 7, 28), (20, 4, 8, 30), (20, 4, 9, 26), (20, 4, 10, 32), (20, 4, 11, 29), (20, 4, 12, 27);

-- Insert weak_subjects for the students having poor performances
INSERT INTO weak_subjects (student_id, subject_code, subject_name) VALUES
-- Student 3 (weak in math)
(3, 'MTH101', 'Engineering Mathematics I'),
(3, 'MTH102', 'Engineering Mathematics II'),
(3, 'MTH201', 'Probability and Statistics'),
(3, 'MTH202', 'Numerical Methods'),

-- Student 4 (multiple weak subjects)
(4, 'MTH101', 'Engineering Mathematics I'),
(4, 'PHY101', 'Engineering Physics'),
(4, 'CHM101', 'Engineering Chemistry'),
(4, 'CSE201', 'Data Structures'),
(4, 'CSE205', 'Algorithms Design'),
(4, 'CSE303', 'Artificial Intelligence'),

-- Student 8 (multiple weak subjects)
(8, 'MTH101', 'Engineering Mathematics I'),
(8, 'PHY101', 'Engineering Physics'),
(8, 'CSE201', 'Data Structures'),
(8, 'CSE202', 'Digital Logic Design'),

-- Student 12 (multiple weak subjects)
(12, 'MTH101', 'Engineering Mathematics I'),
(12, 'ELE101', 'Basic Electrical Engineering'),
(12, 'CSE201', 'Data Structures'),
(12, 'CSE206', 'Database Management Systems'),

-- Student 15 (multiple weak subjects)
(15, 'MTH101', 'Engineering Mathematics I'),
(15, 'PHY101', 'Engineering Physics'),
(15, 'CSE201', 'Data Structures'),
(15, 'CSE205', 'Algorithms Design'),

-- Student 17 (multiple weak subjects)
(17, 'MTH101', 'Engineering Mathematics I'),
(17, 'CSE101', 'Introduction to Programming'),
(17, 'CSE201', 'Data Structures'),

-- Student 20 (multiple weak subjects)
(20, 'MTH101', 'Engineering Mathematics I'),
(20, 'MEC101', 'Engineering Mechanics'),
(20, 'CSE201', 'Data Structures'),

-- Student 22 (first year with weak subjects)
(22, 'MTH101', 'Engineering Mathematics I'),
(22, 'PHY101', 'Engineering Physics'),
(22, 'CSE101', 'Introduction to Programming'),

-- Student 25 (first year with weak subjects)
(25, 'MTH101', 'Engineering Mathematics I'),
(25, 'PHY101', 'Engineering Physics'),
(25, 'CHM101', 'Engineering Chemistry'),
(25, 'CSE101', 'Introduction to Programming');

-- Insert attendance_records for CS students (first semester only as example)
-- Student 1: Good attendance
-- Insert attendance records for students (75-85% attendance for most, some with <50%)
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
-- Student 1 (good attendance)
(1, 1, 1, 85), (1, 1, 2, 88), (1, 1, 3, 82), (1, 1, 4, 90), (1, 1, 5, 84), (1, 1, 6, 86),
(1, 2, 7, 87), (1, 2, 8, 89), (1, 2, 9, 85), (1, 2, 10, 91), (1, 2, 11, 83), (1, 2, 12, 88),

-- Student 4 (poor attendance)
(4, 1, 1, 45), (4, 1, 2, 50), (4, 1, 3, 48), (4, 1, 4, 52), (4, 1, 5, 47), (4, 1, 6, 49),
(4, 2, 7, 42), (4, 2, 8, 46), (4, 2, 9, 40), (4, 2, 10, 44), (4, 2, 11, 38), (4, 2, 12, 43),

-- Student 8 (very poor attendance)
(8, 5, 1, 35), (8, 5, 2, 40), (8, 5, 3, 38), (8, 5, 4, 42), (8, 5, 5, 36), (8, 5, 6, 39),

-- Student 12 (poor attendance)
(12, 5, 1, 48), (12, 5, 2, 52), (12, 5, 3, 50), (12, 5, 4, 46), (12, 5, 5, 44), (12, 5, 6, 49),

-- Student 15 (very poor attendance)
(15, 5, 1, 30), (15, 5, 2, 35), (15, 5, 3, 32), (15, 5, 4, 38), (15, 5, 5, 34), (15, 5, 6, 36),

-- Student 17 (poor attendance)
(17, 3, 13, 45), (17, 3, 14, 50), (17, 3, 15, 48), (17, 3, 16, 52), (17, 3, 17, 47), (17, 3, 18, 49),

-- Student 20 (very poor attendance)
(20, 3, 13, 28), (20, 3, 14, 32), (20, 3, 15, 30), (20, 3, 16, 35), (20, 3, 17, 33), (20, 3, 18, 31),

-- Student 22 (poor attendance)
(22, 3, 1, 42), (22, 3, 2, 46), (22, 3, 3, 44), (22, 3, 4, 48), (22, 3, 5, 40), (22, 3, 6, 45),

-- Student 25 (very poor attendance)
(25, 3, 1, 25), (25, 3, 2, 30), (25, 3, 3, 28), (25, 3, 4, 32), (25, 3, 5, 26), (25, 3, 6, 29),

-- Other students with good attendance (75-85%)
(2, 1, 1, 80), (2, 1, 2, 82), (2, 1, 3, 78), (2, 1, 4, 85), (2, 1, 5, 80), (2, 1, 6, 83),
(3, 1, 1, 75), (3, 1, 2, 78), (3, 1, 3, 72), (3, 1, 4, 80), (3, 1, 5, 74), (3, 1, 6, 77),
(5, 1, 1, 82), (5, 1, 2, 85), (5, 1, 3, 80), (5, 1, 4, 88), (5, 1, 5, 78), (5, 1, 6, 84),
(6, 5, 1, 78), (6, 5, 2, 80), (6, 5, 3, 75), (6, 5, 4, 82), (6, 5, 5, 76), (6, 5, 6, 79),
(7, 5, 1, 85), (7, 5, 2, 88), (7, 5, 3, 82), (7, 5, 4, 90), (7, 5, 5, 84), (7, 5, 6, 86),
(9, 5, 1, 80), (9, 5, 2, 82), (9, 5, 3, 78), (9, 5, 4, 85), (9, 5, 5, 80), (9, 5, 6, 83),
(10, 5, 1, 82), (10, 5, 2, 85), (10, 5, 3, 80), (10, 5, 4, 88), (10, 5, 5, 78), (10, 5, 6, 84),
(11, 5, 1, 78), (11, 5, 2, 80), (11, 5, 3, 75), (11, 5, 4, 82), (11, 5, 5, 76), (11, 5, 6, 79),
(13, 5, 1, 80), (13, 5, 2, 82), (13, 5, 3, 78), (13, 5, 4, 85), (13, 5, 5, 80), (13, 5, 6, 83),
(14, 5, 1, 75), (14, 5, 2, 78), (14, 5, 3, 72), (14, 5, 4, 80), (14, 5, 5, 74), (14, 5, 6, 77),
(16, 3, 13, 82), (16, 3, 14, 85), (16, 3, 15, 80), (16, 3, 16, 88), (16, 3, 17, 78), (16, 3, 18, 84),
(18, 3, 13, 80), (18, 3, 14, 82), (18, 3, 15, 78), (18, 3, 16, 85), (18, 3, 17, 80), (18, 3, 18, 83),
(19, 3, 13, 85), (19, 3, 14, 88), (19, 3, 15, 82), (19, 3, 16, 90), (19, 3, 17, 84), (19, 3, 18, 86),
(21, 3, 1, 80), (21, 3, 2, 82), (21, 3, 3, 78), (21, 3, 4, 85), (21, 3, 5, 80), (21, 3, 6, 83),
(23, 3, 1, 85), (23, 3, 2, 88), (23, 3, 3, 82), (23, 3, 4, 90), (23, 3, 5, 84), (23, 3, 6, 86),
(24, 3, 1, 75), (24, 3, 2, 78), (24, 3, 3, 72), (24, 3, 4, 80), (24, 3, 5, 74), (24, 3, 6, 77);

-- Insert attendance_summary for the first semester for all students
-- Insert attendance summary for students (aggregating from attendance_records)
INSERT INTO attendance_summary (student_id, semester_id, attendance_percentage, days_present, days_absent, late_arrivals) VALUES
-- Student 1 (good attendance)
(1, 1, 85.5, 77, 13, 2),
(1, 2, 87.2, 78, 12, 1),

-- Student 2 (good attendance)
(2, 1, 82.3, 74, 16, 3),
(2, 2, 83.7, 75, 15, 2),

-- Student 3 (average attendance)
(3, 1, 75.8, 68, 22, 5),
(3, 2, 77.2, 69, 21, 4),

-- Student 4 (poor attendance)
(4, 1, 48.3, 43, 47, 8),
(4, 2, 42.1, 38, 52, 10),

-- Student 5 (good attendance)
(5, 1, 83.6, 75, 15, 3),
(5, 2, 84.9, 76, 14, 2),

-- Student 6 (good attendance)
(6, 5, 78.5, 71, 19, 4),
(6, 6, 79.8, 72, 18, 3),

-- Student 7 (excellent attendance)
(7, 5, 85.7, 77, 13, 1),
(7, 6, 86.9, 78, 12, 1),

-- Student 8 (very poor attendance)
(8, 5, 38.2, 34, 56, 12),
(8, 6, 35.7, 32, 58, 15),

-- Student 9 (good attendance)
(9, 5, 80.1, 72, 18, 3),
(9, 6, 81.4, 73, 17, 2),

-- Student 10 (good attendance)
(10, 5, 82.9, 75, 15, 3),
(10, 6, 84.2, 76, 14, 2),

-- Student 11 (good attendance)
(11, 5, 78.0, 70, 20, 4),
(11, 6, 79.3, 71, 19, 3),

-- Student 12 (poor attendance)
(12, 5, 48.9, 44, 46, 9),
(12, 6, 46.2, 42, 48, 11),

-- Student 13 (good attendance)
(13, 5, 80.5, 72, 18, 3),
(13, 6, 81.8, 74, 16, 2),

-- Student 14 (average attendance)
(14, 5, 75.2, 68, 22, 5),
(14, 6, 76.6, 69, 21, 4),

-- Student 15 (very poor attendance)
(15, 5, 32.8, 30, 60, 14),
(15, 6, 30.5, 27, 63, 16),

-- Student 16 (good attendance)
(16, 3, 83.1, 75, 15, 3),
(16, 4, 84.4, 76, 14, 2),

-- Student 17 (poor attendance)
(17, 3, 48.7, 44, 46, 9),
(17, 4, 46.0, 41, 49, 11),

-- Student 18 (good attendance)
(18, 3, 80.8, 73, 17, 3),
(18, 4, 82.1, 74, 16, 2),

-- Student 19 (excellent attendance)
(19, 3, 86.5, 78, 12, 1),
(19, 4, 87.8, 79, 11, 1),

-- Student 20 (very poor attendance)
(20, 3, 30.7, 28, 62, 15),
(20, 4, 28.4, 26, 64, 17),

-- Student 21 (good attendance)
(21, 3, 82.0, 74, 16, 3),
(21, 4, 83.3, 75, 15, 2),

-- Student 22 (poor attendance)
(22, 3, 42.5, 38, 52, 10),
(22, 4, 40.8, 37, 53, 12),

-- Student 23 (excellent attendance)
(23, 3, 85.9, 77, 13, 1),
(23, 4, 87.2, 78, 12, 1),

-- Student 24 (average attendance)
(24, 3, 75.6, 68, 22, 5),
(24, 4, 77.0, 69, 21, 4),

-- Student 25 (very poor attendance)
(25, 3, 28.3, 25, 65, 16),
(25, 4, 26.0, 23, 67, 18);

--- Insert admin data
INSERT INTO admin (name, email, password) VALUES
('Admin User', 'admin@example.com', 'adminpassword');

-- Update tests table to be consistent with academic records
INSERT INTO tests (test_name, test_type, course_id, semester_id, max_score) VALUES
-- Semester 1 courses (for 2021, 2023, 2024 batches)
('MTH101 Midterm', 'midterm', 1, 1, 30),
('MTH101 Final', 'final', 1, 1, 70),
('PHY101 Midterm', 'midterm', 2, 1, 30),
('PHY101 Final', 'final', 2, 1, 70),
('CHM101 Midterm', 'midterm', 3, 1, 30),
('CHM101 Final', 'final', 3, 1, 70),
('ENG101 Midterm', 'midterm', 4, 1, 30),
('ENG101 Final', 'final', 4, 1, 70),
('MEC101 Midterm', 'midterm', 5, 1, 30),
('MEC101 Final', 'final', 5, 1, 70),
('CSE101 Midterm', 'midterm', 6, 1, 30),
('CSE101 Final', 'final', 6, 1, 70),

-- Semester 2 courses
('MTH102 Midterm', 'midterm', 7, 2, 30),
('MTH102 Final', 'final', 7, 2, 70),
('PHY102 Midterm', 'midterm', 8, 2, 30),
('PHY102 Final', 'final', 8, 2, 70),
('ELE101 Midterm', 'midterm', 9, 2, 30),
('ELE101 Final', 'final', 9, 2, 70),
('EVS101 Midterm', 'midterm', 10, 2, 30),
('EVS101 Final', 'final', 10, 2, 70),
('ENG102 Midterm', 'midterm', 11, 2, 30),
('ENG102 Final', 'final', 11, 2, 70),
('CSE102 Midterm', 'midterm', 12, 2, 30),
('CSE102 Final', 'final', 12, 2, 70),

-- Semester 3 courses (Computer Science)
('CSE201 Midterm', 'midterm', 13, 3, 30),
('CSE201 Final', 'final', 13, 3, 70),
('CSE202 Midterm', 'midterm', 14, 3, 30),
('CSE202 Final', 'final', 14, 3, 70),
('CSE203 Midterm', 'midterm', 15, 3, 30),
('CSE203 Final', 'final', 15, 3, 70),
('CSE204 Midterm', 'midterm', 16, 3, 30),
('CSE204 Final', 'final', 16, 3, 70),
('MTH201 Midterm', 'midterm', 17, 3, 30),
('MTH201 Final', 'final', 17, 3, 70),
('HUM201 Midterm', 'midterm', 18, 3, 30),
('HUM201 Final', 'final', 18, 3, 70),

-- Semester 5 courses (Computer Science)
('CSE301 Midterm', 'midterm', 25, 5, 30),
('CSE301 Final', 'final', 25, 5, 70),
('CSE302 Midterm', 'midterm', 26, 5, 30),
('CSE302 Final', 'final', 26, 5, 70),
('CSE303 Midterm', 'midterm', 27, 5, 30),
('CSE303 Final', 'final', 27, 5, 70),
('CSE304 Midterm', 'midterm', 28, 5, 30),
('CSE304 Final', 'final', 28, 5, 70),
('CSE305 Midterm', 'midterm', 29, 5, 30),
('CSE305 Final', 'final', 29, 5, 70),
('CSE306 Midterm', 'midterm', 30, 5, 30),
('CSE306 Final', 'final', 30, 5, 70);

-- Insert student_test_results (connecting students with tests based on their courses)
INSERT INTO student_test_results (student_id, test_id, test_date, score) VALUES
-- Student 1 (good student)
(1, 1, '2023-03-15', 25),  -- MTH101 Midterm
(1, 2, '2023-05-10', 62),   -- MTH101 Final
(1, 3, '2023-03-20', 26),   -- PHY101 Midterm
(1, 4, '2023-05-15', 60),   -- PHY101 Final
(1, 5, '2023-03-25', 24),   -- CHM101 Midterm
(1, 6, '2023-05-20', 64),   -- CHM101 Final
(1, 13, '2023-03-15', 27),  -- MTH102 Midterm
(1, 14, '2023-05-10', 61),  -- MTH102 Final
(1, 15, '2023-03-20', 25),  -- PHY102 Midterm
(1, 16, '2023-05-15', 60),  -- PHY102 Final

-- Student 3 (average with math weakness)
(3, 1, '2023-03-15', 12),   -- MTH101 Midterm
(3, 2, '2023-05-10', 33),   -- MTH101 Final
(3, 3, '2023-03-20', 22),   -- PHY101 Midterm
(3, 4, '2023-05-15', 53),   -- PHY101 Final
(3, 13, '2023-03-15', 14),  -- MTH102 Midterm
(3, 14, '2023-05-10', 28),  -- MTH102 Final

-- Student 4 (poor performance)
(4, 1, '2023-03-15', 8),    -- MTH101 Midterm
(4, 2, '2023-05-10', 27),   -- MTH101 Final
(4, 3, '2023-03-20', 10),   -- PHY101 Midterm
(4, 4, '2023-05-15', 32),   -- PHY101 Final
(4, 13, '2023-03-15', 9),   -- MTH102 Midterm
(4, 14, '2023-05-10', 23),  -- MTH102 Final

-- Student 7 (good student)
(7, 25, '2023-03-15', 26),  -- CSE301 Midterm
(7, 26, '2023-05-10', 62),  -- CSE301 Final
(7, 27, '2023-03-20', 25),  -- CSE302 Midterm
(7, 28, '2023-05-15', 59),  -- CSE302 Final

-- Student 8 (poor performance)
(8, 25, '2023-03-15', 10),  -- CSE301 Midterm
(8, 26, '2023-05-10', 25),  -- CSE301 Final
(8, 27, '2023-03-20', 12),  -- CSE302 Midterm
(8, 28, '2023-05-15', 23),  -- CSE302 Final

-- Student 16 (good student)
(16, 37, '2024-03-15', 24), -- CSE201 Midterm
(16, 38, '2024-05-10', 59), -- CSE201 Final
(16, 39, '2024-03-20', 26), -- CSE202 Midterm
(16, 40, '2024-05-15', 62), -- CSE202 Final

-- Student 17 (poor performance)
(17, 37, '2024-03-15', 11), -- CSE201 Midterm
(17, 38, '2024-05-10', 27), -- CSE201 Final
(17, 39, '2024-03-20', 13), -- CSE202 Midterm
(17, 40, '2024-05-15', 25); -- CSE202 Final

-- Insert student_feedback (feedback from students about courses)
INSERT INTO student_feedback (student_id, course_id, feedback_text, sentiment_score) VALUES
-- Positive feedback
(1, 1, 'The mathematics course was well structured and the professor explained concepts clearly.', 0.85),
(1, 6, 'Introduction to Programming was excellent! The practical assignments really helped me learn.', 0.92),
(7, 25, 'Software Engineering course provided valuable real-world insights and project experience.', 0.88),
(16, 13, 'Data Structures was challenging but the professor made complex topics understandable.', 0.82),

-- Negative feedback (from struggling students)
(3, 1, 'The math course moved too fast and I struggled to keep up with the concepts.', -0.65),
(4, 2, 'Physics was too theoretical without enough practical examples to help understand.', -0.72),
(8, 26, 'Database concepts were not explained clearly and the assignments were too difficult.', -0.78),
(17, 13, 'Data Structures was too advanced for an introductory course, needed more basic examples.', -0.69);

-- Insert dropout_risk (risk assessment for students)
INSERT INTO dropout_risk (student_id, risk_score, risk_level, confidence_score, contributing_factors) VALUES
-- High risk students
(4, 0.85, 'High', 0.92, 'Poor academic performance, low attendance, multiple failed courses'),
(8, 0.78, 'High', 0.88, 'Consistently low grades, declining attendance'),
(12, 0.82, 'High', 0.90, 'Multiple failed courses, financial difficulties'),
(15, 0.79, 'High', 0.85, 'Very poor attendance, failing grades'),
(17, 0.76, 'High', 0.82, 'Struggling with core subjects, low motivation'),
(20, 0.81, 'High', 0.87, 'Poor performance across all subjects'),
(22, 0.72, 'Medium', 0.80, 'Struggling in first year, needs academic support'),
(25, 0.83, 'High', 0.89, 'Very poor first semester performance'),

-- Medium risk students
(3, 0.65, 'Medium', 0.78, 'Weak in mathematics but performing adequately in other subjects'),
(14, 0.58, 'Medium', 0.75, 'Average performance, some attendance issues'),

-- Low risk students
(1, 0.12, 'Low', 0.95, 'Consistently strong academic performance'),
(2, 0.15, 'Low', 0.93, 'Good grades and attendance'),
(5, 0.18, 'Low', 0.91, 'Steady performance across semesters'),
(7, 0.10, 'Low', 0.96, 'Excellent academic record'),
(10, 0.14, 'Low', 0.94, 'Strong performance in all courses'),
(16, 0.08, 'Low', 0.97, 'Top performer in class'),
(19, 0.05, 'Low', 0.98, 'Exceptional student with perfect attendance');

-- Insert online_courses (external courses that could help with weak subjects)
INSERT INTO online_courses (platform, course_title, course_url, description, subject_category, difficulty_level, price, is_free) VALUES
('Coursera', 'Mathematics for Engineers', 'https://coursera.org/math-engineers', 'Comprehensive math course covering all engineering mathematics topics', 'Mathematics', 'Intermediate', 49.99, FALSE),
('edX', 'Introduction to Data Structures', 'https://edx.org/data-structures', 'Learn fundamental data structures with practical implementations', 'Computer Science', 'Beginner', 0, TRUE),
('Udemy', 'Programming Fundamentals', 'https://udemy.com/programming-fundamentals', 'Master programming basics with hands-on exercises', 'Computer Science', 'Beginner', 19.99, FALSE),
('Khan Academy', 'College Algebra', 'https://khanacademy.org/college-algebra', 'Free algebra course covering all essential topics', 'Mathematics', 'Beginner', 0, TRUE),
('Coursera', 'Database Systems Concepts', 'https://coursera.org/database-systems', 'Learn database design and implementation', 'Computer Science', 'Intermediate', 49.99, FALSE),
('edX', 'Physics for Engineers', 'https://edx.org/physics-engineers', 'Applied physics concepts for engineering students', 'Physics', 'Intermediate', 99.99, FALSE),
('Udacity', 'Artificial Intelligence Fundamentals', 'https://udacity.com/ai-fundamentals', 'Intro to AI concepts and applications', 'Computer Science', 'Intermediate', 0, TRUE),
('Coursera', 'Algorithms Specialization', 'https://coursera.org/algorithms-spec', 'Comprehensive algorithms course series', 'Computer Science', 'Advanced', 79.99, FALSE),
('edX', 'Discrete Mathematics', 'https://edx.org/discrete-math', 'Essential discrete math for computer science', 'Mathematics', 'Intermediate', 0, TRUE),
('Udemy', 'Complete Web Development Bootcamp', 'https://udemy.com/web-dev-bootcamp', 'Full-stack web development course', 'Computer Science', 'Beginner', 29.99, FALSE);

-- Insert student_course_recommendations (connecting weak subjects with online courses)
INSERT INTO student_course_recommendations (student_id, weak_subject_id, online_course_id, is_viewed, is_enrolled) VALUES
-- Student 3 (weak in math)
(3, 1, 1, TRUE, TRUE),  -- Math course
(3, 2, 1, TRUE, TRUE),  -- Same math course for MTH102
(3, 3, 4, FALSE, FALSE), -- Khan Academy Algebra

-- Student 4 (multiple weak subjects)
(4, 4, 2, TRUE, FALSE), -- Data Structures
(4, 5, 8, FALSE, FALSE), -- Algorithms
(4, 6, 7, FALSE, FALSE), -- AI Fundamentals

-- Student 8 (weak in programming)
(8, 7, 3, TRUE, TRUE),  -- Programming Fundamentals
(8, 8, 5, TRUE, FALSE), -- Database Systems

-- Student 12 (weak in math and databases)
(12, 9, 1, FALSE, FALSE), -- Math for Engineers
(12, 10, 5, TRUE, TRUE),  -- Database Systems

-- Student 17 (weak in programming)
(17, 11, 3, TRUE, TRUE), -- Programming Fundamentals
(17, 12, 2, FALSE, FALSE), -- Data Structures

-- Student 22 (first year struggling)
(22, 13, 4, TRUE, TRUE), -- Khan Academy Algebra
(22, 14, 3, FALSE, FALSE); -- Programming Fundamentals

-- Insert external_scholarships (financial aid opportunities)
INSERT INTO external_scholarships (name, provider, category, eligibility_criteria, application_url, amount_range, deadline) VALUES
('National Engineering Scholarship', 'Government Education Dept', 'Merit-based', 'Minimum 75% marks in previous semester', 'https://scholarships.gov.in/eng', '₹50,000 per year', '2024-06-30'),
('STEM Talent Scholarship', 'Tech Foundation', 'Merit-based', 'Engineering students with 80%+ marks', 'https://stemfoundation.org/scholarships', '₹75,000 one-time', '2024-05-15'),
('Underprivileged Student Grant', 'Social Welfare Trust', 'Need-based', 'Family income < ₹5L/year', 'https://swtrust.org/grants', 'Full tuition + stipend', '2024-07-31'),
('Women in Tech Scholarship', 'Women Who Code', 'Diversity', 'Female engineering students', 'https://womenwhocode.com/scholarships', '₹1,00,000 per year', '2024-04-20'),
('Rural Student Scholarship', 'Education for All', 'Need-based', 'Students from rural areas', 'https://efa.org/rural-scholarship', '₹25,000 per semester', '2024-08-15'),
('Computer Science Excellence Award', 'CS Association', 'Merit-based', 'Top 10% CS students', 'https://csassociation.org/awards', '₹50,000 one-time', '2024-06-01'),
('First Generation Scholar Program', 'Higher Ed Foundation', 'Need-based', 'First in family to attend college', 'https://hefoundation.org/firstgen', '₹60,000 per year', '2024-09-10'),
('Disability Inclusion Grant', 'Equal Opportunity Trust', 'Diversity', 'Students with disabilities', 'https://eotrust.org/grants', '₹1,20,000 per year', '2024-07-15');

-- Insert student_scholarship_recommendations (matching students with scholarships)
INSERT INTO student_scholarship_recommendations (student_id, scholarship_id, match_score, is_viewed, is_applied) VALUES
-- High performing students (merit-based)
(1, 1, 0.95, TRUE, TRUE),   -- National Engineering Scholarship
(1, 2, 0.92, TRUE, FALSE),  -- STEM Talent Scholarship
(1, 6, 0.98, FALSE, FALSE), -- CS Excellence Award
(7, 1, 0.93, TRUE, TRUE),
(7, 2, 0.96, TRUE, TRUE),
(16, 1, 0.94, TRUE, FALSE),
(16, 6, 0.97, FALSE, FALSE),

-- Female students
(2, 4, 0.99, TRUE, TRUE),   -- Women in Tech
(10, 4, 0.98, TRUE, FALSE),
(14, 4, 0.95, FALSE, FALSE),

-- Need-based scholarships
(4, 3, 0.88, TRUE, TRUE),   -- Underprivileged Student Grant
(4, 5, 0.82, TRUE, FALSE),  -- Rural Student Scholarship
(8, 3, 0.85, FALSE, FALSE),
(12, 3, 0.90, TRUE, TRUE),
(17, 7, 0.92, TRUE, FALSE),  -- First Generation Scholar
(22, 5, 0.87, FALSE, FALSE);

-- Insert student_financial_assessment (financial background of students)
INSERT INTO student_financial_assessment (student_id, income_category, needs_financial_aid, eligible_for_aid_categories, household_size) VALUES
-- Wealthier students
(1, 'high', FALSE, NULL, 4),
(2, 'high', FALSE, NULL, 5),
(7, 'high', FALSE, NULL, 3),
(16, 'high', FALSE, NULL, 4),
(19, 'high', FALSE, NULL, 5),

-- Middle class students
(3, 'middle', TRUE, 'Partial scholarships, loans', 4),
(5, 'middle', FALSE, NULL, 3),
(10, 'middle', FALSE, NULL, 4),
(13, 'middle', TRUE, 'Partial scholarships', 5),
(18, 'middle', FALSE, NULL, 4),

-- Lower income students
(4, 'low', TRUE, 'Full scholarships, grants', 6),
(8, 'low', TRUE, 'Full scholarships, grants', 5),
(12, 'low', TRUE, 'Full scholarships, grants', 7),
(15, 'low', TRUE, 'Full scholarships, grants', 4),
(17, 'low', TRUE, 'Full scholarships, grants', 3),
(20, 'low', TRUE, 'Full scholarships, grants', 5),
(22, 'low', TRUE, 'Full scholarships, grants', 4),
(25, 'low', TRUE, 'Full scholarships, grants', 6);

-- Insert model_versions (tracking ML model versions)
INSERT INTO model_versions (model_name, model_version, description) VALUES
('Dropout Prediction', '1.0.0', 'Initial version with basic academic features'),
('Dropout Prediction', '1.1.0', 'Added attendance and financial features'),
('Dropout Prediction', '2.0.0', 'Improved with ensemble methods'),
('Course Recommendation', '1.0.0', 'Basic content-based filtering'),
('Scholarship Matching', '1.0.0', 'Rule-based matching engine');

-- Insert model_performance_metrics (tracking model performance)
INSERT INTO model_performance_metrics (model_version_id, training_date, accuracy, precision_score, recall_score, f1_score, auc_roc, feature_importance, hyperparameters) VALUES
(1, '2024-01-15 10:00:00', 0.82, 0.78, 0.85, 0.81, 0.89, 
 '{"attendance": 0.35, "gpa": 0.45, "failed_courses": 0.20}', 
 '{"n_estimators": 100, "max_depth": 5}'),
(2, '2024-02-20 11:30:00', 0.85, 0.81, 0.88, 0.84, 0.91, 
 '{"attendance": 0.30, "gpa": 0.40, "failed_courses": 0.15, "financial_need": 0.15}', 
 '{"n_estimators": 150, "max_depth": 7}'),
(3, '2024-03-10 09:15:00', 0.88, 0.85, 0.90, 0.87, 0.93, 
 '{"attendance": 0.25, "gpa": 0.35, "failed_courses": 0.15, "financial_need": 0.10, "sentiment": 0.15}', 
 '{"n_estimators": 200, "max_depth": 8, "learning_rate": 0.1}'),
(4, '2024-01-20 14:00:00', NULL, NULL, NULL, NULL, NULL, 
 '{"course_similarity": 0.60, "student_weaknesses": 0.40}', 
 '{"k_neighbors": 5}'),
(5, '2024-02-05 16:45:00', 0.92, 0.90, 0.94, 0.92, NULL, 
 '{"income_match": 0.40, "academic_match": 0.35, "demographic_match": 0.25}', 
 '{}');

-- Insert model_training_history (tracking training runs)
INSERT INTO model_training_history (model_version_id, accuracy, parameters, features_used) VALUES
(1, 0.82, '{"n_estimators": 100, "max_depth": 5}', 'gpa, attendance, failed_courses'),
(1, 0.81, '{"n_estimators": 120, "max_depth": 6}', 'gpa, attendance, failed_courses'),
(2, 0.85, '{"n_estimators": 150, "max_depth": 7}', 'gpa, attendance, failed_courses, financial_need'),
(2, 0.84, '{"n_estimators": 200, "max_depth": 5}', 'gpa, attendance, failed_courses, financial_need'),
(3, 0.88, '{"n_estimators": 200, "max_depth": 8, "learning_rate": 0.1}', 'gpa, attendance, failed_courses, financial_need, sentiment'),
(3, 0.87, '{"n_estimators": 250, "max_depth": 10, "learning_rate": 0.05}', 'gpa, attendance, failed_courses, financial_need, sentiment'),
(4, NULL, '{"k_neighbors": 5}', 'course_content, student_weaknesses'),
(5, 0.92, '{}', 'income, academics, demographics');

-- Insert api_integration_log (tracking external API calls)
INSERT INTO api_integration_log (service_name, response_status, records_processed, error_message, processing_time_ms) VALUES
('Scholarship Matching', 200, 15, NULL, 450),
('Course Recommendation', 200, 8, NULL, 320),
('Payment Gateway', 500, 0, 'Internal server error', 1200),
('Email Service', 200, 25, NULL, 180),
('SMS Gateway', 200, 25, NULL, 220),
('Scholarship Matching', 200, 10, NULL, 380),
('Course Recommendation', 429, 0, 'Rate limit exceeded', 150),
('Payment Gateway', 200, 5, NULL, 800);

-- Insert self_evaluation_score (student self-assessment vs actual scores)
INSERT INTO self_evaluation_score (student_id, test_id, test_score) VALUES
-- Student 1 (accurate self-assessment)
(1, 1, 24),  -- Self-evaluated 24 vs actual 25
(1, 2, 60),  -- Self-evaluated 60 vs actual 62
(1, 3, 25),  -- Self-evaluated 25 vs actual 26

-- Student 3 (overestimates)
(3, 1, 18),  -- Self-evaluated 18 vs actual 12
(3, 2, 40),  -- Self-evaluated 40 vs actual 33
(3, 3, 25),  -- Self-evaluated 25 vs actual 22

-- Student 4 (underestimates)
(4, 1, 5),   -- Self-evaluated 5 vs actual 8
(4, 2, 20),  -- Self-evaluated 20 vs actual 27
(4, 3, 8),   -- Self-evaluated 8 vs actual 10

-- Student 7 (accurate)
(7, 25, 25), -- Self-evaluated 25 vs actual 26
(7, 26, 60), -- Self-evaluated 60 vs actual 62

-- Student 8 (overestimates)
(8, 25, 15), -- Self-evaluated 15 vs actual 10
(8, 26, 30); -- Self-evaluated 30 vs actual 25

-- Insert study_resources (resources for weak subjects)
INSERT INTO study_resources (resource_name, resource_link, resource_type, subject_id) VALUES
('Math Cheat Sheet', 'https://university.edu/math-cheatsheet', 'PDF', 1),
('Data Structures Video Tutorials', 'https://youtube.com/playlist?list=DS101', 'Video', 4),
('Programming Exercises', 'https://codingpractice.org/beginner', 'Interactive', 7),
('Database Design Guide', 'https://dbguides.com/intro', 'Website', 10),
('Algebra Practice Problems', 'https://khanacademy.org/algebra-practice', 'Interactive', 13);

-- Insert dropout_history (students who have dropped out)
INSERT INTO dropout_history (student_id, dropout_date, dropout_reason, semester_id) VALUES
-- Historical dropouts (not current students)
(20, '2023-12-15', 'Financial difficulties', 2),
(21, '2023-12-15', 'Academic struggles', 2),
(22, '2024-05-30', 'Health issues', 3),
(23, '2022-12-15', 'Transferred to another university', 4),
(24, '2022-05-30', 'Personal reasons', 3);

use test_db;
-- Remove the extra semesters and keep only 8 (4 years * 2 semesters per year)
DELETE FROM academic_records WHERE semester_id > 8;
DELETE FROM attendance_records WHERE semester_id > 8;
DELETE FROM tests WHERE semester_id > 8;
DELETE FROM attendance_summary WHERE semester_id > 8;
DELETE FROM dropout_history WHERE semester_id > 8;

-- Then delete from semesters
DELETE FROM semesters WHERE semester_id > 8;

-- Update the existing semesters to represent 4 years (8 semesters)
UPDATE semesters 
SET 
    year = CASE semester_id 
        WHEN 1 THEN 2021 WHEN 2 THEN 2021 
        WHEN 3 THEN 2022 WHEN 4 THEN 2022 
        WHEN 5 THEN 2023 WHEN 6 THEN 2023 
        WHEN 7 THEN 2024 WHEN 8 THEN 2024 
    END,
    start_date = CASE semester_id 
        WHEN 1 THEN '2021-01-15' WHEN 2 THEN '2021-07-15' 
        WHEN 3 THEN '2022-01-15' WHEN 4 THEN '2022-07-15' 
        WHEN 5 THEN '2023-01-15' WHEN 6 THEN '2023-07-15' 
        WHEN 7 THEN '2024-01-15' WHEN 8 THEN '2024-07-15' 
    END,
    end_date = CASE semester_id 
    
        WHEN 1 THEN '2021-05-30' WHEN 2 THEN '2021-12-15' 
        WHEN 3 THEN '2022-05-30' WHEN 4 THEN '2022-12-15' 
        WHEN 5 THEN '2023-05-30' WHEN 6 THEN '2023-12-15' 
        WHEN 7 THEN '2024-05-30' WHEN 8 THEN '2024-12-15' 
    END
WHERE semester_id BETWEEN 1 AND 8;

-- First update with a WHERE clause that covers all cases

-- Delete any academic records for semesters that don't exist
DELETE FROM academic_records WHERE semester_id > 8;

-- Update semester_id in academic_records to match the new semester structure
-- For 2021 batch (students 1-5): semesters 1-7
-- For 2022 batch (students 6-15): semesters 1-5
-- For 2023 batch (students 16-20): semesters 1-3
-- For 2024 batch (students 21-25): semesters 1-2 (currently in 3rd)

-- First, delete all academic records
SET SQL_SAFE_UPDATES = 0;
DELETE FROM academic_records;
SET SQL_SAFE_UPDATES = 1; -- Turn it back on after
SET SQL_SAFE_UPDATES = 0;
DELETE FROM attendance_records;
SET SQL_SAFE_UPDATES = 1;
SET SQL_SAFE_UPDATES = 0;
DELETE FROM attendance_summary;
SET SQL_SAFE_UPDATES = 1;

-- Now re-insert records with correct semester mapping
-- 2021 batch (students 1-5) - semesters 1-7
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
-- Student 1 (semesters 1-7)
(1, 1, 1, 85), (1, 1, 2, 82), (1, 1, 3, 88), (1, 1, 4, 90), (1, 1, 5, 78), (1, 1, 6, 92),
(1, 2, 7, 88), (1, 2, 8, 85), (1, 2, 9, 90), (1, 2, 10, 87), (1, 2, 11, 84), (1, 2, 12, 92),
(1, 3, 13, 86), (1, 3, 14, 82), (1, 3, 15, 88), (1, 3, 16, 84), (1, 3, 17, 80), (1, 3, 18, 90),
(1, 4, 19, 84), (1, 4, 20, 80), (1, 4, 21, 86), (1, 4, 22, 82), (1, 4, 23, 78), (1, 4, 24, 88),
(1, 5, 25, 88), (1, 5, 26, 84), (1, 5, 27, 90), (1, 5, 28, 86), (1, 5, 29, 82), (1, 5, 30, 92),
(1, 6, 31, 86), (1, 6, 32, 82), (1, 6, 33, 88), (1, 6, 34, 84), (1, 6, 35, 80), (1, 6, 36, 90),
(1, 7, 37, 90), (1, 7, 38, 86), (1, 7, 39, 92), (1, 7, 40, 88), (1, 7, 41, 84), (1, 7, 42, 94),

-- Student 2 (semesters 1-7)
(2, 1, 1, 80), (2, 1, 2, 85), (2, 1, 3, 75), (2, 1, 4, 88), (2, 1, 5, 82), (2, 1, 6, 79),
(2, 2, 7, 82), (2, 2, 8, 85), (2, 2, 9, 78), (2, 2, 10, 88), (2, 2, 11, 80), (2, 2, 12, 84),
(2, 3, 13, 80), (2, 3, 14, 76), (2, 3, 15, 82), (2, 3, 16, 78), (2, 3, 17, 74), (2, 3, 18, 84),
(2, 4, 19, 78), (2, 4, 20, 74), (2, 4, 21, 80), (2, 4, 22, 76), (2, 4, 23, 72), (2, 4, 24, 82),
(2, 5, 25, 82), (2, 5, 26, 78), (2, 5, 27, 84), (2, 5, 28, 80), (2, 5, 29, 76), (2, 5, 30, 86),
(2, 6, 31, 80), (2, 6, 32, 76), (2, 6, 33, 82), (2, 6, 34, 78), (2, 6, 35, 74), (2, 6, 36, 84),
(2, 7, 37, 84), (2, 7, 38, 80), (2, 7, 39, 86), (2, 7, 40, 82), (2, 7, 41, 78), (2, 7, 42, 88),

-- Student 3 (semesters 1-7, math weakness)
(3, 1, 1, 45), (3, 1, 2, 75), (3, 1, 3, 70), (3, 1, 4, 65), (3, 1, 5, 62), (3, 1, 6, 68),
(3, 2, 7, 42), (3, 2, 8, 68), (3, 2, 9, 72), (3, 2, 10, 65), (3, 2, 11, 70), (3, 2, 12, 74),
(3, 3, 13, 45), (3, 3, 14, 68), (3, 3, 15, 70), (3, 3, 16, 66), (3, 3, 17, 46), (3, 3, 18, 72),
(3, 4, 19, 48), (3, 4, 20, 70), (3, 4, 21, 72), (3, 4, 22, 68), (3, 4, 23, 47), (3, 4, 24, 74),
(3, 5, 25, 50), (3, 5, 26, 72), (3, 5, 27, 74), (3, 5, 28, 70), (3, 5, 29, 48), (3, 5, 30, 76),
(3, 6, 31, 45), (3, 6, 32, 70), (3, 6, 33, 73), (3, 6, 34, 69), (3, 6, 35, 47), (3, 6, 36, 75),
(3, 7, 37, 42), (3, 7, 38, 68), (3, 7, 39, 71), (3, 7, 40, 67), (3, 7, 41, 44), (3, 7, 42, 73),

-- Student 4 (semesters 1-7, poor performance)
(4, 1, 1, 35), (4, 1, 2, 42), (4, 1, 3, 38), (4, 1, 4, 55), (4, 1, 5, 40), (4, 1, 6, 39),
(4, 2, 7, 32), (4, 2, 8, 38), (4, 2, 9, 35), (4, 2, 10, 40), (4, 2, 11, 36), (4, 2, 12, 34),
(4, 3, 13, 30), (4, 3, 14, 35), (4, 3, 15, 32), (4, 3, 16, 36), (4, 3, 17, 31), (4, 3, 18, 34),
(4, 4, 19, 28), (4, 4, 20, 33), (4, 4, 21, 30), (4, 4, 22, 34), (4, 4, 23, 29), (4, 4, 24, 32),
(4, 5, 25, 25), (4, 5, 26, 30), (4, 5, 27, 28), (4, 5, 28, 32), (4, 5, 29, 27), (4, 5, 30, 29),
(4, 6, 31, 23), (4, 6, 32, 28), (4, 6, 33, 26), (4, 6, 34, 30), (4, 6, 35, 25), (4, 6, 36, 27),
(4, 7, 37, 20), (4, 7, 38, 26), (4, 7, 39, 24), (4, 7, 40, 28), (4, 7, 41, 22), (4, 7, 42, 25),

-- Student 5 (semesters 1-7)
(5, 1, 1, 65), (5, 1, 2, 62), (5, 1, 3, 70), (5, 1, 4, 75), (5, 1, 5, 68), (5, 1, 6, 72),
(5, 2, 7, 68), (5, 2, 8, 65), (5, 2, 9, 72), (5, 2, 10, 70), (5, 2, 11, 66), (5, 2, 12, 74),
(5, 3, 13, 70), (5, 3, 14, 66), (5, 3, 15, 72), (5, 3, 16, 68), (5, 3, 17, 64), (5, 3, 18, 74),
(5, 4, 19, 68), (5, 4, 20, 64), (5, 4, 21, 70), (5, 4, 22, 66), (5, 4, 23, 62), (5, 4, 24, 72),
(5, 5, 25, 72), (5, 5, 26, 68), (5, 5, 27, 74), (5, 5, 28, 70), (5, 5, 29, 66), (5, 5, 30, 76),
(5, 6, 31, 70), (5, 6, 32, 66), (5, 6, 33, 72), (5, 6, 34, 68), (5, 6, 35, 64), (5, 6, 36, 74),
(5, 7, 37, 74), (5, 7, 38, 70), (5, 7, 39, 76), (5, 7, 40, 72), (5, 7, 41, 68), (5, 7, 42, 78);

-- 2022 batch (students 6-15) - semesters 1-5
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
-- Student 6 (semesters 1-5)
(6, 1, 1, 75), (6, 1, 2, 70), (6, 1, 3, 72), (6, 1, 4, 68), (6, 1, 5, 74), (6, 1, 6, 71),
(6, 2, 7, 78), (6, 2, 8, 80), (6, 2, 9, 75), (6, 2, 10, 82), (6, 2, 11, 76), (6, 2, 12, 79),
(6, 3, 13, 74), (6, 3, 14, 70), (6, 3, 15, 76), (6, 3, 16, 72), (6, 3, 17, 68), (6, 3, 18, 78),
(6, 4, 19, 72), (6, 4, 20, 68), (6, 4, 21, 74), (6, 4, 22, 70), (6, 4, 23, 66), (6, 4, 24, 76),
(6, 5, 25, 78), (6, 5, 26, 74), (6, 5, 27, 80), (6, 5, 28, 76), (6, 5, 29, 72), (6, 5, 30, 82),

-- Student 7 (semesters 1-5)
(7, 1, 1, 85), (7, 1, 2, 82), (7, 1, 3, 88), (7, 1, 4, 84), (7, 1, 5, 78), (7, 1, 6, 86),
(7, 2, 7, 87), (7, 2, 8, 89), (7, 2, 9, 85), (7, 2, 10, 91), (7, 2, 11, 83), (7, 2, 12, 88),
(7, 3, 13, 84), (7, 3, 14, 80), (7, 3, 15, 86), (7, 3, 16, 82), (7, 3, 17, 78), (7, 3, 18, 88),
(7, 4, 19, 86), (7, 4, 20, 82), (7, 4, 21, 88), (7, 4, 22, 84), (7, 4, 23, 80), (7, 4, 24, 90),
(7, 5, 25, 88), (7, 5, 26, 84), (7, 5, 27, 90), (7, 5, 28, 86), (7, 5, 29, 82), (7, 5, 30, 92),

-- Student 8 (semesters 1-5, poor performance)
(8, 1, 1, 55), (8, 1, 2, 35), (8, 1, 3, 40), (8, 1, 4, 48), (8, 1, 5, 52), (8, 1, 6, 43),
(8, 2, 7, 42), (8, 2, 8, 46), (8, 2, 9, 40), (8, 2, 10, 44), (8, 2, 11, 38), (8, 2, 12, 43),
(8, 3, 13, 38), (8, 3, 14, 42), (8, 3, 15, 35), (8, 3, 16, 40), (8, 3, 17, 36), (8, 3, 18, 39),
(8, 4, 19, 32), (8, 4, 20, 36), (8, 4, 21, 30), (8, 4, 22, 34), (8, 4, 23, 33), (8, 4, 24, 35),
(8, 5, 25, 30), (8, 5, 26, 36), (8, 5, 27, 32), (8, 5, 28, 34), (8, 5, 29, 33), (8, 5, 30, 35),

-- Student 9 (semesters 1-5)
(9, 1, 1, 60), (9, 1, 2, 65), (9, 1, 3, 62), (9, 1, 4, 68), (9, 1, 5, 64), (9, 1, 6, 66),
(9, 2, 7, 66), (9, 2, 8, 62), (9, 2, 9, 68), (9, 2, 10, 64), (9, 2, 11, 60), (9, 2, 12, 70),
(9, 3, 13, 64), (9, 3, 14, 60), (9, 3, 15, 66), (9, 3, 16, 62), (9, 3, 17, 58), (9, 3, 18, 68),
(9, 4, 19, 66), (9, 4, 20, 62), (9, 4, 21, 68), (9, 4, 22, 64), (9, 4, 23, 60), (9, 4, 24, 70),
(9, 5, 25, 68), (9, 5, 26, 64), (9, 5, 27, 70), (9, 5, 28, 66), (9, 5, 29, 62), (9, 5, 30, 72),

-- Student 10 (semesters 1-5)
(10, 1, 1, 78), (10, 1, 2, 75), (10, 1, 3, 80), (10, 1, 4, 76), (10, 1, 5, 73), (10, 1, 6, 77),
(10, 2, 7, 82), (10, 2, 8, 85), (10, 2, 9, 80), (10, 2, 10, 88), (10, 2, 11, 78), (10, 2, 12, 84),
(10, 3, 13, 76), (10, 3, 14, 72), (10, 3, 15, 78), (10, 3, 16, 74), (10, 3, 17, 70), (10, 3, 18, 80),
(10, 4, 19, 78), (10, 4, 20, 74), (10, 4, 21, 80), (10, 4, 22, 76), (10, 4, 23, 72), (10, 4, 24, 82),
(10, 5, 25, 80), (10, 5, 26, 76), (10, 5, 27, 82), (10, 5, 28, 78), (10, 5, 29, 74), (10, 5, 30, 84),

-- Student 11 (semesters 1-5)
(11, 1, 1, 82), (11, 1, 2, 78), (11, 1, 3, 85), (11, 1, 4, 80), (11, 1, 5, 76), (11, 1, 6, 83),
(11, 2, 7, 80), (11, 2, 8, 76), (11, 2, 9, 82), (11, 2, 10, 78), (11, 2, 11, 74), (11, 2, 12, 84),
(11, 3, 13, 80), (11, 3, 14, 76), (11, 3, 15, 82), (11, 3, 16, 78), (11, 3, 17, 74), (11, 3, 18, 84),
(11, 4, 19, 82), (11, 4, 20, 78), (11, 4, 21, 84), (11, 4, 22, 80), (11, 4, 23, 76), (11, 4, 24, 86),
(11, 5, 25, 84), (11, 5, 26, 80), (11, 5, 27, 86), (11, 5, 28, 82), (11, 5, 29, 78), (11, 5, 30, 88),

-- Student 12 (semesters 1-5, poor performance)
(12, 1, 1, 30), (12, 1, 2, 35), (12, 1, 3, 28), (12, 1, 4, 40), (12, 1, 5, 32), (12, 1, 6, 38),
(12, 2, 7, 48), (12, 2, 8, 52), (12, 2, 9, 50), (12, 2, 10, 46), (12, 2, 11, 44), (12, 2, 12, 49),
(12, 3, 13, 32), (12, 3, 14, 28), (12, 3, 15, 34), (12, 3, 16, 30), (12, 3, 17, 26), (12, 3, 18, 36),
(12, 4, 19, 30), (12, 4, 20, 26), (12, 4, 21, 32), (12, 4, 22, 28), (12, 4, 23, 24), (12, 4, 24, 34),
(12, 5, 25, 28), (12, 5, 26, 32), (12, 5, 27, 30), (12, 5, 28, 34), (12, 5, 29, 29), (12, 5, 30, 31),

-- Student 13 (semesters 1-5)
(13, 1, 1, 68), (13, 1, 2, 65), (13, 1, 3, 72), (13, 1, 4, 70), (13, 1, 5, 66), (13, 1, 6, 74),
(13, 2, 7, 70), (13, 2, 8, 66), (13, 2, 9, 72), (13, 2, 10, 68), (13, 2, 11, 64), (13, 2, 12, 74),
(13, 3, 13, 68), (13, 3, 14, 64), (13, 3, 15, 70), (13, 3, 16, 66), (13, 3, 17, 62), (13, 3, 18, 72),
(13, 4, 19, 72), (13, 4, 20, 68), (13, 4, 21, 74), (13, 4, 22, 70), (13, 4, 23, 66), (13, 4, 24, 76),
(13, 5, 25, 74), (13, 5, 26, 70), (13, 5, 27, 76), (13, 5, 28, 72), (13, 5, 29, 68), (13, 5, 30, 78),

-- Student 14 (semesters 1-5)
(14, 1, 1, 58), (14, 1, 2, 55), (14, 1, 3, 62), (14, 1, 4, 60), (14, 1, 5, 56), (14, 1, 6, 64),
(14, 2, 7, 62), (14, 2, 8, 58), (14, 2, 9, 64), (14, 2, 10, 60), (14, 2, 11, 56), (14, 2, 12, 66),
(14, 3, 13, 60), (14, 3, 14, 56), (14, 3, 15, 62), (14, 3, 16, 58), (14, 3, 17, 54), (14, 3, 18, 64),
(14, 4, 19, 62), (14, 4, 20, 58), (14, 4, 21, 64), (14, 4, 22, 60), (14, 4, 23, 56), (14, 4, 24, 66),
(14, 5, 25, 64), (14, 5, 26, 60), (14, 5, 27, 66), (14, 5, 28, 62), (14, 5, 29, 58), (14, 5, 30, 68),

-- Student 15 (semesters 1-5, poor performance)
(15, 1, 1, 25), (15, 1, 2, 22), (15, 1, 3, 28), (15, 1, 4, 26), (15, 1, 5, 30), (15, 1, 6, 24),
(15, 2, 7, 28), (15, 2, 8, 30), (15, 2, 9, 26), (15, 2, 10, 32), (15, 2, 11, 29), (15, 2, 12, 27),
(15, 3, 13, 28), (15, 3, 14, 32), (15, 3, 15, 30), (15, 3, 16, 34), (15, 3, 17, 26), (15, 3, 18, 29),
(15, 4, 19, 25), (15, 4, 20, 30), (15, 4, 21, 28), (15, 4, 22, 32), (15, 4, 23, 27), (15, 4, 24, 26),
(15, 5, 25, 23), (15, 5, 26, 28), (15, 5, 27, 26), (15, 5, 28, 30), (15, 5, 29, 25), (15, 5, 30, 27);

-- 2023 batch (students 16-20) - semesters 1-3
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
-- Student 16 (semesters 1-3)
(16, 1, 1, 65), (16, 1, 2, 62), (16, 1, 3, 68), (16, 1, 4, 66), (16, 1, 5, 60), (16, 1, 6, 70),
(16, 2, 7, 70), (16, 2, 8, 66), (16, 2, 9, 72), (16, 2, 10, 68), (16, 2, 11, 64), (16, 2, 12, 74),
(16, 3, 13, 72), (16, 3, 14, 68), (16, 3, 15, 75), (16, 3, 16, 70), (16, 3, 17, 66), (16, 3, 18, 73),

-- Student 17 (semesters 1-3, poor performance)
(17, 1, 1, 35), (17, 1, 2, 30), (17, 1, 3, 40), (17, 1, 4, 38), (17, 1, 5, 32), (17, 1, 6, 36),
(17, 2, 7, 42), (17, 2, 8, 46), (17, 2, 9, 40), (17, 2, 10, 44), (17, 2, 11, 38), (17, 2, 12, 43),
(17, 3, 13, 38), (17, 3, 14, 35), (17, 3, 15, 30), (17, 3, 16, 42), (17, 3, 17, 36), (17, 3, 18, 40),

-- Student 18 (semesters 1-3)
(18, 1, 1, 60), (18, 1, 2, 56), (18, 1, 3, 62), (18, 1, 4, 58), (18, 1, 5, 54), (18, 1, 6, 64),
(18, 2, 7, 62), (18, 2, 8, 58), (18, 2, 9, 64), (18, 2, 10, 60), (18, 2, 11, 56), (18, 2, 12, 66),
(18, 3, 13, 58), (18, 3, 14, 55), (18, 3, 15, 62), (18, 3, 16, 60), (18, 3, 17, 56), (18, 3, 18, 64),

-- Student 19 (semesters 1-3)
(19, 1, 1, 80), (19, 1, 2, 76), (19, 1, 3, 82), (19, 1, 4, 78), (19, 1, 5, 74), (19, 1, 6, 84),
(19, 2, 7, 82), (19, 2, 8, 78), (19, 2, 9, 84), (19, 2, 10, 80), (19, 2, 11, 76), (19, 2, 12, 86),
(19, 3, 13, 82), (19, 3, 14, 78), (19, 3, 15, 85), (19, 3, 16, 80), (19, 3, 17, 76), (19, 3, 18, 83),

-- Student 20 (semesters 1-3, poor performance)
(20, 1, 1, 28), (20, 1, 2, 25), (20, 1, 3, 35), (20, 1, 4, 30), (20, 1, 5, 32), (20, 1, 6, 27),
(20, 2, 7, 30), (20, 2, 8, 35), (20, 2, 9, 32), (20, 2, 10, 38), (20, 2, 11, 34), (20, 2, 12, 29),
(20, 3, 13, 28), (20, 3, 14, 25), (20, 3, 15, 35), (20, 3, 16, 30), (20, 3, 17, 32), (20, 3, 18, 27);

-- 2024 batch (students 21-25) - semesters 1-2
INSERT INTO academic_records (student_id, semester_id, course_id, marks) VALUES
-- Student 21 (semesters 1-2)
(21, 1, 1, 65), (21, 1, 2, 62), (21, 1, 3, 68), (21, 1, 4, 66), (21, 1, 5, 60), (21, 1, 6, 70),
(21, 2, 7, 68), (21, 2, 8, 65), (21, 2, 9, 72), (21, 2, 10, 70), (21, 2, 11, 66), (21, 2, 12, 74),

-- Student 22 (semesters 1-2, poor performance)
(22, 1, 1, 35), (22, 1, 2, 30), (22, 1, 3, 40), (22, 1, 4, 38), (22, 1, 5, 32), (22, 1, 6, 36),
(22, 2, 7, 38), (22, 2, 8, 42), (22, 2, 9, 40), (22, 2, 10, 44), (22, 2, 11, 36), (22, 2, 12, 39),

-- Student 23 (semesters 1-2)
(23, 1, 1, 75), (23, 1, 2, 72), (23, 1, 3, 78), (23, 1, 4, 76), (23, 1, 5, 70), (23, 1, 6, 80),
(23, 2, 7, 78), (23, 2, 8, 74), (23, 2, 9, 80), (23, 2, 10, 76), (23, 2, 11, 72), (23, 2, 12, 82),

-- Student 24 (semesters 1-2)
(24, 1, 1, 55), (24, 1, 2, 52), (24, 1, 3, 58), (24, 1, 4, 56), (24, 1, 5, 50), (24, 1, 6, 60),
(24, 2, 7, 58), (24, 2, 8, 54), (24, 2, 9, 60), (24, 2, 10, 56), (24, 2, 11, 52), (24, 2, 12, 62),

-- Student 25 (semesters 1-2, poor performance)
(25, 1, 1, 25), (25, 1, 2, 22), (25, 1, 3, 28), (25, 1, 4, 26), (25, 1, 5, 30), (25, 1, 6, 24),
(25, 2, 7, 28), (25, 2, 8, 25), (25, 2, 9, 30), (25, 2, 10, 26), (25, 2, 11, 32), (25, 2, 12, 23);

-- 2021 Batch (students 1-5) - semesters 1-7
-- Student 1 (excellent attendance)
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(1,1,1,88),(1,1,2,90),(1,1,3,85),(1,1,4,92),(1,1,5,86),(1,1,6,89),
(1,2,7,89),(1,2,8,91),(1,2,9,87),(1,2,10,93),(1,2,11,85),(1,2,12,90),
(1,3,13,88),(1,3,14,84),(1,3,15,90),(1,3,16,86),(1,3,17,82),(1,3,18,92),
(1,4,19,86),(1,4,20,82),(1,4,21,88),(1,4,22,84),(1,4,23,80),(1,4,24,90),
(1,5,25,90),(1,5,26,86),(1,5,27,92),(1,5,28,88),(1,5,29,84),(1,5,30,94),
(1,6,31,88),(1,6,32,84),(1,6,33,90),(1,6,34,86),(1,6,35,82),(1,6,36,92),
(1,7,37,92),(1,7,38,88),(1,7,39,94),(1,7,40,90),(1,7,41,86),(1,7,42,96);

-- Student 2 (good attendance)
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(2,1,1,82),(2,1,2,85),(2,1,3,80),(2,1,4,87),(2,1,5,83),(2,1,6,84),
(2,2,7,84),(2,2,8,86),(2,2,9,82),(2,2,10,88),(2,2,11,80),(2,2,12,85),
(2,3,13,82),(2,3,14,78),(2,3,15,84),(2,3,16,80),(2,3,17,76),(2,3,18,86),
(2,4,19,80),(2,4,20,76),(2,4,21,82),(2,4,22,78),(2,4,23,74),(2,4,24,84),
(2,5,25,84),(2,5,26,80),(2,5,27,86),(2,5,28,82),(2,5,29,78),(2,5,30,88),
(2,6,31,82),(2,6,32,78),(2,6,33,84),(2,6,34,80),(2,6,35,76),(2,6,36,86),
(2,7,37,86),(2,7,38,82),(2,7,39,88),(2,7,40,84),(2,7,41,80),(2,7,42,90);

-- Student 3 (average with math struggles)
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(3,1,1,72),(3,1,2,78),(3,1,3,75),(3,1,4,80),(3,1,5,70),(3,1,6,77),
(3,2,7,70),(3,2,8,75),(3,2,9,72),(3,2,10,78),(3,2,11,68),(3,2,12,76),
(3,3,13,65),(3,3,14,72),(3,3,15,70),(3,3,16,74),(3,3,17,62),(3,3,18,72),
(3,4,19,68),(3,4,20,72),(3,4,21,70),(3,4,22,75),(3,4,23,64),(3,4,24,74),
(3,5,25,70),(3,5,26,74),(3,5,27,72),(3,5,28,76),(3,5,29,66),(3,5,30,75),
(3,6,31,68),(3,6,32,72),(3,6,33,70),(3,6,34,74),(3,6,35,64),(3,6,36,73),
(3,7,37,66),(3,7,38,70),(3,7,39,72),(3,7,40,74),(3,7,41,62),(3,7,42,72);

-- Student 4 (poor attendance)
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(4,1,1,45),(4,1,2,50),(4,1,3,48),(4,1,4,52),(4,1,5,47),(4,1,6,49),
(4,2,7,42),(4,2,8,46),(4,2,9,40),(4,2,10,44),(4,2,11,38),(4,2,12,43),
(4,3,13,40),(4,3,14,45),(4,3,15,42),(4,3,16,48),(4,3,17,38),(4,3,18,44),
(4,4,19,38),(4,4,20,42),(4,4,21,40),(4,4,22,45),(4,4,23,36),(4,4,24,43),
(4,5,25,35),(4,5,26,40),(4,5,27,38),(4,5,28,42),(4,5,29,36),(4,5,30,39),
(4,6,31,33),(4,6,32,38),(4,6,33,36),(4,6,34,40),(4,6,35,34),(4,6,36,37),
(4,7,37,30),(4,7,38,36),(4,7,39,34),(4,7,40,38),(4,7,41,32),(4,7,42,35);

-- Student 5 (good attendance)
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(5,1,1,82),(5,1,2,85),(5,1,3,80),(5,1,4,87),(5,1,5,78),(5,1,6,84),
(5,2,7,83),(5,2,8,85),(5,2,9,81),(5,2,10,87),(5,2,11,79),(5,2,12,84),
(5,3,13,81),(5,3,14,77),(5,3,15,83),(5,3,16,79),(5,3,17,75),(5,3,18,85),
(5,4,19,79),(5,4,20,75),(5,4,21,81),(5,4,22,77),(5,4,23,73),(5,4,24,83),
(5,5,25,83),(5,5,26,79),(5,5,27,85),(5,5,28,81),(5,5,29,77),(5,5,30,87),
(5,6,31,81),(5,6,32,77),(5,6,33,83),(5,6,34,79),(5,6,35,75),(5,6,36,85),
(5,7,37,85),(5,7,38,81),(5,7,39,87),(5,7,40,83),(5,7,41,79),(5,7,42,89);

-- 2022 Batch (students 6-15) - semesters 1-5
-- Student 6 (good attendance)
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(6,1,1,78),(6,1,2,80),(6,1,3,75),(6,1,4,82),(6,1,5,76),(6,1,6,79),
(6,2,7,79),(6,2,8,81),(6,2,9,77),(6,2,10,83),(6,2,11,75),(6,2,12,80),
(6,3,13,77),(6,3,14,73),(6,3,15,79),(6,3,16,75),(6,3,17,71),(6,3,18,81),
(6,4,19,75),(6,4,20,71),(6,4,21,77),(6,4,22,73),(6,4,23,69),(6,4,24,79),
(6,5,25,79),(6,5,26,75),(6,5,27,81),(6,5,28,77),(6,5,29,73),(6,5,30,83);

-- Student 7 (excellent attendance)
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(7,1,1,85),(7,1,2,88),(7,1,3,82),(7,1,4,90),(7,1,5,84),(7,1,6,86),
(7,2,7,87),(7,2,8,89),(7,2,9,85),(7,2,10,91),(7,2,11,83),(7,2,12,88),
(7,3,13,85),(7,3,14,81),(7,3,15,87),(7,3,16,83),(7,3,17,79),(7,3,18,89),
(7,4,19,83),(7,4,20,79),(7,4,21,85),(7,4,22,81),(7,4,23,77),(7,4,24,87),
(7,5,25,87),(7,5,26,83),(7,5,27,89),(7,5,28,85),(7,5,29,81),(7,5,30,91);

-- Student 8 (poor attendance)
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(8,1,1,38),(8,1,2,42),(8,1,3,40),(8,1,4,45),(8,1,5,36),(8,1,6,41),
(8,2,7,40),(8,2,8,44),(8,2,9,38),(8,2,10,46),(8,2,11,36),(8,2,12,42),
(8,3,13,36),(8,3,14,40),(8,3,15,38),(8,3,16,44),(8,3,17,34),(8,3,18,40),
(8,4,19,34),(8,4,20,38),(8,4,21,36),(8,4,22,42),(8,4,23,32),(8,4,24,38),
(8,5,25,38),(8,5,26,42),(8,5,27,40),(8,5,28,44),(8,5,29,34),(8,5,30,40);

-- Student 9 (good attendance)
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(9,1,1,80),(9,1,2,82),(9,1,3,78),(9,1,4,84),(9,1,5,76),(9,1,6,81),
(9,2,7,81),(9,2,8,83),(9,2,9,79),(9,2,10,85),(9,2,11,77),(9,2,12,82),
(9,3,13,79),(9,3,14,75),(9,3,15,81),(9,3,16,77),(9,3,17,73),(9,3,18,83),
(9,4,19,77),(9,4,20,73),(9,4,21,79),(9,4,22,75),(9,4,23,71),(9,4,24,81),
(9,5,25,81),(9,5,26,77),(9,5,27,83),(9,5,28,79),(9,5,29,75),(9,5,30,85);

-- Student 10 (excellent attendance)
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(10,1,1,85),(10,1,2,88),(10,1,3,82),(10,1,4,90),(10,1,5,84),(10,1,6,87),
(10,2,7,87),(10,2,8,89),(10,2,9,85),(10,2,10,91),(10,2,11,83),(10,2,12,88),
(10,3,13,85),(10,3,14,81),(10,3,15,87),(10,3,16,83),(10,3,17,79),(10,3,18,89),
(10,4,19,83),(10,4,20,79),(10,4,21,85),(10,4,22,81),(10,4,23,77),(10,4,24,87),
(10,5,25,87),(10,5,26,83),(10,5,27,89),(10,5,28,85),(10,5,29,81),(10,5,30,91);

-- Student 11 (good attendance)
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(11,1,1,82),(11,1,2,85),(11,1,3,80),(11,1,4,87),(11,1,5,78),(11,1,6,84),
(11,2,7,83),(11,2,8,85),(11,2,9,81),(11,2,10,87),(11,2,11,79),(11,2,12,84),
(11,3,13,81),(11,3,14,77),(11,3,15,83),(11,3,16,79),(11,3,17,75),(11,3,18,85),
(11,4,19,79),(11,4,20,75),(11,4,21,81),(11,4,22,77),(11,4,23,73),(11,4,24,83),
(11,5,25,83),(11,5,26,79),(11,5,27,85),(11,5,28,81),(11,5,29,77),(11,5,30,87);

-- Student 12 (poor attendance)
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(12,1,1,40),(12,1,2,45),(12,1,3,42),(12,1,4,48),(12,1,5,38),(12,1,6,44),
(12,2,7,42),(12,2,8,46),(12,2,9,40),(12,2,10,44),(12,2,11,38),(12,2,12,43),
(12,3,13,38),(12,3,14,42),(12,3,15,40),(12,3,16,45),(12,3,17,36),(12,3,18,43),
(12,4,19,36),(12,4,20,40),(12,4,21,38),(12,4,22,44),(12,4,23,34),(12,4,24,40),
(12,5,25,38),(12,5,26,42),(12,5,27,40),(12,5,28,44),(12,5,29,36),(12,5,30,42);

-- Student 13 (good attendance)
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(13,1,1,78),(13,1,2,80),(13,1,3,75),(13,1,4,82),(13,1,5,76),(13,1,6,79),
(13,2,7,79),(13,2,8,81),(13,2,9,77),(13,2,10,83),(13,2,11,75),(13,2,12,80),
(13,3,13,77),(13,3,14,73),(13,3,15,79),(13,3,16,75),(13,3,17,71),(13,3,18,81),
(13,4,19,75),(13,4,20,71),(13,4,21,77),(13,4,22,73),(13,4,23,69),(13,4,24,79),
(13,5,25,79),(13,5,26,75),(13,5,27,81),(13,5,28,77),(13,5,29,73),(13,5,30,83);

-- Student 14 (average attendance)
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(14,1,1,72),(14,1,2,75),(14,1,3,70),(14,1,4,78),(14,1,5,68),(14,1,6,74),
(14,2,7,70),(14,2,8,74),(14,2,9,72),(14,2,10,76),(14,2,11,66),(14,2,12,75),
(14,3,13,68),(14,3,14,72),(14,3,15,70),(14,3,16,74),(14,3,17,64),(14,3,18,73),
(14,4,19,70),(14,4,20,74),(14,4,21,72),(14,4,22,76),(14,4,23,66),(14,4,24,75),
(14,5,25,72),(14,5,26,76),(14,5,27,74),(14,5,28,78),(14,5,29,68),(14,5,30,77);

-- Student 15 (poor attendance)
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(15,1,1,35),(15,1,2,40),(15,1,3,38),(15,1,4,42),(15,1,5,36),(15,1,6,39),
(15,2,7,38),(15,2,8,42),(15,2,9,40),(15,2,10,44),(15,2,11,36),(15,2,12,41),
(15,3,13,36),(15,3,14,40),(15,3,15,38),(15,3,16,44),(15,3,17,34),(15,3,18,40),
(15,4,19,34),(15,4,20,38),(15,4,21,36),(15,4,22,42),(15,4,23,32),(15,4,24,38),
(15,5,25,38),(15,5,26,42),(15,5,27,40),(15,5,28,44),(15,5,29,36),(15,5,30,42);

-- 2023 batch (students 16-20) - semesters 1-3
-- Student 16 (good attendance)
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(16,1,1,80),(16,1,2,82),(16,1,3,78),(16,1,4,84),(16,1,5,76),(16,1,6,81),
(16,2,7,81),(16,2,8,83),(16,2,9,79),(16,2,10,85),(16,2,11,77),(16,2,12,82),
(16,3,13,79),(16,3,14,75),(16,3,15,81),(16,3,16,77),(16,3,17,73),(16,3,18,83);

-- Student 17 (poor attendance)
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(17,1,1,42),(17,1,2,45),(17,1,3,40),(17,1,4,48),(17,1,5,38),(17,1,6,44),
(17,2,7,40),(17,2,8,44),(17,2,9,38),(17,2,10,46),(17,2,11,36),(17,2,12,42),
(17,3,13,36),(17,3,14,40),(17,3,15,38),(17,3,16,44),(17,3,17,34),(17,3,18,40);

-- Student 18 (average attendance)
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(18,1,1,75),(18,1,2,78),(18,1,3,72),(18,1,4,80),(18,1,5,70),(18,1,6,76),
(18,2,7,72),(18,2,8,76),(18,2,9,74),(18,2,10,78),(18,2,11,68),(18,2,12,77),
(18,3,13,70),(18,3,14,74),(18,3,15,72),(18,3,16,76),(18,3,17,66),(18,3,18,75);

-- Student 19 (excellent attendance)
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(19,1,1,88),(19,1,2,90),(19,1,3,85),(19,1,4,92),(19,1,5,86),(19,1,6,89),
(19,2,7,89),(19,2,8,91),(19,2,9,87),(19,2,10,93),(19,2,11,85),(19,2,12,90),
(19,3,13,88),(19,3,14,84),(19,3,15,90),(19,3,16,86),(19,3,17,82),(19,3,18,92);

-- Student 20 (poor attendance)
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(20,1,1,38),(20,1,2,42),(20,1,3,40),(20,1,4,45),(20,1,5,36),(20,1,6,41),
(20,2,7,40),(20,2,8,44),(20,2,9,38),(20,2,10,46),(20,2,11,36),(20,2,12,42),
(20,3,13,36),(20,3,14,40),(20,3,15,38),(20,3,16,44),(20,3,17,34),(20,3,18,40);

-- 2024 batch (students 21-25) - semesters 1-2
-- Student 21 (good attendance)
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(21,1,1,82),(21,1,2,85),(21,1,3,80),(21,1,4,87),(21,1,5,78),(21,1,6,84),
(21,2,7,83),(21,2,8,85),(21,2,9,81),(21,2,10,87),(21,2,11,79),(21,2,12,84);

-- Student 22 (poor attendance)
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(22,1,1,45),(22,1,2,50),(22,1,3,48),(22,1,4,52),(22,1,5,47),(22,1,6,49),
(22,2,7,42),(22,2,8,46),(22,2,9,40),(22,2,10,44),(22,2,11,38),(22,2,12,43);

-- Student 23 (excellent attendance)
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(23,1,1,88),(23,1,2,90),(23,1,3,85),(23,1,4,92),(23,1,5,86),(23,1,6,89),
(23,2,7,89),(23,2,8,91),(23,2,9,87),(23,2,10,93),(23,2,11,85),(23,2,12,90);

-- Student 24 (average attendance)
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(24,1,1,72),(24,1,2,75),(24,1,3,70),(24,1,4,78),(24,1,5,68),(24,1,6,74),
(24,2,7,70),(24,2,8,74),(24,2,9,72),(24,2,10,76),(24,2,11,66),(24,2,12,75);

-- Student 25 (poor attendance)
INSERT INTO attendance_records (student_id, semester_id, course_id, attendance) VALUES
(25,1,1,38),(25,1,2,42),(25,1,3,40),(25,1,4,45),(25,1,5,36),(25,1,6,41),
(25,2,7,40),(25,2,8,44),(25,2,9,38),(25,2,10,46),(25,2,11,36),(25,2,12,42);

-- 2021 Batch (students 1-5) - semesters 1-7
-- Student 1 (excellent attendance)
INSERT INTO attendance_summary (student_id, semester_id, attendance_percentage, days_present, days_absent, late_arrivals) VALUES
(1, 1, 88.67, 133, 17, 2),
(1, 2, 89.17, 134, 16, 3),
(1, 3, 87.00, 131, 19, 1),
(1, 4, 85.00, 128, 22, 2),
(1, 5, 89.00, 134, 16, 1),
(1, 6, 87.00, 131, 19, 3),
(1, 7, 91.00, 137, 13, 0);

-- Student 2 (good attendance)
INSERT INTO attendance_summary (student_id, semester_id, attendance_percentage, days_present, days_absent, late_arrivals) VALUES
(2, 1, 82.50, 124, 26, 5),
(2, 2, 83.17, 125, 25, 4),
(2, 3, 80.00, 120, 30, 6),
(2, 4, 78.00, 117, 33, 7),
(2, 5, 82.17, 123, 27, 5),
(2, 6, 80.00, 120, 30, 6),
(2, 7, 84.33, 127, 23, 3);

-- Student 3 (average with math struggles)
INSERT INTO attendance_summary (student_id, semester_id, attendance_percentage, days_present, days_absent, late_arrivals) VALUES
(3, 1, 73.50, 110, 40, 12),
(3, 2, 71.33, 107, 43, 15),
(3, 3, 69.17, 104, 46, 18),
(3, 4, 70.17, 105, 45, 17),
(3, 5, 71.50, 107, 43, 16),
(3, 6, 69.67, 105, 45, 18),
(3, 7, 68.50, 103, 47, 19);

-- Student 4 (poor attendance)
INSERT INTO attendance_summary (student_id, semester_id, attendance_percentage, days_present, days_absent, late_arrivals) VALUES
(4, 1, 47.17, 71, 79, 25),
(4, 2, 42.33, 64, 86, 28),
(4, 3, 41.50, 62, 88, 30),
(4, 4, 39.17, 59, 91, 32),
(4, 5, 38.33, 58, 92, 33),
(4, 6, 36.17, 54, 96, 35),
(4, 7, 32.50, 49, 101, 38);

-- Student 5 (good attendance)
INSERT INTO attendance_summary (student_id, semester_id, attendance_percentage, days_present, days_absent, late_arrivals) VALUES
(5, 1, 80.50, 121, 29, 6),
(5, 2, 81.50, 122, 28, 5),
(5, 3, 79.17, 119, 31, 7),
(5, 4, 77.50, 116, 34, 8),
(5, 5, 81.83, 123, 27, 5),
(5, 6, 79.17, 119, 31, 7),
(5, 7, 83.50, 125, 25, 4);

-- 2022 Batch (students 6-15) - semesters 1-5
-- Student 6 (good attendance)
INSERT INTO attendance_summary (student_id, semester_id, attendance_percentage, days_present, days_absent, late_arrivals) VALUES
(6, 1, 78.17, 117, 33, 8),
(6, 2, 79.17, 119, 31, 7),
(6, 3, 77.00, 116, 34, 9),
(6, 4, 75.17, 113, 37, 10),
(6, 5, 79.50, 119, 31, 7);

-- Student 7 (excellent attendance)
INSERT INTO attendance_summary (student_id, semester_id, attendance_percentage, days_present, days_absent, late_arrivals) VALUES
(7, 1, 85.83, 129, 21, 1),
(7, 2, 87.17, 131, 19, 0),
(7, 3, 85.17, 128, 22, 2),
(7, 4, 83.50, 125, 25, 3),
(7, 5, 87.83, 132, 18, 1);

-- Student 8 (poor attendance)
INSERT INTO attendance_summary (student_id, semester_id, attendance_percentage, days_present, days_absent, late_arrivals) VALUES
(8, 1, 40.17, 60, 90, 32),
(8, 2, 41.33, 62, 88, 30),
(8, 3, 38.83, 58, 92, 34),
(8, 4, 36.50, 55, 95, 36),
(8, 5, 38.67, 58, 92, 34);

-- Student 9 (good attendance)
INSERT INTO attendance_summary (student_id, semester_id, attendance_percentage, days_present, days_absent, late_arrivals) VALUES
(9, 1, 80.17, 120, 30, 7),
(9, 2, 81.17, 122, 28, 6),
(9, 3, 79.00, 119, 31, 8),
(9, 4, 77.17, 116, 34, 9),
(9, 5, 81.50, 122, 28, 6);

-- Student 10 (excellent attendance)
INSERT INTO attendance_summary (student_id, semester_id, attendance_percentage, days_present, days_absent, late_arrivals) VALUES
(10, 1, 86.17, 129, 21, 1),
(10, 2, 87.50, 131, 19, 0),
(10, 3, 85.50, 128, 22, 2),
(10, 4, 83.83, 126, 24, 3),
(10, 5, 88.17, 132, 18, 1);

-- Student 11 (good attendance)
INSERT INTO attendance_summary (student_id, semester_id, attendance_percentage, days_present, days_absent, late_arrivals) VALUES
(11, 1, 81.83, 123, 27, 5),
(11, 2, 82.83, 124, 26, 4),
(11, 3, 80.67, 121, 29, 6),
(11, 4, 78.83, 118, 32, 7),
(11, 5, 83.17, 125, 25, 4);

-- Student 12 (poor attendance)
INSERT INTO attendance_summary (student_id, semester_id, attendance_percentage, days_present, days_absent, late_arrivals) VALUES
(12, 1, 41.83, 63, 87, 29),
(12, 2, 42.17, 63, 87, 28),
(12, 3, 40.50, 61, 89, 31),
(12, 4, 38.67, 58, 92, 33),
(12, 5, 40.17, 60, 90, 32);

-- Student 13 (good attendance)
INSERT INTO attendance_summary (student_id, semester_id, attendance_percentage, days_present, days_absent, late_arrivals) VALUES
(13, 1, 78.17, 117, 33, 8),
(13, 2, 79.17, 119, 31, 7),
(13, 3, 77.00, 116, 34, 9),
(13, 4, 75.17, 113, 37, 10),
(13, 5, 79.50, 119, 31, 7);

-- Student 14 (average attendance)
INSERT INTO attendance_summary (student_id, semester_id, attendance_percentage, days_present, days_absent, late_arrivals) VALUES
(14, 1, 72.83, 109, 41, 14),
(14, 2, 73.83, 111, 39, 13),
(14, 3, 71.67, 108, 42, 15),
(14, 4, 70.00, 105, 45, 16),
(14, 5, 74.33, 112, 38, 13);

-- Student 15 (poor attendance)
INSERT INTO attendance_summary (student_id, semester_id, attendance_percentage, days_present, days_absent, late_arrivals) VALUES
(15, 1, 38.17, 57, 93, 35),
(15, 2, 40.33, 61, 89, 33),
(15, 3, 38.67, 58, 92, 34),
(15, 4, 36.83, 55, 95, 36),
(15, 5, 39.17, 59, 91, 35);

-- 2023 Batch (students 16-20) - semesters 1-3
-- Student 16 (good attendance)
INSERT INTO attendance_summary (student_id, semester_id, attendance_percentage, days_present, days_absent, late_arrivals) VALUES
(16, 1, 80.17, 120, 30, 7),
(16, 2, 81.17, 122, 28, 6),
(16, 3, 83.50, 125, 25, 5);

-- Student 17 (poor attendance)
INSERT INTO attendance_summary (student_id, semester_id, attendance_percentage, days_present, days_absent, late_arrivals) VALUES
(17, 1, 41.83, 63, 87, 29),
(17, 2, 42.17, 63, 87, 28),
(17, 3, 38.50, 58, 92, 34);

-- Student 18 (average attendance)
INSERT INTO attendance_summary (student_id, semester_id, attendance_percentage, days_present, days_absent, late_arrivals) VALUES
(18, 1, 75.17, 113, 37, 10),
(18, 2, 73.83, 111, 39, 13),
(18, 3, 74.50, 112, 38, 12);

-- Student 19 (excellent attendance)
INSERT INTO attendance_summary (student_id, semester_id, attendance_percentage, days_present, days_absent, late_arrivals) VALUES
(19, 1, 88.50, 133, 17, 2),
(19, 2, 89.50, 134, 16, 1),
(19, 3, 90.17, 135, 15, 1);

-- Student 20 (poor attendance)
INSERT INTO attendance_summary (student_id, semester_id, attendance_percentage, days_present, days_absent, late_arrivals) VALUES
(20, 1, 40.17, 60, 90, 32),
(20, 2, 41.33, 62, 88, 30),
(20, 3, 38.83, 58, 92, 34);

-- 2024 Batch (students 21-25) - semesters 1-2
-- Student 21 (good attendance)
INSERT INTO attendance_summary (student_id, semester_id, attendance_percentage, days_present, days_absent, late_arrivals) VALUES
(21, 1, 81.83, 123, 27, 5),
(21, 2, 82.83, 124, 26, 4);

-- Student 22 (poor attendance)
INSERT INTO attendance_summary (student_id, semester_id, attendance_percentage, days_present, days_absent, late_arrivals) VALUES
(22, 1, 47.17, 71, 79, 25),
(22, 2, 42.33, 64, 86, 28);

-- Student 23 (excellent attendance)
INSERT INTO attendance_summary (student_id, semester_id, attendance_percentage, days_present, days_absent, late_arrivals) VALUES
(23, 1, 88.67, 133, 17, 2),
(23, 2, 89.17, 134, 16, 1);

-- Student 24 (average attendance)
INSERT INTO attendance_summary (student_id, semester_id, attendance_percentage, days_present, days_absent, late_arrivals) VALUES
(24, 1, 72.83, 109, 41, 14),
(24, 2, 71.83, 108, 42, 15);

-- Student 25 (poor attendance)
INSERT INTO attendance_summary (student_id, semester_id, attendance_percentage, days_present, days_absent, late_arrivals) VALUES
(25, 1, 40.17, 60, 90, 32),
(25, 2, 38.33, 58, 92, 34);

-- Update tests table
-- First disable safe updates
SET SQL_SAFE_UPDATES = 0;

-- Then run your update commands
UPDATE tests SET semester_id = 
    CASE 
        WHEN test_name LIKE '%101%' THEN 1 
        WHEN test_name LIKE '%102%' THEN 2
        WHEN test_name LIKE '%201%' THEN 3
        WHEN test_name LIKE '%202%' THEN 4
        WHEN test_name LIKE '%301%' THEN 5
        WHEN test_name LIKE '%302%' THEN 6
        WHEN test_name LIKE '%401%' THEN 7
        WHEN test_name LIKE '%402%' THEN 8
    END;

-- Delete from student_test_results
DELETE FROM student_test_results 
WHERE test_id IN (SELECT test_id FROM tests WHERE semester_id > 8);

-- Update dropout_history
UPDATE dropout_history SET semester_id = 
    CASE 
        WHEN semester_id > 8 THEN semester_id % 8 
        ELSE semester_id 
    END;

-- Finally, re-enable safe updates
SET SQL_SAFE_UPDATES = 1;