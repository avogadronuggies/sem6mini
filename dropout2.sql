create database dropout2;
use dropout2;

CREATE TABLE parents (
    parent_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(15) NOT NULL,
    email VARCHAR(100),
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
    address TEXT NOT NULL,
    parent_id INT,
    FOREIGN KEY (parent_id) REFERENCES parents(parent_id)
);


CREATE TABLE teachers (
    teacher_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    department VARCHAR(50) NOT NULL,
    phone VARCHAR(15) NOT NULL,
    email VARCHAR(100) NOT NULL,
    date_of_joining DATE NOT NULL
);

CREATE TABLE academic_records (
    record_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    semester_id INT NOT NULL,
    department VARCHAR(50) NOT NULL,
    course_id INT NOT NULL,
    course_name VARCHAR(100) NOT NULL,
    marks INT NOT NULL,
    UNIQUE KEY (student_id, semester_id, course_id),
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

CREATE TABLE attendance_records (
    record_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    semester_id INT NOT NULL,
    department VARCHAR(50) NOT NULL,
    course_id INT NOT NULL,
    course_name VARCHAR(100) NOT NULL,
    attendance INT NOT NULL,
    UNIQUE KEY (student_id, semester_id, course_id),
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

CREATE TABLE student_feedback (
    feedback_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    course_id INT NOT NULL,
    course_name VARCHAR(100) NOT NULL,
    feedback_text TEXT NOT NULL,
    sentiment_score FLOAT,
    submission_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

-- Modify existing predicative_analysis table or replace it
DROP TABLE IF EXISTS predicative_analysis;
CREATE TABLE dropout_risk (
    risk_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    risk_score DECIMAL(5,2) NOT NULL,  -- Numerical score (e.g., 0-100)
    risk_level ENUM('High', 'Medium', 'Low', 'None') NOT NULL,
    prediction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    confidence_score DECIMAL(5,2),  -- Model confidence
    contributing_factors TEXT,  -- JSON or comma-separated list of factors
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

CREATE TABLE student_test_results (
    result_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    test_name VARCHAR(100) NOT NULL,
    test_date DATE NOT NULL,
    score DECIMAL(5,2) NOT NULL,
    max_score DECIMAL(5,2) NOT NULL,
    course_id INT,
    test_type ENUM('quiz', 'midterm', 'final', 'assignment', 'project') NOT NULL,
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

CREATE TABLE online_courses (
    course_id INT AUTO_INCREMENT PRIMARY KEY,
    platform VARCHAR(50) NOT NULL,  -- Coursera, Udemy, etc.
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

CREATE TABLE student_course_recommendations (
    recommendation_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    weak_subject_id INT NOT NULL,  -- Need to create a subjects table
    course_id INT NOT NULL,
    recommendation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_viewed BOOLEAN DEFAULT FALSE,
    is_enrolled BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (course_id) REFERENCES online_courses(course_id)
);

CREATE TABLE subjects (
    subject_id INT AUTO_INCREMENT PRIMARY KEY,
    subject_code VARCHAR(20) NOT NULL,
    subject_name VARCHAR(100) NOT NULL,
    department VARCHAR(50) NOT NULL,
    UNIQUE KEY (subject_code)
);
-- Add foreign key to academic_records table
ALTER TABLE academic_records
ADD COLUMN subject_id INT AFTER course_id,
ADD FOREIGN KEY (subject_id) REFERENCES subjects(subject_id);

-- Replace your simple scholarships table with a more detailed one
DROP TABLE IF EXISTS scholarships;
CREATE TABLE external_scholarships (
    scholarship_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    provider VARCHAR(100) NOT NULL,
    category VARCHAR(100),  -- need-based, merit-based, etc.
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
    match_score DECIMAL(4,2) NOT NULL,  -- How well student matches scholarship
    recommendation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_viewed BOOLEAN DEFAULT FALSE,
    is_applied BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (scholarship_id) REFERENCES external_scholarships(scholarship_id)
);
-- Enhance financial_records table for better scholarship matching
DROP TABLE IF EXISTS financial_records;
CREATE TABLE student_financial_assessment (
    assessment_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    income_category ENUM('high', 'middle', 'low') NOT NULL,
    needs_financial_aid BOOLEAN DEFAULT FALSE,
    eligible_for_aid_categories VARCHAR(255),  -- comma-separated list of categories
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
    UNIQUE KEY (student_id, semester_id)
);

CREATE TABLE model_performance_metrics (
    metric_id INT AUTO_INCREMENT PRIMARY KEY,
    model_name VARCHAR(50) NOT NULL,
    model_version VARCHAR(20) NOT NULL,
    training_date TIMESTAMP NOT NULL,
    accuracy DECIMAL(5,4),
    precision_score DECIMAL(5,4),
    recall_score DECIMAL(5,4),
    f1_score DECIMAL(5,4),
    auc_roc DECIMAL(5,4),
    feature_importance TEXT,  -- JSON format of feature importance
    hyperparameters TEXT      -- JSON format of hyperparameters
);


CREATE TABLE api_integration_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    service_name VARCHAR(50) NOT NULL,  -- 'coursera', 'udemy', 'scholarship_portal'
    request_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    response_status INT,
    records_processed INT,
    error_message TEXT,
    processing_time_ms INT
);

CREATE TABLE self_evaluation_score (
    eval_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    test_id VARCHAR(20) NOT NULL,
    test_score INT NOT NULL,
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

CREATE TABLE study_resources (
    resource_id INT AUTO_INCREMENT PRIMARY KEY,
    resource_name VARCHAR(100) NOT NULL,
    resource_link VARCHAR(255) NOT NULL
);

CREATE TABLE model_training_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    model_type VARCHAR(50),
    training_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    accuracy DECIMAL(5,4),
    parameters TEXT,  -- JSON of parameters
    features_used TEXT  -- JSON of feature list
);

CREATE TABLE dropout_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    dropout_date DATE,
    dropout_reason TEXT,
    semester_of_dropout INT,
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);





-- Parents
INSERT INTO parents (name, phone, email, occupation, address, relation_to_student) VALUES
('Rajesh Kumar', '9876543210', 'rajesh.kumar@example.com', 'Engineer', '123 MG Road, Mumbai', 'father'),
('Anita Sharma', '9123456780', 'anita.sharma@example.com', 'Teacher', '456 Park Street, Pune', 'mother'),
('Sunil Verma', '9812345678', 'sunil.verma@example.com', 'Businessman', '789 Industrial Area, Nashik', 'father'),
('Meena Joshi', '9001122334', 'meena.joshi@example.com', 'Doctor', '23 Residency Road, Nagpur', 'mother'),
('Deepak Das', '9988776655', 'deepak.das@example.com', 'Clerk', '10 Nehru Chowk, Thane', 'father'),
('Renu Singh', '9090909090', 'renu.singh@example.com', 'Engineer', '66 Green Street, Delhi', 'mother'),
('Ashok Rao', '9111223344', 'ashok.rao@example.com', 'Technician', '44 South End, Bangalore', 'father'),
('Sita Kulkarni', '8777888899', 'sita.kulkarni@example.com', 'Nurse', '33 West Wing, Hyderabad', 'mother'),
('Nilesh Patil', '8222334455', 'nilesh.patil@example.com', 'Contractor', 'Plot 5, Latur', 'father'),
('Manisha Jain', '8111222333', 'manisha.jain@example.com', 'Banker', 'Plot 9, Surat', 'mother');

-- Students
INSERT INTO students (name, branch, current_semester, batch_year, phone, email, address, parent_id) VALUES
('Amit Kumar', 'Computer Science', 4, 2022, '9876543211', 'amit.kumar@example.com', 'Mumbai', 1),
('Priya Sharma', 'Mechanical Engineering', 6, 2021, '9123456781', 'priya.sharma@example.com', 'Pune', 2),
('Ravi Verma', 'Electrical', 3, 2023, '9812345671', 'ravi.verma@example.com', 'Nashik', 3),
('Kavita Joshi', 'IT', 2, 2024, '9001122345', 'kavita.joshi@example.com', 'Nagpur', 4),
('Suresh Das', 'Civil', 4, 2022, '9988776644', 'suresh.das@example.com', 'Thane', 5),
('Pooja Singh', 'Computer Science', 5, 2022, '9090909080', 'pooja.singh@example.com', 'Delhi', 6),
('Manoj Rao', 'Mechanical Engineering', 6, 2021, '9111223300', 'manoj.rao@example.com', 'Bangalore', 7),
('Swati Kulkarni', 'IT', 2, 2024, '8777888877', 'swati.k@example.com', 'Hyderabad', 8),
('Ajay Patil', 'Electrical', 3, 2023, '8222334411', 'ajay.patil@example.com', 'Latur', 9),
('Neha Jain', 'Civil', 4, 2022, '8111222311', 'neha.jain@example.com', 'Surat', 10);

-- Teachers
INSERT INTO teachers (name, department, phone, email, date_of_joining) VALUES
('Dr. Suresh Mehta', 'Computer Science', '9876543212', 'suresh.mehta@example.com', '2015-06-15'),
('Prof. Neha Verma', 'Mechanical Engineering', '9123456782', 'neha.verma@example.com', '2017-08-20');

-- Subjects
INSERT INTO subjects (subject_code, subject_name, department) VALUES
('CS101', 'Data Structures', 'Computer Science'),
('ME201', 'Thermodynamics', 'Mechanical Engineering'),
('EE301', 'Circuit Theory', 'Electrical'),
('IT401', 'Web Technologies', 'IT'),
('CE501', 'Structural Analysis', 'Civil');

-- Academic Records
INSERT INTO academic_records (student_id, semester_id, department, course_id, course_name, marks, subject_id) VALUES
(1, 4, 'Computer Science', 101, 'Data Structures', 85, 1),
(2, 6, 'Mechanical Engineering', 201, 'Thermodynamics', 78, 2),
(3, 3, 'Electrical', 301, 'Circuit Theory', 70, 3),
(4, 2, 'IT', 401, 'Web Technologies', 88, 4),
(5, 4, 'Civil', 501, 'Structural Analysis', 60, 5),
(6, 5, 'Computer Science', 101, 'Data Structures', 72, 1),
(7, 6, 'Mechanical Engineering', 201, 'Thermodynamics', 74, 2),
(8, 2, 'IT', 401, 'Web Technologies', 65, 4),
(9, 3, 'Electrical', 301, 'Circuit Theory', 69, 3),
(10, 4, 'Civil', 501, 'Structural Analysis', 55, 5);

-- Attendance Records
INSERT INTO attendance_records (student_id, semester_id, department, course_id, course_name, attendance) VALUES
(1, 4, 'Computer Science', 101, 'Data Structures', 90),
(2, 6, 'Mechanical Engineering', 201, 'Thermodynamics', 85),
(3, 3, 'Electrical', 301, 'Circuit Theory', 88),
(4, 2, 'IT', 401, 'Web Technologies', 92),
(5, 4, 'Civil', 501, 'Structural Analysis', 78),
(6, 5, 'Computer Science', 101, 'Data Structures', 84),
(7, 6, 'Mechanical Engineering', 201, 'Thermodynamics', 79),
(8, 2, 'IT', 401, 'Web Technologies', 90),
(9, 3, 'Electrical', 301, 'Circuit Theory', 83),
(10, 4, 'Civil', 501, 'Structural Analysis', 76);

-- Dropout Risk
INSERT INTO dropout_risk (student_id, risk_score, risk_level, confidence_score, contributing_factors) VALUES
(1, 30.5, 'Low', 0.85, '["Low attendance"]'),
(2, 65.0, 'Medium', 0.75, '["Low grades"]'),
(3, 55.0, 'Medium', 0.70, '["Financial issues"]'),
(4, 20.0, 'Low', 0.90, '["Consistent performance"]'),
(5, 80.0, 'High', 0.95, '["Low grades", "High absenteeism"]'),
(6, 60.0, 'Medium', 0.77, '["Average grades"]'),
(7, 25.0, 'Low', 0.80, '["Improved attendance"]'),
(8, 35.0, 'Low', 0.88, '["Engaged in class"]'),
(9, 70.0, 'High', 0.82, '["Family issues"]'),
(10, 85.0, 'High', 0.91, '["Low academic performance"]');

-- Student Feedback
INSERT INTO student_feedback (student_id, course_id, course_name, feedback_text, sentiment_score) VALUES
(1, 101, 'Data Structures', 'Great course with practical examples.', 0.9),
(2, 201, 'Thermodynamics', 'Difficult but manageable.', 0.6),
(3, 301, 'Circuit Theory', 'Challenging concepts.', 0.5),
(4, 401, 'Web Technologies', 'Enjoyed the hands-on sessions.', 0.8),
(5, 501, 'Structural Analysis', 'Needs better explanation.', 0.4),
(6, 101, 'Data Structures', 'Helpful assignments.', 0.7),
(7, 201, 'Thermodynamics', 'More real-life examples needed.', 0.6),
(8, 401, 'Web Technologies', 'Fun and interactive.', 0.85),
(9, 301, 'Circuit Theory', 'Difficult labs.', 0.5),
(10, 501, 'Structural Analysis', 'Very theoretical.', 0.45);


-- First, alter tables to add password fields
ALTER TABLE students ADD COLUMN password VARCHAR(255) NOT NULL;
ALTER TABLE teachers ADD COLUMN password VARCHAR(255) NOT NULL;
ALTER TABLE parents ADD COLUMN password VARCHAR(255) NOT NULL;

-- Update existing data with passwords
-- For parents (10 existing records)
UPDATE parents SET password = CONCAT('parent', parent_id, 'pass') WHERE parent_id BETWEEN 1 AND 10;

-- For students (10 existing records)
UPDATE students SET password = CONCAT('student', student_id, 'pass') WHERE student_id BETWEEN 1 AND 10;

-- For teachers (2 existing records)
UPDATE teachers SET password = CONCAT('teacher', teacher_id, 'pass') WHERE teacher_id BETWEEN 1 AND 2;

-- Now add 90 more parent-student pairs (for a total of 100 students)

-- Insert 90 more parents (bringing total to 100)
INSERT INTO parents (name, phone, email, occupation, address, relation_to_student, password) VALUES
-- Parent IDs will continue from 11 to 100
('Vikram Malhotra', '9876543220', 'vikram.m@example.com', 'Software Developer', '123 JP Nagar, Bangalore', 'father', 'parent11pass'),
('Sunita Patel', '9876543221', 'sunita.p@example.com', 'Doctor', '456 MG Road, Ahmedabad', 'mother', 'parent12pass'),
('Rahul Gupta', '9876543222', 'rahul.g@example.com', 'Accountant', '789 Civil Lines, Jaipur', 'father', 'parent13pass'),
('Priyanka Reddy', '9876543223', 'priyanka.r@example.com', 'Professor', '101 Jubilee Hills, Hyderabad', 'mother', 'parent14pass'),
('Arun Sharma', '9876543224', 'arun.s@example.com', 'Businessman', '202 Aundh, Pune', 'father', 'parent15pass'),
('Kiran Bedi', '9876543225', 'kiran.b@example.com', 'Police Officer', '303 Indiranagar, Bangalore', 'mother', 'parent16pass'),
('Rajiv Gandhi', '9876543226', 'rajiv.g@example.com', 'Government Employee', '404 Shastri Nagar, Delhi', 'father', 'parent17pass'),
('Meenakshi Iyer', '9876543227', 'meenakshi.i@example.com', 'Bank Manager', '505 T Nagar, Chennai', 'mother', 'parent18pass'),
('Prakash Jha', '9876543228', 'prakash.j@example.com', 'Film Director', '606 Juhu, Mumbai', 'father', 'parent19pass'),
('Lakshmi Nair', '9876543229', 'lakshmi.n@example.com', 'Teacher', '707 Kakkanad, Kochi', 'mother', 'parent20pass'),
('Venkat Rao', '9876543230', 'venkat.r@example.com', 'Farmer', '808 Miyapur, Hyderabad', 'father', 'parent21pass'),
('Shobha Devi', '9876543231', 'shobha.d@example.com', 'Nurse', '909 Koramangala, Bangalore', 'mother', 'parent22pass'),
('Dinesh Kumar', '9876543232', 'dinesh.k@example.com', 'Architect', '1010 Model Town, Ludhiana', 'father', 'parent23pass'),
('Anu Agarwal', '9876543233', 'anu.a@example.com', 'Entrepreneur', '1111 Sector 18, Noida', 'mother', 'parent24pass'),
('Sanjay Saxena', '9876543234', 'sanjay.s@example.com', 'Doctor', '1212 Malviya Nagar, Jaipur', 'father', 'parent25pass'),
('Geeta Menon', '9876543235', 'geeta.m@example.com', 'Scientist', '1313 Sadashiv Peth, Pune', 'mother', 'parent26pass'),
('Ramesh Tiwari', '9876543236', 'ramesh.t@example.com', 'Lawyer', '1414 Gomti Nagar, Lucknow', 'father', 'parent27pass'),
('Sarita Ahluwalia', '9876543237', 'sarita.a@example.com', 'Professor', '1515 Chandigarh Road, Mohali', 'mother', 'parent28pass'),
('Mohan Kapoor', '9876543238', 'mohan.k@example.com', 'Businessman', '1616 FC Road, Pune', 'father', 'parent29pass'),
('Nandini Seth', '9876543239', 'nandini.s@example.com', 'Writer', '1717 Salt Lake, Kolkata', 'mother', 'parent30pass'),
('Prabhu Desai', '9876543240', 'prabhu.d@example.com', 'Engineer', '1818 Mapusa, Goa', 'father', 'parent31pass'),
('Swarna Pillai', '9876543241', 'swarna.p@example.com', 'Bank Manager', '1919 Adyar, Chennai', 'mother', 'parent32pass'),
('Kailash Mehra', '9876543242', 'kailash.m@example.com', 'Government Employee', '2020 Rohini, Delhi', 'father', 'parent33pass'),
('Usha Rajput', '9876543243', 'usha.r@example.com', 'Teacher', '2121 Shivaji Nagar, Nagpur', 'mother', 'parent34pass'),
('Mahesh Bhatt', '9876543244', 'mahesh.b@example.com', 'Film Producer', '2222 Andheri, Mumbai', 'father', 'parent35pass'),
('Divya Thakur', '9876543245', 'divya.t@example.com', 'Dentist', '2323 Vaishali, Ghaziabad', 'mother', 'parent36pass'),
('Ranjit Singh', '9876543246', 'ranjit.s@example.com', 'Pharmacist', '2424 Model Town, Amritsar', 'father', 'parent37pass'),
('Sangeeta Yadav', '9876543247', 'sangeeta.y@example.com', 'Accountant', '2525 Hazratganj, Lucknow', 'mother', 'parent38pass'),
('Dilip Chatterjee', '9876543248', 'dilip.c@example.com', 'Professor', '2626 Park Street, Kolkata', 'father', 'parent39pass'),
('Jyoti Prakash', '9876543249', 'jyoti.p@example.com', 'HR Manager', '2727 Kankarbagh, Patna', 'mother', 'parent40pass'),
('Ashish Khanna', '9876543250', 'ashish.k@example.com', 'Software Engineer', '2828 Vasant Kunj, Delhi', 'father', 'parent41pass'),
('Neelam Mishra', '9876543251', 'neelam.m@example.com', 'Doctor', '2929 Aliganj, Lucknow', 'mother', 'parent42pass'),
('Pankaj Tripathi', '9876543252', 'pankaj.t@example.com', 'Actor', '3030 Boring Road, Patna', 'father', 'parent43pass'),
('Rekha Gupta', '9876543253', 'rekha.g@example.com', 'Teacher', '3131 Kothrud, Pune', 'mother', 'parent44pass'),
('Vikas Batra', '9876543254', 'vikas.b@example.com', 'Businessman', '3232 Jalandhar Road, Ludhiana', 'father', 'parent45pass'),
('Sudha Murthy', '9876543255', 'sudha.m@example.com', 'Writer', '3333 Jayanagar, Bangalore', 'mother', 'parent46pass'),
('Rajesh Jain', '9876543256', 'rajesh.j@example.com', 'Chartered Accountant', '3434 CG Road, Ahmedabad', 'father', 'parent47pass'),
('Lata Banerjee', '9876543257', 'lata.b@example.com', 'Professor', '3535 Gariahat, Kolkata', 'mother', 'parent48pass'),
('Krishna Iyer', '9876543258', 'krishna.i@example.com', 'Lawyer', '3636 MG Road, Kochi', 'father', 'parent49pass'),
('Shalini Kapoor', '9876543259', 'shalini.k@example.com', 'Fashion Designer', '3737 Saket, Delhi', 'mother', 'parent50pass'),
('Naveen Shetty', '9876543260', 'naveen.s@example.com', 'Businessman', '3838 Mangalore Road, Udupi', 'father', 'parent51pass'),
('Preeti Verma', '9876543261', 'preeti.v@example.com', 'Doctor', '3939 Civil Lines, Allahabad', 'mother', 'parent52pass'),
('Gautam Singhania', '9876543262', 'gautam.s@example.com', 'Businessman', '4040 Marine Drive, Mumbai', 'father', 'parent53pass'),
('Asha Sharma', '9876543263', 'asha.s@example.com', 'Nurse', '4141 Saharanpur Road, Dehradun', 'mother', 'parent54pass'),
('Vijay Mallya', '9876543264', 'vijay.m@example.com', 'Businessman', '4242 Cunningham Road, Bangalore', 'father', 'parent55pass'),
('Mamta Kulkarni', '9876543265', 'mamta.k@example.com', 'Teacher', '4343 Camp, Pune', 'mother', 'parent56pass'),
('Rakesh Roshan', '9876543266', 'rakesh.r@example.com', 'Film Director', '4444 Juhu, Mumbai', 'father', 'parent57pass'),
('Shilpa Sood', '9876543267', 'shilpa.s@example.com', 'Interior Designer', '4545 Sector 17, Chandigarh', 'mother', 'parent58pass'),
('Anil Ambani', '9876543268', 'anil.a@example.com', 'Businessman', '4646 Peddar Road, Mumbai', 'father', 'parent59pass'),
('Kavita Krishnan', '9876543269', 'kavita.k@example.com', 'Activist', '4747 JNU Campus, Delhi', 'mother', 'parent60pass'),
('Farhan Ahmad', '9876543270', 'farhan.a@example.com', 'Doctor', '4848 Hazratganj, Lucknow', 'father', 'parent61pass'),
('Zeenat Khan', '9876543271', 'zeenat.k@example.com', 'Professor', '4949 Banjara Hills, Hyderabad', 'mother', 'parent62pass'),
('Mohd Iqbal', '9876543272', 'mohd.i@example.com', 'Teacher', '5050 Jamia Nagar, Delhi', 'father', 'parent63pass'),
('Farhana Azmi', '9876543273', 'farhana.a@example.com', 'Lawyer', '5151 Frazer Town, Bangalore', 'mother', 'parent64pass'),
('Abdul Karim', '9876543274', 'abdul.k@example.com', 'Businessman', '5252 Muhammad Ali Road, Mumbai', 'father', 'parent65pass'),
('Salma Patel', '9876543275', 'salma.p@example.com', 'Doctor', '5353 Juhapura, Ahmedabad', 'mother', 'parent66pass'),
('Joseph Mathew', '9876543276', 'joseph.m@example.com', 'Engineer', '5454 Kochi Bypass, Kochi', 'father', 'parent67pass'),
('Mary Thomas', '9876543277', 'mary.t@example.com', 'Nurse', '5555 Adoor, Kerala', 'mother', 'parent68pass'),
('George Varghese', '9876543278', 'george.v@example.com', 'Teacher', '5656 Kottayam, Kerala', 'father', 'parent69pass'),
('Anna Joseph', '9876543279', 'anna.j@example.com', 'Professor', '5757 Ernakulam, Kochi', 'mother', 'parent70pass'),
('Gurpreet Singh', '9876543280', 'gurpreet.s@example.com', 'Farmer', '5858 Amritsar Road, Jalandhar', 'father', 'parent71pass'),
('Harpreet Kaur', '9876543281', 'harpreet.k@example.com', 'Teacher', '5959 Model Town, Ludhiana', 'mother', 'parent72pass'),
('Jaspal Bhatti', '9876543282', 'jaspal.b@example.com', 'Comedian', '6060 Sector 43, Chandigarh', 'father', 'parent73pass'),
('Paramjit Kaur', '9876543283', 'paramjit.k@example.com', 'Nurse', '6161 Civil Lines, Amritsar', 'mother', 'parent74pass'),
('Wang Liu', '9876543284', 'wang.l@example.com', 'Business Consultant', '6262 Hakka Colony, Kolkata', 'father', 'parent75pass'),
('Mei Chen', '9876543285', 'mei.c@example.com', 'Restaurant Owner', '6363 China Town, Mumbai', 'mother', 'parent76pass'),
('David Smith', '9876543286', 'david.s@example.com', 'Expat Executive', '6464 Embassy Area, Delhi', 'father', 'parent77pass'),
('Emma Johnson', '9876543287', 'emma.j@example.com', 'International School Teacher', '6565 Whitefield, Bangalore', 'mother', 'parent78pass'),
('Mohammad Ali', '9876543288', 'mohammad.a@example.com', 'Doctor', '6666 Bhendi Bazaar, Mumbai', 'father', 'parent79pass'),
('Fatima Sheikh', '9876543289', 'fatima.s@example.com', 'Professor', '6767 Shivajinagar, Pune', 'mother', 'parent80pass'),
('Ratan Tata', '9876543290', 'ratan.t@example.com', 'Industrialist', '6868 Colaba, Mumbai', 'father', 'parent81pass'),
('Lalita Devi', '9876543291', 'lalita.d@example.com', 'Homemaker', '6969 Boring Road, Patna', 'mother', 'parent82pass'),
('Brijesh Patel', '9876543292', 'brijesh.p@example.com', 'Sports Coach', '7070 Navrangpura, Ahmedabad', 'father', 'parent83pass'),
('Radha Kumari', '9876543293', 'radha.k@example.com', 'Social Worker', '7171 Gandhi Nagar, Hyderabad', 'mother', 'parent84pass'),
('Vivek Oberoi', '9876543294', 'vivek.o@example.com', 'Actor', '7272 Film City, Mumbai', 'father', 'parent85pass'),
('Neetu Singh', '9876543295', 'neetu.s@example.com', 'Fashion Designer', '7373 Model Town, Delhi', 'mother', 'parent86pass'),
('Harish Rawat', '9876543296', 'harish.r@example.com', 'Politician', '7474 Dehradun Road, Rishikesh', 'father', 'parent87pass'),
('Chitra Dixit', '9876543297', 'chitra.d@example.com', 'Artist', '7575 Hauz Khas, Delhi', 'mother', 'parent88pass'),
('Bharat Patel', '9876543298', 'bharat.p@example.com', 'Businessman', '7676 Sabarmati, Ahmedabad', 'father', 'parent89pass'),
('Sheela Gowda', '9876543299', 'sheela.g@example.com', 'Artist', '7777 Malleshwaram, Bangalore', 'mother', 'parent90pass'),
('Rohit Shetty', '9876543300', 'rohit.s@example.com', 'Film Director', '7878 Versova, Mumbai', 'father', 'parent91pass'),
('Mira Nair', '9876543301', 'mira.n@example.com', 'Filmmaker', '7979 Greater Kailash, Delhi', 'mother', 'parent92pass'),
('Tushar Kapoor', '9876543302', 'tushar.k@example.com', 'Actor', '8080 Andheri, Mumbai', 'father', 'parent93pass'),
('Vandana Luthra', '9876543303', 'vandana.l@example.com', 'Entrepreneur', '8181 Defence Colony, Delhi', 'mother', 'parent94pass'),
('Prakash Padukone', '9876543304', 'prakash.p@example.com', 'Badminton Player', '8282 Malleswaram, Bangalore', 'father', 'parent95pass'),
('Kalpana Chawla', '9876543305', 'kalpana.c@example.com', 'Astronaut', '8383 Karnal Road, Haryana', 'mother', 'parent96pass'),
('Narayan Murthy', '9876543306', 'narayan.m@example.com', 'IT Entrepreneur', '8484 JP Nagar, Bangalore', 'father', 'parent97pass'),
('Indra Nooyi', '9876543307', 'indra.n@example.com', 'Corporate Executive', '8585 Anna Nagar, Chennai', 'mother', 'parent98pass'),
('Mukesh Ambani', '9876543308', 'mukesh.a@example.com', 'Businessman', '8686 Altamount Road, Mumbai', 'father', 'parent99pass'),
('Nita Ambani', '9876543309', 'nita.a@example.com', 'Philanthropist', '8787 Peddar Road, Mumbai', 'mother', 'parent100pass');

-- Insert 90 more students (bringing total to 100)
INSERT INTO students (name, branch, current_semester, batch_year, phone, email, address, parent_id, password) VALUES
-- Student IDs will continue from 11 to 100
('Rohit Sharma', 'Computer Science', 4, 2022, '9876543310', 'rohit.sharma@example.com', 'Bangalore', 11, 'student11pass'),
('Sneha Patel', 'Electronics', 3, 2023, '9876543311', 'sneha.patel@example.com', 'Ahmedabad', 12, 'student12pass'),
('Vikram Gupta', 'Mechanical Engineering', 5, 2021, '9876543312', 'vikram.gupta@example.com', 'Jaipur', 13, 'student13pass'),
('Aishwarya Reddy', 'IT', 2, 2024, '9876543313', 'aishwarya.r@example.com', 'Hyderabad', 14, 'student14pass'),
('Rajat Sharma', 'Civil', 4, 2022, '9876543314', 'rajat.sharma@example.com', 'Pune', 15, 'student15pass'),
('Anjali Bedi', 'Computer Science', 3, 2023, '9876543315', 'anjali.bedi@example.com', 'Bangalore', 16, 'student16pass'),
('Vikas Gandhi', 'Electrical', 5, 2021, '9876543316', 'vikas.gandhi@example.com', 'Delhi', 17, 'student17pass'),
('Shweta Iyer', 'IT', 2, 2024, '9876543317', 'shweta.iyer@example.com', 'Chennai', 18, 'student18pass'),
('Akash Jha', 'Mechanical Engineering', 4, 2022, '9876543318', 'akash.jha@example.com', 'Mumbai', 19, 'student19pass'),
('Divya Nair', 'Electronics', 3, 2023, '9876543319', 'divya.nair@example.com', 'Kochi', 20, 'student20pass'),
('Sridhar Rao', 'Civil', 5, 2021, '9876543320', 'sridhar.rao@example.com', 'Hyderabad', 21, 'student21pass'),
('Nikita Devi', 'Computer Science', 2, 2024, '9876543321', 'nikita.devi@example.com', 'Bangalore', 22, 'student22pass'),
('Arjun Kumar', 'Mechanical Engineering', 4, 2022, '9876543322', 'arjun.kumar@example.com', 'Ludhiana', 23, 'student23pass'),
('Tanya Agarwal', 'IT', 3, 2023, '9876543323', 'tanya.agarwal@example.com', 'Noida', 24, 'student24pass'),
('Vivek Saxena', 'Electrical', 5, 2021, '9876543324', 'vivek.saxena@example.com', 'Jaipur', 25, 'student25pass'),
('Ananya Menon', 'Computer Science', 2, 2024, '9876543325', 'ananya.menon@example.com', 'Pune', 26, 'student26pass'),
('Gaurav Tiwari', 'Civil', 4, 2022, '9876543326', 'gaurav.tiwari@example.com', 'Lucknow', 27, 'student27pass'),
('Ritika Ahluwalia', 'Electronics', 3, 2023, '9876543327', 'ritika.ahluwalia@example.com', 'Mohali', 28, 'student28pass'),
('Nikhil Kapoor', 'Mechanical Engineering', 5, 2021, '9876543328', 'nikhil.kapoor@example.com', 'Pune', 29, 'student29pass'),
('Shreya Seth', 'IT', 2, 2024, '9876543329', 'shreya.seth@example.com', 'Kolkata', 30, 'student30pass'),
('Vishal Desai', 'Electrical', 4, 2022, '9876543330', 'vishal.desai@example.com', 'Goa', 31, 'student31pass'),
('Nisha Pillai', 'Computer Science', 3, 2023, '9876543331', 'nisha.pillai@example.com', 'Chennai', 32, 'student32pass'),
('Rahul Mehra', 'Civil', 5, 2021, '9876543332', 'rahul.mehra@example.com', 'Delhi', 33, 'student33pass'),
('Meera Rajput', 'Electronics', 2, 2024, '9876543333', 'meera.rajput@example.com', 'Nagpur', 34, 'student34pass'),
('Alok Bhatt', 'Mechanical Engineering', 4, 2022, '9876543334', 'alok.bhatt@example.com', 'Mumbai', 35, 'student35pass'),
('Sonia Thakur', 'IT', 3, 2023, '9876543335', 'sonia.thakur@example.com', 'Ghaziabad', 36, 'student36pass'),
('Gurpreet Singh', 'Electrical', 5, 2021, '9876543336', 'gurpreet.singh@example.com', 'Amritsar', 37, 'student37pass'),
('Deepika Yadav', 'Computer Science', 2, 2024, '9876543337', 'deepika.yadav@example.com', 'Lucknow', 38, 'student38pass'),
('Arnab Chatterjee', 'Civil', 4, 2022, '9876543338', 'arnab.chatterjee@example.com', 'Kolkata', 39, 'student39pass'),
('Ritu Prakash', 'Electronics', 3, 2023, '9876543339', 'ritu.prakash@example.com', 'Patna', 40, 'student40pass'),
('Kunal Khanna', 'Mechanical Engineering', 5, 2021, '9876543340', 'kunal.khanna@example.com', 'Delhi', 41, 'student41pass'),
('Shweta Mishra', 'IT', 2, 2024, '9876543341', 'shweta.mishra@example.com', 'Lucknow', 42, 'student42pass'),
('Ankur Tripathi', 'Electrical', 4, 2022, '9876543342', 'ankur.tripathi@example.com', 'Patna', 43, 'student43pass'),
('Shalini Gupta', 'Computer Science', 3, 2023, '9876543343', 'shalini.gupta@example.com', 'Pune', 44, 'student44pass'),
('Ankit Batra', 'Civil', 5, 2021, '9876543344', 'ankit.batra@example.com', 'Ludhiana', 45, 'student45pass'),
('Rohan Murthy', 'Electronics', 2, 2024, '9876543345', 'rohan.murthy@example.com', 'Bangalore', 46, 'student46pass'),
('Neha Jain', 'Mechanical Engineering', 4, 2022, '9876543346', 'neha.jain@example.com', 'Ahmedabad', 47, 'student47pass'),
('Arijit Banerjee', 'IT', 3, 2023, '9876543347', 'arijit.banerjee@example.com', 'Kolkata', 48, 'student48pass'),
('Rahul Iyer', 'Electrical', 5, 2021, '9876543348', 'rahul.iyer@example.com', 'Kochi', 49, 'student49pass'),
('Prachi Kapoor', 'Computer Science', 2, 2024, '9876543349', 'prachi.kapoor@example.com', 'Delhi', 50, 'student50pass'),
('Karthik Shetty', 'Civil', 4, 2022, '9876543350', 'karthik.shetty@example.com', 'Udupi', 51, 'student51pass'),
('Shikha Verma', 'Electronics', 3, 2023, '9876543351', 'shikha.verma@example.com', 'Allahabad', 52, 'student52pass'),
('Rishab Singhania', 'Mechanical Engineering', 5, 2021, '9876543352', 'rishab.singhania@example.com', 'Mumbai', 53, 'student53pass'),
('Sakshi Sharma', 'IT', 2, 2024, '9876543353', 'sakshi.sharma@example.com', 'Dehradun', 54, 'student54pass'),
('Akshay Mallya', 'Electrical', 4, 2022, '9876543354', 'akshay.mallya@example.com', 'Bangalore', 55, 'student55pass'),
('Nandita Kulkarni', 'Computer Science', 3, 2023, '9876543355', 'nandita.kulkarni@example.com', 'Pune', 56, 'student56pass'),
('Hrithik Roshan', 'Civil', 5, 2021, '9876543356', 'hrithik.roshan@example.com', 'Mumbai', 57, 'student57pass'),
('Kirti Sood', 'Electronics', 2, 2024, '9876543357', 'kirti.sood@example.com', 'Chandigarh', 58, 'student58pass'),
('Dhruv Ambani', 'Mechanical Engineering', 4, 2022, '9876543358', 'dhruv.ambani@example.com', 'Mumbai', 59, 'student59pass'),
('Priya Krishnan', 'IT', 3, 2023, '9876543359', 'priya.krishnan@example.com', 'Delhi', 60, 'student60pass'),
('Arif Ahmad', 'Electrical', 5, 2021, '9876543360', 'arif.ahmad@example.com', 'Lucknow', 61, 'student61pass'),
('Farah Khan', 'Computer Science', 2, 2024, '9876543361', 'farah.khan@example.com', 'Hyderabad', 62, 'student62pass'),
('Imran Iqbal', 'Civil', 4, 2022, '9876543362', 'imran.iqbal@example.com', 'Delhi', 63, 'student63pass'),
('Shabana Azmi', 'Electronics', 3, 2023, '9876543363', 'shabana.azmi@example.com', 'Bangalore', 64, 'student64pass'),
('Ibrahim Karim', 'Mechanical Engineering', 5, 2021, '9876543364', 'ibrahim.karim@example.com', 'Mumbai', 65, 'student65pass'),
('Ayesha Patel', 'IT', 2, 2024, '9876543365', 'ayesha.patel@example.com', 'Ahmedabad', 66, 'student66pass'),
('Thomas Mathew', 'Electrical', 4, 2022, '9876543366', 'thomas.mathew@example.com', 'Kochi', 67, 'student67pass'),
('Susan Thomas', 'Computer Science', 3, 2023, '9876543367', 'susan.thomas@example.com', 'Kerala', 68, 'student68pass'),
('Philip Varghese', 'Civil', 5, 2021, '9876543368', 'philip.varghese@example.com', 'Kottayam', 69, 'student69pass'),
('Elizabeth Joseph', 'Electronics', 2, 2024, '9876543369', 'elizabeth.j@example.com', 'Kochi', 70, 'student70pass'),
('Manpreet Singh', 'Mechanical Engineering', 4, 2022, '9876543370', 'manpreet.singh@example.com', 'Jalandhar', 71, 'student71pass'),
('Jaspreet Kaur', 'IT', 3, 2023, '9876543371', 'jaspreet.kaur@example.com', 'Ludhiana', 72, 'student72pass'),
('Navjot Bhatti', 'Electrical', 5, 2021, '9876543372', 'navjot.bhatti@example.com', 'Chandigarh', 73, 'student73pass'),
('Simran Kaur', 'Computer Science', 2, 2024, '9876543373', 'simran.kaur@example.com', 'Amritsar', 74, 'student74pass'),
('Lee Wong', 'Civil', 4, 2022, '9876543374', 'lee.wong@example.com', 'Kolkata', 75, 'student75pass'),
('Li Chen', 'Electronics', 3, 2023, '9876543375', 'li.chen@example.com', 'Mumbai', 76, 'student76pass'),
('John Smith', 'Mechanical Engineering', 5, 2021, '9876543376', 'john.smith@example.com', 'Delhi', 77, 'student77pass'),
('Sarah Johnson', 'IT', 2, 2024, '9876543377', 'sarah.johnson@example.com', 'Bangalore', 78, 'student78pass'),
('Ahmed Ali', 'Electrical', 4, 2022, '9876543378', 'ahmed.ali@example.com', 'Mumbai', 79, 'student79pass'),
('Aisha Sheikh', 'Computer Science', 3, 2023, '9876543379', 'aisha.sheikh@example.com', 'Pune', 80, 'student80pass'),
('Ranbir Tata', 'Civil', 5, 2021, '9876543380', 'ranbir.tata@example.com', 'Mumbai', 81, 'student81pass'),
('Anita Devi', 'Electronics', 2, 2024, '9876543381', 'anita.devi@example.com', 'Patna', 82, 'student82pass'),
('Rajesh Patel', 'Mechanical Engineering', 4, 2022, '9876543382', 'rajesh.patel@example.com', 'Ahmedabad', 83, 'student83pass'),
('Sunita Kumari', 'IT', 3, 2023, '9876543383', 'sunita.kumari@example.com', 'Hyderabad', 84, 'student84pass'),
('Aditya Oberoi', 'Electrical', 5, 2021, '9876543384', 'aditya.oberoi@example.com', 'Mumbai', 85, 'student85pass'),
('Kavita Singh', 'Computer Science', 2, 2024, '9876543385', 'kavita.singh@example.com', 'Delhi', 86, 'student86pass'),
('Ajay Rawat', 'Civil', 4, 2022, '9876543386', 'ajay.rawat@example.com', 'Rishikesh', 87, 'student87pass'),
('Poonam Dixit', 'Electronics', 3, 2023, '9876543387', 'poonam.dixit@example.com', 'Delhi', 88, 'student88pass'),
('Hitesh Patel', 'Mechanical Engineering', 5, 2021, '9876543388', 'hitesh.patel@example.com', 'Ahmedabad', 89, 'student89pass'),
('Meena Gowda', 'IT', 2, 2024, '9876543389', 'meena.gowda@example.com', 'Bangalore', 90, 'student90pass'),
('Varun Shetty', 'Electrical', 4, 2022, '9876543390', 'varun.shetty@example.com', 'Mumbai', 91, 'student91pass'),
('Deepti Nair', 'Computer Science', 3, 2023, '9876543391', 'deepti.nair@example.com', 'Delhi', 92, 'student92pass'),
('Karan Kapoor', 'Civil', 5, 2021, '9876543392', 'karan.kapoor@example.com', 'Mumbai', 93, 'student93pass'),
('Sonali Luthra', 'Electronics', 2, 2024, '9876543393', 'sonali.luthra@example.com', 'Delhi', 94, 'student94pass'),
('Anand Padukone', 'Mechanical Engineering', 4, 2022, '9876543394', 'anand.padukone@example.com', 'Bangalore', 95, 'student95pass'),
('Manisha Chawla', 'IT', 3, 2023, '9876543395', 'manisha.chawla@example.com', 'Haryana', 96, 'student96pass'),
('Rohan Murthy', 'Electrical', 5, 2021, '9876543396', 'rohan.murthy@example.com', 'Bangalore', 97, 'student97pass'),
('Shanti Nooyi', 'Computer Science', 2, 2024, '9876543397', 'shanti.nooyi@example.com', 'Chennai', 98, 'student98pass'),
('Aakash Ambani', 'Civil', 4, 2022, '9876543398', 'aakash.ambani@example.com', 'Mumbai', 99, 'student99pass'),
('Isha Ambani', 'Electronics', 3, 2023, '9876543399', 'isha.ambani@example.com', 'Mumbai', 100, 'student100pass');

-- Add more academic records, attendance records, dropout risk, etc. for the new students
-- Sample academic records for some of the new students (just a small sample set)
INSERT INTO academic_records (student_id, semester_id, department, course_id, course_name, marks, subject_id) VALUES
(11, 4, 'Computer Science', 101, 'Data Structures', 82, 1),
(12, 3, 'Electronics', 301, 'Circuit Theory', 75, 3),
(13, 5, 'Mechanical Engineering', 201, 'Thermodynamics', 79, 2),
(14, 2, 'IT', 401, 'Web Technologies', 90, 4),
(15, 4, 'Civil', 501, 'Structural Analysis', 65, 5),
(16, 3, 'Computer Science', 101, 'Data Structures', 77, 1),
(17, 5, 'Electrical', 301, 'Circuit Theory', 85, 3),
(18, 2, 'IT', 401, 'Web Technologies', 93, 4),
(19, 4, 'Mechanical Engineering', 201, 'Thermodynamics', 66, 2),
(20, 3, 'Electronics', 301, 'Circuit Theory', 71, 3);

-- Sample attendance records for some of the new students
INSERT INTO attendance_records (student_id, semester_id, department, course_id, course_name, attendance) VALUES
(11, 4, 'Computer Science', 101, 'Data Structures', 88),
(12, 3, 'Electronics', 301, 'Circuit Theory', 92),
(13, 5, 'Mechanical Engineering', 201, 'Thermodynamics', 75),
(14, 2, 'IT', 401, 'Web Technologies', 94),
(15, 4, 'Civil', 501, 'Structural Analysis', 80),
(16, 3, 'Computer Science', 101, 'Data Structures', 86),
(17, 5, 'Electrical', 301, 'Circuit Theory', 78),
(18, 2, 'IT', 401, 'Web Technologies', 95),
(19, 4, 'Mechanical Engineering', 201, 'Thermodynamics', 69),
(20, 3, 'Electronics', 301, 'Circuit Theory', 82);

-- Sample dropout risk for some of the new students
INSERT INTO dropout_risk (student_id, risk_score, risk_level, confidence_score, contributing_factors) VALUES
(11, 25.0, 'Low', 0.88, '["Good performance", "Regular attendance"]'),
(12, 35.0, 'Low', 0.82, '["Above average performance"]'),
(13, 45.0, 'Medium', 0.75, '["Average attendance"]'),
(14, 15.0, 'Low', 0.92, '["Excellent performance", "High attendance"]'),
(15, 55.0, 'Medium', 0.70, '["Below average performance"]'),
(16, 30.0, 'Low', 0.85, '["Good peer interactions"]'),
(17, 50.0, 'Medium', 0.73, '["Financial issues"]'),
(18, 20.0, 'Low', 0.90, '["Strong academic record"]'),
(19, 75.0, 'High', 0.88, '["Poor attendance", "Low grades"]'),
(20, 40.0, 'Medium', 0.78, '["Family issues"]');

-- Add a few more teachers while we're at it
INSERT INTO teachers (name, department, phone, email, date_of_joining, password) VALUES
('Dr. Ramesh Joshi', 'Computer Science', '9876543200', 'ramesh.joshi@example.com', '2016-07-10', 'teacher3pass'),
('Prof. Anita Desai', 'Electronics', '9876543201', 'anita.desai@example.com', '2018-05-15', 'teacher4pass'),
('Dr. Sanjay Gupta', 'Mechanical Engineering', '9876543202', 'sanjay.gupta@example.com', '2014-11-22', 'teacher5pass'),
('Prof. Kavita Singh', 'IT', '9876543203', 'kavita.singh@example.com', '2019-01-05', 'teacher6pass'),
('Dr. Prakash Reddy', 'Civil', '9876543204', 'prakash.reddy@example.com', '2017-09-18', 'teacher7pass'),
('Prof. Deepak Kumar', 'Electrical', '9876543205', 'deepak.kumar@example.com', '2020-02-28', 'teacher8pass');

-- Add more student feedback for some of the new students
INSERT INTO student_feedback (student_id, course_id, course_name, feedback_text, sentiment_score) VALUES
(11, 101, 'Data Structures', 'The course was well structured and informative.', 0.85),
(12, 301, 'Circuit Theory', 'Labs were helpful but theory classes need improvement.', 0.65),
(13, 201, 'Thermodynamics', 'Difficult to follow at times, needs more examples.', 0.55),
(14, 401, 'Web Technologies', 'Very practical and useful for industry applications.', 0.92),
(15, 501, 'Structural Analysis', 'The course material needs updating.', 0.48),
(16, 101, 'Data Structures', 'Assignments helped solidify concepts.', 0.82),
(17, 301, 'Circuit Theory', 'Professor explains complex topics clearly.', 0.88),
(18, 401, 'Web Technologies', 'Best course I have taken so far!', 0.95),
(19, 201, 'Thermodynamics', 'Too many formulas to memorize without context.', 0.40),
(20, 301, 'Circuit Theory', 'Labs need better equipment.', 0.60);



-- Academic Records for student_id = 1, semester_id = 4
INSERT INTO academic_records (student_id, semester_id, department, course_id, course_name, marks, subject_id) VALUES
(1, 4, 'Computer Science', 102, 'Algorithms', 78, 2),
(1, 4, 'Computer Science', 103, 'Operating Systems', 82, 3),
(1, 4, 'Computer Science', 104, 'Database Management Systems', 88, 4),
(1, 4, 'Computer Science', 105, 'Computer Networks', 75, 5);

-- Attendance Records for student_id = 1, semester_id = 4
INSERT INTO attendance_records (student_id, semester_id, department, course_id, course_name, attendance) VALUES
(1, 4, 'Computer Science', 102, 'Algorithms', 85),
(1, 4, 'Computer Science', 103, 'Operating Systems', 88),
(1, 4, 'Computer Science', 104, 'Database Management Systems', 92),
(1, 4, 'Computer Science', 105, 'Computer Networks', 80);
-- Academic Records for student_id = 1, semester_id = 3
use dropout2;
INSERT INTO academic_records (student_id, semester_id, department, course_id, course_name, marks, subject_id) VALUES
(1, 3, 'Computer Science', 101, 'Data Structures', 56, 1),
(1, 3, 'Computer Science', 102, 'Algorithms', 73, 2),
(1, 3, 'Computer Science', 103, 'Operating Systems', 68, 3),
(1, 3, 'Computer Science', 104, 'Database Management Systems', 88, 4);

-- Attendance Records for student_id = 1, semester_id = 3
INSERT INTO attendance_records (student_id, semester_id, department, course_id, course_name, attendance) VALUES
(1, 3, 'Computer Science', 101, 'Data Structures', 80),
(1, 3, 'Computer Science', 102, 'Algorithms', 85),
(1, 3, 'Computer Science', 103, 'Operating Systems', 78),
(1, 3, 'Computer Science', 104, 'Database Management Systems', 92);

-- Academic Records for student_id = 1, semester_id = 2
INSERT INTO academic_records (student_id, semester_id, department, course_id, course_name, marks, subject_id) VALUES
(1, 2, 'Computer Science', 101, 'Data Structures', 61, 1),
(1, 2, 'Computer Science', 102, 'Algorithms', 70, 2),
(1, 2, 'Computer Science', 103, 'Operating Systems', 23, 3),
(1, 2, 'Computer Science', 104, 'Database Management Systems', 85, 4);

-- Attendance Records for student_id = 1, semester_id = 2
INSERT INTO attendance_records (student_id, semester_id, department, course_id, course_name, attendance) VALUES
(1, 2, 'Computer Science', 101, 'Data Structures', 78),
(1, 2, 'Computer Science', 102, 'Algorithms', 85),
(1, 2, 'Computer Science', 103, 'Operating Systems', 75),
(1, 2, 'Computer Science', 104, 'Database Management Systems', 90);

-- Academic Records for student_id = 1, semester_id = 1
INSERT INTO academic_records (student_id, semester_id, department, course_id, course_name, marks, subject_id) VALUES
(1, 1, 'Computer Science', 101, 'Data Structures', 50, 1),
(1, 1, 'Computer Science', 102, 'Algorithms', 60, 2),
(1, 1, 'Computer Science', 103, 'Operating Systems', 55, 3),
(1, 1, 'Computer Science', 104, 'Database Management Systems', 80, 4);

-- Attendance Records for student_id = 1, semester_id = 1
INSERT INTO attendance_records (student_id, semester_id, department, course_id, course_name, attendance) VALUES
(1, 1, 'Computer Science', 101, 'Data Structures', 70),
(1, 1, 'Computer Science', 102, 'Algorithms', 75),
(1, 1, 'Computer Science', 103, 'Operating Systems', 65),
(1, 1, 'Computer Science', 104, 'Database Management Systems', 85);
