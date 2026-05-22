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
    if (loggedInUser != null) {
        model.User dbUser = model.UserDAO.getInternById(loggedInUser.getId(), getServletContext());
        if (dbUser != null && dbUser.isResetHours()) {
            forceResetHours = true;
            model.UserDAO.setResetHoursFlag(loggedInUser.getId(), false, getServletContext());
        }
    }
    
    String fullName = loggedInUser.getFirstName() + " " + loggedInUser.getLastName();

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

            <main class="main-content">

                <header class="top-bar">
                    <h2 class="page-title" id="mainPageTitle">Intern's Dashboard</h2>
                    <div class="user-profile">
                        <div class="profile-chip">
                            <span><%= fullName %></span>
                            <img src="https://ui-avatars.com/api/?name=<%= fullName %>&background=d63384&color=fff" alt="Intern">
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
                             <form id="sandboxLogForm" action="SubmitTaskServlet?tabId=<%= tabId %>" method="POST" enctype="multipart/form-data" onsubmit="return handleManualLogSubmission(event)">
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
            const currentUserId = "<%= loggedInUser != null ? loggedInUser.getId() : "" %>";
            const renderedHoursKey = 'renderedHours_' + currentUserId;
            
            <% if (forceResetHours) { %>
                localStorage.setItem(renderedHoursKey, '0');
            <% } %>
            let renderedHoursBase = parseFloat(localStorage.getItem(renderedHoursKey)) || 148.5;
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
                checkIcon.textContent = "✓";
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

                // Dynamic persistent top bar title sync
                const mainPageTitle = document.getElementById('mainPageTitle');
                if (mainPageTitle) {
                    if (tabId === 'dashboard-view') {
                        mainPageTitle.textContent = "Intern's Dashboard";
                    } else if (tabId === 'coordinator-view') {
                        mainPageTitle.textContent = "Internship Setup Configuration";
                    }
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
                        renderedHoursBase = 148.5;
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
        </script>
    </body>
</html>
