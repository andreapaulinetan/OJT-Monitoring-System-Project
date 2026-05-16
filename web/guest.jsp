<%@page contentType="text/html" pageEncoding="UTF-8"%>
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

                <div id="dashboard-view" class="view-panel active-view">
                    <header class="content-header">
                        <div class="header-title-group">
                            <div class="title-with-icon">
                                <i class="fa-solid fa-graduation-cap header-icon"></i>
                                <h1>Intern's Dashboard</h1>
                            </div>
                            <p class="welcome-text">Live Analytics & Performance Tracker</p>
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
                        <div class="stat-card card-yellow">
                            <span class="card-metric-title">TOTAL RENDERED HOURS</span>
                            <div class="value" id="renderedHoursDisplay">148.5h</div>
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

                        <div class="card simulate-task-card">
                            <h3>Simulate Task Entry Log</h3>

                            <div class="form-group">
                                <label>Hours Spent on Task</label>
                                <input type="text" name="simulatedHours" class="form-control" placeholder="e.g. 7.5" value="${param.simulatedHours}">
                            </div>

                            <div class="form-group attachment-container">
                                <label>Proof of Attendance <span class="required-asterisk">*</span></label>
                                <div class="photo-dropzone" onclick="document.getElementById('attendance-photo').click();">
                                    <i class="fa-solid fa-camera"></i>
                                    <p>Click or drag to <strong>add attachment (photo)</strong></p>
                                    <span class="file-hint">Supports PNG, JPG, or JPEG</span>
                                    <input type="file" id="attendance-photo" name="attendancePhoto" accept="image/*" hidden>
                                </div>
                                <div id="photo-preview-name" class="photo-preview-text"></div>
                            </div>

                            <button type="submit" class="btn-inject-hours">
                                <i class="fa-solid fa-paper-plane"></i> Inject Simulation Hours
                            </button>
                        </div>

                        <div class="dashboard-pane layout-calendar-pane">
                            <div class="calendar-nav-header d-flex justify-content-between align-items-center mb-3">
                                <h3 class="calendar-month-title m-0 h5 font-bold" id="calendarMonthTitle">May 2026</h3>
                                <div class="calendar-action-arrows">
                                    <button type="button" class="btn btn-sm btn-outline-secondary py-0 px-2" onclick="adjustCalendarMonth(-1)"><i class="fa-solid fa-chevron-left"></i></button>
                                    <button type="button" class="btn btn-sm btn-outline-secondary py-0 px-2" onclick="adjustCalendarMonth(1)"><i class="fa-solid fa-chevron-right"></i></button>
                                </div>
                            </div>

                            <div class="calendar-grid-days-header d-grid text-center font-bold text-muted mb-2" style="grid-template-columns: repeat(7, 1fr); font-size: 11px;">
                                <div>S</div><div>M</div><div>T</div><div>W</div><div>T</div><div>F</div><div>S</div>
                            </div>

                            <div class="calendar-days-surface" id="calendarDaysSurface"></div>

                            <div class="calendar-legends-footer d-flex gap-2 flex-wrap text-muted justify-content-between mt-3" style="font-size: 11px;">
                                <div class="legend-item"><span class="badge bg-danger p-1 me-1">&nbsp;</span>Holiday</div>
                                <div class="legend-item"><span class="badge bg-secondary p-1 me-1">&nbsp;</span>Off</div>
                                <div class="legend-item"><span class="badge p-1 me-1" style="background-color: rgba(59, 130, 246, 0.15)">&nbsp;</span>Scheduled</div>
                                <div class="legend-item"><span class="badge bg-success p-1 me-1">&nbsp;</span>Target End</div>
                            </div>
                        </div>
                    </div>
                </div>

                <div id="coordinator-view" class="view-panel">
                    <header class="content-header">
                        <div class="header-title-group">
                            <div class="title-with-icon">
                                <i class="fa-solid fa-sliders header-icon"></i>
                                <h1>Internship Setup Configuration</h1>
                            </div>
                            <p class="welcome-text">Customize your target goals and weekly work shifts to update your live progress matrix.</p>
                        </div>
                        <button type="button" class="reset-btn" onclick="resetConfigurationForm()"><i class="fa-solid fa-rotate-left"></i> Reset Defaults</button>
                    </header>

                    <form id="goalsSetupForm" onsubmit="saveConfigState(event)">
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
                                            <i class="fa-solid fa-calendar-xmark"></i> Yes
                                        </button>
                                        <button type="button" id="holidayBtnNo" class="toggle-btn" onclick="setHolidayExclusion(false)">
                                            <i class="fa-solid fa-calendar-check"></i> No
                                        </button>
                                    </div>
                                </div>
                            </div>

                            <div class="card card-pink">
                                <h3 class="card-title">Work Schedule</h3>
                                <label class="field-label-small">WEEKLY WORK DAYS</label>
                                <div class="days-selector">
                                    <div class="day-circle disabled" data-day="0" onclick="toggleDayCircle(this)">S</div>
                                    <div class="day-circle active" data-day="1" onclick="toggleDayCircle(this)">M</div>
                                    <div class="day-circle active" data-day="2" onclick="toggleDayCircle(this)">T</div>
                                    <div class="day-circle active" data-day="3" onclick="toggleDayCircle(this)">W</div>
                                    <div class="day-circle active" data-day="4" onclick="toggleDayCircle(this)">T</div>
                                    <div class="day-circle active" data-day="5" onclick="toggleDayCircle(this)">F</div>
                                    <div class="day-circle disabled" data-day="6" onclick="toggleDayCircle(this)">S</div>
                                </div>
                                <div class="helper-text">
                                    <i class="fa-solid fa-star info-symbol"></i> Selected active days count as projectable work terms
                                </div>
                            </div>

                            <div class="card card-blue">
                                <h3 class="card-title">Projection Mode</h3>
                                <div class="mode-options">
                                    <input type="hidden" id="projectionModeHidden" value="Auto">
                                    <button type="button" id="projBtnManual" class="mode-btn" onclick="setProjectionMode('Manual')">
                                        <i class="fa-solid fa-hand"></i><span>Manual</span>
                                    </button>
                                    <button type="button" id="projBtnAuto" class="mode-btn active" onclick="setProjectionMode('Auto')">
                                        <i class="fa-solid fa-layer-group"></i><span>Auto</span>
                                    </button>
                                </div>
                            </div>
                        </div>

                        <div class="form-actions-row">
                            <div class="info-footer-status">
                                <p>Simulating analytics metrics live inside your <span class="session-badge">browser session</span></p>
                            </div>

                            <button type="submit" class="btn-apply-shifts">
                                <i class="fa-solid fa-floppy-disk"></i> Apply Schedule Shifts
                            </button>
                        </div>
                    </form>
                </div>

            </main>
        </div>

        <script>
            // State Storage
            let renderedHoursBase = parseFloat(localStorage.getItem('guest_renderedHours')) || 148.5;
            let calendarYear = 2026;
            let calendarMonth = 4; // May (Zero-indexed representation)

            let stopwatchInterval = null;
            let activeTimerRunning = false;
            let accumulatedSeconds = 0;
            let projectedEndDateISO = "";

            // Philippine Official Holiday Exclusions Dataset 2026
            const phHolidays2026 = [
                "2026-01-01", "2026-02-17", "2026-04-02", "2026-04-03",
                "2026-04-09", "2026-05-01", "2026-06-12", "2026-08-31",
                "2026-11-01", "2026-11-30", "2026-12-25", "2026-12-30"
            ];
            const monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

            window.onload = function () {
                loadConfigState();
                restoreTimerSessionOnLoad();
                recalculateProgressEngine();
            };

            function switchTab(tabId, navId) {
                document.querySelectorAll('.view-panel').forEach(view => view.classList.remove('active-view'));
                document.querySelectorAll('.nav-menu .nav-item').forEach(btn => btn.classList.remove('active'));
                document.getElementById(tabId).classList.add('active-view');
                document.getElementById(navId).classList.add('active');
            }

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
                element.classList.toggle('disabled');
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

            /* Optional Attendance Timer Logic Section */
            function toggleTimerAttendanceSession() {
                const dot = document.getElementById('statusIndicatorDot');
                const label = document.getElementById('statusIndicatorText');
                const btn = document.getElementById('btnAttendanceToggle');
                const manualPane = document.getElementById('manualTaskLogPane');
                const timerCard = document.getElementById('attendanceSimulatorCard');

                if (!activeTimerRunning) {
                    // Turn stopwatch sequence operational
                    activeTimerRunning = true;
                    localStorage.setItem('sw_active', 'true');
                    localStorage.setItem('sw_startTimeStamp', Date.now() - (accumulatedSeconds * 1000));

                    dot.className = "status-dot green";
                    label.textContent = "Clocked In & Tracking Time";
                    btn.className = "btn btn-danger w-100 py-2 fw-bold";
                    btn.innerHTML = '<i class="fa-solid fa-stop me-2"></i> Time Out';

                    // Style adjustments & input blocking
                    timerCard.classList.add('timer-active-card');
                    manualPane.classList.add('manual-disabled-overlay');

                    stopwatchInterval = setInterval(incrementStopwatchRuntime, 1000);
                } else {
                    // Turn stopwatch sequence off
                    activeTimerRunning = false;
                    clearInterval(stopwatchInterval);

                    // Convert duration run into hours logic fraction
                    const computedHoursEarned = accumulatedSeconds / 3600;
                    renderedHoursBase += computedHoursEarned;
                    localStorage.setItem('guest_renderedHours', renderedHoursBase);

                    // Wipe storage indices clear
                    accumulatedSeconds = 0;
                    localStorage.removeItem('sw_active');
                    localStorage.removeItem('sw_startTimeStamp');

                    dot.className = "status-dot red";
                    label.textContent = "Not Clocked In";
                    btn.className = "btn btn-success w-100 py-2 fw-bold";
                    btn.innerHTML = '<i class="fa-solid fa-play me-2"></i> Time In';
                    document.getElementById('liveTimerDisplay').textContent = "00:00:00";

                    timerCard.classList.remove('timer-active-card');
                    manualPane.classList.remove('manual-disabled-overlay');

                    alert(`Time frame captured successfully! Added: ${computedHoursEarned.toFixed(3)} hours to total logs.`);
                    recalculateProgressEngine();
                }
            }

            function incrementStopwatchRuntime() {
                const cachedStamp = parseInt(localStorage.getItem('sw_startTimeStamp'));
                if (cachedStamp) {
                    accumulatedSeconds = Math.floor((Date.now() - cachedStamp) / 1000);
                } else {
                    accumulatedSeconds++;
                }
                const hrs = String(Math.floor(accumulatedSeconds / 3600)).padStart(2, '0');
                const mins = String(Math.floor((accumulatedSeconds % 3600) / 60)).padStart(2, '0');
                const secs = String(accumulatedSeconds % 60).padStart(2, '0');
                document.getElementById('liveTimerDisplay').textContent = `${hrs}:${mins}:${secs}`;
                    }

                    function restoreTimerSessionOnLoad() {
                        if (localStorage.getItem('sw_active') === 'true') {
                            activeTimerRunning = true;
                            const cachedStamp = parseInt(localStorage.getItem('sw_startTimeStamp'));
                            accumulatedSeconds = Math.floor((Date.now() - cachedStamp) / 1000);

                            document.getElementById('statusIndicatorDot').className = "status-dot green";
                            document.getElementById('statusIndicatorText').textContent = "Clocked In & Tracking Time";

                            const btn = document.getElementById('btnAttendanceToggle');
                            btn.className = "btn btn-danger w-100 py-2 fw-bold";
                            btn.innerHTML = '<i class="fa-solid fa-stop me-2"></i> Time Out';

                            document.getElementById('attendanceSimulatorCard').classList.add('timer-active-card');
                            document.getElementById('manualTaskLogPane').classList.add('manual-disabled-overlay');

                            // Fire immediately to prevent layout shifts before the interval starts
                            incrementStopwatchRuntime();
                            stopwatchInterval = setInterval(incrementStopwatchRuntime, 1000);
                        }
                    }

                    function handleManualLogSubmission(event) {
                        event.preventDefault();
                        if (activeTimerRunning)
                            return; // Prevent submission if tracking with timer

                        const hoursInput = parseFloat(document.getElementById('sandboxLogHours').value) || 0;
                        renderedHoursBase += hoursInput;
                        localStorage.setItem('guest_renderedHours', renderedHoursBase);

                        document.getElementById('sandboxLogForm').reset();
                        recalculateProgressEngine();
                        alert("Simulated working log units processed!");
                    }

                    /* Timeline Analyzer Processing Architecture */
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
                            document.getElementById('projectedEndDateDisplay').textContent = "Set 'Auto' projection mode & check workdays to run projection simulation.";
                        } else {
                            let currentSimDate = new Date(startDateVal + "T00:00:00");
                            let today = new Date();
                            today.setHours(0, 0, 0, 0);

                            // If start date is in the past, simulate forward from the current calendar date
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

                        const excludeHolidays = document.getElementById('excludeHolidaysHidden').value === "true";
                        let hoursPerDay = document.getElementById('hoursSlider').value;

                        let todayDate = new Date();
                        let todayISO = todayDate.getFullYear() + '-' + String(todayDate.getMonth() + 1).padStart(2, '0') + '-' + String(todayDate.getDate()).padStart(2, '0');

                        for (let i = 0; i < firstDayIndex; i++) {
                            let emptyCell = document.createElement('div');
                            emptyCell.className = 'calendar-day-cell empty';
                            surface.appendChild(emptyCell);
                        }

                        for (let day = 1; day <= totalDaysInMonth; day++) {
                            let cell = document.createElement('div');
                            cell.className = 'calendar-day-cell';

                            let dayNumSpan = document.createElement('span');
                            dayNumSpan.textContent = day;
                            cell.appendChild(dayNumSpan);

                            let currentLoopDateObj = new Date(calendarYear, calendarMonth, day);
                            let formattedISODate = currentLoopDateObj.getFullYear() + '-' +
                                    String(currentLoopDateObj.getMonth() + 1).padStart(2, '0') + '-' +
                                    String(currentLoopDateObj.getDate()).padStart(2, '0');

                            let currentDayOfWeekIndex = currentLoopDateObj.getDay();
                            let isHoliday = excludeHolidays && phHolidays2026.includes(formattedISODate);
                            let isWorkingDay = activeWeekdays.includes(currentDayOfWeekIndex);

                            // Apply layout status descriptors
                            if (formattedISODate === todayISO) {
                                cell.classList.add('today');
                            }
                            if (formattedISODate === projectedEndDateISO) {
                                cell.classList.add('completion-day');
                            } else if (isHoliday) {
                                cell.classList.add('holiday');
                            } else if (!isWorkingDay) {
                                cell.classList.add('day-off');
                            } else {
                                cell.classList.add('scheduled');
                                let hoursSub = document.createElement('div');
                                hoursSub.className = 'hours-sub';
                                hoursSub.textContent = hoursPerDay + 'h';
                                cell.appendChild(hoursSub);
                            }
                            surface.appendChild(cell);
                        }
                    }

                    // LocalStorage State Handlers for Persistent Layout Mocking
                    function saveConfigState(e) {
                        e.preventDefault();
                        localStorage.setItem('config_targetHours', document.getElementById('inputTargetHours').value);
                        localStorage.setItem('config_startDate', document.getElementById('inputStartDate').value);
                        localStorage.setItem('config_hoursSlider', document.getElementById('hoursSlider').value);
                        localStorage.setItem('config_excludeHolidays', document.getElementById('excludeHolidaysHidden').value);
                        localStorage.setItem('config_projectionMode', document.getElementById('projectionModeHidden').value);

                        let selectedDays = [];
                        document.querySelectorAll('.days-selector .day-circle').forEach(circle => {
                            if (circle.classList.contains('active')) {
                                selectedDays.push(circle.getAttribute('data-day'));
                            }
                        });
                        localStorage.setItem('config_activeDays', JSON.stringify(selectedDays));
                        alert("Configuration states locked into LocalStorage matrix container!");
                        recalculateProgressEngine();
                    }

                    function loadConfigState() {
                        if (localStorage.getItem('config_targetHours')) {
                            document.getElementById('inputTargetHours').value = localStorage.getItem('config_targetHours');
                            document.getElementById('inputStartDate').value = localStorage.getItem('config_startDate');

                            let sliderVal = localStorage.getItem('config_hoursSlider');
                            document.getElementById('hoursSlider').value = sliderVal;
                            document.getElementById('sliderValDisplay').textContent = sliderVal + 'h';

                            let holidayFlag = localStorage.getItem('config_excludeHolidays') === "true";
                            setHolidayExclusion(holidayFlag);

                            let projMode = localStorage.getItem('config_projectionMode') || "Auto";
                            setProjectionMode(projMode);

                            let activeDays = JSON.parse(localStorage.getItem('config_activeDays') || "[]");
                            document.querySelectorAll('.days-selector .day-circle').forEach(circle => {
                                let dayVal = circle.getAttribute('data-day');
                                if (activeDays.includes(dayVal)) {
                                    circle.className = "day-circle active";
                                } else {
                                    circle.className = "day-circle disabled";
                                }
                            });
                        }
                    }

                    function resetConfigurationForm() {
                        localStorage.clear();
                        renderedHoursBase = 148.5;
                        location.reload();
                    }
        </script>
    </body>
</html>
