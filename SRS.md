# Software Requirements Specification (SRS)

## 0.1 Title
Active Learning: Automated Internship Progress & Attendance Tracking System

## 0.2 Contributors
Dela Cruz, Kurt James | Hernandez, Sean Matthew | Mejia, Cyprus | Tan, Andrea Pauline

## 1. Introduction

### 1.1 Purpose of the System / Business Goals
The primary purpose of the system is to automate the tracking of rendering hours, progress tracking, and mandatory milestone logs for interns within Active Learning. This initiative replaces the disorganized, spreadsheet-based internship tracker with a secure, distributed web portal.
* **Stop Using Spreadsheets**: Replace messy, manual Excel sheets with an automated system.
* **Show Clear End Dates**: Give interns a smart dashboard that instantly calculates exactly when they will finish their required hours based on daily parameters.
* **Easy Rule Enforcement**: Make sure interns log tasks, upload proof, and hit their milestones all in one place.
* **Enforce Data Isolation and Security**: Utilize a 3-tier Multi-DBMS architecture to separate user credentials, core business logs, and compliance audit trails.

### 1.2 Multi-DBMS System Architecture
* **Apache Derby (DBMS 1 — authdb)**: Manages secure user profiles, credentials, role configurations, and demographic information (e.g. Universities, assigned offices) for Interns and Administrators.
* **MySQL (DBMS 2 — monitoringdb)**: Houses the high-frequency daily transaction tables: `activity_submissions` (task logs, simulated hours, and uploaded JPEG/PNG proof-of-work images) and `internship_logs` (stopwatch sessions).
* **PostgreSQL (DBMS 3 — ojt_auditdb)**: Hosts the secure, append-only security logs recording system actions (`LOGIN`, `LOGOUT`, `REPORT_GENERATED`, `SESSION_TIMEOUT`) along with timestamps and origin IP addresses.

### 1.3 User Roles
* **Intern (Guest User)**: Views their dynamic hour cards, fills out the daily activity form with image proof, manages the optional live visual timer, and checks their projected calendar.
* **Coordinator / Admin**: Customizes the master timeline parameters, adjusts baseline daily loads using sliders, toggles holiday exclusions, reviews task submissions, and manages system user profiles.

## 2. Functional Requirements (FRs)

### 2.1 Authentication and Session Module
* **FR-AUTH-01: Secure Role Navigation**: The system must authenticate user accounts from the database (`APP.ADMIN` and `APP.INTERN` tables in Apache Derby) and open the correct workspace views (`admin.jsp` or `guest.jsp`) based on their account type. Submissions are handled securely via HTTPS POST requests to a back-end validation controller (`LoginServlet.java`).
* **FR-AUTH-02: Database Validation & Security**: The system shall validate login parameters against the existing authentication database and strictly block unauthenticated users from directly targeting protected application routes via the browser URL bar. There must be a controller class (`UserDAO.java`) that handles the Apache Derby (DBMS 1) database containing the user record. It verifies credentials using cryptographic hash checks (`CryptoUtil.java` using PBKDF2WithHmacSHA256) without exposing plain-text values.
* **FR-AUTH-03: Session Filtering**: The server must implement a global HTTP Session Filter (`AuthFilter.java`) that checks all incoming requests. If no active login session is found, access is denied and the request is redirected to the login page.
* **FR-AUTH-04: Error Message Handling**: If any validation checkpoint fails, the login servlet returns a warning context string. It displays a localized, user-friendly red alert box for invalid CAPTCHA (handled via `CaptchaServlet.java`) and handles invalid credentials gracefully without crashing the page layout.
* **FR-AUTH-05: Explicit Session Termination**: Destroys the active server-side session object explicitly via `session.invalidate()` within `LogoutServlet.java`. It completely clears the browser’s authentication token footprint, records the logout event in the PostgreSQL audit trail, and forces a hard client-side redirection.

### 2.2 Intern Tracking and Submission Module
* **FR-TRACK-01: Activity Submission**: Interns must be able to submit daily logs containing the submission date, rendered hours, description of tasks, and an attached JPEG/PNG file as proof of work. Form submission is sent to `SubmitTaskServlet.java`.
* **FR-TRACK-02: Work Hour Synchronization**: The system must automatically update the rendered hours, remaining hours, completion percentage, and milestone progress on the intern's dashboard upon coordinator approval of task submissions.
* **FR-TRACK-03: Real-Time Stopwatch**: Interns can use an optional client-side timer widget to simulate daily attendance tracking, which logs active sessions to the MySQL database.
* **FR-TRACK-04: Multi-Tab Isolation**: The system isolates user sessions per browser tab utilizing `TabSessionHelper.java` and `tabSession.js` via a unique `tabId` parameter to prevent session conflicts when users open multiple tabs.

### 2.3 Coordinator and Administration Module
* **FR-ADMIN-01: Intern Account Creation**: Admins must be able to register new interns, which triggers automatic, non-sequential alphanumeric ID generation and office assignment.
* **FR-ADMIN-02: Task Review Queue**: Admins can approve or reject submitted activity logs. Approving a log updates the intern's cumulative hours in the operational database.
* **FR-ADMIN-03: System Configuration**: Admins can adjust baseline parameters such as required internship hours, holiday exclusions, and daily load projections.

### 2.4 Audit and Reporting Module
* **FR-AUDIT-01: Audit Log Capturing**: The system must log security-sensitive operations (logins, logouts, report generation, system errors) into the PostgreSQL `ojt_auditdb` database via `PostgreSQLDAO.java`.
* **FR-AUDIT-02: PDF Generation**: Admins can generate and download landscape PDF reports (All Users, Admin Activity Records, OJT Activity Logs, and System Audit Trails) compiled on-the-fly via `PdfReportHelper.java` and streamed directly to the browser.

## 3. Non-Functional Requirements (NFRs)

### 3.1 Usability Requirements
* **NFR-USE-001: Grid Layout System**: The system shall utilize a clean, multi-column grid layout system structured in `admin.css` and `guest.css` that keeps dashboard elements organized, readable, and perfectly spaced across all monitor and laptop sizes.

### 3.2 Security Requirements
* **NFR-SEC-001: Password Hashing**: Passwords must be hashed using PBKDF2WithHmacSHA256 with cryptographically strong, dynamic salts.
* **NFR-SEC-002: PDF Data Protection**: The system does not display or print passwords in any PDF report. It completely excludes credential strings from file compilation classes during document exports to ensure the absolute security and privacy of user records.
* **NFR-SEC-003: Cross-Site Scripting (XSS) Defenses**: The system must sanitize and HTML-encode all user-supplied inputs using `HtmlUtil.java` and `InputValidator.java` prior to rendering them in JSP views.
* **NFR-SEC-004: Upload Validation**: The system must inspect binary magic-bytes (`%PDF-` or image headers) of uploaded proof files to block disguised executable uploads.
* **NFR-SEC-005: CSRF Prevention**: The system must generate and validate token-based CSRF checks using `CsrfUtil.java` for all state-changing POST forms.

### 3.3 Compatibility and Document Layout Requirements
* **NFR-COMP-003: PDF Readability & Standardized Tabular Layout**: The generated PDF shall be readable using standard PDF viewers.
  * **Standardized Tabular Layout**: The system compiles raw database values from the PostgreSQL source (DBMS 3 — `ojt_auditdb`) into a clean, structured matrix. It avoids layout overlapping or clipping, rendering perfectly aligned columns for indices, User IDs, Usernames, Actions, Details, IP Addresses, and Timestamps.
  * **Typography and Text Wrapping**: The system uses standard, highly compatible sans-serif vector fonts (Helvetica) to prevent text-rendering or character-encoding bugs. Long administrative action strings utilize built-in text-wrapping rules to remain perfectly contained within their designated cell grids without bleeding into adjacent columns.
  * **Clean Document Metadata**: The header automatically generates standard, readable document properties at the top, cleanly rendering the report title, the generation author, and the strict 2026 processing time window (e.g., `May 19, 2026 — 02:04:33 AM`) without relying on specialized plugins or third-party rendering extensions.

## 4. Business Rules (BRs)

* **BR1: Application-Layer ID Generation**: User IDs must be generated exclusively at the application layer (Java Backend) prior to any database `INSERT` operation. The system must not rely on native database auto-incrementing or identity integers for user identification.
* **BR2: Intern ID Formatting and Calculation**: Intern accounts must be assigned a formatted alphanumeric ID adhering strictly to the structure: `INT[Current Year]-[Company Age][4-Digit Sequence]` (e.g., `INT2026-70001`). The "Company Age" component must be calculated dynamically using the formula: `(Current Year - 2020 + 1)`. The 4-digit sequence must reset at the beginning of each calendar year.
* **BR3: Admin ID Formatting**: Administrator accounts must be assigned a formatted alphanumeric ID adhering strictly to the structure: `ADM[Current Year]-[4-Digit Sequence]` (e.g., `ADM2026-0001`). The 4-digit sequence must reset at the beginning of each calendar year.
* **BR4: Database Schema Constraints**: All columns utilized for storing user identification (such as `INTERN_ID`, `ADMIN_ID`, and `USER_ID`) across all integrated databases (Apache Derby, MySQL, PostgreSQL) must be standardized to the `VARCHAR(20)` data type to accommodate the 13-character smart IDs and allow for future scalability.
* **BR5: Cross-Table Role Delineation**: The system must rely on the role prefixes (`INT` or `ADM`) embedded within the shared `USER_ID` column to differentiate user roles in shared database tables (e.g., `ACTIVITY_SUBMISSIONS`). This ensures zero data collision without the need for complex SQL `JOIN` statements.

## 5. Simple Process Flow & Pain Points

### 5.1 Current Process
* **Intern**:
  1. Intern records daily attendance and rendered hours manually through a spreadsheet or separate tracker.
  2. Intern writes the daily activity/progress update and keeps proof files in a separate folder, chat, email, or manual submission channel.
  3. Intern manually checks the total rendered hours and estimates the remaining hours or possible end date.
  4. Intern waits for the coordinator/admin to review the submitted logs and confirm milestone compliance.
* **Admin/Coordinator**:
  1. Coordinator/Admin collects internship attendance records, daily activity updates, and proof files from spreadsheets or separate submission channels.
  2. Coordinator/Admin manually checks each intern's rendered hours, remaining hours, daily progress, and milestone status.
  3. Coordinator/Admin updates master tracker settings such as required hours, daily load assumptions, holidays, and projected completion dates manually.
  4. Coordinator/Admin prepares summaries or reports by filtering spreadsheet records, checking proof, and formatting the output manually.

### 5.2 Pain Points in Current Process
* Spreadsheet records are prone to missing entries, duplicate rows, wrong formulas, and inconsistent formatting.
* Interns do not always see an updated total of rendered hours, remaining hours, or estimated completion date in real time.
* Activity logs and proof images are scattered across different files or submission channels, making verification slower.
* Coordinators spend extra time checking calculations, comparing proof, and confirming whether milestone logs are complete.
* Holiday exclusions, daily workload changes, and timeline adjustments are difficult to apply consistently in a manual tracker.
* Manual records have weak access control and limited audit trail, so it is harder to prove who changed or generated a record.
* Generating clean reports takes longer because data must be copied, filtered, formatted, and checked manually.

### 5.3 Future Process
* **Step 1**: Intern logs in to the secure web portal and opens the personal internship dashboard.
* **Step 2**: Intern submits the daily activity form with date, rendered hours, progress details, and proof image in one place.
* **Step 3**: The system automatically updates rendered hours, remaining hours, progress percentage, milestone status, and projected completion date.
* **Step 4**: Coordinator/Admin reviews records, adjusts timeline settings if needed, generates PDF reports, and the system records important actions in the audit log.

## 6. Test Scenarios (TS)

### 6.1 Test Scenario 1 (Role-Based Access / TC-ROLE-002)
* **Test Steps**: Log in to the application using valid Guest (Intern) credentials, and attempt to directly open the Admin Report Generation URL via the browser address bar.
* **Expected Result**: The system immediately denies access and redirects the user to a customized error page or access denied page.

### 6.2 Test Scenario 2 (Time-Bound Reporting & Error Handling / TC-TIME-002 & TC-TIME-004)
* **Test Steps**: Log in as an Admin and navigate to the Time-Bound Report generation feature. Enter a valid date range that contains zero records, or enter a start date that is later than the end date.
* **Expected Result**: The system does not crash. If the date range is invalid, a validation message is displayed preventing generation. If the date range is valid but empty, the system gracefully handles the empty result by displaying "No records found" or generating a clear empty report.

### 6.3 Test Scenario 3 (Comprehensive PDF Generation / TC-REP-001, TC-REP-004, TC-REP-010)
* **Test Steps**: Log in as an Admin and click "Generate All Records Report" for a dataset containing at least 50 user records. Inspect the downloaded PDF content and the server project folder.
* **Expected Result**: The PDF is successfully downloaded to the client browser and is not found permanently saved on the server. The report correctly displays multiple pages (testing pagination), is in landscape orientation, places an asterisk (*) beside the logged-in Admin's name, and strictly hides all password columns.
