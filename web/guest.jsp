<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="model.User"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<c:if test="${empty sessionScope.user}">
    <c:redirect url="login.jsp"/>
</c:if>

<c:set var="alertMessage" value=""/>
<c:set var="alertClass" value=""/>
<c:set var="parsedDbHours" value="0.0"/>

<c:if test="${not empty param.approvedHours}">
    <c:catch var="parseError">
        <c:set var="parsedDbHours" value="${param.approvedHours + 0.0}"/>
    </c:catch>
</c:if>

<c:choose>
    <c:when test="${param.status == 'success'}">
        <c:set var="alertMessage" value="Success! Your tracking log details have been saved to MySQL."/>
        <c:if test="${parsedDbHours > 0}">
            <c:set var="alertMessage" value="${alertMessage} (${parsedDbHours} hours successfully synchronized into active record matrix.)"/>
        </c:if>
        <c:set var="alertClass" value="alert alert-success mt-3 mb-3"/>
    </c:when>
    <c:when test="${param.status == 'db_error'}">
        <c:set var="alertMessage" value="Database Error: Could not save attendance record."/>
        <c:set var="alertClass" value="alert alert-danger mt-3 mb-3"/>
    </c:when>
    <c:when test="${param.status == 'no_clock_in'}">
        <c:set var="alertMessage" value="Error: No matching clock-in event timestamp tracked in session state."/>
        <c:set var="alertClass" value="alert alert-warning mt-3 mb-3"/>
    </c:when>
</c:choose>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Guest Intern's Dashboard | Active Learning</title>

        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
        <link rel="stylesheet" type="text/css" href="${pageContext.request.contextPath}/css/guest.css">
    </head>

    <body>

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

                <div class="sidebar-footer">
                    <a href="login.jsp" class="logout-btn">
                        <i class="fa-solid fa-arrow-right-from-bracket"></i> Log Out
                    </a>
                </div>
            </aside>

            <main class="main-content">

                <c:if test="${not empty alertMessage}">
                <div class="${alertClass}" role="alert">
                    <i class="fa-solid fa-circle-info me-2"></i> ${alertMessage}
                </div>
                </c:if>

                <input type="hidden" id="dbInjectedHoursField" value="${parsedDbHours}">
                <input type="hidden" id="dbSubmissionStatusField" value="${empty param.status ? '' : param.status}">

                <div id="dashboard-view" class="view-panel active-view">
                    <header class="content-header d-flex justify-content-between align-items-start mb-4">
                        <div class="header-title-group">
                            <div class="title-with-icon">
                                <i class="fa-solid fa-graduation-cap header-icon"></i>
                                <h1>Intern's Dashboard</h1>
                            </div>
                            <p class="welcome-text">Live Analytics & Performance Tracker</p>
                        </div>
                        <div class="user-profile d-flex align-items-center bg-white px-3 py-2 border shadow-sm" style="border-radius: 50px;">
                            <div class="profile-chip d-flex align-items-center gap-2">
                                <span class="fw-bold small text-secondary">${sessionScope.user.fullName}</span>
                                <img src="https://ui-avatars.com/api/?name=${sessionScope.user.fullName}&background=d63384&color=fff" alt="Intern" class="rounded-circle" style="width: 32px; height: 32px;">
                            </div>
                        </div>
                    </header>

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
                            <span class="card-metric-title">TOTAL RENDERED HOURS</span>
                            <div class="value" id="renderedHoursDisplay">148.5h</div>

                            <c:if test="${param.status == 'success' and parsedDbHours > 0}">
                            <span class="position-absolute bottom-0 end-0 bg-success text-white px-2 py-1 small rounded-start fw-bold" style="font-size: 10px; opacity: 0.95; z-index: 5;">
                                <i class="fa-solid fa-cloud-arrow-up me-1"></i> Sync Live: +${parsedDbHours}h
                            </span>
                            </c:if>
                        </div>
                        <div class="stat-card card-pink">
                            <span class="card-metric-title">REMAINING HOURS</span>
                            <div class="value" id="remainingHoursDisplay">251.5h</div>
                        </div>
                        <div class="stat-card card-green">
                            <span class="card-metric-title">TARGET GOAL</span>
                            <div class="value" id="targetGoalDisplay">400h</div>
                        </div>
                        <div class="stat-card card-blue">
                            <span class="card-metric-title">COMPLETION RATE</span>
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
                        <div class="dashboard-pane" id="attendanceSimulatorCard">
                            <h3 class="pane-title">Daily Attendance Simulator</h3>
                            <div class="attendance-box text-center py-3">
                                <div class="mb-3">
                                    <div class="status-marker">
                                        <span class="indicator-dot status-offline" id="statusIndicatorDot"></span>
                                        <span id="statusIndicatorText">Not Clocked In</span>
                                    </div>
                                </div>
                                <div id="liveTimerDisplay" class="live-timer-display my-3 h1 fw-bold" style="font-size: 42px; letter-spacing: -1px;">00:00:00</div>
                                <button id="btnAttendanceToggle" class="btn-attendance-action clock-in-state" onclick="toggleTimerAttendanceSession()">
                                    <i class="fa-solid fa-play me-2"></i> Time In
                                </button>
                                <div class="text-muted mt-2 text-center" style="font-size: 11px;">
                                    *Optional: Use this timer if you want to track runtime parameters natively.
                                </div>
                            </div>
                        </div>

                        <div class="dashboard-pane" id="manualTaskLogPane">
                            <h3 class="pane-title fw-bolder">Simulate Task Entry Log</h3>
                            <form id="sandboxLogForm" onsubmit="handleManualLogSubmission(event)">
                                <div class="form-group mb-3">
                                    <label class="field-label-small d-block mb-2">HOURS SPENT ON TASK</label>
                                    <input type="text" id="sandboxLogHours" name="simulatedHours" class="form-control" placeholder="e.g. 7.5" value="${param.simulatedHours}" required style="background-color: #f1f5f9; border-color: #cbd5e1; color: #0f172a;">
                                </div>

                                <div class="form-group attachment-container mb-3">
                                    <label class="field-label-small d-block mb-2">PROOF OF ATTENDANCE <span class="text-danger">*</span></label>
                                    <div class="photo-dropzone text-center p-3 border border-dashed rounded" style="cursor: pointer; background-color: #f8fafc; border-color: #cbd5e1;" onclick="document.getElementById('attendance-photo').click();" ondragover="event.preventDefault(); this.style.opacity='0.5';" ondragleave="this.style.opacity='1';" ondrop="event.preventDefault(); this.style.opacity='1'; if(event.dataTransfer.files.length > 0) { document.getElementById('attendance-photo').files = event.dataTransfer.files; handleFileChange(document.getElementById('attendance-photo')); }">
                                        <i class="fa-solid fa-camera fa-2x mb-2 text-muted" style="color: #94a3b8 !important;"></i>
                                        <p class="m-0 small" style="color: #475569;">Click or drag to <strong>add attachment (photo)</strong></p>
                                        <span class="file-hint text-muted" style="font-size: 11px; color: #94a3b8 !important;">Supports PNG, JPG, or JPEG</span>
                                        <input type="file" id="attendance-photo" name="attendancePhoto" accept="image/*" onchange="handleFileChange(this)" hidden onclick="event.stopPropagation();">
                                    </div>
                                    <div id="photo-preview-name" class="photo-preview-text mt-2 text-success small fw-bold"></div>
                                </div>

                                <button type="submit" class="btn-submit-log">
                                    <i class="fa-solid fa-paper-plane"></i> Inject Simulation Hours
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

                            <div class="calendar-days-surface d-grid text-center gap-1" id="calendarDaysSurface" style="grid-template-columns: repeat(7, 1fr); font-size: 12px;"></div>

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
                    <header class="content-header d-flex justify-content-between align-items-start mb-4">
                        <div class="header-title-group">
                            <div class="title-with-icon">
                                <i class="fa-solid fa-sliders header-icon" style="color: #9E1B4C;"></i>
                                <h1>Internship Setup Configuration</h1>
                            </div>
                            <p class="welcome-text m-0">Customize your target goals and weekly work shifts to update your live progress matrix.</p>
                        </div>
                        <div class="d-flex align-items-center gap-3">
                            <button type="button" class="reset-btn" onclick="resetConfigurationForm(); return false;">
                                <i class="fa-solid fa-rotate-left me-1"></i> Reset Defaults
                            </button>
                            <div class="user-profile d-flex align-items-center bg-white px-3 py-2 border shadow-sm" style="border-radius: 50px;">
                                <div class="profile-chip d-flex align-items-center gap-2">
                                    <span class="fw-bold small text-secondary">${sessionScope.user.fullName}</span>
                                    <img src="https://ui-avatars.com/api/?name=${sessionScope.user.fullName}&background=d63384&color=fff" alt="Intern" class="rounded-circle" style="width: 32px; height: 32px;">
                                </div>
                            </div>
                        </div>
                    </header>

                    <form id="goalsSetupForm" onsubmit="saveConfigState(event); return false;">
                        <div class="setup-grid">

                            <div class="card card-yellow">
                                <h3 class="card-title">Internship Goals</h3>
                                <div class="input-group-row">
                                    <div class="input-field">
                                        <label for="inputTargetHours">TARGET HOURS</label>
                                        <div class="input-wrapper">
                                            <input type="number" id="inputTargetHours" value="400" min="1" required oninput="recalculateProgressEngine()">
                                            <i class="fa-solid fa-clock field-icon"></i>
                                        </div>
                                    </div>
                                    <div class="input-field">
                                        <label for="inputStartDate">START DATE</label>
                                        <div class="input-wrapper">
                                            <input type="date" id="inputStartDate" value="2026-05-06" required onchange="recalculateProgressEngine()">
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div class="card card-green">
                                <h3 class="card-title">Load & Holiday</h3>
                                <div class="slider-container">
                                    <div class="slider-header">
                                        <label for="hoursSlider">HOURS PER DAY</label>
                                        <span class="slider-value-badge" id="sliderValDisplay">7h</span>
                                    </div>
                                    <input type="range" min="1" max="12" value="7" class="custom-slider" id="hoursSlider" oninput="updateSliderLabel(this.value)">
                                </div>
                                <div class="toggle-container">
                                    <label class="toggle-label">EXCLUDE PH HOLIDAYS (2026)?</label>
                                    <div class="toggle-buttons">
                                        <input type="hidden" id="excludeHolidaysHidden" value="true">
                                        <button type="button" id="holidayBtnYes" class="toggle-btn active" onclick="setHolidayExclusion(true)">
                                            <i class="fa-solid fa-calendar-check"></i> Yes
                                        </button>
                                        <button type="button" id="holidayBtnNo" class="toggle-btn" onclick="setHolidayExclusion(false)">
                                            <i class="fa-solid fa-calendar-xmark"></i> No
                                        </button>
                                    </div>
                                </div>
                            </div>

                            <div class="card card-pink">
                                <div>
                                    <h3 class="card-title mb-1">Work Schedule</h3>
                                    <label class="field-label-small d-block mb-3">WEEKLY WORK DAYS</label>
                                    <div class="days-selector">
                                        <div class="day-circle" data-day="0" onclick="toggleDayCircle(this)" style="pointer-events: auto;">S</div>
                                        <div class="day-circle active" data-day="1" onclick="toggleDayCircle(this)" style="pointer-events: auto;">M</div>
                                        <div class="day-circle active" data-day="2" onclick="toggleDayCircle(this)" style="pointer-events: auto;">T</div>
                                        <div class="day-circle active" data-day="3" onclick="toggleDayCircle(this)" style="pointer-events: auto;">W</div>
                                        <div class="day-circle active" data-day="4" onclick="toggleDayCircle(this)" style="pointer-events: auto;">T</div>
                                        <div class="day-circle active" data-day="5" onclick="toggleDayCircle(this)" style="pointer-events: auto;">F</div>
                                        <div class="day-circle" data-day="6" onclick="toggleDayCircle(this)" style="pointer-events: auto;">S</div>
                                    </div>
                                </div>
                                <div class="helper-text mt-3">
                                    <i class="fa-solid fa-star info-symbol"></i> <span id="activeDaysCountText">5</span>&nbsp;Selected active days count as projectable work terms
                                </div>
                            </div>

                            <div class="card card-blue">
                                <h3 class="card-title">Projection Mode</h3>
                                <div class="w-100">
                                    <div class="mode-options">
                                        <input type="hidden" id="projectionModeHidden" value="Auto">
                                        <button type="button" id="projBtnManual" class="mode-btn" onclick="setProjectionMode('Manual')">
                                            <i class="fa-solid fa-hand-pointer"></i> Manual
                                        </button>
                                        <button type="button" id="projBtnAuto" class="mode-btn active" onclick="setProjectionMode('Auto')">
                                            <i class="fa-solid fa-layer-group"></i> Auto
                                        </button>
                                    </div>
                                </div>
                            </div>

                        </div>

                        <div class="d-flex justify-content-between align-items-center mt-4">
                            <span class="text-muted small">Simulating analytics metrics live inside your <strong>browser session</strong></span>
                            <button type="button" class="btn-submit-log fw-bold w-auto px-4 m-0" style="font-size: 14px;" onclick="saveConfigState(event); return false;">
                                <i class="fa-solid fa-floppy-disk me-2"></i> Apply Schedule Shifts
                            </button>
                        </div>
                    </form>
                </div>

            </main>
        </div>
        <script>
            // --- Global State Variables ---
            let renderedHoursBase = parseFloat(localStorage.getItem('guest_renderedHours')) || 148.5;
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
                    borderLeft: `6px solid ${borderColor}`,
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

            function updateActiveDaysCount() {
                let count = 0;
                document.querySelectorAll('.days-selector .day-circle').forEach(circle => {
                    if (circle.classList.contains('active')) count++;
                });
                const txt = document.getElementById('activeDaysCountText');
                if (txt) txt.textContent = count;
            }

            function toggleDayCircle(element) {
                element.classList.toggle('active');
                updateActiveDaysCount();
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
                    localStorage.setItem('sw_startTimeStamp', Date.now() - (accumulatedSeconds * 1000));

                    dot.className = "indicator-dot status-online";
                    dot.style.backgroundColor = "";
                    label.textContent = "Clocked In & Tracking Time";
                    btn.className = "btn-attendance-action clock-out-state";
                    btn.innerHTML = '<i class="fa-solid fa-stop me-2"></i> Time Out';

                    timerCard.style.boxShadow = "0 0 15px rgba(16, 185, 129, 0.2)";
                    manualPane.style.opacity = "0.5";
                    manualPane.style.pointerEvents = "none";

                    stopwatchInterval = setInterval(incrementStopwatchRuntime, 1000);
                } else {
                    activeTimerRunning = false;
                    clearInterval(stopwatchInterval);

                    const computedHoursEarned = accumulatedSeconds / 3600;
                    renderedHoursBase += computedHoursEarned;
                    localStorage.setItem('guest_renderedHours', renderedHoursBase);

                    accumulatedSeconds = 0;
                    localStorage.removeItem('sw_active');
                    localStorage.removeItem('sw_startTimeStamp');

                    dot.className = "indicator-dot status-offline";
                    dot.style.backgroundColor = "";
                    label.textContent = "Not Clocked In";
                    btn.className = "btn-attendance-action clock-in-state";
                    btn.innerHTML = '<i class="fa-solid fa-play me-2"></i> Time In';
                    document.getElementById('liveTimerDisplay').textContent = "00:00:00";

                    timerCard.style.boxShadow = "none";
                    manualPane.style.opacity = "1";
                    manualPane.style.pointerEvents = "auto";

                    showCustomToast(`Attendance session stored! Added +${computedHoursEarned.toFixed(2)} hours.`, "success");
                    recalculateProgressEngine();
                }
            }

            function incrementStopwatchRuntime() {
                let cachedStamp = parseInt(localStorage.getItem('sw_startTimeStamp'));
                if (cachedStamp && !isNaN(cachedStamp)) {
                    accumulatedSeconds = Math.floor((Date.now() - cachedStamp) / 1000);
                } else {
                    accumulatedSeconds++;
                }
                if (isNaN(accumulatedSeconds) || accumulatedSeconds < 0) accumulatedSeconds = 0;
                let h = Math.floor(accumulatedSeconds / 3600);
                let m = Math.floor((accumulatedSeconds % 3600) / 60);
                let s = accumulatedSeconds % 60;
                let hrs = h < 10 ? '0' + h : h;
                let mins = m < 10 ? '0' + m : m;
                let secs = s < 10 ? '0' + s : s;
                document.getElementById('liveTimerDisplay').textContent = hrs + ':' + mins + ':' + secs;
                    }

                    function restoreTimerSessionOnLoad() {
                        if (localStorage.getItem('sw_active') === 'true') {
                            activeTimerRunning = true;
                            const cachedStamp = parseInt(localStorage.getItem('sw_startTimeStamp'));
                            accumulatedSeconds = Math.floor((Date.now() - cachedStamp) / 1000);

                            const dot = document.getElementById('statusIndicatorDot');
                            dot.className = "indicator-dot status-online";
                            dot.style.backgroundColor = "";
                            document.getElementById('statusIndicatorText').textContent = "Clocked In & Tracking Time";

                            const btn = document.getElementById('btnAttendanceToggle');
                            btn.className = "btn-attendance-action clock-out-state";
                            btn.innerHTML = '<i class="fa-solid fa-stop me-2"></i> Time Out';

                            document.getElementById('attendanceSimulatorCard').style.boxShadow = "0 0 15px rgba(16, 185, 129, 0.2)";
                            const manualPane = document.getElementById('manualTaskLogPane');
                            manualPane.style.opacity = "0.5";
                            manualPane.style.pointerEvents = "none";

                            incrementStopwatchRuntime();
                            stopwatchInterval = setInterval(incrementStopwatchRuntime, 1000);
                        }
                    }

                    function handleManualLogSubmission(event) {
                        event.preventDefault();
                        if (activeTimerRunning)
                            return;

                        const hoursInput = parseFloat(document.getElementById('sandboxLogHours').value) || 0;

                        if (hoursInput <= 0) {
                            showCustomToast("Please specify a valid count of entry hours.", "error");
                            return;
                        }

                        const fileInput = document.getElementById('attendance-photo');
                        if (!fileInput.files || fileInput.files.length === 0) {
                            showCustomToast("Proof of Attendance is required.", "error");
                            return;
                        }

                        renderedHoursBase += hoursInput;
                        localStorage.setItem('guest_renderedHours', renderedHoursBase);

                        document.getElementById('sandboxLogForm').reset();
                        document.getElementById('photo-preview-name').textContent = "";
                        recalculateProgressEngine();

                        showCustomToast("Attendance was submitted to your coordinator.", "success");
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
                        document.querySelectorAll('.days-selector .day-circle').forEach(circle => {
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
                        document.querySelectorAll('.days-selector .day-circle').forEach(circle => {
                            if (circle.classList.contains('active')) {
                                activeWeekdays.push(parseInt(circle.getAttribute('data-day')));
                            }
                        });

                        let excludeHolidays = document.getElementById('excludeHolidaysHidden').value === "true";

                        for (let i = 0; i < firstDayIndex; i++) {
                            const filler = document.createElement('div');
                            filler.className = "calendar-day filler text-muted p-1";
                            filler.innerHTML = "&nbsp;";
                            surface.appendChild(filler);
                        }

                        for (let day = 1; day <= totalDaysInMonth; day++) {
                            const dayCell = document.createElement('div');
                            dayCell.className = "calendar-day p-1 rounded border";
                            dayCell.textContent = day;

                            let evaluationDate = new Date(calendarYear, calendarMonth, day);
                            let evalISOStr = calendarYear + '-' + String(calendarMonth + 1).padStart(2, '0') + '-' + String(day).padStart(2, '0');

                            if (excludeHolidays && phHolidays2026.includes(evalISOStr)) {
                                dayCell.classList.add('bg-danger', 'text-white');
                            } else if (evalISOStr === projectedEndDateISO) {
                                dayCell.classList.add('bg-success', 'text-white', 'fw-bold');
                            } else if (activeWeekdays.includes(evaluationDate.getDay())) {
                                dayCell.style.backgroundColor = "rgba(59, 130, 246, 0.15)";
                                dayCell.style.color = "#2563eb";
                            } else {
                                dayCell.classList.add('bg-light', 'text-muted');
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
                        document.querySelectorAll('.days-selector .day-circle').forEach(circle => {
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
                            document.querySelectorAll('.days-selector .day-circle').forEach(circle => {
                                let val = parseInt(circle.getAttribute('data-day'));
                                if (activeDays.includes(String(val)) || activeDays.includes(val)) {
                                    circle.classList.add('active');
                                } else {
                                    circle.classList.remove('active');
                                }
                            });
                            updateActiveDaysCount();
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

                        document.querySelectorAll('.days-selector .day-circle').forEach(circle => {
                            let d = parseInt(circle.getAttribute('data-day'));
                            if (d >= 1 && d <= 5) {
                                circle.classList.add('active');
                            } else {
                                circle.classList.remove('active');
                            }
                        });
                        updateActiveDaysCount();

                        showCustomToast("Configuration attributes reset to factory defaults.", "success");
                        recalculateProgressEngine();
                    }
        </script>
    </body>
</html>
