USE student_dropout_system;

-- Students Table
CREATE TABLE students (
    student_pid INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender ENUM('M', 'F', 'Other') NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(15) UNIQUE NOT NULL,
    address TEXT NOT NULL,
    socio_economic_status ENUM('Low', 'Medium', 'High') NOT NULL,
    enrollment_date DATE NOT NULL
);

-- Subjects Table
CREATE TABLE subjects (
    subject_id INT PRIMARY KEY AUTO_INCREMENT,
    subject_name VARCHAR(100) NOT NULL,
    subject_code VARCHAR(20) UNIQUE NOT NULL
);

-- Academic Records Table (Updated)
CREATE TABLE academic_records (
    record_id INT PRIMARY KEY AUTO_INCREMENT,
    student_pid INT NOT NULL,
    subject_id INT NOT NULL,
    semester VARCHAR(10) NOT NULL,
    ise1 DECIMAL(5,2) CHECK (ise1 BETWEEN 0 AND 10),
    ise2 DECIMAL(5,2) CHECK (ise2 BETWEEN 0 AND 10),
    mse DECIMAL(5,2) CHECK (mse BETWEEN 0 AND 20),
    ese DECIMAL(5,2) CHECK (ese BETWEEN 0 AND 60),
    practical_viva DECIMAL(5,2) CHECK (practical_viva BETWEEN 0 AND 25),
    termwork DECIMAL(5,2) CHECK (termwork BETWEEN 0 AND 15),
    class_behavior DECIMAL(5,2) CHECK (class_behavior BETWEEN 0 AND 5),
    attendance_marks DECIMAL(5,2) CHECK (attendance_marks BETWEEN 0 AND 5),
    internal DECIMAL(5,2) GENERATED ALWAYS AS 
        (practical_viva + termwork + class_behavior + attendance_marks) STORED,
    total_grade DECIMAL(5,2) GENERATED ALWAYS AS 
        (ise1 + ise2 + mse + ese + internal) STORED,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (student_pid) REFERENCES students(student_pid) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subjects(subject_id) ON DELETE CASCADE
);

-- Attendance Records Table
CREATE TABLE attendance_records (
    attendance_id INT PRIMARY KEY AUTO_INCREMENT,
    student_pid INT NOT NULL,
    subject_id INT NOT NULL,
    semester VARCHAR(10) NOT NULL,
    date DATE NOT NULL,
    no_of_hours_attended INT NOT NULL CHECK (no_of_hours_attended >= 0),
    total_hours INT NOT NULL CHECK (total_hours > 0),
    attendance_percentage DECIMAL(5,2) GENERATED ALWAYS AS ((no_of_hours_attended / total_hours) * 100) STORED,
    FOREIGN KEY (student_pid) REFERENCES students(student_pid) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subjects(subject_id) ON DELETE CASCADE
);

-- Dropout Risk Assessment Table
CREATE TABLE dropout_risk_assessment (
    risk_id INT PRIMARY KEY AUTO_INCREMENT,
    student_pid INT NOT NULL,
    risk_score DECIMAL(3,2) CHECK (risk_score BETWEEN 0 AND 1),
    risk_level ENUM('Low', 'Medium', 'High') NOT NULL,
    assessment_date DATE NOT NULL,
    FOREIGN KEY (student_pid) REFERENCES students(student_pid) ON DELETE CASCADE
);

-- Alerts Table
CREATE TABLE alerts (
    alert_id INT PRIMARY KEY AUTO_INCREMENT,
    student_pid INT NOT NULL,
    alert_type VARCHAR(100) NOT NULL,
    alert_message TEXT NOT NULL,
    sent_to VARCHAR(100) NOT NULL,
    sent_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_pid) REFERENCES students(student_pid) ON DELETE CASCADE
);

-- Recommendations Table
CREATE TABLE recommendations (
    rec_id INT PRIMARY KEY AUTO_INCREMENT,
    student_pid INT NOT NULL,
    risk_level ENUM('Low', 'Medium', 'High') NOT NULL,
    recommendation_text TEXT NOT NULL,
    date_generated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_pid) REFERENCES students(student_pid) ON DELETE CASCADE
);

-- Scholarships Table
CREATE TABLE scholarships (
    scholarship_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    eligibility TEXT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    application_deadline DATE NOT NULL,
    website_link VARCHAR(255) NOT NULL
);

-- Trigger for Attendance Marks
DELIMITER //
CREATE TRIGGER set_attendance_marks
BEFORE INSERT ON academic_records
FOR EACH ROW
BEGIN
    DECLARE att_percentage DECIMAL(5,2);
    
    SELECT attendance_percentage INTO att_percentage
    FROM attendance_records 
    WHERE student_pid = NEW.student_pid 
    AND subject_id = NEW.subject_id
    AND semester = NEW.semester
    ORDER BY date DESC
    LIMIT 1;
    
    IF att_percentage >= 90 THEN
        SET NEW.attendance_marks = 5;
    ELSEIF att_percentage >= 85 THEN
        SET NEW.attendance_marks = 4;
    ELSEIF att_percentage >= 80 THEN
        SET NEW.attendance_marks = 3;
    ELSE
        SET NEW.attendance_marks = 0;
    END IF;
END;
//
DELIMITER ;