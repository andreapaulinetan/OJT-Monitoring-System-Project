<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@page import="model.User"%>
<%@page import="util.TabSessionHelper"%>
<%@page import="util.CsrfUtil"%>
<%@page import="util.HtmlUtil"%>
<%
    // Prevent browser caching of protected page
    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    String tabId = TabSessionHelper.getTabId(request);
    User loggedInUser = TabSessionHelper.getUser(session, tabId);
    if (loggedInUser == null || "admin".equalsIgnoreCase(loggedInUser.getRole())) {
        response.sendRedirect("login.jsp?err=unauthorized");
        return;
    }
    
    // Check if the administrator triggered a reset for this intern's simulated hours
    boolean forceResetHours = false;
    double baselineHours = 148.5;
    if (loggedInUser != null) {
        model.User dbUser = model.UserDAO.getInternById(loggedInUser.getId(), getServletContext());
        if (dbUser != null) {
            baselineHours = dbUser.getBaselineHours();
            if (dbUser.isResetHours()) {
                forceResetHours = true;
                model.UserDAO.setResetHoursFlag(loggedInUser.getId(), false, getServletContext());
            }
        }
    }
    
    String fullName = loggedInUser.getFullName();
    String displayName = loggedInUser.getDisplayName();

    // Build initials from name (e.g. "Juan Cruz" -> "JC")
    String initials = "";
    if (loggedInUser != null) {
        String fn = loggedInUser.getFirstName();
        String ln = loggedInUser.getLastName();
        if (fn != null && !fn.isEmpty()) initials += fn.charAt(0);
        if (ln != null && !ln.isEmpty()) initials += ln.charAt(0);
        initials = initials.toUpperCase();
    }
    if (initials.isEmpty()) initials = "GI";

    String statusParam = request.getParameter("status");
    String alertMessage = "";
    String alertClass = "";

    // Safely parse the approved database hours passed from the controller servlet
    String dbHoursParam = request.getParameter("approvedHours");
    double parsedDbHours = 0.0;
    if (dbHoursParam != null && !dbHoursParam.isEmpty()) {
        try {
            parsedDbHours = Double.parseDouble(dbHoursParam);
        } catch (Exception e) {
        }
    }

    if ("success".equals(statusParam)) {
        alertMessage = "Success! Your tracking log details have been saved to MySQL.";
        if (parsedDbHours > 0) {
            alertMessage += " (" + parsedDbHours + " hours successfully synchronized into active record matrix.)";
        }
        alertClass = "alert alert-success mt-3 mb-3";
    } else if ("db_error".equals(statusParam)) {
        alertMessage = "Database Error: Could not save attendance record.";
        alertClass = "alert alert-danger mt-3 mb-3";
    } else if ("invalid_file".equals(statusParam)) {
        alertMessage = "Error: Invalid file type uploaded. Please upload a valid PNG, JPG, or JPEG image as proof of work.";
        alertClass = "alert alert-danger mt-3 mb-3";
    } else if ("no_clock_in".equals(statusParam)) {
        alertMessage = "Error: No matching clock-in event timestamp tracked in session state.";
        alertClass = "alert alert-warning mt-3 mb-3";
    } else if ("invalid_input".equals(statusParam)) {
        alertMessage = "Error: Invalid input provided. Please verify hours (0.0001 - 24) and description (5 - 500 characters, no HTML).";
        alertClass = "alert alert-danger mt-3 mb-3";
    }
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <script src="${pageContext.request.contextPath}/js/tabSession.js"></script>
        <title>Guest Intern's Dashboard | Active Learning</title>

        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
        <link rel="stylesheet" type="text/css" href="${pageContext.request.contextPath}/css/guest.css?v=<%= System.currentTimeMillis() %>">
    </head>

    <body>
        <div id="successToast" class="custom-toast">
            <div class="toast-icon-wrap">
                <i class="fa-solid fa-circle-check"></i>
            </div>
            <div class="toast-body">
                <h5>Success!</h5>
                <p id="toastMessageText">Simulated hours logged successfully.</p>
            </div>
        </div>

        <div class="app-container">

            <aside class="sidebar">
                <div class="brand-container">
                    <span class="brand-name">Active Learning</span>
                </div>

                <nav class="nav-menu">
                    <button type="button" class="nav-item active" id="nav-dashboard" onclick="switchTab('dashboard-view', 'nav-dashboard')">
                        <i class="fa-solid fa-chart-pie"></i> Dashboard
                    </button>
                    <button type="button" class="nav-item" id="nav-announcements" onclick="switchTab('announcements-view', 'nav-announcements')">
                        <i class="fa-solid fa-bullhorn"></i> Announcements <span id="announcementsBadge" class="badge bg-danger ms-1 d-none">0</span>
                    </button>
                    <button type="button" class="nav-item" id="nav-messages" onclick="switchTab('messages-view', 'nav-messages')">
                        <i class="fa-solid fa-comments"></i> Messages <span id="messagesBadge" class="badge bg-danger ms-1 d-none">0</span>
                    </button>
                    <button type="button" class="nav-item" id="nav-coordinator" onclick="switchTab('coordinator-view', 'nav-coordinator')">
                        <i class="fa-solid fa-sliders"></i> Configuration
                    </button>
                </nav>

                <div class="sidebar-footer" style="padding-top: 10px;">
                    <a href="LogoutServlet" class="logout-btn">
                        <i class="fa-solid fa-arrow-right-from-bracket"></i> Log Out
                    </a>
                </div>
            </aside>
            <div class="sidebar-overlay" onclick="toggleSidebar()"></div>

            <main class="main-content">

                <header class="top-bar">
                    <div class="d-flex align-items-center gap-3">
                        <button type="button" id="sidebarToggle" class="btn btn-outline-secondary" onclick="toggleSidebar()">
                            <i class="fa-solid fa-bars"></i>
                        </button>
                        <h2 class="page-title" id="mainPageTitle">Intern's Dashboard</h2>
                    </div>
                    <div class="user-profile">
                        <div class="profile-chip" onclick="switchTab('coordinator-view', 'nav-coordinator')" style="cursor: pointer;">
                            <span><%= displayName %></span>
                            <img src="https://ui-avatars.com/api/?name=<%= java.net.URLEncoder.encode(fullName, "UTF-8") %>&background=d63384&color=fff" alt="Intern" style="object-fit: cover;">
                        </div>
                    </div>
                </header>

                <% if (!alertMessage.isEmpty()) {%>
                <div class="<%= alertClass%>" role="alert">
                    <i class="fa-solid fa-circle-info me-2"></i> <%= alertMessage%>
                </div>
                <% }%>

                <input type="hidden" id="dbInjectedHoursField" value="<%= parsedDbHours%>">
                <input type="hidden" id="dbSubmissionStatusField" value="<%= statusParam != null ? statusParam : ""%>">

                <div id="dashboard-view" class="view-panel active-view">

                    <div id="latestAnnouncementBanner" class="latest-announcement-banner d-none mb-3" onclick="switchTab('announcements-view', 'nav-announcements')">
                        <div class="banner-icon"><i class="fa-solid fa-bullhorn text-pink"></i></div>
                        <div class="banner-content">
                            <span class="banner-badge">LATEST ANNOUNCEMENT</span>
                            <h5 id="latestAnnTitle" class="mb-1 fw-bold">Title</h5>
                            <p id="latestAnnExcerpt" class="mb-0 text-muted small">Excerpt...</p>
                        </div>
                        <div class="banner-arrow"><i class="fa-solid fa-chevron-right"></i></div>
                    </div>

                    <div class="projection-alert-box">
                        <div class="projection-icon-wrap">
                            <i class="fa-solid fa-calendar-check"></i>
                        </div>
                        <div>
                            <p>ESTIMATED COMPLETION DATE</p>
                            <h4 id="projectedEndDateDisplay">Calculating engine matrix...</h4>
                        </div>
                    </div>

                    <section class="stats-row">
                        <div class="stat-card card-yellow position-relative overflow-hidden">
                            <span class="label">Total Rendered Hours</span>
                            <div class="value" id="renderedHoursDisplay">148.5h</div>

                            <% if ("success".equals(statusParam) && parsedDbHours > 0) {%>
                            <span class="position-absolute bottom-0 end-0 bg-success text-white px-2 py-1 small rounded-start fw-bold" style="font-size: 10px; opacity: 0.95; z-index: 5;">
                                <i class="fa-solid fa-cloud-arrow-up me-1"></i> Sync Live: +<%= parsedDbHours%>h
                            </span>
                            <% }%>
                        </div>
                        <div class="stat-card card-pink">
                            <span class="label">Remaining Hours</span>
                            <div class="value" id="remainingHoursDisplay">251.5h</div>
                        </div>
                        <div class="stat-card card-green">
                            <span class="label">Target Goal</span>
                            <div class="value" id="targetGoalDisplay">400h</div>
                        </div>
                        <div class="stat-card card-blue">
                            <span class="label">Completion Rate</span>
                            <div class="value" id="completionRateDisplay">37.1%</div>
                        </div>
                    </section>

                    <div class="progress-container-box">
                        <div class="progress-bar-header">
                            <span>Overall Track Progress</span>
                            <strong id="progressBarText">37.1%</strong>
                        </div>
                        <div class="progress-bar-track">
                            <div class="progress-bar-fill" id="progressBarFill" style="width: 37.1%;"></div>
                        </div>
                    </div>

                    <div class="dashboard-triple-grid">
                        <div class="dashboard-column" style="display: flex; flex-direction: column; gap: 20px; height: 100%;">
                            <div class="dashboard-pane" id="attendanceSimulatorCard" style="min-height: auto; flex: 1; display: flex; flex-direction: column;">
                                <h3 class="pane-title">Daily Attendance Simulator</h3>
                                <div class="attendance-box text-center py-3" style="flex: 1; display: flex; flex-direction: column; justify-content: center; gap: 10px;">
                                    <div class="mb-3">
                                        <div class="attendance-status-badge">
                                            <span class="status-dot red" id="statusIndicatorDot"></span>
                                            <span id="statusIndicatorText">Not Clocked In</span>
                                        </div>
                                    </div>
                                    <div id="liveTimerDisplay" class="live-timer-display my-3 font-monospace h1 fw-bold" style="font-size: 42px; letter-spacing: -1px;">00:00:00</div>
                                    <button id="btnAttendanceToggle" class="btn btn-success w-100 py-2 fw-bold" onclick="toggleTimerAttendanceSession()">
                                        <i class="fa-solid fa-play me-2"></i> Time In
                                    </button>
                                    <div class="text-muted mt-2 text-center" style="font-size: 11px;">
                                        *Optional: Use this timer if you want to track runtime parameters natively.
                                    </div>
                                </div>
                            </div>

                            <div class="download-record-card-small">
                                <div class="download-record-info-small">
                                    <div class="download-record-icon-small">
                                        <i class="fa-solid fa-file-arrow-down"></i>
                                    </div>
                                    <div style="min-width: 0;">
                                        <h4 class="download-record-title-small">Download My Record</h4>
                                        <p class="download-record-desc-small">PDF report, hours & logs.</p>
                                    </div>
                                </div>
                                <a href="${pageContext.request.contextPath}/ReportServlet?type=INTERN_RECORD&tabId=<%= tabId %>" class="download-record-btn-small" title="Download Report">
                                    <i class="fa-solid fa-download"></i>
                                </a>
                            </div>
                        </div>

                        <div class="dashboard-pane" id="manualTaskLogPane">
                            <h3 class="pane-title">Simulate Task Entry Log</h3>
                             <form id="sandboxLogForm" action="SubmitTaskServlet?tabId=<%= tabId %>&csrfToken=<%= CsrfUtil.getToken(session) %>" method="POST" enctype="multipart/form-data" onsubmit="return handleManualLogSubmission(event)">
                                <input type="hidden" name="csrfToken" value="<%= CsrfUtil.getToken(session) %>"/>
                                <div class="form-group mb-3">
                                    <label class="form-label fw-bold small">Hours Spent on Task</label>
                                    <input type="text" id="sandboxLogHours" name="simulatedHours" class="form-control" placeholder="e.g. 7.5" value="<%= request.getParameter("simulatedHours") != null ? HtmlUtil.escape(request.getParameter("simulatedHours")) : "" %>" required>
                                    <div class="invalid-feedback">Please specify a valid count of entry hours between 0.0001 and 24.</div>
                                </div>

                                <div class="form-group mb-3">
                                    <label class="form-label fw-bold small">Task / Activity Completed</label>
                                    <textarea id="sandboxLogDescription" name="taskDescription" class="form-control" rows="2" placeholder="e.g. Created backend API for login validation." required></textarea>
                                    <div class="invalid-feedback">Description must be between 5 and 500 characters and cannot contain HTML tags.</div>
                                </div>

                                <div class="form-group mb-3">
                                    <label class="form-label fw-bold small">What I Learned Today</label>
                                    <textarea id="sandboxLogLearningReflection" name="learningReflection" class="form-control" rows="2" placeholder="e.g. I learned how servlet controllers validate user credentials and redirect users based on role." required></textarea>
                                    <div class="invalid-feedback">Learning reflection must be between 5 and 500 characters and cannot contain HTML tags.</div>
                                </div>

                                <div class="form-group attachment-container mb-3">
                                    <label class="form-label fw-bold small">Proof of Attendance <span class="text-danger">*</span></label>
                                    <div class="photo-dropzone text-center p-3 border border-dashed rounded" id="photoDropzone" style="cursor: pointer;" onclick="document.getElementById('attendance-photo').click();">
                                        <i class="fa-solid fa-camera fa-2x mb-2 text-muted"></i>
                                        <p class="m-0 small">Click to <strong>add attachment (photo)</strong></p>
                                        <span class="file-hint text-muted" style="font-size: 11px;">Supports PNG, JPG, or JPEG</span>
                                        <input type="file" id="attendance-photo" name="attendancePhoto" accept="image/png, image/jpeg" onchange="handleFileChange(this)" hidden required>
                                    </div>
                                    <div id="photo-preview-name" class="photo-preview-text mt-2 text-success small fw-bold"></div>
                                    <div id="photo-error-message" class="text-danger small mt-1 fw-bold" style="display: none;">Please upload a proof of attendance image (PNG, JPG, or JPEG, max 10MB).</div>
                                </div>

                                <button type="submit" class="btn btn-primary w-100 py-2 fw-bold" style="background-color: #4f46e5; border: none;">
                                    <i class="fa-solid fa-paper-plane me-2"></i> Inject Simulation Hours
                                </button>
                            </form>
                        </div>

                        <div class="dashboard-pane layout-calendar-pane">
                            <div class="calendar-nav-header d-flex justify-content-between align-items-center mb-3">
                                <h3 class="calendar-month-title m-0 h6 fw-bold" id="calendarMonthTitle">May 2026</h3>
                                <div class="calendar-action-arrows">
                                    <button type="button" class="btn btn-sm btn-outline-secondary py-0 px-2" onclick="adjustCalendarMonth(-1)"><i class="fa-solid fa-chevron-left"></i></button>
                                    <button type="button" class="btn btn-sm btn-outline-secondary py-0 px-2" onclick="adjustCalendarMonth(1)"><i class="fa-solid fa-chevron-right"></i></button>
                                </div>
                            </div>

                            <div class="calendar-grid-days-header d-grid text-center fw-bold text-muted mb-2" style="grid-template-columns: repeat(7, 1fr); font-size: 11px;">
                                <div>S</div><div>M</div><div>T</div><div>W</div><div>T</div><div>F</div><div>S</div>
                            </div>

                            <div class="calendar-days-surface text-center" id="calendarDaysSurface"></div>

                            <div class="calendar-legends-footer d-flex gap-2 flex-wrap text-muted justify-content-between mt-3" style="font-size: 11px;">
                                <div class="legend-item"><span class="badge bg-danger p-1 me-1">&nbsp;</span>Holiday</div>
                                <div class="legend-item"><span class="badge bg-secondary p-1 me-1">&nbsp;</span>Off</div>
                                <div class="legend-item"><span class="badge p-1 me-1" style="background-color: rgba(59, 130, 246, 0.15); color:#2563eb;">&nbsp;</span>Scheduled</div>
                                <div class="legend-item"><span class="badge bg-success p-1 me-1">&nbsp;</span>Target End</div>
                            </div>
                        </div>
                    </div>

                </div>

                <div id="announcements-view" class="view-panel">
                    <div class="section-header mb-4">
                        <p class="welcome-text m-0" style="margin-left: 0 !important;">View targeted announcements and news published by your coordinators.</p>
                    </div>
                    <div id="announcementsFeedContainer" class="d-flex flex-column gap-3">
                        <div class="text-center py-5 text-muted">
                            <i class="fa-solid fa-bullhorn fa-3x mb-3 text-muted" style="opacity: 0.5;"></i>
                            <p class="mb-0">No announcements published yet.</p>
                        </div>
                    </div>
                </div>

                <div id="messages-view" class="view-panel">
                    <div class="chat-layout">
                        <!-- Contacts Sidebar -->
                        <div class="chat-contacts-list">
                            <div class="chat-contacts-header">
                                <i class="fa-solid fa-address-book"></i> Coordinators
                            </div>
                            <div class="chat-search-container" style="padding: 12px; border-bottom: 1px solid #e2e8f0; background-color: #f8fafc;">
                                <div class="position-relative">
                                    <i class="fa-solid fa-search position-absolute top-50 start-0 translate-middle-y ms-3 text-muted"></i>
                                    <input type="text" id="chatSearchInput" class="form-control form-control-sm" placeholder="Search contacts..." onkeyup="filterContacts()" style="padding-left: 32px; border-radius: 20px; border: 1px solid #cbd5e1; font-size: 0.85rem; box-shadow: none;">
                                </div>
                            </div>
                            <div class="chat-contacts-container" id="chatContactsContainer">
                                <!-- Populated dynamically -->
                            </div>
                        </div>

                        <!-- Conversation Area -->
                        <div class="chat-conversation-area">
                            <div id="chatEmptyState" class="chat-empty-state">
                                <i class="fa-solid fa-comments fa-4x text-muted" style="opacity: 0.5;"></i>
                                <h5>Your Messages</h5>
                                <p class="text-muted small">Select a coordinator from the sidebar to begin direct messaging.</p>
                            </div>
                            <div id="chatActiveArea" class="flex-column h-100" style="display: none;">
                                <div class="chat-header">
                                    <div class="chat-header-info">
                                        <img id="activeContactAvatar" src="https://ui-avatars.com/api/?name=Admin&background=d63384&color=fff" class="contact-avatar" alt="Avatar">
                                        <div>
                                            <div class="contact-name" id="activeContactName">Admin Name</div>
                                            <div class="contact-sub" id="activeContactRole">Coordinator</div>
                                        </div>
                                    </div>
                                </div>
                                <div class="chat-messages-container" id="chatMessagesContainer">
                                    <!-- Messages dynamic -->
                                </div>
                                <div class="chat-templates">
                                    <button type="button" class="template-btn" onclick="useTemplate('Hello! I would like to ask about my logs status.')">Logs Inquiry</button>
                                    <button type="button" class="template-btn" onclick="useTemplate('Good day. I experienced an issue with the time tracker.')">Tracker Issue</button>
                                    <button type="button" class="template-btn" onclick="useTemplate('I have uploaded my missing proof of attendance, please review.')">Proof Re-upload</button>
                                    <button type="button" class="template-btn" onclick="useTemplate('Thank you so much!')">Thank You</button>
                                </div>
                                <form id="chatMessageForm" class="chat-input-bar" onsubmit="submitChatMessage(event)">
                                    <input type="text" id="chatInputMessage" placeholder="Type your message here..." required autocomplete="off">
                                    <button type="submit" class="btn btn-primary btn-pink text-white">
                                        <i class="fa-solid fa-paper-plane"></i>
                                    </button>
                                </form>
                            </div>
                        </div>
                    </div>
                </div>

                <div id="coordinator-view" class="view-panel">
                    <div class="section-header d-flex justify-content-between align-items-center mb-4">
                        <p class="welcome-text m-0" style="margin-left: 0 !important;">Customize your target goals and weekly work shifts to update your live progress matrix.</p>
                        <button type="button" class="reset-defaults-btn" onclick="resetConfigurationForm()">
                            <i class="fa-solid fa-rotate-left me-1"></i> Reset Defaults
                        </button>
                    </div>

                    <form id="goalsSetupForm" onsubmit="saveConfigState(event)">
                        <div class="configuration-grid-wrapper">

                            <div class="config-card card-ui-yellow">
                                <h3 class="card-title-custom">Internship Goals</h3>
                                <div class="horizontal-inputs mb-3">
                                    <div>
                                        <label class="custom-label" for="inputTargetHours">Target Hours</label>
                                        <div class="input-group">
                                            <input type="number" id="inputTargetHours" class="form-control" value="400" min="1" required oninput="recalculateProgressEngine()">
                                            <span class="input-group-text"><i class="fa-solid fa-clock text-muted"></i></span>
                                        </div>
                                    </div>
                                    <div>
                                        <label class="custom-label" for="inputStartDate">Start Date</label>
                                        <input type="date" id="inputStartDate" class="form-control" value="2026-05-06" required onchange="recalculateProgressEngine()">
                                    </div>
                                </div>

                            </div>

                            <div class="config-card card-ui-green">
                                <h3 class="card-title-custom">Load & Holiday</h3>
                                <div class="w-100 mb-3">
                                    <div class="d-flex justify-content-between align-items-center mb-1">
                                        <label class="custom-label m-0" for="hoursSlider">Hours Per Day</label>
                                        <span class="badge bg-white text-dark border" id="sliderValDisplay" style="border-radius:6px; font-weight:700;">7h</span>
                                    </div>
                                    <input type="range" min="1" max="12" value="7" class="form-range custom-slider" id="hoursSlider" oninput="updateSliderLabel(this.value)">
                                </div>
                                <div class="w-100">
                                    <label class="custom-label d-block mb-2">Exclude PH Holidays (2026)?</label>
                                    <div class="modern-toggle-group" role="group">
                                        <input type="hidden" id="excludeHolidaysHidden" value="true">
                                        <button type="button" id="holidayBtnYes" class="btn active" onclick="setHolidayExclusion(true)">
                                            <i class="fa-solid fa-calendar-xmark me-1"></i> Yes
                                        </button>
                                        <button type="button" id="holidayBtnNo" class="btn" onclick="setHolidayExclusion(false)">
                                            <i class="fa-solid fa-calendar-check"></i> No
                                        </button>
                                    </div>
                                </div>
                            </div>

                            <div class="config-card card-ui-pink">
                                <div>
                                    <h3 class="card-title-custom mb-1">Work Schedule</h3>
                                    <label class="custom-label d-block mb-3">Weekly Work Days</label>
                                    <div class="circle-day-picker">
                                        <div class="day-circle-btn" data-day="0" onclick="toggleDayCircle(this)">S</div>
                                        <div class="day-circle-btn active" data-day="1" onclick="toggleDayCircle(this)">M</div>
                                        <div class="day-circle-btn active" data-day="2" onclick="toggleDayCircle(this)">T</div>
                                        <div class="day-circle-btn active" data-day="3" onclick="toggleDayCircle(this)">W</div>
                                        <div class="day-circle-btn active" data-day="4" onclick="toggleDayCircle(this)">T</div>
                                        <div class="day-circle-btn active" data-day="5" onclick="toggleDayCircle(this)">F</div>
                                        <div class="day-circle-btn" data-day="6" onclick="toggleDayCircle(this)">S</div>
                                    </div>
                                </div>
                                <div class="text-muted mt-3" style="font-size:12px; font-weight: 500;">
                                    <i class="fa-solid fa-star text-warning me-1"></i> Selected active days count as projectable work terms
                                </div>
                            </div>

                            <div class="config-card card-ui-blue">
                                <h3 class="card-title-custom">Projection Mode</h3>
                                <div class="w-100">
                                    <div class="modern-toggle-group" role="group">
                                        <input type="hidden" id="projectionModeHidden" value="Auto">
                                        <button type="button" id="projBtnManual" class="btn" onclick="setProjectionMode('Manual')">
                                            <i class="fa-solid fa-hand me-1"></i> Manual
                                        </button>
                                        <button type="button" id="projBtnAuto" class="btn active" onclick="setProjectionMode('Auto')">
                                            <i class="fa-solid fa-layer-group me-1"></i> Auto
                                        </button>
                                    </div>
                                </div>
                            </div>

                        </div>

                        <div class="d-flex justify-content-between align-items-center mt-4">
                            <span class="text-muted small">Simulating analytics metrics live inside your <strong>browser session</strong></span>
                            <button type="submit" class="apply-shifts-btn">
                                <i class="fa-solid fa-floppy-disk me-2"></i> Apply Schedule Shifts
                            </button>
                        </div>
                    </form>
                </div>

            </main>
        </div>
        <script>
            // --- Global State Variables ---
            const currentUserId = "INT_<%= loggedInUser != null ? loggedInUser.getId() : "" %>";
            const renderedHoursKey = 'renderedHours_' + currentUserId;
            
            <%
                double dbCustomHours = 0.0;
                java.util.List<model.ActivitySubmission> userSubs = null;
                if (loggedInUser != null) {
                    userSubs = model.UserDAO.getSubmissionsByUserId(loggedInUser.getId(), getServletContext());
                    if (userSubs != null) {
                        for (model.ActivitySubmission sub : userSubs) {
                            if (!"Rejected".equalsIgnoreCase(sub.getStatus())) {
                                dbCustomHours += util.PdfReportHelper.extractHoursFromDescription(sub.getDescription());
                            }
                        }
                    }
                }
            %>
            let baselineHours = <%= baselineHours %>;
            let dbSubmissions = [
                <%
                if (userSubs != null) {
                    for (int i = 0; i < userSubs.size(); i++) {
                        model.ActivitySubmission sub = userSubs.get(i);
                        String cleanId = sub.getSubmissionId() != null ? sub.getSubmissionId().replace("\"", "\\\"").replace("\n", " ").replace("\r", " ") : "";
                        String cleanStatus = sub.getStatus() != null ? sub.getStatus().replace("\"", "\\\"").replace("\n", " ").replace("\r", " ") : "";
                        String cleanDesc = sub.getDescription() != null ? sub.getDescription().replace("\"", "\\\"").replace("\n", " ").replace("\r", " ") : "";
                        %>
                        {
                            id: "<%= cleanId %>",
                            status: "<%= cleanStatus %>",
                            desc: "<%= cleanDesc %>"
                        }<%= (i < userSubs.size() - 1) ? "," : "" %>
                        <%
                    }
                }
                %>
            ];
            let dbCustomHours = <%= dbCustomHours %>;
            let renderedHoursBase = baselineHours + dbCustomHours;
            localStorage.setItem(renderedHoursKey, renderedHoursBase.toString());
            let calendarYear = 2026;
            let calendarMonth = 4; // May (0-indexed)

            let stopwatchInterval = null;
            let activeTimerRunning = false;
            let accumulatedSeconds = 0;
            let projectedEndDateISO = "";

            // Philippine Holidays 2026 Presets
            const phHolidays2026 = [
                "2026-01-01", "2026-02-17", "2026-04-02", "2026-04-03",
                "2026-04-09", "2026-05-01", "2026-06-12", "2026-08-31",
                "2026-11-01", "2026-11-30", "2026-12-25", "2026-12-30"
            ];
            const monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

            // --- Lifecycle Events ---
            window.onload = function () {
                loadConfigState();
                restoreTimerSessionOnLoad();
                recalculateProgressEngine();
                checkSubmissionNotifications();
                loadAnnouncementsSilent();
                pollUnreadMessagesCount();

                // Auto-route to specific view if specified in URL query params
                const urlParams = new URLSearchParams(window.location.search);
                const viewParam = urlParams.get('view');
                if (viewParam) {
                    if (viewParam === 'coordinator') {
                        switchTab('coordinator-view', 'nav-coordinator');
                    } else if (viewParam === 'messages') {
                        switchTab('messages-view', 'nav-messages');
                    } else if (viewParam === 'announcements') {
                        switchTab('announcements-view', 'nav-announcements');
                    } else if (viewParam === 'dashboard') {
                        switchTab('dashboard-view', 'nav-dashboard');
                    }
                }

                // Set up input listeners to clear invalid states dynamically
                const hoursField = document.getElementById('sandboxLogHours');
                if (hoursField) {
                    hoursField.addEventListener('input', function() {
                        this.classList.remove('is-invalid');
                    });
                }
                const descField = document.getElementById('sandboxLogDescription');
                if (descField) {
                    descField.addEventListener('input', function() {
                        this.classList.remove('is-invalid');
                    });
                }
                const fileInput = document.getElementById('attendance-photo');
                if (fileInput) {
                    fileInput.addEventListener('change', function() {
                        const dropzone = document.getElementById('photoDropzone');
                        const photoErrorMsg = document.getElementById('photo-error-message');
                        if (dropzone) {
                            dropzone.style.border = '';
                            dropzone.style.backgroundColor = '';
                        }
                        if (photoErrorMsg) {
                            photoErrorMsg.style.display = 'none';
                        }
                    });
                }
            };

            function checkSubmissionNotifications() {
                if (!currentUserId) return;
                const storedStatusesKey = 'submission_statuses_' + currentUserId;
                let savedStatuses = {};
                try {
                    const localData = localStorage.getItem(storedStatusesKey);
                    if (localData) {
                        savedStatuses = JSON.parse(localData);
                    }
                } catch (e) {
                    console.error("Failed to parse saved statuses:", e);
                }

                let newStatuses = {};
                dbSubmissions.forEach(sub => {
                    const savedStatus = savedStatuses[sub.id];
                    if (savedStatus && savedStatus !== sub.status) {
                        if (sub.status === "Approved") {
                            showCustomToast("Your log \"" + sub.desc + "\" has been Approved!", "success");
                        } else if (sub.status === "Rejected") {
                            showCustomToast("Your log \"" + sub.desc + "\" has been Rejected!", "error");
                        }
                    }
                    newStatuses[sub.id] = sub.status;
                });
                
                try {
                    localStorage.setItem(storedStatusesKey, JSON.stringify(newStatuses));
                } catch (e) {
                    console.error("Failed to save submission statuses:", e);
                }
            }

            // --- Custom Coherent Toast Notification System ---
            function showCustomToast(message, type = "success") {
                // 1. Create or grab the floating stack layer attached directly to the body root
                let container = document.getElementById('custom-toast-container');
                if (!container) {
                    container = document.createElement('div');
                    container.id = 'custom-toast-container';
                    Object.assign(container.style, {
                        position: 'fixed',
                        top: '24px',
                        right: '24px',
                        zIndex: '9999999', // Makes sure it floats on top of all panels
                        display: 'flex',
                        flexDirection: 'column',
                        gap: '12px',
                        pointerEvents: 'none'
                    });
                    document.body.appendChild(container);
                }

                // 2. Cohesive dashboard matching colors
                const bgColor = type === "success" ? "#e6f4ea" : "#fce8e6";
                const textColor = type === "success" ? "#137333" : "#c5221f";
                const borderColor = type === "success" ? "#10b981" : "#ef4444";

                // 3. Create the notification pill wrapper
                const toast = document.createElement('div');
                toast.className = "custom-toast-alert dynamic-fade-in";

                Object.assign(toast.style, {
                    backgroundColor: bgColor,
                    borderLeft: '6px solid ' + borderColor,
                    padding: '16px 20px',
                    borderRadius: '12px',
                    boxShadow: '0 10px 30px rgba(0, 0, 0, 0.12)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'flex-start',
                    gap: '14px',
                    width: '380px',
                    minWidth: '380px',
                    boxSizing: 'border-box',
                    pointerEvents: 'auto'
                });

                // 4. Create the icon using a bold tag (which works)
                const checkIcon = document.createElement('b');
                checkIcon.textContent = type === "success" ? "✓" : "✗";
                Object.assign(checkIcon.style, {
                    color: textColor,
                    fontSize: '20px',
                    fontWeight: '900',
                    lineHeight: '1',
                    display: 'inline-block',
                    flexShrink: '0'
                });
                toast.appendChild(checkIcon);

                // 5. THE CRITICAL TEXT FIX: Using a generic div with forced overrides
                const textMessage = document.createElement('div');
                textMessage.textContent = message;

                // Applying CSS text styles directly as a string to allow !important overrides
                textMessage.style.setProperty('color', '#1e293b', 'important'); // Dark slate text color
                textMessage.style.setProperty('font-size', '14px', 'important'); // Visible font size
                textMessage.style.setProperty('font-weight', '600', 'important'); // Semi-bold layout weight
                textMessage.style.setProperty('display', 'block', 'important');
                textMessage.style.setProperty('visibility', 'visible', 'important');
                textMessage.style.setProperty('opacity', '1', 'important');

                // Standard layout formatting
                Object.assign(textMessage.style, {
                    fontFamily: 'system-ui, -apple-system, sans-serif',
                    lineHeight: '1.4',
                    margin: '0',
                    padding: '0',
                    textAlign: 'left',
                    wordBreak: 'break-word',
                    flexGrow: '1'
                });

                toast.appendChild(textMessage);
                container.appendChild(toast);

                // 6. Smooth automatic dismissal transition sequence
                setTimeout(() => {
                    toast.style.opacity = '0';
                    toast.style.transform = 'translateY(-15px)';
                    toast.style.transition = 'all 0.3s ease';
                    setTimeout(() => toast.remove(), 300);
                }, 4500);
            }

            // --- View & Tab Handling ---
            function switchTab(tabId, navId) {
                document.querySelectorAll('.view-panel').forEach(view => view.classList.remove('active-view'));
                document.querySelectorAll('.nav-menu .nav-item').forEach(btn => btn.classList.remove('active'));

                document.getElementById(tabId).classList.add('active-view');
                document.getElementById(navId).classList.add('active');

                // Auto-close sidebar on mobile after choosing a tab
                document.body.classList.remove("show-sidebar");

                // Dynamic persistent top bar title sync
                const mainPageTitle = document.getElementById('mainPageTitle');
                if (mainPageTitle) {
                    if (tabId === 'dashboard-view') {
                        mainPageTitle.textContent = "Intern's Dashboard";
                    } else if (tabId === 'announcements-view') {
                        mainPageTitle.textContent = "Announcements Feed";
                        loadAnnouncements();
                    } else if (tabId === 'messages-view') {
                        mainPageTitle.textContent = "Direct Messaging";
                        loadContacts();
                        startMessagingPolling();
                    } else if (tabId === 'coordinator-view') {
                        mainPageTitle.textContent = "Internship Setup Configuration";
                    }
                }

                if (tabId !== 'messages-view') {
                    stopMessagingPolling();
                }
            }

            // --- UI Form Event Handlers ---
            function updateSliderLabel(val) {
                document.getElementById('sliderValDisplay').textContent = val + 'h';
                recalculateProgressEngine();
            }

            function setHolidayExclusion(flag) {
                document.getElementById('excludeHolidaysHidden').value = flag;
                document.getElementById('holidayBtnYes').classList.toggle('active', flag);
                document.getElementById('holidayBtnNo').classList.toggle('active', !flag);
                recalculateProgressEngine();
            }

            function toggleDayCircle(element) {
                element.classList.toggle('active');
                recalculateProgressEngine();
            }

            function setProjectionMode(mode) {
                document.getElementById('projectionModeHidden').value = mode;
                document.getElementById('projBtnAuto').classList.toggle('active', mode === 'Auto');
                document.getElementById('projBtnManual').classList.toggle('active', mode === 'Manual');
                recalculateProgressEngine();
            }

            function adjustCalendarMonth(direction) {
                calendarMonth += direction;
                if (calendarMonth > 11) {
                    calendarMonth = 0;
                    calendarYear++;
                } else if (calendarMonth < 0) {
                    calendarMonth = 11;
                    calendarYear--;
                }
                renderCalendarComponent();
            }

            function handleFileChange(input) {
                const display = document.getElementById('photo-preview-name');
                if (input.files && input.files[0]) {
                    display.textContent = "Selected: " + input.files[0].name;
                } else {
                    display.textContent = "";
                }
            }

            // --- Realtime Attendance Tracker (Stopwatch) Engine ---
            function toggleTimerAttendanceSession() {
                const dot = document.getElementById('statusIndicatorDot');
                const label = document.getElementById('statusIndicatorText');
                const btn = document.getElementById('btnAttendanceToggle');
                const manualPane = document.getElementById('manualTaskLogPane');
                const timerCard = document.getElementById('attendanceSimulatorCard');

                if (!activeTimerRunning) {
                    activeTimerRunning = true;
                    localStorage.setItem('sw_active', 'true');
                    
                    if (isNaN(accumulatedSeconds) || accumulatedSeconds < 0) {
                        accumulatedSeconds = 0;
                    }
                    localStorage.setItem('sw_startTimeStamp', String(Date.now() - (accumulatedSeconds * 1000)));

                    dot.className = "status-dot green";
                    dot.style.backgroundColor = "#10b981";
                    label.textContent = "Clocked In & Tracking Time";
                    btn.className = "btn btn-danger w-100 py-2 fw-bold";
                    btn.innerHTML = '<i class="fa-solid fa-stop me-2"></i> Time Out';

                    timerCard.style.boxShadow = "0 0 15px rgba(16, 185, 129, 0.2)";
                    manualPane.style.opacity = "0.5";
                    manualPane.style.pointerEvents = "none";

                    incrementStopwatchRuntime();
                    stopwatchInterval = setInterval(incrementStopwatchRuntime, 1000);
                } else {
                    activeTimerRunning = false;
                    clearInterval(stopwatchInterval);

                    if (isNaN(accumulatedSeconds) || accumulatedSeconds < 0) {
                        accumulatedSeconds = 0;
                    }
                    const computedHoursEarned = accumulatedSeconds / 3600;
                    renderedHoursBase += computedHoursEarned;
                    
                    if (isNaN(renderedHoursBase) || renderedHoursBase < 0) {
                        renderedHoursBase = baselineHours;
                    }
                    localStorage.setItem(renderedHoursKey, String(renderedHoursBase));

                    // Background AJAX POST to save stopwatch session in MySQL
                    if (computedHoursEarned > 0) {
                        const formData = new URLSearchParams();
                        formData.append("simulatedHours", computedHoursEarned.toFixed(4));
                        formData.append("taskDescription", "Daily attendance simulator: Clocked out session");
                        formData.append("tabId", window.name);
                        formData.append("csrfToken", "<%= CsrfUtil.getToken(session) %>");

                        fetch("SubmitTaskServlet", {
                            method: "POST",
                            headers: {
                                "Content-Type": "application/x-www-form-urlencoded"
                            },
                            body: formData.toString()
                        })
                        .then(response => {
                            if (response.ok) {
                                console.log("Stopwatch attendance record synchronised successfully in database queue.");
                            } else {
                                console.error("Stopwatch attendance record database sync failed.");
                            }
                        })
                        .catch(err => console.error("Stopwatch attendance network pipeline error: ", err));
                    }

                    accumulatedSeconds = 0;
                    localStorage.removeItem('sw_active');
                    localStorage.removeItem('sw_startTimeStamp');

                    dot.className = "status-dot red";
                    dot.style.backgroundColor = "#ef4444";
                    label.textContent = "Not Clocked In";
                    btn.className = "btn btn-success w-100 py-2 fw-bold";
                    btn.innerHTML = '<i class="fa-solid fa-play me-2"></i> Time In';
                    document.getElementById('liveTimerDisplay').textContent = "00:00:00";

                    timerCard.style.boxShadow = "none";
                    manualPane.style.opacity = "1";
                    manualPane.style.pointerEvents = "auto";

                    showCustomToast("Attendance session stored! Added +" + computedHoursEarned.toFixed(2) + " hours.", "success");
                    recalculateProgressEngine();
                }
            }

            function incrementStopwatchRuntime() {
                const rawStamp = localStorage.getItem('sw_startTimeStamp');
                const cachedStamp = rawStamp ? parseInt(rawStamp, 10) : null;
                
                if (cachedStamp && !isNaN(cachedStamp)) {
                    accumulatedSeconds = Math.floor((Date.now() - cachedStamp) / 1000);
                } else {
                    accumulatedSeconds++;
                }

                if (isNaN(accumulatedSeconds) || accumulatedSeconds < 0) {
                    accumulatedSeconds = 0;
                }

                const hrs = String(Math.floor(accumulatedSeconds / 3600)).padStart(2, '0');
                const mins = String(Math.floor((accumulatedSeconds % 3600) / 60)).padStart(2, '0');
                const secs = String(accumulatedSeconds % 60).padStart(2, '0');
                
                const timerElem = document.getElementById('liveTimerDisplay');
                if (timerElem) {
                    timerElem.textContent = hrs + ":" + mins + ":" + secs;
                }
            }

            function restoreTimerSessionOnLoad() {
                if (localStorage.getItem('sw_active') === 'true') {
                    activeTimerRunning = true;
                    const rawStamp = localStorage.getItem('sw_startTimeStamp');
                    const cachedStamp = rawStamp ? parseInt(rawStamp, 10) : null;
                    
                    if (cachedStamp && !isNaN(cachedStamp)) {
                        accumulatedSeconds = Math.floor((Date.now() - cachedStamp) / 1000);
                    } else {
                        accumulatedSeconds = 0;
                        localStorage.setItem('sw_startTimeStamp', String(Date.now()));
                    }
                    
                    if (isNaN(accumulatedSeconds) || accumulatedSeconds < 0) {
                        accumulatedSeconds = 0;
                    }

                    const dot = document.getElementById('statusIndicatorDot');
                    if (dot) {
                        dot.className = "status-dot green";
                        dot.style.backgroundColor = "#10b981";
                    }
                    const label = document.getElementById('statusIndicatorText');
                    if (label) {
                        label.textContent = "Clocked In & Tracking Time";
                    }

                    const btn = document.getElementById('btnAttendanceToggle');
                    if (btn) {
                        btn.className = "btn btn-danger w-100 py-2 fw-bold";
                        btn.innerHTML = '<i class="fa-solid fa-stop me-2"></i> Time Out';
                    }

                    const timerCard = document.getElementById('attendanceSimulatorCard');
                    if (timerCard) {
                        timerCard.style.boxShadow = "0 0 15px rgba(16, 185, 129, 0.2)";
                    }
                    const manualPane = document.getElementById('manualTaskLogPane');
                    if (manualPane) {
                        manualPane.style.opacity = "0.5";
                        manualPane.style.pointerEvents = "none";
                    }

                    incrementStopwatchRuntime();
                    stopwatchInterval = setInterval(incrementStopwatchRuntime, 1000);
                }
            }

                    function handleManualLogSubmission(event) {
                        if (activeTimerRunning) {
                            showCustomToast("Cannot submit logs while the live timer is running.", "error");
                            event.preventDefault();
                            return false;
                        }

                        const hoursField = document.getElementById('sandboxLogHours');
                        const descField = document.getElementById('sandboxLogDescription');
                        const learnField = document.getElementById('sandboxLogLearningReflection');
                        const fileInput = document.getElementById('attendance-photo');
                        const dropzone = document.getElementById('photoDropzone');
                        const photoErrorMsg = document.getElementById('photo-error-message');

                        // Reset visual states
                        hoursField.classList.remove('is-invalid');
                        descField.classList.remove('is-invalid');
                        learnField.classList.remove('is-invalid');
                        if (dropzone) {
                            dropzone.style.border = '';
                            dropzone.style.backgroundColor = '';
                        }
                        if (photoErrorMsg) {
                            photoErrorMsg.style.display = 'none';
                        }

                        let isValid = true;

                        // Hours validation
                        const hoursVal = hoursField.value.trim();
                        const hoursInput = parseFloat(hoursVal);
                        if (isNaN(hoursInput) || hoursInput < 0.0001 || hoursInput > 24.0) {
                            hoursField.classList.add('is-invalid');
                            hoursField.focus();
                            isValid = false;
                        }

                        // Description validation
                        const descInput = descField.value.trim();
                        if (descInput.length < 5 || descInput.length > 500 || descInput.includes("<") || descInput.includes(">")) {
                            descField.classList.add('is-invalid');
                            if (isValid) {
                                descField.focus();
                            }
                            isValid = false;
                        }

                        // Learning Reflection validation
                        const learnInput = learnField.value.trim();
                        if (learnInput.length < 5 || learnInput.length > 500 || learnInput.includes("<") || learnInput.includes(">")) {
                            learnField.classList.add('is-invalid');
                            if (isValid) {
                                learnField.focus();
                            }
                            isValid = false;
                        }

                        // Attachment validation
                        let fileValid = true;
                        if (!fileInput || !fileInput.files || fileInput.files.length === 0) {
                            fileValid = false;
                        } else {
                            const file = fileInput.files[0];
                            const fileName = file.name.toLowerCase();
                            const isSupported = fileName.endsWith('.png') || fileName.endsWith('.jpg') || fileName.endsWith('.jpeg');
                            if (!isSupported || file.size > 10 * 1024 * 1024) {
                                fileValid = false;
                            }
                        }

                        if (!fileValid) {
                            if (dropzone) {
                                dropzone.style.border = '1.5px solid #dc3545';
                                dropzone.style.backgroundColor = 'rgba(220, 53, 69, 0.05)';
                            }
                            if (photoErrorMsg) {
                                photoErrorMsg.style.display = 'block';
                            }
                            isValid = false;
                        }

                        if (!isValid) {
                            event.preventDefault();
                            return false;
                        }

                        // Save to localStorage before submitting so client-side state is preserved on redirect!
                        renderedHoursBase += hoursInput;
                        localStorage.setItem(renderedHoursKey, renderedHoursBase);

                        return true;
                    }

                    // --- Calculation Engine & Prediction Simulator ---
                    function recalculateProgressEngine() {
                        let targetHours = parseFloat(document.getElementById('inputTargetHours').value) || 400;
                        let remainingHours = targetHours - renderedHoursBase;
                        if (remainingHours < 0)
                            remainingHours = 0;

                        let percent = (renderedHoursBase / targetHours) * 100;
                        if (percent > 100)
                            percent = 100;

                        document.getElementById('targetGoalDisplay').textContent = targetHours + 'h';
                        document.getElementById('renderedHoursDisplay').textContent = renderedHoursBase.toFixed(1) + 'h';
                        document.getElementById('remainingHoursDisplay').textContent = remainingHours.toFixed(1) + 'h';
                        document.getElementById('completionRateDisplay').textContent = percent.toFixed(1) + '%';
                        document.getElementById('progressBarText').textContent = percent.toFixed(1) + '%';
                        document.getElementById('progressBarFill').style.width = percent + '%';

                        let hoursPerDay = parseFloat(document.getElementById('hoursSlider').value) || 8;
                        let excludeHolidays = document.getElementById('excludeHolidaysHidden').value === "true";
                        let startDateVal = document.getElementById('inputStartDate').value;
                        let projectionMode = document.getElementById('projectionModeHidden').value;

                        let activeWeekdays = [];
                        document.querySelectorAll('.circle-day-picker .day-circle-btn').forEach(circle => {
                            if (circle.classList.contains('active')) {
                                activeWeekdays.push(parseInt(circle.getAttribute('data-day')));
                            }
                        });

                        if (remainingHours === 0) {
                            projectedEndDateISO = "Completed";
                            document.getElementById('projectedEndDateDisplay').textContent = "Target Goal Fully Achieved!";
                        } else if (projectionMode === "Manual" || activeWeekdays.length === 0) {
                            projectedEndDateISO = "N/A";
                            document.getElementById('projectedEndDateDisplay').textContent = "Set 'Auto' projection mode & check workdays.";
                        } else {
                            let currentSimDate = new Date(startDateVal + "T00:00:00");
                            let today = new Date();
                            today.setHours(0, 0, 0, 0);

                            if (currentSimDate < today) {
                                currentSimDate = new Date(today);
                            }

                            let simulatedAccumulatedHours = 0;
                            let safetyCounter = 0;

                            while (simulatedAccumulatedHours < remainingHours && safetyCounter < 2000) {
                                safetyCounter++;
                                let simISOStr = currentSimDate.getFullYear() + '-' +
                                        String(currentSimDate.getMonth() + 1).padStart(2, '0') + '-' +
                                        String(currentSimDate.getDate()).padStart(2, '0');

                                let isHoliday = excludeHolidays && phHolidays2026.includes(simISOStr);
                                let isWorkingDay = activeWeekdays.includes(currentSimDate.getDay());

                                if (isWorkingDay && !isHoliday) {
                                    simulatedAccumulatedHours += hoursPerDay;
                                }

                                if (simulatedAccumulatedHours < remainingHours) {
                                    currentSimDate.setDate(currentSimDate.getDate() + 1);
                                }
                            }

                            projectedEndDateISO = currentSimDate.getFullYear() + '-' +
                                    String(currentSimDate.getMonth() + 1).padStart(2, '0') + '-' +
                                    String(currentSimDate.getDate()).padStart(2, '0');

                            const options = {weekday: 'long', year: 'numeric', month: 'long', day: 'numeric'};
                            document.getElementById('projectedEndDateDisplay').textContent = currentSimDate.toLocaleDateString('en-US', options);
                        }

                        renderCalendarComponent();
                    }

                    function renderCalendarComponent() {
                        const surface = document.getElementById('calendarDaysSurface');
                        if (!surface)
                            return;
                        surface.innerHTML = '';

                        document.getElementById('calendarMonthTitle').textContent = monthNames[calendarMonth] + " " + calendarYear;

                        const firstDayIndex = new Date(calendarYear, calendarMonth, 1).getDay();
                        const totalDaysInMonth = new Date(calendarYear, calendarMonth + 1, 0).getDate();

                        let activeWeekdays = [];
                        document.querySelectorAll('.circle-day-picker .day-circle-btn').forEach(circle => {
                            if (circle.classList.contains('active')) {
                                activeWeekdays.push(parseInt(circle.getAttribute('data-day')));
                            }
                        });

                        let excludeHolidays = document.getElementById('excludeHolidaysHidden').value === "true";
                        let hoursPerDay = parseFloat(document.getElementById('hoursSlider').value) || 8;

                        for (let i = 0; i < firstDayIndex; i++) {
                            const filler = document.createElement('div');
                            filler.className = "calendar-day-cell empty";
                            filler.innerHTML = "&nbsp;";
                            surface.appendChild(filler);
                        }

                        let today = new Date();
                        let todayDay = today.getDate();
                        let todayMonth = today.getMonth();
                        let todayYear = today.getFullYear();

                        for (let day = 1; day <= totalDaysInMonth; day++) {
                            const dayCell = document.createElement('div');
                            dayCell.className = "calendar-day-cell";

                            let evaluationDate = new Date(calendarYear, calendarMonth, day);
                            let evalISOStr = calendarYear + '-' + String(calendarMonth + 1).padStart(2, '0') + '-' + String(day).padStart(2, '0');

                            let isToday = (day === todayDay && calendarMonth === todayMonth && calendarYear === todayYear);

                            if (excludeHolidays && phHolidays2026.includes(evalISOStr)) {
                                dayCell.classList.add('holiday');
                                dayCell.innerHTML = "<span class=\"day-num\">" + day + "</span>";
                            } else if (evalISOStr === projectedEndDateISO) {
                                dayCell.classList.add('completion-day');
                                dayCell.innerHTML = "<span class=\"day-num\">" + day + "</span>";
                            } else if (activeWeekdays.includes(evaluationDate.getDay())) {
                                dayCell.classList.add('scheduled');
                                dayCell.innerHTML = "<span class=\"day-num\">" + day + "</span><span class=\"hours-sub\">" + hoursPerDay + "h</span>";
                            } else {
                                dayCell.classList.add('day-off');
                                dayCell.innerHTML = "<span class=\"day-num\">" + day + "</span>";
                            }

                            if (isToday) {
                                dayCell.classList.add('today');
                            }

                            surface.appendChild(dayCell);
                        }
                    }



                    function saveConfigState(event) {
                        event.preventDefault();
                        localStorage.setItem('config_targetHours', document.getElementById('inputTargetHours').value);
                        localStorage.setItem('config_startDate', document.getElementById('inputStartDate').value);
                        localStorage.setItem('config_hoursPerDay', document.getElementById('hoursSlider').value);
                        localStorage.setItem('config_excludeHolidays', document.getElementById('excludeHolidaysHidden').value);
                        localStorage.setItem('config_projMode', document.getElementById('projectionModeHidden').value);

                        let selectedDays = [];
                        document.querySelectorAll('.circle-day-picker .day-circle-btn').forEach(circle => {
                            if (circle.classList.contains('active')) {
                                selectedDays.push(circle.getAttribute('data-day'));
                            }
                        });
                        localStorage.setItem('config_activeDays', JSON.stringify(selectedDays));

                        showCustomToast("Configuration matrix saved successfully.", "success");
                        recalculateProgressEngine();
                    }

                    function loadConfigState() {
                        if (localStorage.getItem('config_targetHours')) {
                            document.getElementById('inputTargetHours').value = localStorage.getItem('config_targetHours');
                            document.getElementById('inputStartDate').value = localStorage.getItem('config_startDate');

                            let sliderVal = localStorage.getItem('config_hoursPerDay');
                            document.getElementById('hoursSlider').value = sliderVal;
                            document.getElementById('sliderValDisplay').textContent = sliderVal + 'h';

                            let exHol = localStorage.getItem('config_excludeHolidays') === "true";
                            document.getElementById('excludeHolidaysHidden').value = exHol;
                            document.getElementById('holidayBtnYes').classList.toggle('active', exHol);
                            document.getElementById('holidayBtnNo').classList.toggle('active', !exHol);

                            let mode = localStorage.getItem('config_projMode') || "Auto";
                            document.getElementById('projectionModeHidden').value = mode;
                            document.getElementById('projBtnAuto').classList.toggle('active', mode === 'Auto');
                            document.getElementById('projBtnManual').classList.toggle('active', mode === 'Manual');

                            let activeDays = JSON.parse(localStorage.getItem('config_activeDays') || "[]");
                            document.querySelectorAll('.circle-day-picker .day-circle-btn').forEach(circle => {
                                let val = parseInt(circle.getAttribute('data-day'));
                                if (activeDays.includes(String(val)) || activeDays.includes(val)) {
                                    circle.classList.add('active');
                                } else {
                                    circle.classList.remove('active');
                                }
                            });
                        }
                    }

                    function resetConfigurationForm() {
                        localStorage.removeItem('config_targetHours');
                        localStorage.removeItem('config_startDate');
                        localStorage.removeItem('config_hoursPerDay');
                        localStorage.removeItem('config_excludeHolidays');
                        localStorage.removeItem('config_projMode');
                        localStorage.removeItem('config_activeDays');

                        document.getElementById('inputTargetHours').value = "400";
                        document.getElementById('inputStartDate').value = "2026-05-06";
                        document.getElementById('hoursSlider').value = "7";
                        document.getElementById('sliderValDisplay').textContent = "7h";

                        document.getElementById('excludeHolidaysHidden').value = "true";
                        document.getElementById('holidayBtnYes').classList.add('active');
                        document.getElementById('holidayBtnNo').classList.remove('active');

                        document.getElementById('projectionModeHidden').value = "Auto";
                        document.getElementById('projBtnAuto').classList.add('active');
                        document.getElementById('projBtnManual').classList.remove('active');

                        document.querySelectorAll('.circle-day-picker .day-circle-btn').forEach(circle => {
                            let d = parseInt(circle.getAttribute('data-day'));
                            if (d >= 1 && d <= 5) {
                                circle.classList.add('active');
                            } else {
                                circle.classList.remove('active');
                            }
                        });

                        showCustomToast("Configuration attributes reset to factory defaults.", "success");
                        recalculateProgressEngine();
                    }

            // --- Custom Announcements & Messaging Features ---
            let activeContactId = null;
            let activeContactName = null;
            let chatPollInterval = null;
            let contactPollInterval = null;

            function toggleSidebar() {
                if (window.innerWidth >= 992) {
                    document.body.classList.toggle("sidebar-collapsed");
                } else {
                    document.body.classList.toggle("show-sidebar");
                }
            }

            function loadAnnouncements() {
                const container = document.getElementById("announcementsFeedContainer");
                const tabId = window.name || sessionStorage.getItem('tabId') || '';
                fetch("announcements_api.jsp?tabId=" + encodeURIComponent(tabId))
                    .then(r => r.json())
                    .then(data => {
                        renderAnnouncements(data);
                    })
                    .catch(e => {
                        if (container) {
                            container.innerHTML = '<div class="text-center py-4 text-danger">Failed to load announcements feed.</div>';
                        }
                    });
            }

            function loadAnnouncementsSilent() {
                const tabId = window.name || sessionStorage.getItem('tabId') || '';
                fetch("announcements_api.jsp?tabId=" + encodeURIComponent(tabId))
                    .then(r => r.json())
                    .then(data => {
                        updateAnnouncementWidgets(data);
                    })
                    .catch(e => console.error("Silent announcements poll failed", e));
            }

            function renderAnnouncements(data) {
                const container = document.getElementById("announcementsFeedContainer");
                if (!container) return;
                if (data.length === 0) {
                    container.innerHTML = `
                        <div class="text-center py-5 text-muted">
                            <i class="fa-solid fa-bullhorn fa-3x mb-3 text-muted" style="opacity: 0.5;"></i>
                            <p class="mb-0">No announcements published yet.</p>
                        </div>
                    `;
                    return;
                }
                let html = "";
                data.forEach(ann => {
                    const formattedDate = formatAnnouncementTime(ann.createdAt);
                    html += `
                        <div class="announcement-card">
                            <div class="d-flex justify-content-between align-items-start mb-2">
                                <h5 class="fw-bold mb-0 text-dark">\${escapeHtml(ann.title)}</h5>
                                <span class="badge bg-secondary small">\${escapeHtml(ann.targetType)} Target</span>
                            </div>
                            <p class="mb-3 text-muted" style="font-size: 0.92rem; white-space: pre-wrap;">\${escapeHtml(ann.content)}</p>
                            <div class="d-flex justify-content-between align-items-center text-muted" style="font-size: 0.78rem;">
                                <span>Published by: <strong>\${escapeHtml(ann.senderName)}</strong></span>
                                <span>\${formattedDate}</span>
                            </div>
                        </div>
                    `;
                });
                container.innerHTML = html;
                updateAnnouncementWidgets(data);
            }

            function formatAnnouncementTime(dateStr) {
                if (!dateStr) return "";
                try {
                    const parts = dateStr.split(" ");
                    if (parts.length >= 2) {
                        const timeParts = parts[1].split(":");
                        if (timeParts.length >= 2) {
                            let hour = parseInt(timeParts[0]);
                            const minute = timeParts[1];
                            const ampm = hour >= 12 ? "PM" : "AM";
                            hour = hour % 12;
                            hour = hour ? hour : 12;
                            return parts[0] + " " + hour + ":" + minute + " " + ampm;
                        }
                    }
                    return dateStr;
                } catch(e) {
                    return dateStr;
                }
            }

            function updateAnnouncementWidgets(data) {
                // 1. Update Badge
                const badge = document.getElementById("announcementsBadge");
                if (badge) {
                    if (data.length > 0) {
                        badge.textContent = data.length;
                        badge.classList.remove("d-none");
                    } else {
                        badge.classList.add("d-none");
                    }
                }

                // 2. Update dashboard banner with the latest announcement
                const banner = document.getElementById("latestAnnouncementBanner");
                const titleElem = document.getElementById("latestAnnTitle");
                const excerptElem = document.getElementById("latestAnnExcerpt");
                if (banner && titleElem && excerptElem) {
                    if (data.length > 0) {
                        const latest = data[0]; // Assuming order is descending from DB (most recent first)
                        titleElem.textContent = latest.title;
                        let excerpt = latest.content;
                        if (excerpt.length > 120) {
                            excerpt = excerpt.substring(0, 117) + "...";
                        }
                        excerptElem.textContent = excerpt;
                        banner.classList.remove("d-none");
                    } else {
                        banner.classList.add("d-none");
                    }
                }
            }

            function escapeHtml(text) {
                if (!text) return "";
                return text
                    .replace(/&/g, "&amp;")
                    .replace(/</g, "&lt;")
                    .replace(/>/g, "&gt;")
                    .replace(/"/g, "&quot;")
                    .replace(/'/g, "&#039;");
            }

            function startMessagingPolling() {
                if (chatPollInterval) clearInterval(chatPollInterval);
                if (contactPollInterval) clearInterval(contactPollInterval);

                contactPollInterval = setInterval(loadContactsSilent, 4000);
                chatPollInterval = setInterval(() => {
                    if (activeContactId) {
                        loadChatSilent(activeContactId);
                    }
                }, 3000);
            }

            function stopMessagingPolling() {
                if (chatPollInterval) clearInterval(chatPollInterval);
                if (contactPollInterval) clearInterval(contactPollInterval);
                chatPollInterval = null;
                contactPollInterval = null;
            }

            function loadContacts() {
                const listContainer = document.getElementById("chatContactsContainer");
                const tabId = window.name || sessionStorage.getItem('tabId') || '';
                fetch("messages_api.jsp?action=contacts&tabId=" + encodeURIComponent(tabId))
                    .then(r => r.json())
                    .then(data => renderContactsList(data))
                    .catch(e => {
                        if (listContainer) {
                            listContainer.innerHTML = '<div class="text-center py-4 text-danger">Failed to load contacts.</div>';
                        }
                    });
            }

            function loadContactsSilent() {
                const tabId = window.name || sessionStorage.getItem('tabId') || '';
                fetch("messages_api.jsp?action=contacts&tabId=" + encodeURIComponent(tabId))
                    .then(r => r.json())
                    .then(data => renderContactsList(data))
                    .catch(e => console.error("Contacts refresh failed", e));
            }

            let allContactsData = [];
            function renderContactsList(data) {
                if (data) {
                    allContactsData = data;
                }
                const listContainer = document.getElementById("chatContactsContainer");
                if (!listContainer) return;

                const searchInput = document.getElementById("chatSearchInput");
                const query = searchInput ? searchInput.value.toLowerCase().trim() : "";

                const filteredData = allContactsData.filter(c => {
                    return c.name.toLowerCase().includes(query) || 
                           c.id.toLowerCase().includes(query) ||
                           (c.role && c.role.toLowerCase().includes(query)) ||
                           (c.office && c.office.toLowerCase().includes(query));
                });

                if (filteredData.length === 0) {
                    listContainer.innerHTML = '<div class="text-center py-4 text-muted">No contacts found.</div>';
                    let totalUnread = 0;
                    allContactsData.forEach(c => {
                        let unread = c.id === activeContactId ? 0 : c.unreadCount;
                        totalUnread += unread;
                    });
                    updateMessagesBadge(totalUnread);
                    return;
                }

                let html = "";
                let totalUnread = 0;

                allContactsData.forEach(c => {
                    let unread = c.id === activeContactId ? 0 : c.unreadCount;
                    totalUnread += unread;
                });

                // Sort filtered data: unread count > 0 at the top, then by last message time descending, then alphabetically by name
                const sortedData = filteredData.sort((a, b) => {
                    const unreadA = a.id === activeContactId ? 0 : a.unreadCount;
                    const unreadB = b.id === activeContactId ? 0 : b.unreadCount;
                    
                    if ((unreadA > 0) !== (unreadB > 0)) {
                        return unreadB > 0 ? 1 : -1;
                    }
                    
                    const timeA = a.lastMessageTime ? new Date(a.lastMessageTime.replace(/-/g, "/")).getTime() : 0;
                    const timeB = b.lastMessageTime ? new Date(b.lastMessageTime.replace(/-/g, "/")).getTime() : 0;
                    
                    if (timeA !== timeB) {
                        return timeB - timeA;
                    }
                    
                    return a.name.localeCompare(b.name);
                });

                sortedData.forEach(c => {
                    let unread = c.id === activeContactId ? 0 : c.unreadCount;
                    const isActive = c.id === activeContactId ? "active" : "";
                    const badgeClass = unread > 0 ? "" : "d-none";
                    const avatarUrl = 'https://ui-avatars.com/api/?name=' + encodeURIComponent(c.name) + '&background=d63384&color=fff';
                    html += '<div class="contact-item ' + isActive + '" data-id="' + c.id + '" onclick="selectContact(\'' + c.id + '\', \'' + c.name.replace(/'/g, "\\'") + '\', \'' + c.role + '\', \'\')">' +
                        '<img src="' + avatarUrl + '" class="contact-avatar" alt="Avatar" style="object-fit: cover;">' +
                        '<div class="contact-details">' +
                            '<div class="contact-name-row">' +
                                '<span class="contact-name">' + c.name + '</span>' +
                                '<span class="badge bg-danger ' + badgeClass + '">' + unread + '</span>' +
                            '</div>' +
                            '<div class="contact-sub">' + c.role + ' — ' + c.office + '</div>' +
                        '</div>' +
                    '</div>';
                });
                listContainer.innerHTML = html;

                updateMessagesBadge(totalUnread);
            }

            function updateMessagesBadge(totalUnread) {
                const messagesBadge = document.getElementById("messagesBadge");
                if (messagesBadge) {
                    messagesBadge.innerText = totalUnread;
                    if (totalUnread > 0) {
                        messagesBadge.classList.remove("d-none");
                    } else {
                        messagesBadge.classList.add("d-none");
                    }
                }
            }

            function filterContacts() {
                renderContactsList();
            }

            function selectContact(contactId, contactName, contactRole, avatarPath) {
                activeContactId = contactId;
                activeContactName = contactName;

                // Mark as read in client-side cache immediately
                const contact = allContactsData.find(c => c.id === contactId);
                if (contact) {
                    contact.unreadCount = 0;
                }

                renderContactsList();

                document.getElementById("chatEmptyState").classList.add("d-none");
                const activeArea = document.getElementById("chatActiveArea");
                activeArea.style.display = "flex";
                activeArea.classList.remove("d-none");

                document.getElementById("activeContactName").textContent = contactName;
                document.getElementById("activeContactRole").textContent = contactRole;
                
                const avatarUrl = "https://ui-avatars.com/api/?name=" + encodeURIComponent(contactName) + "&background=d63384&color=fff";
                document.getElementById("activeContactAvatar").src = avatarUrl;

                const msgsContainer = document.getElementById("chatMessagesContainer");
                msgsContainer.innerHTML = '<div class="text-center py-4 text-muted"><i class="fas fa-spinner fa-spin me-2"></i>Loading messages...</div>';

                // Mark messages as read by requesting history
                loadChat(contactId);
            }

            function useTemplate(text) {
                const input = document.getElementById("chatInputMessage");
                if (input) {
                    input.value = text;
                    input.focus();
                }
            }

            function loadChat(contactId) {
                const msgsContainer = document.getElementById("chatMessagesContainer");
                const tabId = window.name || sessionStorage.getItem('tabId') || '';
                fetch("messages_api.jsp?action=history&contactId=" + encodeURIComponent(contactId) + "&tabId=" + encodeURIComponent(tabId))
                    .then(r => r.json())
                    .then(data => {
                        renderChatMessages(data);
                        scrollToBottom("chatMessagesContainer");
                    })
                    .catch(e => {
                        if (msgsContainer) {
                            msgsContainer.innerHTML = '<div class="text-center py-4 text-danger">Failed to load chat history.</div>';
                        }
                    });
            }

            function loadChatSilent(contactId) {
                const tabId = window.name || sessionStorage.getItem('tabId') || '';
                fetch("messages_api.jsp?action=history&contactId=" + encodeURIComponent(contactId) + "&tabId=" + encodeURIComponent(tabId))
                    .then(r => r.json())
                    .then(data => {
                        const msgsContainer = document.getElementById("chatMessagesContainer");
                        if (msgsContainer) {
                            const currentHtml = msgsContainer.innerHTML;
                            renderChatMessages(data);
                            if (msgsContainer.innerHTML !== currentHtml) {
                                scrollToBottom("chatMessagesContainer");
                            }
                        }
                    })
                    .catch(e => console.error("Chat polling failed", e));
            }

            function renderChatMessages(data) {
                const msgsContainer = document.getElementById("chatMessagesContainer");
                if (!msgsContainer) return;
                if (data.length === 0) {
                    msgsContainer.innerHTML = '<div class="text-center py-4 text-muted">No messages yet. Send a message to start the conversation!</div>';
                    return;
                }

                let html = "";
                data.forEach(m => {
                    const isSelf = m.senderId === currentUserId;
                    const msgClass = isSelf ? "outgoing" : "incoming";
                    const formattedDate = formatMessageTime(m.createdAt);
                    html += '<div class="message-bubble-wrapper ' + msgClass + '">' +
                        '<div class="message-bubble">' +
                            '<div class="message-text">' + escapeHtml(m.messageText) + '</div>' +
                            '<div class="message-time">' + formattedDate + '</div>' +
                        '</div>' +
                    '</div>';
                });
                msgsContainer.innerHTML = html;
            }

            function formatMessageTime(dateStr) {
                if (!dateStr) return "";
                try {
                    const parts = dateStr.split(" ");
                    if (parts.length >= 2) {
                        const timeParts = parts[1].split(":");
                        if (timeParts.length >= 2) {
                            let hour = parseInt(timeParts[0]);
                            const minute = timeParts[1];
                            const ampm = hour >= 12 ? "PM" : "AM";
                            hour = hour % 12;
                            hour = hour ? hour : 12;
                            return hour + ":" + minute + " " + ampm;
                        }
                    }
                    return dateStr;
                } catch(e) {
                    return dateStr;
                }
            }

            function scrollToBottom(containerId) {
                const el = document.getElementById(containerId);
                if (el) {
                    el.scrollTop = el.scrollHeight;
                }
            }

            function submitChatMessage(event) {
                event.preventDefault();
                const input = document.getElementById("chatInputMessage");
                if (!input || !activeContactId) return;

                const text = input.value.trim();
                if (text === "") return;

                input.value = "";
                const tabId = window.name || sessionStorage.getItem('tabId') || '';

                const params = new URLSearchParams();
                params.append("action", "send");
                params.append("receiverId", activeContactId);
                params.append("messageText", text);
                params.append("tabId", tabId);

                fetch("messages_api.jsp", {
                    method: "POST",
                    headers: { "Content-Type": "application/x-www-form-urlencoded" },
                    body: params.toString()
                })
                .then(r => r.json())
                .then(res => {
                    if (res.success) {
                        loadChat(activeContactId);
                    } else {
                        showCustomToast("Failed to send message: " + (res.error || ""), "error");
                    }
                })
                .catch(e => showCustomToast("Error sending message", "error"));
            }

            function pollUnreadMessagesCount() {
                const tabId = window.name || sessionStorage.getItem('tabId') || '';
                fetch("messages_api.jsp?action=contacts&tabId=" + encodeURIComponent(tabId))
                    .then(r => r.json())
                    .then(data => {
                        let totalUnread = 0;
                        const messagesPanel = document.getElementById("messages-view");
                        const isMessagingActive = messagesPanel && messagesPanel.classList.contains("active-view");
                        data.forEach(c => {
                            let unread = (isMessagingActive && c.id === activeContactId) ? 0 : c.unreadCount;
                            totalUnread += unread;
                        });
                        const messagesBadge = document.getElementById("messagesBadge");
                        if (messagesBadge) {
                            messagesBadge.innerText = totalUnread;
                            if (totalUnread > 0) messagesBadge.classList.remove("d-none");
                            else messagesBadge.classList.add("d-none");
                        }
                    })
                    .catch(e => console.log("Background badge poll failed", e));
            }

            // Background message badge poll
            setInterval(() => {
                const messagesPanel = document.getElementById("messages-view");
                if (messagesPanel && !messagesPanel.classList.contains("active-view")) {
                    pollUnreadMessagesCount();
                }
            }, 8000);

            // Background announcements banner/badge poll
            setInterval(() => {
                const announcementsPanel = document.getElementById("announcements-view");
                if (announcementsPanel && !announcementsPanel.classList.contains("active-view")) {
                    loadAnnouncementsSilent();
                }
            }, 8000);
        </script>
    </body>
</html>
