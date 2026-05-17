<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="model.User"%>
<%
    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);
    User user = (User) session.getAttribute("user");
    if (user == null) { response.sendRedirect("login.jsp"); return; }
    String fullName = user.getFullName();
    if (fullName == null || fullName.trim().isEmpty()) fullName = "Intern";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Intern Dashboard | OJT Monitor</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/guest.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
</head>
<body>
<div class="dashboard-wrapper">

    <!-- ======== SIDEBAR ======== -->
    <aside class="sidebar">
        <div class="brand-name"><i class="fa-solid fa-layer-group"></i> Active Learning</div>
        <nav class="sidebar-nav">
            <a class="nav-item active" id="navDashboard" onclick="switchTab('dashboard')">
                <i class="fa-solid fa-chart-pie"></i> Dashboard
            </a>
            <a class="nav-item" id="navConfig" onclick="switchTab('config')">
                <i class="fa-solid fa-sliders"></i> Configuration
            </a>
        </nav>
        <a class="logout" href="LogoutServlet"><i class="fa-solid fa-right-from-bracket"></i> Log Out</a>
    </aside>

    <!-- ======== MAIN CONTENT ======== -->
    <div class="main-content">

        <!-- TOP BAR with Profile Chip (Task 3) -->
        <div class="top-bar">
            <div class="page-header">
                <h1><i class="fa-solid fa-graduation-cap"></i> Intern's Dashboard</h1>
                <p>Live Analytics & Performance Tracker</p>
            </div>
            <div class="user-profile">
                <div class="profile-chip">
                    <span><%= fullName %></span>
                    <img src="https://ui-avatars.com/api/?name=<%= java.net.URLEncoder.encode(fullName, "UTF-8") %>&background=d63384&color=fff&size=80" alt="Avatar">
                </div>
            </div>
        </div>

        <!-- ================ DASHBOARD TAB ================ -->
        <div class="tab-content active" id="tabDashboard">

            <!-- Completion Banner -->
            <div class="completion-banner">
                <small>Estimated Completion Date</small>
                <div class="date" id="completionDate">Calculating...</div>
            </div>

            <!-- Stats Row -->
            <div class="stats-row">
                <div class="stat-card yellow">
                    <span class="label">Total Rendered Hours</span>
                    <div class="value" id="statRendered">0h</div>
                </div>
                <div class="stat-card pink">
                    <span class="label">Remaining Hours</span>
                    <div class="value" id="statRemaining">400h</div>
                </div>
                <div class="stat-card green">
                    <span class="label">Target Goal</span>
                    <div class="value" id="statTarget">400h</div>
                </div>
                <div class="stat-card red">
                    <span class="label">Completion Rate</span>
                    <div class="value" id="statCompletion">0%</div>
                </div>
            </div>

            <!-- Progress Bar -->
            <div class="progress-section">
                <div class="progress-header">
                    <h4>Overall Track Progress</h4>
                    <span id="progressPercent">0%</span>
                </div>
                <div class="progress-track">
                    <div class="progress-fill" id="progressFill" style="width:0%"></div>
                </div>
            </div>

            <!-- Middle Row -->
            <div class="middle-row">

                <!-- Attendance Simulator (Task 5) -->
                <div class="card-panel">
                    <h3>Daily Attendance Simulator</h3>
                    <div class="attendance-status">
                        <span class="status-dot inactive" id="statusDot"></span>
                        <span id="statusText">Not Clocked In</span>
                    </div>
                    <div class="timer-display" id="timerDisplay">00:00:00</div>
                    <button class="btn-timein" id="timerBtn" onclick="toggleTimer()">
                        <i class="fa-solid fa-play"></i> <span>Time In</span>
                    </button>
                    <p class="timer-note">*Optional: Use this timer if you want to track runtime parameters natively.</p>
                </div>

                <!-- Task Entry Log (Task 4) -->
                <div class="card-panel">
                    <h3>Simulate Task Entry Log</h3>
                    <div class="task-form-group">
                        <label>Hours Spent on Task</label>
                        <input type="number" id="taskHours" min="0.5" max="24" step="0.5" placeholder="e.g. 7.5">
                    </div>
                    <div class="task-form-group">
                        <label>Proof of Attendance *</label>
                        <div class="drop-zone" id="dropZone">
                            <input type="file" id="fileInput" accept="image/png,image/jpeg,image/jpg">
                            <div class="drop-zone-icon"><i class="fa-solid fa-camera"></i></div>
                            <p class="drop-zone-text">Click or drag to <strong>add attachment</strong> (photo)</p>
                            <p class="drop-zone-hint">Supports PNG, JPG, or JPEG</p>
                            <p class="file-name" id="fileName" style="display:none"></p>
                        </div>
                    </div>
                    <button class="btn-inject" id="injectBtn" onclick="injectHours()">
                        <i class="fa-solid fa-paper-plane"></i> Inject Simulation Hours
                    </button>
                </div>

                <!-- Mini Calendar -->
                <div class="card-panel">
                    <div class="calendar-header">
                        <h3 id="calendarTitle">May 2026</h3>
                        <div class="calendar-nav">
                            <button onclick="changeMonth(-1)"><i class="fa-solid fa-chevron-left"></i></button>
                            <button onclick="changeMonth(1)"><i class="fa-solid fa-chevron-right"></i></button>
                        </div>
                    </div>
                    <div class="calendar-grid" id="calendarGrid"></div>
                </div>
            </div>
        </div>

        <!-- ================ CONFIGURATION TAB (Task 1 — SPA, no server redirect) ================ -->
        <div class="tab-content" id="tabConfig">
            <div class="config-header">
                <div>
                    <h2><i class="fa-solid fa-sliders"></i> Internship Setup Configuration</h2>
                    <p>Customize your target goals and weekly work shifts to update your live progress metric.</p>
                </div>
                <button class="btn-reset" onclick="resetDefaults()"><i class="fa-solid fa-rotate-left"></i> Reset Defaults</button>
            </div>

            <div class="config-grid">
                <!-- Internship Goals -->
                <div class="config-card goals">
                    <h4>Internship Goals</h4>
                    <div class="config-form-row">
                        <div class="config-field">
                            <label>Target Hours</label>
                            <input type="number" id="cfgTargetHours" value="400" min="100" max="2000">
                        </div>
                        <div class="config-field">
                            <label>Start Date</label>
                            <input type="date" id="cfgStartDate">
                        </div>
                    </div>
                </div>

                <!-- Load & Holiday -->
                <div class="config-card load">
                    <h4>Load & Holiday</h4>
                    <div class="slider-group">
                        <label style="font-size:0.72rem;font-weight:700;text-transform:uppercase;letter-spacing:0.8px;color:#6c757d;white-space:nowrap;">Hours Per Day</label>
                        <input type="range" id="cfgHoursPerDay" min="1" max="12" value="8" oninput="updateSliderLabel()">
                        <span class="slider-value" id="sliderLabel">8h</span>
                    </div>
                    <div class="toggle-row">
                        <span>Exclude PH Holidays (2026)?</span>
                        <div class="toggle-switch">
                            <button class="toggle-option active-yes" id="holYes" onclick="setHoliday(true)"><i class="fa-solid fa-lock"></i> Yes</button>
                            <button class="toggle-option" id="holNo" onclick="setHoliday(false)"><i class="fa-solid fa-lock-open"></i> No</button>
                        </div>
                    </div>
                </div>

                <!-- Work Schedule (Task 2 — fixed toggle) -->
                <div class="config-card schedule">
                    <h4>Work Schedule</h4>
                    <p style="font-size:0.72rem;font-weight:700;text-transform:uppercase;letter-spacing:0.8px;color:#6c757d;margin-bottom:12px;">Weekly Work Days</p>
                    <div class="day-toggle-row" id="dayToggleRow">
                        <button class="day-btn weekend-btn" data-day="0" onclick="toggleDay(this)">S</button>
                        <button class="day-btn active" data-day="1" onclick="toggleDay(this)">M</button>
                        <button class="day-btn active" data-day="2" onclick="toggleDay(this)">T</button>
                        <button class="day-btn active" data-day="3" onclick="toggleDay(this)">W</button>
                        <button class="day-btn active" data-day="4" onclick="toggleDay(this)">T</button>
                        <button class="day-btn active" data-day="5" onclick="toggleDay(this)">F</button>
                        <button class="day-btn weekend-btn" data-day="6" onclick="toggleDay(this)">S</button>
                    </div>
                    <p class="day-count-note" id="dayCountNote">&#11088; 5 selected active days count as projectable work terms</p>
                </div>

                <!-- Projection Mode -->
                <div class="config-card projection">
                    <h4>Projection Mode</h4>
                    <div class="projection-toggle">
                        <button class="proj-option" id="projManual" onclick="setProjection('manual')"><i class="fa-solid fa-pen"></i> Manual</button>
                        <button class="proj-option active" id="projAuto" onclick="setProjection('auto')"><i class="fa-solid fa-wand-magic-sparkles"></i> Auto</button>
                    </div>
                </div>
            </div>

            <div class="config-footer">
                <span class="config-note">Simulating analytics metrics live inside your browser session</span>
                <button class="btn-apply" onclick="applyConfig()"><i class="fa-solid fa-check"></i> Apply Schedule Shifts</button>
            </div>
        </div>
    </div>
</div>

<!-- Toast -->
<div class="toast" id="toast"></div>

<script>
// ======================== STATE ========================
const STATE_KEY = 'ojt_intern_state';
let state = loadState();

function defaultState() {
    return {
        renderedHours: 0, targetHours: 400, hoursPerDay: 8,
        startDate: new Date().toISOString().split('T')[0],
        activeDays: [1,2,3,4,5], excludeHolidays: true,
        projectionMode: 'auto', timerRunning: false,
        timerStart: null, timerElapsed: 0, taskLogs: [], logDates: []
    };
}
function loadState() {
    try { const s = localStorage.getItem(STATE_KEY); return s ? Object.assign(defaultState(), JSON.parse(s)) : defaultState(); }
    catch(e) { return defaultState(); }
}
function saveState() { localStorage.setItem(STATE_KEY, JSON.stringify(state)); }

// ======================== TAB SWITCHING (Task 1 fix) ========================
function switchTab(tab) {
    document.getElementById('tabDashboard').classList.toggle('active', tab === 'dashboard');
    document.getElementById('tabConfig').classList.toggle('active', tab === 'config');
    document.getElementById('navDashboard').classList.toggle('active', tab === 'dashboard');
    document.getElementById('navConfig').classList.toggle('active', tab === 'config');
}

// ======================== STATS & PROGRESS (Task 4) ========================
function updateDashboard() {
    const rendered = state.renderedHours;
    const target = state.targetHours;
    const remaining = Math.max(0, target - rendered);
    const pct = target > 0 ? Math.min(100, (rendered / target) * 100) : 0;

    document.getElementById('statRendered').textContent = rendered.toFixed(1) + 'h';
    document.getElementById('statRemaining').textContent = remaining.toFixed(1) + 'h';
    document.getElementById('statTarget').textContent = target + 'h';
    document.getElementById('statCompletion').textContent = pct.toFixed(1) + '%';
    document.getElementById('progressPercent').textContent = pct.toFixed(1) + '%';
    document.getElementById('progressFill').style.width = pct + '%';
    updateCompletionDate();
    saveState();
}

function updateCompletionDate() {
    const remaining = Math.max(0, state.targetHours - state.renderedHours);
    if (remaining <= 0) { document.getElementById('completionDate').textContent = 'Completed!'; return; }
    const dailyHours = state.hoursPerDay;
    const activeDays = state.activeDays;
    if (!activeDays.length || dailyHours <= 0) { document.getElementById('completionDate').textContent = 'N/A'; return; }
    let hoursLeft = remaining, d = new Date();
    while (hoursLeft > 0) {
        d.setDate(d.getDate() + 1);
        if (activeDays.includes(d.getDay())) hoursLeft -= dailyHours;
    }
    const opts = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' };
    document.getElementById('completionDate').textContent = d.toLocaleDateString('en-US', opts);
}

// ======================== ATTENDANCE TIMER (Task 5) ========================
let timerInterval = null;

function toggleTimer() {
    if (!state.timerRunning) {
        state.timerRunning = true;
        state.timerStart = Date.now() - (state.timerElapsed || 0);
        saveState();
        startTimerTick();
        document.getElementById('statusDot').className = 'status-dot active';
        document.getElementById('statusText').textContent = 'Clocked In & Tracking Time';
        const btn = document.getElementById('timerBtn');
        btn.className = 'btn-timeout';
        btn.innerHTML = '<i class="fa-solid fa-stop"></i> <span>Time Out</span>';
    } else {
        state.timerRunning = false;
        state.timerElapsed = Date.now() - state.timerStart;
        clearInterval(timerInterval); timerInterval = null;
        saveState();
        document.getElementById('statusDot').className = 'status-dot inactive';
        document.getElementById('statusText').textContent = 'Not Clocked In';
        const btn = document.getElementById('timerBtn');
        btn.className = 'btn-timein';
        btn.innerHTML = '<i class="fa-solid fa-play"></i> <span>Time In</span>';
        showToast('Timer stopped. Elapsed time recorded.', 'info');
    }
}

function startTimerTick() {
    timerInterval = setInterval(() => {
        const elapsed = Date.now() - state.timerStart;
        const s = Math.floor(elapsed / 1000);
        const h = String(Math.floor(s / 3600)).padStart(2, '0');
        const m = String(Math.floor((s % 3600) / 60)).padStart(2, '0');
        const sec = String(s % 60).padStart(2, '0');
        document.getElementById('timerDisplay').textContent = h + ':' + m + ':' + sec;
    }, 1000);
}

function restoreTimer() {
    if (state.timerRunning && state.timerStart) {
        startTimerTick();
        document.getElementById('statusDot').className = 'status-dot active';
        document.getElementById('statusText').textContent = 'Clocked In & Tracking Time';
        const btn = document.getElementById('timerBtn');
        btn.className = 'btn-timeout';
        btn.innerHTML = '<i class="fa-solid fa-stop"></i> <span>Time Out</span>';
    } else if (state.timerElapsed > 0) {
        const s = Math.floor(state.timerElapsed / 1000);
        const h = String(Math.floor(s / 3600)).padStart(2, '0');
        const m = String(Math.floor((s % 3600) / 60)).padStart(2, '0');
        const sec = String(s % 60).padStart(2, '0');
        document.getElementById('timerDisplay').textContent = h + ':' + m + ':' + sec;
    }
}

// ======================== FILE UPLOAD (Task 4) ========================
let selectedFile = null;

function initDropZone() {
    const dz = document.getElementById('dropZone');
    const fi = document.getElementById('fileInput');

    dz.addEventListener('click', () => fi.click());
    dz.addEventListener('dragover', (e) => { e.preventDefault(); dz.classList.add('drag-over'); });
    dz.addEventListener('dragleave', () => dz.classList.remove('drag-over'));
    dz.addEventListener('drop', (e) => {
        e.preventDefault(); dz.classList.remove('drag-over');
        if (e.dataTransfer.files.length) handleFile(e.dataTransfer.files[0]);
    });
    fi.addEventListener('change', () => { if (fi.files.length) handleFile(fi.files[0]); });
}

function handleFile(file) {
    const valid = ['image/png', 'image/jpeg', 'image/jpg'];
    if (!valid.includes(file.type)) { showToast('Only PNG, JPG, or JPEG files are allowed.', 'error'); return; }
    selectedFile = file;
    const dz = document.getElementById('dropZone');
    dz.classList.add('has-file');
    document.getElementById('fileName').style.display = 'block';
    document.getElementById('fileName').textContent = '\u2705 ' + file.name;
    dz.querySelector('.drop-zone-text').style.display = 'none';
    dz.querySelector('.drop-zone-hint').style.display = 'none';
}

function resetDropZone() {
    selectedFile = null;
    const dz = document.getElementById('dropZone');
    dz.classList.remove('has-file');
    document.getElementById('fileName').style.display = 'none';
    document.getElementById('fileInput').value = '';
    dz.querySelector('.drop-zone-text').style.display = '';
    dz.querySelector('.drop-zone-hint').style.display = '';
}

function injectHours() {
    const hoursInput = document.getElementById('taskHours');
    const hours = parseFloat(hoursInput.value);
    if (!hours || hours <= 0) { showToast('Please enter valid hours (> 0).', 'error'); return; }
    if (!selectedFile) { showToast('Please attach a proof photo before submitting.', 'error'); return; }

    state.renderedHours = Math.round((state.renderedHours + hours) * 100) / 100;
    const today = new Date().toISOString().split('T')[0];
    if (!state.logDates.includes(today)) state.logDates.push(today);
    state.taskLogs.push({ date: today, hours: hours, file: selectedFile.name });
    saveState();
    updateDashboard();
    renderCalendar();
    hoursInput.value = '';
    resetDropZone();
    showToast('Added ' + hours + 'h \u2014 progress updated!', 'success');
}

// ======================== CALENDAR ========================
let calendarDate = new Date();

function renderCalendar() {
    const grid = document.getElementById('calendarGrid');
    const year = calendarDate.getFullYear(), month = calendarDate.getMonth();
    const today = new Date();
    const firstDay = new Date(year, month, 1).getDay();
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const monthNames = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    document.getElementById('calendarTitle').textContent = monthNames[month] + ' ' + year;

    let html = ['S','M','T','W','T','F','S'].map(d => '<div class="day-label">' + d + '</div>').join('');
    for (let i = 0; i < firstDay; i++) html += '<div class="day-cell empty"></div>';
    for (let d = 1; d <= daysInMonth; d++) {
        const dateStr = year + '-' + String(month+1).padStart(2,'0') + '-' + String(d).padStart(2,'0');
        const isToday = (d === today.getDate() && month === today.getMonth() && year === today.getFullYear());
        const hasLog = state.logDates.includes(dateStr);
        const dow = new Date(year, month, d).getDay();
        const isWeekend = (dow === 0 || dow === 6);
        let cls = 'day-cell';
        if (isToday) cls += ' today';
        if (hasLog) cls += ' has-log';
        if (isWeekend && !hasLog && !isToday) cls += ' weekend';
        html += '<div class="' + cls + '">' + d + '</div>';
    }
    grid.innerHTML = html;
}

function changeMonth(delta) { calendarDate.setMonth(calendarDate.getMonth() + delta); renderCalendar(); }

// ======================== DAY TOGGLE (Task 2 fix) ========================
function toggleDay(btn) {
    btn.classList.toggle('active');
    updateActiveDays();
}

function updateActiveDays() {
    state.activeDays = [];
    document.querySelectorAll('.day-btn').forEach(btn => {
        if (btn.classList.contains('active')) state.activeDays.push(parseInt(btn.dataset.day));
    });
    const count = state.activeDays.length;
    document.getElementById('dayCountNote').innerHTML = '&#11088; ' + count + ' selected active days count as projectable work terms';
    saveState();
}

function restoreDayToggles() {
    document.querySelectorAll('.day-btn').forEach(btn => {
        const day = parseInt(btn.dataset.day);
        btn.classList.toggle('active', state.activeDays.includes(day));
    });
    updateActiveDays();
}

// ======================== CONFIG (Task 1) ========================
function updateSliderLabel() {
    const v = document.getElementById('cfgHoursPerDay').value;
    document.getElementById('sliderLabel').textContent = v + 'h';
}

function setHoliday(val) {
    state.excludeHolidays = val;
    document.getElementById('holYes').className = 'toggle-option' + (val ? ' active-yes' : '');
    document.getElementById('holNo').className = 'toggle-option' + (!val ? ' active-no' : '');
    saveState();
}

function setProjection(mode) {
    state.projectionMode = mode;
    document.getElementById('projManual').className = 'proj-option' + (mode === 'manual' ? ' active' : '');
    document.getElementById('projAuto').className = 'proj-option' + (mode === 'auto' ? ' active' : '');
    saveState();
}

function applyConfig() {
    state.targetHours = parseInt(document.getElementById('cfgTargetHours').value) || 400;
    state.startDate = document.getElementById('cfgStartDate').value || state.startDate;
    state.hoursPerDay = parseInt(document.getElementById('cfgHoursPerDay').value) || 8;
    saveState();
    updateDashboard();
    showToast('Configuration applied successfully!', 'success');
    switchTab('dashboard');
}

function resetDefaults() {
    const fresh = defaultState();
    Object.assign(state, fresh);
    saveState();
    document.getElementById('cfgTargetHours').value = 400;
    document.getElementById('cfgStartDate').value = fresh.startDate;
    document.getElementById('cfgHoursPerDay').value = 8;
    updateSliderLabel();
    setHoliday(true);
    setProjection('auto');
    restoreDayToggles();
    updateDashboard();
    renderCalendar();
    showToast('All settings reset to defaults.', 'info');
}

function restoreConfig() {
    document.getElementById('cfgTargetHours').value = state.targetHours;
    document.getElementById('cfgStartDate').value = state.startDate;
    document.getElementById('cfgHoursPerDay').value = state.hoursPerDay;
    updateSliderLabel();
    setHoliday(state.excludeHolidays);
    setProjection(state.projectionMode);
    restoreDayToggles();
}

// ======================== TOAST ========================
function showToast(msg, type) {
    const t = document.getElementById('toast');
    const icons = { success: 'fa-circle-check', error: 'fa-circle-xmark', info: 'fa-circle-info' };
    t.className = 'toast ' + (type || 'info');
    t.innerHTML = '<i class="fa-solid ' + (icons[type] || icons.info) + '"></i> ' + msg;
    t.classList.add('show');
    setTimeout(() => t.classList.remove('show'), 3500);
}

// ======================== INIT ========================
document.addEventListener('DOMContentLoaded', () => {
    updateDashboard();
    restoreTimer();
    restoreConfig();
    initDropZone();
    renderCalendar();
});
</script>
</body>
</html>