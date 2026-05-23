<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@page import="model.User"%>
<%@page import="model.UserDAO"%>
<%@page import="model.ActivitySubmission"%>
<%@page import="java.util.List"%>
<%@page import="util.TabSessionHelper"%>
<%@page import="util.CsrfUtil"%>
<%
    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    String tabId = TabSessionHelper.getTabId(request);
    User user = TabSessionHelper.getUser(session, tabId);
    if (user == null || !"admin".equalsIgnoreCase(user.getRole())) {
        response.sendRedirect("login.jsp?err=unauthorized");
        return;
    }

    List<User> internList = UserDAO.getAllInterns(getServletContext());
    List<ActivitySubmission> submissionList = UserDAO.getAllSubmissions(getServletContext());

    int totalInterns = (internList != null) ? internList.size() : 0;
    int pendingLogs = UserDAO.getPendingLogsCount(getServletContext());

    // Calculate actual completion hours and rates
    double avgCompletionRate = 0.0;
    java.util.Map<String, Double> internHoursMap = new java.util.HashMap<String, Double>();
    if (internList != null) {
        for (User u : internList) {
            internHoursMap.put(u.getId(), u.getBaselineHours());
        }
    }
    if (submissionList != null) {
        for (ActivitySubmission sub : submissionList) {
            if ("Approved".equalsIgnoreCase(sub.getStatus())) {
                String internId = sub.getUserId();
                if (internHoursMap.containsKey(internId)) {
                    double hrs = util.PdfReportHelper.extractHoursFromDescription(sub.getDescription());
                    internHoursMap.put(internId, internHoursMap.get(internId) + hrs);
                }
            }
        }
    }

    java.util.Map<String, List<Double>> officeRates = new java.util.HashMap<String, List<Double>>();
    java.util.Map<String, List<Double>> roleRates = new java.util.HashMap<String, List<Double>>();
    if (internList != null && !internList.isEmpty()) {
        double totalSum = 0.0;
        for (User u : internList) {
            String office = u.getOffice();
            if (office == null || office.trim().isEmpty()) {
                office = "Unassigned Office";
            }
            String role = u.getRole();
            if (role == null || role.trim().isEmpty()) {
                role = "Unassigned Role";
            }
            
            double hours = internHoursMap.containsKey(u.getId()) ? internHoursMap.get(u.getId()) : 0.0;
            double rate = (hours / 400.0) * 100.0;
            if (rate > 100.0) rate = 100.0;
            totalSum += rate;
            
            if (!officeRates.containsKey(office)) {
                officeRates.put(office, new java.util.ArrayList<Double>());
            }
            officeRates.get(office).add(rate);
            
            if (!roleRates.containsKey(role)) {
                roleRates.put(role, new java.util.ArrayList<Double>());
            }
            roleRates.get(role).add(rate);
        }
        avgCompletionRate = totalSum / internList.size();
    }

    java.util.Map<String, Double> avgOfficeRates = new java.util.TreeMap<String, Double>();
    for (java.util.Map.Entry<String, List<Double>> entry : officeRates.entrySet()) {
        double sum = 0;
        for (double r : entry.getValue()) sum += r;
        avgOfficeRates.put(entry.getKey(), sum / entry.getValue().size());
    }

    java.util.Map<String, Double> avgRoleRates = new java.util.TreeMap<String, Double>();
    for (java.util.Map.Entry<String, List<Double>> entry : roleRates.entrySet()) {
        double sum = 0;
        for (double r : entry.getValue()) sum += r;
        avgRoleRates.put(entry.getKey(), sum / entry.getValue().size());
    }

    String reqView = request.getParameter("view");
    if (reqView == null || reqView.trim().isEmpty()) {
        reqView = "dashboard";
    }
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <script src="${pageContext.request.contextPath}/js/tabSession.js"></script>
        <title>Coordinator's Dashboard | Active Learning</title>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
        <link rel="stylesheet" type="text/css" href="${pageContext.request.contextPath}/css/admin.css">

        <style>
            /* Hide select column unless table has active class */
            #internTable .col-select {
                display: none !important;
            }
            #internTable.delete-mode-active .col-select {
                display: table-cell !important;
            }
            /* Layout Correction Engine for Gorgeous Tables */
            .data-table tbody tr {
                border-bottom: 1px solid #ebeef2 !important; /* Soft lines between records */
                transition: background-color 0.2s ease;
            }
            .data-table tbody tr:hover {
                background-color: #f8fafc !important; /* Premium subtle hover effect */
            }
            .data-table td {
                padding: 14px 12px !important; /* Balanced row padding */
                vertical-align: middle !important;
                color: #333e48;
                font-size: 14px;
            }
            /* Normalized Intern ID & Tracker Typography Size Constraints */
            .col-id, .intern-row td:first-child {
                font-size: 13px !important;
                font-weight: 600 !important;
                color: #4a5568 !important;
                font-family: 'SFMono-Regular', Consolas, monospace !important;
            }
            /* Tamed Submission ID - Code Badge Layout Fix */
            .sub-id-badge {
                font-size: 12px !important;
                font-weight: 600 !important;
                color: #2d3748 !important;
                background-color: #edf2f7 !important;
                padding: 5px 10px !important;
                border-radius: 6px !important;
                border: 1px solid #e2e8f0 !important;
                font-family: 'SFMono-Regular', Consolas, monospace !important;
                display: inline-block;
                letter-spacing: 0.3px;
            }
            /* Supporting File Overflow Wrap Protection */
            .file-badge-container {
                max-width: 170px !important; /* Keeps column compact */
                white-space: nowrap !important;
                overflow: hidden !important;
                text-overflow: ellipsis !important; /* Beautiful automated string truncation */
                display: inline-block !important;
                vertical-align: middle !important;
            }
            .data-table th {
                font-size: 13px !important;
                text-transform: uppercase;
                letter-spacing: 0.5px;
                color: #718096;
                font-weight: 700;
                padding-bottom: 12px !important;
            }
            .intern-row {
                cursor: pointer;
            }
            #modalFilePreview:hover {
                transform: scale(1.02);
            }

            /* Force chat input visibility - high specificity overrides */
            #chatConversationArea {
                display: flex !important;
                flex-direction: column !important;
                height: 100% !important;
                min-height: 0 !important;
                overflow: hidden !important;
            }
            #chatConversationArea .chat-messages-container {
                flex: 1 1 0 !important;
                min-height: 0 !important;
                overflow-y: auto !important;
            }
            #chatConversationArea .chat-input-bar {
                flex-shrink: 0 !important;
                display: flex !important;
                padding: 16px 24px !important;
                gap: 12px !important;
                border-top: 1px solid #e2e8f0 !important;
                background-color: #ffffff !important;
            }
            #chatConversationArea .chat-input-bar input {
                flex-grow: 1 !important;
                border: 1px solid #cbd5e1 !important;
                border-radius: 8px !important;
                padding: 10px 16px !important;
                font-size: 0.92rem !important;
                outline: none !important;
                min-width: 0 !important;
            }
            #chatConversationArea .chat-templates {
                flex-shrink: 0 !important;
            }
            #chatConversationArea .chat-header {
                flex-shrink: 0 !important;
            }
        </style>
    </head>
    <body>
        <div class="dashboard-wrapper">
            <aside class="sidebar">
                <div class="sidebar-header"><h4 class="brand-name">Active Learning</h4></div>
                <nav class="sidebar-nav">
                    <a href="#" id="nav-dashboard" class="nav-item <%= "dashboard".equals(reqView) ? "active" : "" %>" onclick="switchView('dashboard')">
                        <i class="fas fa-th-large"></i> Dashboard <span class="badge bg-danger ms-2 d-none" id="sidebarDashboardUnreadBadge">0</span>
                    </a>
                    <a href="#" id="nav-interns" class="nav-item <%= "intern-management".equals(reqView) ? "active" : "" %>" onclick="switchView('intern-management')">
                        <i class="fas fa-users"></i> Intern Management
                    </a>
                    <a href="#" id="nav-logs" class="nav-item <%= "log-review".equals(reqView) ? "active" : "" %>" onclick="switchView('log-review')">
                        <i class="fas fa-file-alt"></i> Log Review <span class="badge bg-danger ms-2" id="sidebarPendingBadge"><%= pendingLogs%></span>
                    </a>
                    <a href="#" id="nav-reports" class="nav-item <%= "report-center".equals(reqView) ? "active" : "" %>" onclick="switchView('report-center')">
                        <i class="fas fa-chart-bar"></i> Report Center
                    </a>
                    <a href="#" id="nav-audit" class="nav-item <%= "audit-trail".equals(reqView) ? "active" : "" %>" onclick="switchView('audit-trail')">
                        <i class="fas fa-history"></i> Audit Trail
                    </a>
                </nav>
                <div class="sidebar-footer">
                    <a href="LogoutServlet" class="logout-btn"><i class="fas fa-sign-out-alt"></i> Log out</a>
                </div>
            </aside>
            <div class="sidebar-overlay" onclick="toggleSidebar()"></div>

            <main class="main-content">
                <header class="top-bar">
                    <div class="d-flex align-items-center gap-3">
                        <button type="button" id="sidebarToggle" class="btn btn-outline-secondary" onclick="toggleSidebar()">
                            <i class="fas fa-bars"></i>
                        </button>
                        <h2 class="page-title" id="mainPageTitle">Coordinator's Dashboard</h2>
                    </div>
                    <div class="search-container" style="display: <%= "dashboard".equals(reqView) ? "none" : "block" %>;">
                        <input type="text" id="internSearch" class="search-input" placeholder="Search across columns..." onkeyup="resetToFirstPageAndFilter()">
                    </div>
                    <div class="user-profile">
                        <div class="profile-chip">
                            <span><%= user.getDisplayName()%></span>
                            <img src="https://ui-avatars.com/api/?name=<%= user.getDisplayName()%>&background=d63384&color=fff" alt="Admin">
                        </div>
                    </div>
                </header>

                <div id="dashboard-view" class="view-section" style="display: <%= "dashboard".equals(reqView) ? "block" : "none" %>;">
                    <section class="stats-row mb-4">
                        <div class="stat-card yellow"><span class="label">Total Interns</span><h1 class="value"><%= totalInterns%></h1></div>
                        <div class="stat-card pink"><span class="label">Pending Logs</span><h1 class="value" id="dashboardPendingCount"><%= pendingLogs%></h1></div>
                        <div class="stat-card green"><span class="label">Completion Rate</span><h1 class="value"><%= String.format("%.1f", avgCompletionRate) %>%</h1></div>
                    </section>

                    <!-- Sub-tabs for Dashboard -->
                    <div class="dashboard-sub-nav mb-4">
                        <button type="button" class="sub-tab-btn active" id="btn-sub-overview" onclick="switchSubDashboard('sub-overview')">
                            <i class="fas fa-chart-line me-1"></i> Overview & Stats
                        </button>
                        <button type="button" class="sub-tab-btn" id="btn-sub-announcements" onclick="switchSubDashboard('sub-announcements')">
                            <i class="fas fa-bullhorn me-1"></i> Announcements
                        </button>
                        <button type="button" class="sub-tab-btn" id="btn-sub-messaging" onclick="switchSubDashboard('sub-messaging')">
                            <i class="fas fa-comments me-1"></i> Direct Messaging <span class="badge bg-danger ms-1 d-none" id="dashboardUnreadBadge">0</span>
                        </button>
                    </div>

                    <!-- Sub-view: Overview & Stats -->
                    <div id="sub-overview" class="sub-dashboard-panel">
                        <div class="overview-stats-grid">
                            <div class="stat-bar-card">
                                <h4 class="stat-bar-title"><i class="fas fa-building text-primary"></i> Office Completion Rates</h4>
                                <%
                                    if (avgOfficeRates.isEmpty()) {
                                %>
                                <p class="text-muted text-center py-3">No office stats available yet.</p>
                                <%
                                    } else {
                                        for (java.util.Map.Entry<String, Double> entry : avgOfficeRates.entrySet()) {
                                            String officeName = entry.getKey();
                                            double pct = entry.getValue();
                                            String formattedPct = String.format("%.1f", pct);
                                %>
                                <div class="stat-bar-item">
                                    <div class="stat-bar-info">
                                        <span class="stat-bar-name"><%= officeName %></span>
                                        <span class="stat-bar-percent"><%= formattedPct %>%</span>
                                    </div>
                                    <div class="stat-bar-progress">
                                        <div class="stat-bar-fill" style="width: <%= formattedPct %>%;"></div>
                                    </div>
                                </div>
                                <%
                                        }
                                    }
                                %>
                            </div>
                            <div class="stat-bar-card">
                                <h4 class="stat-bar-title"><i class="fas fa-user-tag text-primary"></i> Role Completion Rates</h4>
                                <%
                                    if (avgRoleRates.isEmpty()) {
                                %>
                                <p class="text-muted text-center py-3">No role stats available yet.</p>
                                <%
                                    } else {
                                        for (java.util.Map.Entry<String, Double> entry : avgRoleRates.entrySet()) {
                                            String roleName = entry.getKey();
                                            double pct = entry.getValue();
                                            String formattedPct = String.format("%.1f", pct);
                                %>
                                <div class="stat-bar-item">
                                    <div class="stat-bar-info">
                                        <span class="stat-bar-name"><%= roleName %></span>
                                        <span class="stat-bar-percent"><%= formattedPct %>%</span>
                                    </div>
                                    <div class="stat-bar-progress">
                                        <div class="stat-bar-fill" style="width: <%= formattedPct %>%;"></div>
                                    </div>
                                </div>
                                <%
                                        }
                                    }
                                %>
                            </div>
                        </div>
                    </div>

                    <!-- Sub-view: Announcements -->
                    <div id="sub-announcements" class="sub-dashboard-panel" style="display: none;">
                        <div class="row">
                            <div class="col-md-5">
                                <div class="announcement-composer-card">
                                    <h4 class="mb-3" style="font-weight: 700; color: #1e293b;"><i class="fas fa-bullhorn text-pink me-2"></i>Compose Announcement</h4>
                                    <form id="announcementForm" onsubmit="submitAnnouncement(event)">
                                        <div class="mb-3">
                                            <label class="form-label fw-bold small text-muted">Title</label>
                                            <input type="text" id="annTitle" class="form-control" placeholder="E.g., System Maintenance Schedule" required>
                                        </div>
                                        <div class="mb-3">
                                            <label class="form-label fw-bold small text-muted">Message Content</label>
                                            <textarea id="annContent" class="form-control" rows="4" placeholder="Write your message details here..." required></textarea>
                                        </div>
                                        <div class="mb-3">
                                            <label class="form-label fw-bold small text-muted">Target Audience</label>
                                            <select id="annTargetType" class="form-select" onchange="handleTargetTypeChange()" required>
                                                <option value="ALL">All Interns</option>
                                                <option value="OFFICE">Specific Office</option>
                                                <option value="ROLE">Specific Role</option>
                                                <option value="CITY">Specific City</option>
                                            </select>
                                        </div>
                                        <div class="mb-3 d-none" id="annTargetValueGroup">
                                            <label class="form-label fw-bold small text-muted" id="annTargetValueLabel">Target Value</label>
                                            <select id="annTargetValue" class="form-select"></select>
                                        </div>
                                        <button type="submit" class="btn text-white w-100 fw-bold" style="background-color: var(--accent-pink); height: 44px; border-radius: 8px;"><i class="fas fa-paper-plane me-1"></i>Publish Announcement</button>
                                    </form>
                                </div>
                            </div>
                            <div class="col-md-7">
                                <div class="announcement-history-card">
                                    <h4 class="mb-3" style="font-weight: 700; color: #1e293b;"><i class="fas fa-history text-muted me-2"></i>Announcement History</h4>
                                    <div class="table-responsive" style="max-height: 400px; overflow-y: auto;">
                                        <table class="table table-hover align-middle" style="font-size: 0.88rem;">
                                            <thead>
                                                <tr>
                                                    <th>Date</th>
                                                    <th>Target</th>
                                                    <th>Title</th>
                                                    <th class="text-end">Action</th>
                                                </tr>
                                            </thead>
                                            <tbody id="announcementHistoryBody">
                                                <tr>
                                                    <td colspan="4" class="text-center py-4 text-muted">Loading announcements...</td>
                                                </tr>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Sub-view: Direct Messaging -->
                    <div id="sub-messaging" class="sub-dashboard-panel" style="display: none;">
                        <div class="chat-layout">
                            <div class="chat-contacts-list">
                                <div class="chat-contacts-header">
                                    <i class="fas fa-address-book text-muted"></i> Contacts
                                </div>
                                <div class="chat-search-container" style="padding: 12px; border-bottom: 1px solid #e2e8f0; background-color: #f8fafc;">
                                    <div class="position-relative">
                                        <i class="fas fa-search position-absolute top-50 start-0 translate-middle-y ms-3 text-muted"></i>
                                        <input type="text" id="chatSearchInput" class="form-control form-control-sm" placeholder="Search contacts..." onkeyup="filterContacts()" style="padding-left: 32px; border-radius: 20px; border: 1px solid #cbd5e1; font-size: 0.85rem; box-shadow: none;">
                                    </div>
                                </div>
                                <div class="chat-contacts-container" id="chatContactsList">
                                    <div class="text-center py-4 text-muted">Loading contacts...</div>
                                </div>
                            </div>
                            <div class="chat-conversation-area" id="chatConversationArea">
                                <div class="chat-empty-state">
                                    <i class="fas fa-comments fa-3x"></i>
                                    <h5>Select a Contact</h5>
                                    <p>Choose an intern or another coordinator from the contact list to start chatting in real-time.</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div id="intern-management-view" class="view-section" style="display: <%= "intern-management".equals(reqView) ? "block" : "none" %>;">
                    <section class="table-section p-0 overflow-hidden">
                        <div class="section-header p-4 pb-2 d-flex justify-content-between align-items-center">
                            <h3>Master Intern Accounts Registry (DBMS 1)</h3>
                            <div class="header-btns">
                                <button class="btn-add" onclick="openAddInternModal()">Add New Intern</button>
                                <button class="btn-import" id="btnDeleteSelected" onclick="handleDeleteModeClick()" style="background-color: #6c757d; border-color: #6c757d; color: white;"><i class="fas fa-trash-alt me-1"></i> Delete Intern</button>
                            </div>
                        </div>

                        <div class="table-responsive px-4">
                            <table class="data-table" id="internTable">
                                <thead>
                                    <tr>
                                        <th class="col-select" style="width: 45px; text-align: center;"><input type="checkbox" id="selectAllInterns" onclick="toggleSelectAllInterns(this)"></th>
                                        <th class="col-id" onclick="sortInternTable(1)" style="cursor:pointer;">Intern ID <i class="fas fa-sort"></i></th>
                                        <th class="col-name" onclick="sortInternTable(2)" style="cursor:pointer;">Intern Profile <i class="fas fa-sort"></i></th>
                                        <th class="col-uni">
                                            <div class="filter-dropdown">
                                                <div class="filter-trigger" id="uniLabel"><span>University</span> <i class="fas fa-university"></i></div>
                                                <div class="filter-content" id="uniOptions"></div>
                                            </div>
                                        </th>
                                        <th class="col-city">
                                            <div class="filter-dropdown">
                                                <div class="filter-trigger" id="cityLabel"><span>City</span> <i class="fas fa-map-marker-alt"></i></div>
                                                <div class="filter-content" id="cityOptions"></div>
                                            </div>
                                        </th>
                                        <th class="col-role">
                                            <div class="filter-dropdown">
                                                <div class="filter-trigger" id="roleLabel"><span>Role</span> <i class="fas fa-user-tag"></i></div>
                                                <div class="filter-content" id="roleOptions"></div>
                                            </div>
                                        </th>
                                        <th class="col-office">
                                            <div class="filter-dropdown">
                                                <div class="filter-trigger" id="officeLabel"><span>Office</span> <i class="fas fa-building"></i></div>
                                                <div class="filter-content" id="officeOptions"></div>
                                            </div>
                                        </th>
                                        <th class="col-actions">Actions</th>
                                    </tr>
                                </thead>
                                <tbody id="internTableBody">
                                    <% if (internList != null && !internList.isEmpty()) {
                                            for (User u : internList) {
                                                String dispId = u.getId();
                                                   if (dispId != null && dispId.matches("\\d+")) {
                                                       dispId = "INT2026-7" + String.format("%04d", Integer.parseInt(dispId));
                                                   }
                                                   String formattedCreatedAt = "N/A";
                                                   if (u.getCreatedAt() != null) {
                                                       java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("MMMM dd, yyyy — hh:mm:ss a");
                                                       formattedCreatedAt = sdf.format(u.getCreatedAt());
                                                   }
                                                   String latestFile = "";
                                                   String latestFileOrig = "";
                                                   if (submissionList != null) {
                                                       for (ActivitySubmission sub : submissionList) {
                                                           if (sub.getUserId().equals(u.getId())) {
                                                               latestFile = sub.getSupportingFile() != null ? sub.getSupportingFile().replace("\"", "&quot;") : "";
                                                               latestFileOrig = sub.getOriginalFileName() != null ? sub.getOriginalFileName().replace("\"", "&quot;") : "";
                                                           }
                                                       }
                                                   }
                                    %>
                                    <tr class="intern-row"
                                        data-id="<%= u.getId()%>"
                                        data-dispid="<%= dispId%>"
                                        data-firstname="<%= u.getFirstName()%>"
                                        data-middlename="<%= u.getMiddleName() != null ? u.getMiddleName() : ""%>"
                                        data-lastname="<%= u.getLastName()%>"
                                        data-email="<%= u.getEmail()%>"
                                        data-university="<%= u.getUniversity()%>"
                                        data-city="<%= (u.getCity() != null) ? u.getCity() : ""%>"
                                        data-role="<%= (u.getRole() != null) ? u.getRole() : ""%>"
                                        data-rolecode="<%= (u.getRoleCode() != null) ? u.getRoleCode() : ""%>"
                                        data-office="<%= u.getOffice()%>"
                                        data-createdat="<%= formattedCreatedAt%>"
                                        data-latestfile="<%= latestFile %>"
                                        data-latestfileorig="<%= latestFileOrig %>"
                                        data-avatarpath="<%= u.getAvatarPath() != null ? u.getAvatarPath() : "" %>"
                                        onclick="openInternDetailsModal(this)">
                                        <td class="col-select" style="text-align: center;" onclick="event.stopPropagation();"><input type="checkbox" class="intern-select-chk" value="<%= u.getId()%>"></td>
                                        <td class="col-id"><%= dispId%></td>
                                        <td class="col-name">
                                            <div class="name-container">
                                                <strong><%= u.getFirstName()%> <%= u.getLastName()%></strong>
                                                <small class="text-primary"><%= u.getEmail()%></small>
                                            </div>
                                        </td>
                                        <td class="col-uni"><%= u.getUniversity()%></td>
                                        <td class="col-city"><%= (u.getCity() != null) ? u.getCity() : "N/A"%></td>
                                        <td class="col-role"><%= (u.getRole() != null) ? u.getRole() : "N/A"%></td>
                                        <td class="col-office"><%= u.getOffice()%></td>
                                        <td class="col-actions" onclick="event.stopPropagation();">
                                            <div class="d-flex gap-1 flex-nowrap">
                                                <a href="${pageContext.request.contextPath}/ReportServlet?type=INTERN_RECORD&internId=<%= u.getId()%>&tabId=<%= tabId %>" class="btn btn-sm" style="border-radius: 8px; font-size: 0.75rem; padding: 4px 8px; display: inline-flex; align-items: center; gap: 3px; text-decoration: none; background-color: var(--brand-pink, #d63384); color: white; border: none;" title="Download Record">
                                                    <i class="fas fa-download"></i>
                                                </a>
                                                <button class="btn btn-sm btn-outline-warning" style="border-radius: 8px; font-size: 0.75rem; padding: 4px 8px;" onclick="confirmResetHours('<%= u.getId()%>', '<%= u.getFirstName()%> <%= u.getLastName()%>')" title="Reset Simulated Hours">
                                                    <i class="fas fa-history"></i>
                                                </button>
                                                <button class="btn btn-sm btn-outline-primary" style="border-radius: 8px; font-size: 0.75rem; padding: 4px 8px;" onclick="openEditInternModal(this.closest('.intern-row'))" title="Edit Intern">
                                                    <i class="fas fa-pen"></i>
                                                </button>
                                                <% if (u.getId() != null && !u.getId().equalsIgnoreCase(user.getId())) { %>
                                                <button class="btn btn-sm btn-outline-danger" style="border-radius: 8px; font-size: 0.75rem; padding: 4px 8px;" onclick="openDeleteInternModal('<%= u.getId()%>', '<%= u.getFirstName()%> <%= u.getLastName()%>')" title="Delete Intern">
                                                    <i class="fas fa-trash-alt"></i>
                                                </button>
                                                <% } else { %>
                                                <button class="btn btn-sm btn-outline-secondary" style="border-radius: 8px; font-size: 0.75rem; padding: 4px 8px;" disabled title="Cannot Delete Self">
                                                    <i class="fas fa-trash-alt"></i>
                                                </button>
                                                <% } %>
                                            </div>
                                        </td>
                                    </tr>
                                    <% }
                                        } %>
                                </tbody>
                            </table>
                        </div>

                        <div class="pagination-container d-flex justify-content-between align-items-center px-4 py-3 border-top bg-light">
                            <div class="pagination-info text-muted small">
                                Showing <span id="pageStart" class="fw-semibold">0</span> to <span id="pageEnd" class="fw-semibold">0</span> of <span id="totalEntries" class="fw-semibold">0</span> entries
                            </div>
                            <nav aria-label="Intern Table Navigation">
                                <ul class="pagination pagination-sm mb-0 gap-1" id="paginationButtons">
                                </ul>
                            </nav>
                            <div class="page-size-selector d-flex align-items-center gap-2 small text-muted">
                                <span>Show</span>
                                <div class="filter-dropdown" style="width: auto; min-width: 80px;">
                                    <div class="filter-trigger" id="internSizeLabel" style="border-radius: 8px; height: 34px; background: white; border: 1px solid #dee2e6; padding: 0 12px;">
                                        <span>50</span> <i class="fas fa-chevron-down solid dynamic-arrow ms-2" style="font-size: 10px; color: #6c757d;"></i>
                                    </div>
                                    <div class="filter-content" style="min-width: 90px; text-align: center;">
                                        <div class="filter-option" onclick="customChangePageSize(10, 'intern')">10</div>
                                        <div class="filter-option" onclick="customChangePageSize(15, 'intern')">15</div>
                                        <div class="filter-option" onclick="customChangePageSize(20, 'intern')">20</div>
                                        <div class="filter-option" onclick="customChangePageSize(50, 'intern')">50</div>
                                        <div class="filter-option" onclick="customChangePageSize(100, 'intern')">100</div>
                                    </div>
                                </div>
                                <span>entries</span>
                            </div>
                        </div>
                    </section>
                </div>

                <div id="log-review-view" class="view-section" style="display: <%= "log-review".equals(reqView) ? "block" : "none" %>;">
                    <section class="table-section p-0 overflow-hidden">
                        <div class="section-header p-4 pb-2 d-flex justify-content-between align-items-center">
                            <div>
                                <h3>OJT Activity Submissions Queue (DBMS 2)</h3>
                                <p class="text-muted small">Verify submitted proof files and update processing workflow operational status flags inside MySQL parameters storage.</p>
                            </div>
                            <button class="btn btn-sm btn-outline-dark" onclick="refreshLogReview()">
                                <i class="fas fa-sync-alt me-1"></i> Refresh
                            </button>
                        </div>
                        <div class="table-responsive px-4">
                            <table class="data-table" id="logReviewTable">
                                <thead class="sticky-top bg-white">
                                    <tr>
                                        <th onclick="sortLogTable(0)" style="cursor:pointer;">Submitted on <i class="fas fa-sort"></i></th>
                                        <th onclick="sortLogTable(1)" style="cursor:pointer;">Submission ID <i class="fas fa-sort"></i></th>
                                        <th onclick="sortLogTable(2)" style="cursor:pointer;">Intern Name <i class="fas fa-sort"></i></th>
                                        <th>Attached Files</th>
                                        <th class="col-office">
                                            <div class="filter-dropdown">
                                                <div class="filter-trigger" id="logOfficeLabel"><span>Assigned Office</span> <i class="fas fa-building"></i></div>
                                                <div class="filter-content" id="logOfficeOptions"></div>
                                            </div>
                                        </th>
                                        <th class="col-status">
                                            <div class="filter-dropdown">
                                                <div class="filter-trigger" id="statusLabel" onclick="sortLogTable(5)" style="cursor:pointer;">
                                                    <span>Status</span> <i class="fas fa-sort"></i>
                                                </div>
                                                <div class="filter-content" onclick="event.stopPropagation();">
                                                    <div class="filter-option reset-opt" onclick="applyLogStatusFilter('', 'Status')">All Status</div>
                                                    <div class="filter-option" onclick="applyLogStatusFilter('Pending', 'Pending')">Pending</div>
                                                    <div class="filter-option" onclick="applyLogStatusFilter('Approved', 'Approved')">Approved</div>
                                                    <div class="filter-option" onclick="applyLogStatusFilter('Rejected', 'Rejected')">Rejected</div>
                                                </div>
                                            </div>
                                        </th>
                                    </tr>
                                </thead>
                                <tbody id="logReviewTableBody">
                                    <% if (submissionList != null && !submissionList.isEmpty()) {
                                            for (ActivitySubmission s : submissionList) {
                                                String subId = s.getSubmissionId();
                                                String internId = s.getUserId();
                                                String internName = s.getInternName();
                                                String dispInternId = internId;
                                                String mappedId = model.UserDAO.mapToDerbyInternId(internId);
                                                 if (mappedId != null && mappedId.matches("\\d+")) {
                                                     dispInternId = "INT2026-7" + String.format("%04d", Integer.parseInt(mappedId));
                                                 }
                                                String dateSub = s.getDateSubmitted().toString();
                                                String desc = s.getDescription() != null ? s.getDescription().replace("'", "\\'") : "";
                                                String learnRef = s.getLearningReflection() != null ? s.getLearningReflection().replace("'", "\\'") : "";
                                                String origFile = s.getOriginalFileName();
                                                String suppFile = s.getSupportingFile();
                                                String office = s.getAssignedOffice();
                                                String status = (s.getStatus() != null) ? s.getStatus() : "Pending";
                                    %>
                                    <tr class="log-row log-row-clickable" onclick="openLogDetailsModal('<%= subId%>', '<%= dispInternId%>', '<%= internName%>', '<%= dateSub%>', '<%= desc%>', '<%= learnRef%>', '<%= origFile%>', '<%= suppFile%>')">
                                        <td><%= dateSub%></td>
                                        <td><span class="sub-id-badge"><%= subId%></span></td>
                                        <td><%= internName%></td>
                                        <td>
                                            <span class="badge bg-light text-dark border file-badge-container" title="<%= origFile%>">
                                                <i class="fas fa-paperclip me-1 text-primary"></i> <%= origFile%>
                                            </span>
                                        </td>
                                        <td><small class="text-muted"><%= office%></small></td>
                                        <td onclick="event.stopPropagation();">
                                            <select class="form-select form-select-sm status-select status-<%= status%>" onchange="updateLogStatusDatabase('<%= subId%>', this)">
                                                <option value="Pending" <%= "Pending".equalsIgnoreCase(status) ? "selected" : ""%>>Pending</option>
                                                <option value="Approved" <%= "Approved".equalsIgnoreCase(status) ? "selected" : ""%>>Approved</option>
                                                <option value="Rejected" <%= "Rejected".equalsIgnoreCase(status) ? "selected" : ""%>>Rejected</option>
                                            </select>
                                        </td>
                                    </tr>
                                    <% }
                                        } %>
                                </tbody>
                            </table>
                        </div>

                        <div class="pagination-container d-flex justify-content-between align-items-center px-4 py-3 border-top bg-light">
                            <div class="pagination-info text-muted small">
                                Showing <span id="logPageStart" class="fw-semibold">0</span> to <span id="logPageEnd" class="fw-semibold">0</span> of <span id="logTotalEntries" class="fw-semibold">0</span> entries
                            </div>
                            <nav aria-label="Log Queue Navigation">
                                <ul class="pagination pagination-sm mb-0 gap-1" id="logPaginationButtons">
                                </ul>
                            </nav>
                            <div class="page-size-selector d-flex align-items-center gap-2 small text-muted">
                                <span>Show</span>
                                <div class="filter-dropdown" style="width: auto; min-width: 80px;">
                                    <div class="filter-trigger" id="logSizeLabel" style="border-radius: 8px; height: 34px; background: white; border: 1px solid #dee2e6; padding: 0 12px;">
                                        <span>10</span> <i class="fas fa-chevron-down solid dynamic-arrow ms-2" style="font-size: 10px; color: #6c757d;"></i>
                                    </div>
                                    <div class="filter-content" style="min-width: 90px; text-align: center;">
                                        <div class="filter-option" onclick="customChangePageSize(10, 'log')">10</div>
                                        <div class="filter-option" onclick="customChangePageSize(15, 'log')">15</div>
                                        <div class="filter-option" onclick="customChangePageSize(20, 'log')">20</div>
                                        <div class="filter-option" onclick="customChangePageSize(50, 'log')">50</div>
                                        <div class="filter-option" onclick="customChangePageSize(100, 'log')">100</div>
                                    </div>
                                </div>
                                <span>entries</span>
                            </div>
                        </div>
                    </section>
                </div>

                <div id="report-center-view" class="view-section" style="display: <%= "report-center".equals(reqView) ? "block" : "none" %>;">
                    <section class="table-section p-0 overflow-hidden">
                        <div class="section-header p-4 pb-2">
                            <h3>PDF Report Compilation Hub</h3>
                            <p class="text-muted small">Generate and download PDF reports directly to your browser. All reports use landscape orientation with automatic pagination.</p>
                        </div>
                        <div class="p-4">
                            <div class="row g-3">
                                <!-- Report Card 1: User List -->
                                <div class="col-md-6 col-lg-3">
                                    <div class="card h-100 border-0 shadow-sm" style="border-radius: 12px;">
                                        <div class="card-body text-center p-4">
                                            <i class="fas fa-users fa-2x mb-3" style="color: #d63384;"></i>
                                            <h6 class="fw-bold mb-2">User List Report</h6>
                                            <p class="text-muted small mb-3">All registered users with roles. No passwords included. Marks current admin with *.</p>
                                            <button class="btn btn-sm btn-dark w-100" onclick="downloadReport('USERLIST')">
                                                <i class="fas fa-download me-1"></i> Download PDF
                                            </button>
                                        </div>
                                    </div>
                                </div>

                                <!-- Report Card 2: Admin Record -->
                                <div class="col-md-6 col-lg-3">
                                    <div class="card h-100 border-0 shadow-sm" style="border-radius: 12px;">
                                        <div class="card-body text-center p-4">
                                            <i class="fas fa-user-shield fa-2x mb-3" style="color: #d63384;"></i>
                                            <h6 class="fw-bold mb-2">Admin Record</h6>
                                            <p class="text-muted small mb-3">Your personal audit activity log — logins, logouts, and reports you generated.</p>
                                            <button class="btn btn-sm btn-dark w-100" onclick="downloadReport('ADMINRECORD')">
                                                <i class="fas fa-download me-1"></i> Download PDF
                                            </button>
                                        </div>
                                    </div>
                                </div>

                                <!-- Report Card 3: OJT Logs (with Date Range) -->
                                <div class="col-md-6 col-lg-3">
                                    <div class="card h-100 border-0 shadow-sm" style="border-radius: 12px;">
                                        <div class="card-body text-center p-4">
                                            <i class="fas fa-file-alt fa-2x mb-3" style="color: #d63384;"></i>
                                            <h6 class="fw-bold mb-2">OJT Logs Report</h6>
                                            <p class="text-muted small mb-2">Activity submissions from MySQL. Use date filters or leave blank for all records.</p>
                                            <div class="mb-2">
                                                <input type="date" id="ojtFromDate" class="form-control form-control-sm mb-1" placeholder="From">
                                                <input type="date" id="ojtToDate" class="form-control form-control-sm" placeholder="To">
                                            </div>
                                            <button class="btn btn-sm btn-dark w-100" onclick="downloadOjtReport()">
                                                <i class="fas fa-download me-1"></i> Download PDF
                                            </button>
                                        </div>
                                    </div>
                                </div>

                                <!-- Report Card 4: Audit Log -->
                                <div class="col-md-6 col-lg-3">
                                    <div class="card h-100 border-0 shadow-sm" style="border-radius: 12px;">
                                        <div class="card-body text-center p-4">
                                            <i class="fas fa-shield-alt fa-2x mb-3" style="color: #d63384;"></i>
                                            <h6 class="fw-bold mb-2">Audit Log Report</h6>
                                            <p class="text-muted small mb-3">Full system audit trail from PostgreSQL (DBMS 3). All login/logout/report events.</p>
                                            <button class="btn btn-sm btn-dark w-100" onclick="downloadReport('AUDITLOG')">
                                                <i class="fas fa-download me-1"></i> Download PDF
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </section>
                </div>

                <div id="audit-trail-view" class="view-section" style="display: <%= "audit-trail".equals(reqView) ? "block" : "none" %>;">
                    <section class="table-section p-0 overflow-hidden">
                        <div class="section-header p-4 pb-2 d-flex justify-content-between align-items-center">
                            <div>
                                <h3>System Security Audit Trail (DBMS 3 — PostgreSQL)</h3>
                                <p class="text-muted small">Real-time authentication cycles, report generation events, and session tracking from the ojt_auditdb database.</p>
                            </div>
                            <button class="btn btn-sm btn-outline-dark" onclick="loadAuditTrail()">
                                <i class="fas fa-sync-alt me-1"></i> Refresh
                            </button>
                        </div>
                        <div class="table-responsive px-4">
                            <table class="data-table" id="auditTable">
                                <thead>
                                    <tr>
                                        <th style="cursor:pointer;" onclick="sortAuditTable(0)">Timestamp <i class="fas fa-sort"></i></th>
                                        <th style="cursor:pointer;" onclick="sortAuditTable(1)">User ID <i class="fas fa-sort"></i></th>
                                        <th style="cursor:pointer;" onclick="sortAuditTable(2)">Username <i class="fas fa-sort"></i></th>
                                        <th style="cursor:pointer;" onclick="sortAuditTable(3)">Action <i class="fas fa-sort"></i></th>
                                        <th>Details</th>
                                        <th>IP Address</th>
                                    </tr>
                                </thead>
                                <tbody id="auditTableBody">
                                    <tr><td colspan="6" class="text-center text-muted py-4"><i class="fas fa-spinner fa-spin me-2"></i>Loading audit data from PostgreSQL...</td></tr>
                                </tbody>
                            </table>
                        </div>

                        <div class="pagination-container d-flex justify-content-between align-items-center px-4 py-3 border-top bg-light">
                            <div class="pagination-info text-muted small">
                                Showing <span id="auditPageStart" class="fw-semibold">0</span> to <span id="auditPageEnd" class="fw-semibold">0</span> of <span id="auditTotalEntries" class="fw-semibold">0</span> entries
                            </div>
                            <nav aria-label="Audit Trail Navigation">
                                <ul class="pagination pagination-sm mb-0 gap-1" id="auditPaginationButtons">
                                </ul>
                            </nav>
                            <div class="page-size-selector d-flex align-items-center gap-2 small text-muted">
                                <span>Show</span>
                                <div class="filter-dropdown" style="width: auto; min-width: 80px;">
                                    <div class="filter-trigger" id="auditSizeLabel" style="border-radius: 8px; height: 34px; background: white; border: 1px solid #dee2e6; padding: 0 12px;">
                                        <span>10</span> <i class="fas fa-chevron-down solid dynamic-arrow ms-2" style="font-size: 10px; color: #6c757d;"></i>
                                    </div>
                                    <div class="filter-content" style="min-width: 90px; text-align: center;">
                                        <div class="filter-option" onclick="customChangePageSize(10, 'audit')">10</div>
                                        <div class="filter-option" onclick="customChangePageSize(15, 'audit')">15</div>
                                        <div class="filter-option" onclick="customChangePageSize(20, 'audit')">20</div>
                                        <div class="filter-option" onclick="customChangePageSize(50, 'audit')">50</div>
                                    </div>
                                </div>
                                <span>entries</span>
                            </div>
                        </div>
                    </section>
                </div>
            </main>
        </div>

        <div class="modal fade" id="logDetailsModal" tabindex="-1" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content style-form-card" style="border-radius:12px;">
                    <div class="modal-header">
                        <h5 class="modal-title fw-bold text-dark"><i class="fas fa-info-circle me-2 text-primary"></i>Submission Metadata Details</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body p-4">
                        <div class="mb-3">
                            <small class="text-muted d-block fw-bold uppercase" style="font-size:11px;">Intern Info</small>
                            <span id="modalInternIdentity" class="fw-bold fs-5 text-dark"></span> 
                            <span id="modalInternId" class="badge bg-secondary ms-2"></span>
                        </div>
                        <div class="row g-2 mb-3">
                            <div class="col-6">
                                <small class="text-muted d-block fw-bold" style="font-size:11px;">Submission ID</small>
                                <span id="modalSubId" class="fw-semibold text-dark"></span>
                            </div>
                            <div class="col-6">
                                <small class="text-muted d-block fw-bold" style="font-size:11px;">Date Created</small>
                                <span id="modalDateSubmitted" class="fw-semibold text-dark"></span>
                            </div>
                        </div>
                        <div class="mb-3 p-3 bg-light rounded border">
                            <small class="text-muted d-block fw-bold mb-1" style="font-size:11px;">Task / Activity Completed</small>
                            <p id="modalDescription" class="mb-0 text-dark small style-prose" style="line-height:1.5;"></p>
                        </div>
                        <div class="mb-3 p-3 bg-light rounded border" style="border-left: 4px solid #d63384 !important;">
                            <small class="text-brand-pink d-block fw-bold mb-1" style="font-size:11px; color: #d63384;">What I Learned Today</small>
                            <p id="modalLearningReflection" class="mb-0 text-dark small style-prose" style="line-height:1.5; font-style: italic;"></p>
                        </div>                        <div>
                            <small class="text-muted d-block fw-bold mb-1" style="font-size:11px;">Attached Cryptographic Files</small>
                            <div class="d-flex align-items-center gap-2 p-2 border rounded bg-white small mb-2">
                                <i class="fas fa-file-pdf text-danger fa-lg"></i>
                                <div class="overflow-hidden">
                                    <strong id="modalOriginalFile" class="d-block text-truncate"></strong>
                                    <small id="modalSupportingFile" class="text-muted text-truncate d-block"></small>
                                </div>
                            </div>
                        </div>
                        <div id="modalFilePreviewContainer" style="display: none;" class="mt-2 text-center">
                            <small class="text-muted d-block fw-bold mb-1 text-start" style="font-size:11px;">Image Proof Preview</small>
                            <img id="modalFilePreview" class="img-fluid rounded border shadow-sm" style="max-height: 220px; object-fit: contain; cursor: pointer; transition: transform 0.2s ease;" onclick="window.open(this.src, '_blank')" alt="Supporting proof preview" />
                        </div>
                    </div>
                    <div class="modal-footer border-0">
                        <button type="button" class="btn btn-sm btn-secondary w-100" data-bs-dismiss="modal">Close Window Details</button>
                    </div>
                </div>
            </div>
        </div>

        <div class="modal fade" id="internDetailsModal" tabindex="-1" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content style-form-card" style="border-radius:12px;">
                    <div class="modal-header">
                        <h5 class="modal-title fw-bold text-dark"><i class="fas fa-id-card me-2 text-primary"></i>Intern Profile Details</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body p-4">
                        <div class="text-center mb-4">
                            <img id="internModalAvatar" src="" class="rounded-circle mb-3 shadow-sm" style="width: 80px; height: 80px; object-fit: cover; border: 2px solid var(--brand-pink, #d63384) !important;" alt="Avatar">
                            <h4 id="internModalName" class="fw-bold text-dark mb-1"></h4>
                            <span id="internModalRole" class="badge bg-primary px-3 py-2 rounded-pill" style="font-size: 0.85rem; background-color: #007bff !important;"></span>
                        </div>

                        <div class="row g-3 mb-4">
                            <div class="col-6">
                                <small class="text-muted d-block fw-bold" style="font-size:11px; text-transform: uppercase;">Intern ID</small>
                                <span id="internModalId" class="fw-bold text-dark font-monospace" style="font-size: 13px;"></span>
                            </div>
                            <div class="col-6">
                                <small class="text-muted d-block fw-bold" style="font-size:11px; text-transform: uppercase;">Email Address</small>
                                <span id="internModalEmail" class="fw-semibold text-dark text-truncate d-block" style="font-size: 13px;"></span>
                            </div>
                            <div class="col-6">
                                <small class="text-muted d-block fw-bold" style="font-size:11px; text-transform: uppercase;">University</small>
                                <span id="internModalUniversity" class="fw-semibold text-dark" style="font-size: 13px;"></span>
                            </div>
                            <div class="col-6">
                                <small class="text-muted d-block fw-bold" style="font-size:11px; text-transform: uppercase;">Assigned Office</small>
                                <span id="internModalOffice" class="fw-semibold text-dark" style="font-size: 13px;"></span>
                            </div>
                            <div class="col-6">
                                <small class="text-muted d-block fw-bold" style="font-size:11px; text-transform: uppercase;">Home City</small>
                                <span id="internModalCity" class="fw-semibold text-dark" style="font-size: 13px;"></span>
                            </div>
                            <div class="col-6">
                                <small class="text-muted d-block fw-bold" style="font-size:11px; text-transform: uppercase;">Registered On</small>
                                <span id="internModalRegistered" class="fw-semibold text-dark" style="font-size: 13px;"></span>
                            </div>
                        </div>

                        <div id="internModalFilePreviewContainer" style="display: none;" class="mb-4">
                            <small class="text-muted d-block fw-bold mb-2" style="font-size:11px; text-transform: uppercase;">Latest Attendance Proof</small>
                            <div class="d-flex align-items-center gap-2 mb-2 p-2 bg-light rounded border">
                                <i class="fas fa-file-image text-primary fa-lg"></i>
                                <div class="overflow-hidden">
                                    <strong id="internModalOriginalFile" class="d-block text-truncate small" style="max-width: 320px;"></strong>
                                    <small id="internModalSupportingFile" class="text-muted text-truncate d-block" style="font-size:11px; max-width: 320px;"></small>
                                </div>
                            </div>
                            <div class="text-center">
                                <img id="internModalFilePreview" class="img-fluid rounded border shadow-sm" style="max-height: 180px; object-fit: contain; cursor: pointer; transition: transform 0.2s ease;" onclick="window.open(this.src, '_blank')" alt="Latest proof preview" />
                            </div>
                        </div>

                        <div class="border-top pt-4">
                            <small class="text-muted d-block fw-bold mb-3" style="font-size:11px; text-transform: uppercase;">Management Actions</small>
                            <div class="d-grid gap-2">
                                <a id="internModalDownloadBtn" href="#" class="btn btn-primary d-flex align-items-center justify-content-center gap-2 py-2 shadow-sm" style="background-color: var(--brand-pink, #d63384); border: none; border-radius: 8px;">
                                    <i class="fas fa-download"></i> <strong>Download Performance Report</strong>
                                </a>
                                <div class="row g-2">
                                    <div class="col-6">
                                        <button id="internModalEditBtn" class="btn btn-outline-primary w-100 d-flex align-items-center justify-content-center gap-2 py-2" style="border-radius: 8px;">
                                            <i class="fas fa-pen"></i> <span>Edit Profile</span>
                                        </button>
                                    </div>
                                    <div class="col-6">
                                        <button id="internModalResetBtn" class="btn btn-outline-warning w-100 d-flex align-items-center justify-content-center gap-2 py-2" style="border-radius: 8px;">
                                            <i class="fas fa-history"></i> <span>Reset Hours</span>
                                        </button>
                                    </div>
                                </div>
                                <button id="internModalDeleteBtn" class="btn btn-outline-danger w-100 d-flex align-items-center justify-content-center gap-2 py-2 mt-1" style="border-radius: 8px;">
                                    <i class="fas fa-trash-alt"></i> <span>Delete Profile</span>
                                </button>
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer border-0">
                        <button type="button" class="btn btn-sm btn-secondary w-100" data-bs-dismiss="modal" style="border-radius: 8px;">Close Window Details</button>
                    </div>
                </div>
            </div>
        </div>        <div class="modal fade" id="addInternModal" data-bs-backdrop="static" tabindex="-1" aria-hidden="true">
            <div class="modal-dialog modal-lg modal-dialog-scrollable">
                <div class="modal-content style-form-card">
                    <div class="modal-header">
                        <h5 class="modal-title fw-bold text-brand-pink"><i class="fas fa-user-plus me-2"></i>Add New Intern</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body p-4">
                        <form id="addInternForm" action="AddInternServlet" method="POST" novalidate>
                            <input type="hidden" name="csrfToken" value="<%= CsrfUtil.getToken(session) %>"/>
                            <input type="hidden" name="tabId" value="<%= tabId %>"/>
                            <div class="row g-3 mb-3">
                                <div class="col-md-4">
                                    <label class="form-label form-label-required small fw-bold">First Name</label>
                                    <input type="text" id="intFirstName" name="firstName" class="form-control shadow-none" maxlength="50" required placeholder="Juan" oninput="clearInvalidState(this)">
                                </div>
                                <div class="col-md-4">
                                    <label class="form-label form-label-required small fw-bold">Middle Name</label>
                                    <input type="text" id="intMiddleName" name="middleName" class="form-control shadow-none" maxlength="50" required placeholder="Reyes" oninput="clearInvalidState(this)">
                                </div>
                                <div class="col-md-4">
                                    <label class="form-label form-label-required small fw-bold">Last Name</label>
                                    <input type="text" id="intLastName" name="lastName" class="form-control shadow-none" maxlength="50" required placeholder="dela Cruz" oninput="clearInvalidState(this)">
                                </div>
                            </div>

                            <div class="row g-3 mb-3 align-items-end">
                                <div class="col-md-3">
                                    <label class="form-label form-label-required small fw-bold">Birth Month</label>
                                    <select id="intBirthMonth" name="birthMonth" class="form-select shadow-none" required onchange="clearInvalidState(this)">
                                        <option value="" disabled selected>Select</option>
                                        <option value="January">January</option><option value="February">February</option>
                                        <option value="March">March</option><option value="April">April</option>
                                        <option value="May">May</option><option value="June">June</option>
                                        <option value="July">July</option><option value="August">August</option>
                                        <option value="September">September</option><option value="October">October</option>
                                        <option value="November">November</option><option value="December">December</option>
                                    </select>
                                </div>
                                <div class="col-md-3">
                                    <label class="form-label form-label-required small fw-bold">Birth Date</label>
                                    <select id="intBirthDate" name="birthDate" class="form-select shadow-none" required onchange="clearInvalidState(this)">
                                        <option value="" disabled selected>Day</option>
                                        <% for (int d = 1; d <= 31; d++) {%>
                                        <option value="<%= String.format("%02d", d)%>"><%= String.format("%02d", d)%></option>
                                        <% }%>
                                    </select>
                                </div>
                                <div class="col-md-3">
                                    <label class="form-label form-label-required small fw-bold">Birth Year</label>
                                    <input type="number" id="intBirthYear" name="birthYear" class="form-control shadow-none" min="1900" max="2026" required placeholder="YYYY" oninput="calculateAge(); clearInvalidState(this);">
                                </div>
                                <div class="col-md-3">
                                    <label class="form-label small fw-bold">Calculated Age</label>
                                    <input type="text" id="intAgeDisplay" name="age" class="form-control bg-light text-dark fw-bold" readonly value="N/A">
                                </div>
                            </div>

                            <div class="row g-3 mb-3">
                                <div class="col-md-6">
                                    <label class="form-label form-label-required small fw-bold">City (Philippines)</label>
                                    <select id="intCity" name="city" class="form-select shadow-none" required onchange="clearInvalidState(this)">
                                        <option value="" disabled selected>Select City</option>
                                        <optgroup label="Metro Manila">
                                            <option value="Manila">Manila</option><option value="Quezon City">Quezon City</option>
                                            <option value="Caloocan">Caloocan</option><option value="Las Piñas">Las Piñas</option>
                                            <option value="Makati">Makati</option><option value="Malabon">Malabon</option>
                                            <option value="Mandaluyong">Mandaluyong</option><option value="Marikina">Marikina</option>
                                            <option value="Muntinlupa">Muntinlupa</option><option value="Navotas">Navotas</option>
                                            <option value="Parañaque">Parañaque</option><option value="Pasay">Pasay</option>
                                            <option value="Pasig">Pasig</option><option value="San Juan">San Juan</option>
                                            <option value="Taguig">Taguig</option><option value="Valenzuela">Valenzuela</option>
                                        </optgroup>
                                        <optgroup label="Luzon">
                                            <option value="Angeles City">Angeles City</option><option value="Antipolo">Antipolo</option>
                                            <option value="Baguio City">Baguio City</option><option value="Batangas City">Batangas City</option>
                                            <option value="Cabanatuan">Cabanatuan</option><option value="Dagupan">Dagupan</option>
                                            <option value="Laoag">Laoag</option><option value="Legazpi">Legazpi</option>
                                            <option value="Lucena">Lucena</option><option value="Naga City">Naga City</option>
                                            <option value="Olongapo">Olongapo</option><option value="Puerto Princesa">Puerto Princesa</option>
                                            <option value="San Fernando">San Fernando</option><option value="Tarlac City">Tarlac City</option>
                                        </optgroup>
                                        <optgroup label="Visayas">
                                            <option value="Bacolod">Bacolod</option><option value="Cebu City">Cebu City</option>
                                            <option value="Dumaguete">Dumaguete</option><option value="Iloilo City">Iloilo City</option>
                                            <option value="Lapu-Lapu City">Lapu-Lapu City</option><option value="Mandaue City">Mandaue City</option>
                                            <option value="Ormoc">Ormoc</option><option value="Roxas City">Roxas City</option>
                                            <option value="Tacloban">Tacloban</option><option value="Tagbilaran">Tagbilaran</option>
                                        </optgroup>
                                        <optgroup label="Mindanao">
                                            <option value="Butuan">Butuan</option><option value="Cagayan de Oro">Cagayan de Oro</option>
                                            <option value="Cotabato City">Cotabato City</option><option value="Davao City">Davao City</option>
                                            <option value="General Santos">General Santos</option><option value="Iligan City">Iligan City</option>
                                            <option value="Marawi">Marawi</option><option value="Pagadian">Pagadian</option>
                                            <option value="Surigao City">Surigao City</option><option value="Zamboanga City">Zamboanga City</option>
                                        </optgroup>
                                    </select>
                                </div>
                                <div class="col-md-6">
                                    <label class="form-label form-label-required small fw-bold">Contact Number</label>
                                    <div class="input-group">
                                        <span class="input-group-text bg-light text-dark fw-bold">PH (+63)</span>
                                        <input type="tel" id="intContactNum" name="contactNum" class="form-control shadow-none" required placeholder="9xxxxxxxxx" oninput="handlePhoneInput(this)">
                                        <span class="input-group-text bg-white d-none border-start-0" id="phoneValidCheck"></span>
                                    </div>
                                    <div id="phoneErrorMsg" class="text-danger small mt-1" style="display: none; font-size: 11px;"></div>
                                </div>
                            </div>

                            <div class="row g-3 mb-3">
                                <div class="col-md-6">
                                    <label class="form-label form-label-required small fw-bold">University</label>
                                    <input type="text" id="intUniversity" name="university" class="form-control shadow-none" maxlength="100" required placeholder="University of Santo Tomas" oninput="clearInvalidState(this)">
                                </div>
                                <div class="col-md-6">
                                    <label class="form-label form-label-required small fw-bold">Technical Intern Role</label>
                                    <select id="intRole" name="role" class="form-select shadow-none" required onchange="handleRoleAssignment(); clearInvalidState(this);">
                                        <option value="" disabled selected>Select Role Choice</option>
                                        <option value="Data Engineer Intern" data-code="da" data-office="Office 1 - Data & Analytics">Data Engineer Intern</option>
                                        <option value="UI/UX Intern" data-code="uiux" data-office="Office 2 - Creative Design">UI/UX Intern</option>
                                        <option value="Front-end Developer Intern" data-code="fe" data-office="Office 2 - Creative Design">Front-end Developer Intern</option>
                                        <option value="Backend Developer Intern" data-code="be" data-office="Office 3 - Systems & Infrastructure">Backend Developer Intern</option>
                                        <option value="Quality Assurance Intern" data-code="qa" data-office="Office 4 - Quality Control">Quality Assurance Intern</option>
                                    </select>
                                </div>
                            </div>

                            <div class="row g-3 mb-3">
                                <div class="col-md-6">
                                    <label class="form-label small fw-bold text-muted">Assigned Office Location (Auto)</label>
                                    <input type="text" id="intOfficeDisplay" name="office" class="form-control bg-light" readonly placeholder="Office Assignment">
                                </div>
                                <div class="col-md-6">
                                    <label class="form-label small fw-bold text-muted">Generated Corporate Email Account (Auto)</label>
                                    <input type="text" id="intEmailDisplay" name="email" class="form-control bg-light fw-bold text-success" readonly placeholder="firstname.lastname.code@gmail.com">
                                </div>
                            </div>

                            <div class="mb-3">
                                <label class="form-label form-label-required small fw-bold">Access Security Password</label>
                                <input type="password" id="intPassword" name="password" class="form-control shadow-none" maxlength="30" required placeholder="Password" oninput="handlePasswordInput(this); clearInvalidState(this);">

                                <div class="password-policies-wrapper mt-2 p-3 bg-light rounded" style="font-size: 12px; border: 1px solid #e9ecef;">
                                    <div class="row g-2">
                                        <div class="col-6 col-md-4 d-flex align-items-center gap-2" id="rule-upper"><i class="far fa-circle text-muted"></i> <span>Uppercase Letter</span></div>
                                        <div class="col-6 col-md-4 d-flex align-items-center gap-2" id="rule-lower"><i class="far fa-circle text-muted"></i> <span>Lowercase Letter</span></div>
                                        <div class="col-6 col-md-4 d-flex align-items-center gap-2" id="rule-number"><i class="far fa-circle text-muted"></i> <span>Numerical Digit</span></div>
                                        <div class="col-6 col-md-4 d-flex align-items-center gap-2" id="rule-special"><i class="far fa-circle text-muted"></i> <span>Special Symbol</span></div>
                                        <div class="col-6 col-md-4 d-flex align-items-center gap-2" id="rule-length"><i class="far fa-circle text-muted"></i> <span>8 to 30 Characters</span></div>
                                    </div>
                                </div>
                            </div>

                            <div id="modalFormError" class="alert alert-danger py-2 small" style="display: none;"></div>

                            <div class="modal-footer px-0 pb-0 pt-3 border-top-eee">
                                <button type="button" class="btn type-button btn-sm btn-secondary" data-bs-dismiss="modal">Cancel</button>
                                <button type="button" class="btn btn-sm btn-brand-pink px-4" onclick="validateAndProcessInternForm()">Save Intern Record</button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>

        <div class="modal fade" id="summaryInternModal" data-bs-backdrop="static" tabindex="-1" aria-hidden="true">
            <div class="modal-dialog">
                <div class="modal-content b-none-r12">
                    <div class="modal-header bg-success text-white card-header-radius">
                        <h5 class="modal-title fw-bold"><i class="fas fa-check-circle me-2"></i>Intern Account Created Successfully!</h5>
                    </div>
                    <div class="modal-body p-4 bg-light">
                        <div class="card shadow-sm p-3 border-0 bg-white mb-3 text-center">
                            <img src="" id="sumAvatar" class="rounded-circle mx-auto mb-2 sum-avatar-size" alt="Avatar" style="width: 80px; height: 80px;">
                            <h4 id="sumFullName" class="fw-bold mb-0 text-dark"></h4>
                            <div class="mt-2">
                                <span class="badge bg-dark px-3 py-2 font-monospace" id="sumGeneratedId" style="font-size: 13px; letter-spacing: 0.5px;"></span>
                            </div>
                            <span id="sumRole" class="badge bg-secondary px-3 py-2 mt-2 align-self-center"></span>
                        </div>
                        <table class="table table-sm table-borderless small mb-0">
                            <tbody>
                                <tr><td class="text-muted fw-bold" style="width:35%;">Generated Email:</td><td id="sumEmail" class="fw-semibold text-primary"></td></tr>
                                <tr><td class="text-muted fw-bold">Assigned Office:</td><td id="sumOffice" class="fw-semibold text-dark"></td></tr>
                                <tr><td class="text-muted fw-bold">Birthdate / Age:</td><td id="sumBirthAge"></td></tr>
                                <tr><td class="text-muted fw-bold">City Address:</td><td id="sumCity"></td></tr>
                                <tr><td class="text-muted fw-bold">Contact Number:</td><td id="sumContact"></td></tr>
                                <tr><td class="text-muted fw-bold">University Name:</td><td id="sumUniversity"></td></tr>
                            </tbody>
                        </table>
                    </div>
                    <div class="modal-footer bg-f8f9fa">
                        <button type="button" class="btn btn-sm btn-success px-4" data-bs-dismiss="modal" onclick="window.location.href = 'admin.jsp?tabId=<%= tabId %>&view=intern-management'">Close Account Details</button>
                    </div>
                </div>
            </div>
        </div>

        <!-- ═══════════════════════════════════════════════════ -->
        <!-- EDIT INTERN MODAL - Profile Modification Interface -->
        <!-- ═══════════════════════════════════════════════════ -->
        <div class="modal fade" id="editInternModal" data-bs-backdrop="static" tabindex="-1" aria-hidden="true">
            <div class="modal-dialog modal-lg modal-dialog-scrollable">
                <div class="modal-content style-form-card">
                    <div class="modal-header" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border-radius: 12px 12px 0 0;">
                        <h5 class="modal-title fw-bold text-white"><i class="fas fa-user-edit me-2"></i>Edit Intern Profile</h5>
                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body p-4">
                        <form id="editInternForm" action="UpdateInternServlet" method="POST" novalidate>
                            <input type="hidden" id="editInternId" name="internId">
                            <input type="hidden" id="editEmail" name="email">
                            <!-- Hidden fields for birth/age/contact - send existing or empty values -->
                            <input type="hidden" id="editBirthMonth" name="birthMonth" value="">
                            <input type="hidden" id="editBirthDate" name="birthDate" value="0">
                            <input type="hidden" id="editBirthYear" name="birthYear" value="0">
                            <input type="hidden" id="editAge" name="age" value="0">
                            <input type="hidden" id="editContactNum" name="contactNum" value="">

                            <!-- Intern ID Badge -->
                            <div class="mb-3 p-3 rounded" style="background: linear-gradient(135deg, #f0f4ff 0%, #f5f0ff 100%); border: 1px solid #e0e7ff;">
                                <small class="text-muted d-block fw-bold" style="font-size: 11px; text-transform: uppercase; letter-spacing: 0.5px;">Editing Record For</small>
                                <span id="editInternIdDisplay" class="fw-bold fs-5" style="color: #4f46e5; font-family: 'SFMono-Regular', Consolas, monospace;"></span>
                            </div>

                            <!-- Name Fields -->
                            <div class="row g-3 mb-3">
                                <div class="col-md-4">
                                    <label class="form-label form-label-required small fw-bold">First Name</label>
                                    <input type="text" id="editFirstName" name="firstName" class="form-control shadow-none" maxlength="50" required placeholder="First Name" oninput="clearInvalidState(this); updateEditEmail();">
                                </div>
                                <div class="col-md-4">
                                    <label class="form-label small fw-bold">Middle Name</label>
                                    <input type="text" id="editMiddleName" name="middleName" class="form-control shadow-none" maxlength="50" placeholder="Middle Name">
                                </div>
                                <div class="col-md-4">
                                    <label class="form-label form-label-required small fw-bold">Last Name</label>
                                    <input type="text" id="editLastName" name="lastName" class="form-control shadow-none" maxlength="50" required placeholder="Last Name" oninput="clearInvalidState(this); updateEditEmail();">
                                </div>
                            </div>

                            <!-- University -->
                            <div class="row g-3 mb-3">
                                <div class="col-md-12">
                                    <label class="form-label form-label-required small fw-bold">University</label>
                                    <input type="text" id="editUniversity" name="university" class="form-control shadow-none" maxlength="100" required placeholder="University" oninput="clearInvalidState(this)">
                                </div>
                            </div>

                            <!-- City -->
                            <div class="row g-3 mb-3">
                                <div class="col-md-6">
                                    <label class="form-label form-label-required small fw-bold">City (Philippines)</label>
                                    <select id="editCity" name="city" class="form-select shadow-none" required onchange="clearInvalidState(this)">
                                        <option value="" disabled>Select City</option>
                                        <optgroup label="Metro Manila">
                                            <option value="Manila">Manila</option><option value="Quezon City">Quezon City</option>
                                            <option value="Caloocan">Caloocan</option><option value="Las Piñas">Las Piñas</option>
                                            <option value="Makati">Makati</option><option value="Malabon">Malabon</option>
                                            <option value="Mandaluyong">Mandaluyong</option><option value="Marikina">Marikina</option>
                                            <option value="Muntinlupa">Muntinlupa</option><option value="Navotas">Navotas</option>
                                            <option value="Parañaque">Parañaque</option><option value="Pasay">Pasay</option>
                                            <option value="Pasig">Pasig</option><option value="San Juan">San Juan</option>
                                            <option value="Taguig">Taguig</option><option value="Valenzuela">Valenzuela</option>
                                        </optgroup>
                                        <optgroup label="Luzon">
                                            <option value="Angeles City">Angeles City</option><option value="Antipolo">Antipolo</option>
                                            <option value="Baguio City">Baguio City</option><option value="Batangas City">Batangas City</option>
                                            <option value="Cabanatuan">Cabanatuan</option><option value="Dagupan">Dagupan</option>
                                            <option value="Laoag">Laoag</option><option value="Legazpi">Legazpi</option>
                                            <option value="Lucena">Lucena</option><option value="Naga City">Naga City</option>
                                            <option value="Olongapo">Olongapo</option><option value="Puerto Princesa">Puerto Princesa</option>
                                            <option value="San Fernando">San Fernando</option><option value="Tarlac City">Tarlac City</option>
                                        </optgroup>
                                        <optgroup label="Visayas">
                                            <option value="Bacolod">Bacolod</option><option value="Cebu City">Cebu City</option>
                                            <option value="Dumaguete">Dumaguete</option><option value="Iloilo City">Iloilo City</option>
                                            <option value="Lapu-Lapu City">Lapu-Lapu City</option><option value="Mandaue City">Mandaue City</option>
                                            <option value="Ormoc">Ormoc</option><option value="Roxas City">Roxas City</option>
                                            <option value="Tacloban">Tacloban</option><option value="Tagbilaran">Tagbilaran</option>
                                        </optgroup>
                                        <optgroup label="Mindanao">
                                            <option value="Butuan">Butuan</option><option value="Cagayan de Oro">Cagayan de Oro</option>
                                            <option value="Cotabato City">Cotabato City</option><option value="Davao City">Davao City</option>
                                            <option value="General Santos">General Santos</option><option value="Iligan City">Iligan City</option>
                                            <option value="Marawi">Marawi</option><option value="Pagadian">Pagadian</option>
                                            <option value="Surigao City">Surigao City</option><option value="Zamboanga City">Zamboanga City</option>
                                        </optgroup>
                                    </select>
                                </div>

                                <!-- Role -->
                                <div class="col-md-6">
                                    <label class="form-label form-label-required small fw-bold">Technical Intern Role</label>
                                    <select id="editRole" name="role" class="form-select shadow-none" required onchange="handleEditRoleAssignment(); clearInvalidState(this);">
                                        <option value="" disabled>Select Role Choice</option>
                                        <option value="Data Engineer Intern" data-code="da" data-office="Office 1 - Data &amp; Analytics">Data Engineer Intern</option>
                                        <option value="UI/UX Intern" data-code="uiux" data-office="Office 2 - Creative Design">UI/UX Intern</option>
                                        <option value="Front-end Developer Intern" data-code="fe" data-office="Office 2 - Creative Design">Front-end Developer Intern</option>
                                        <option value="Backend Developer Intern" data-code="be" data-office="Office 3 - Systems &amp; Infrastructure">Backend Developer Intern</option>
                                        <option value="Quality Assurance Intern" data-code="qa" data-office="Office 4 - Quality Control">Quality Assurance Intern</option>
                                    </select>
                                </div>
                            </div>

                            <!-- Office (Auto) and Email (Auto) -->
                            <div class="row g-3 mb-3">
                                <div class="col-md-6">
                                    <label class="form-label small fw-bold text-muted">Assigned Office Location (Auto)</label>
                                    <input type="text" id="editOffice" name="office" class="form-control bg-light" readonly placeholder="Office Assignment">
                                </div>
                                <div class="col-md-6">
                                    <label class="form-label small fw-bold text-muted">Corporate Email Account (Auto)</label>
                                    <input type="text" id="editEmailDisplay" class="form-control bg-light fw-bold text-success" readonly placeholder="Auto-generated email">
                                </div>
                            </div>

                            <!-- Optional Password Change -->
                            <div class="mb-3">
                                <label class="form-label small fw-bold">New Password <span class="text-muted fw-normal">(leave blank to keep current)</span></label>
                                <input type="password" id="editPassword" name="password" class="form-control shadow-none" maxlength="30" placeholder="Enter new password only if changing" oninput="handleEditPasswordInput(this); clearInvalidState(this);">
                            </div>

                            <!-- Old Password Container (Dynamic) -->
                            <div class="mb-3" id="editOldPasswordContainer" style="display: none;">
                                <label class="form-label form-label-required small fw-bold">Old Password</label>
                                <input type="password" id="editOldPassword" name="oldPassword" class="form-control shadow-none" maxlength="30" placeholder="Enter current password to verify" oninput="clearInvalidState(this);">
                            </div>

                            <!-- New Password Complexity Policies -->
                            <div class="mb-3" id="edit-password-policies" style="display: none;">
                                <div class="password-policies-wrapper mt-2 p-3 bg-light rounded" style="font-size: 12px; border: 1px solid #e9ecef;">
                                    <div class="row g-2">
                                        <div class="col-6 col-md-4 d-flex align-items-center gap-2" id="edit-rule-upper"><i class="far fa-circle text-muted"></i> <span>Uppercase Letter</span></div>
                                        <div class="col-6 col-md-4 d-flex align-items-center gap-2" id="edit-rule-lower"><i class="far fa-circle text-muted"></i> <span>Lowercase Letter</span></div>
                                        <div class="col-6 col-md-4 d-flex align-items-center gap-2" id="edit-rule-number"><i class="far fa-circle text-muted"></i> <span>Numerical Digit</span></div>
                                        <div class="col-6 col-md-4 d-flex align-items-center gap-2" id="edit-rule-special"><i class="far fa-circle text-muted"></i> <span>Special Symbol</span></div>
                                        <div class="col-6 col-md-4 d-flex align-items-center gap-2" id="edit-rule-length"><i class="far fa-circle text-muted"></i> <span>8 to 30 Characters</span></div>
                                    </div>
                                </div>
                            </div>

                            <div id="editFormError" class="alert alert-danger py-2 small" style="display: none;"></div>

                            <div class="modal-footer px-0 pb-0 pt-3 border-top-eee">
                                <button type="button" class="btn btn-sm btn-secondary" data-bs-dismiss="modal">Cancel</button>
                                <button type="button" class="btn btn-sm px-4 text-white" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);" onclick="validateAndSubmitEditForm()">Save Changes</button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>

        <!-- ═══════════════════════════════════════════════════════ -->
        <!-- DELETE INTERN MODAL - Safety Confirmation Dialog      -->
        <!-- ═══════════════════════════════════════════════════════ -->
        <div class="modal fade" id="deleteInternModal" data-bs-backdrop="static" tabindex="-1" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content" style="border-radius: 16px; border: none; overflow: hidden;">
                    <div class="modal-header border-0 pb-0" style="background: linear-gradient(135deg, #fee2e2 0%, #fecaca 100%);">
                        <div class="w-100 text-center pt-3">
                            <div style="width: 64px; height: 64px; border-radius: 50%; background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%); display: inline-flex; align-items: center; justify-content: center; box-shadow: 0 4px 14px rgba(239, 68, 68, 0.3);">
                                <i class="fas fa-exclamation-triangle fa-lg text-white"></i>
                            </div>
                        </div>
                    </div>
                    <div class="modal-body text-center px-4 pt-3 pb-1" style="background: linear-gradient(135deg, #fee2e2 0%, #fecaca 100%);">
                        <h5 class="fw-bold text-dark mb-2">Confirm Deletion</h5>
                        <p class="text-dark mb-3" style="font-size: 15px; line-height: 1.6;">
                            Are you sure you want to delete<br>
                            <strong id="deleteTargetName" class="fs-5" style="color: #dc2626;"></strong>?
                        </p>
                        <div class="p-2 rounded mb-3" style="background: rgba(255,255,255,0.6); border: 1px solid rgba(220,38,38,0.15);">
                            <small class="text-muted"><i class="fas fa-info-circle me-1"></i>This action is permanent and cannot be undone. All associated records for this intern will be removed from the system.</small>
                        </div>
                    </div>
                    <div class="modal-footer border-0 justify-content-center gap-2 pb-4" style="background: linear-gradient(135deg, #fee2e2 0%, #fecaca 100%);">
                        <form id="deleteInternForm" action="DeleteInternServlet" method="POST" style="display: inline;">
                            <input type="hidden" id="deleteInternId" name="internId">
                            <input type="hidden" name="tabId" id="deleteTabId">
                            <button type="button" class="btn btn-sm px-4 py-2" style="border-radius: 8px; background: white; border: 1px solid #d1d5db; color: #374151; font-weight: 600;" data-bs-dismiss="modal">Cancel</button>
                            <button type="submit" class="btn btn-sm px-4 py-2 text-white" style="border-radius: 8px; background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%); border: none; font-weight: 600; box-shadow: 0 2px 8px rgba(239, 68, 68, 0.3);"><i class="fas fa-trash-alt me-1"></i>Yes, Delete</button>
                        </form>
                    </div>
                </div>
            </div>
        </div>

        <!-- ═══════════════════════════════════════════════════════ -->
        <!-- RESET HOURS MODAL - safety confirmation dialog         -->
        <!-- ═══════════════════════════════════════════════════════ -->
        <div class="modal fade" id="resetHoursModal" data-bs-backdrop="static" tabindex="-1" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content" style="border-radius: 16px; border: none; overflow: hidden;">
                    <div class="modal-header border-0 pb-0" style="background: linear-gradient(135deg, #fef3c7 0%, #fde68a 100%);">
                        <div class="w-100 text-center pt-3">
                            <div style="width: 64px; height: 64px; border-radius: 50%; background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%); display: inline-flex; align-items: center; justify-content: center; box-shadow: 0 4px 14px rgba(245, 158, 11, 0.3);">
                                <i class="fas fa-history fa-lg text-white"></i>
                            </div>
                        </div>
                    </div>
                    <div class="modal-body text-center px-4 pt-3 pb-1" style="background: linear-gradient(135deg, #fef3c7 0%, #fde68a 100%);">
                        <h5 class="fw-bold text-dark mb-2">Reset Simulated Hours</h5>
                        <p class="text-dark mb-3" style="font-size: 15px; line-height: 1.6;">
                            Are you sure you want to reset simulated hours for<br>
                            <strong id="resetTargetName" class="fs-5" style="color: #d97706;"></strong> to 0.0?
                        </p>
                        <div class="p-2 rounded mb-3" style="background: rgba(255,255,255,0.6); border: 1px solid rgba(217,119,6,0.15);">
                            <small class="text-muted"><i class="fas fa-info-circle me-1"></i>This sets their simulated rendered hours back to 0 on their next load/dashboard check. Form submissions are preserved.</small>
                        </div>
                    </div>
                    <div class="modal-footer border-0 justify-content-center gap-2 pb-4" style="background: linear-gradient(135deg, #fef3c7 0%, #fde68a 100%);">
                        <form id="resetHoursForm" action="ResetHoursServlet" method="POST" style="display: inline;">
                            <input type="hidden" id="resetInternId" name="internId">
                            <input type="hidden" name="tabId" id="resetTabId">
                            <button type="button" class="btn btn-sm px-4 py-2" style="border-radius: 8px; background: white; border: 1px solid #d1d5db; color: #374151; font-weight: 600;" data-bs-dismiss="modal">Cancel</button>
                            <button type="submit" class="btn btn-sm px-4 py-2 text-white" style="border-radius: 8px; background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%); border: none; font-weight: 600; box-shadow: 0 2px 8px rgba(245, 158, 11, 0.3);"><i class="fas fa-check me-1"></i>Yes, Reset</button>
                        </form>
                    </div>
                </div>
            </div>
        </div>

        <script>
            var activeUserId = '<%= user.getId() %>';

            function toggleSidebar() {
                if (window.innerWidth >= 992) {
                    document.body.classList.toggle("sidebar-collapsed");
                } else {
                    document.body.classList.toggle("show-sidebar");
                }
            }

            let activeFilters = {university: "", role: "", office: "", city: ""};
            let internSortColumn = 1, internSortAsc = false;
            let logSortColumn = 0, logSortAsc = true;
            let logStatusFilter = "";
            let logOfficeFilter = "";

            let internCurrentPage = 1, internPageSize = 10;
            let logCurrentPage = 1, logPageSize = 10;
            let auditCurrentPage = 1, auditPageSize = 10;

            let auditData = [];
            let auditSortColumn = 0, auditSortAsc = false;
            let auditLoaded = false;

            let addInternModalObj = null, summaryInternModalObj = null, detailsModalObj = null;

            document.addEventListener("DOMContentLoaded", () => {
                populateDropdowns();
                sortInternTable(1, false);
                sortLogTable(0, false);

                // Server Post-Submit Success Modal Interception Control
                const urlParams = new URLSearchParams(window.location.search);
                if (urlParams.get('status') === 'success') {
                    document.getElementById("sumFullName").innerText = urlParams.get('newName');
                    document.getElementById("sumGeneratedId").innerText = "ID: " + urlParams.get('newId');
                    document.getElementById("sumRole").innerText = urlParams.get('newRole');
                    document.getElementById("sumEmail").innerText = urlParams.get('newEmail');
                    document.getElementById("sumOffice").innerText = urlParams.get('newOffice');
                    document.getElementById("sumCity").innerText = urlParams.get('newCity') + ", Philippines";
                    document.getElementById("sumContact").innerText = "+63 " + urlParams.get('newContact');
                    document.getElementById("sumUniversity").innerText = urlParams.get('newUni');
                    document.getElementById("sumBirthAge").innerText = urlParams.get('newBirthAge');
                    document.getElementById("sumAvatar").src = "https://ui-avatars.com/api/?name=" + encodeURIComponent(urlParams.get('newName')) + "&background=d63384&color=fff";

                    summaryInternModalObj = new bootstrap.Modal(document.getElementById('summaryInternModal'));
                    summaryInternModalObj.show();
                }

                // Error toast notifications from server-side validation redirects
                const err = urlParams.get('err');
                if (err === 'invalid_date_range') {
                    showAdminToast("Date Range Error: 'From' date must be before or equal to 'To' date.", "danger");
                } else if (err === 'malformed_dates') {
                    showAdminToast("Malformed Dates: The dates provided are invalid or empty.", "danger");
                }

                // Restore active view tab from URL parameter (e.g. log-review)
                const targetView = urlParams.get('view');
                if (targetView) {
                    switchView(targetView);
                }

                // Handle edit/delete/reset success/error toast notifications
                const status = urlParams.get('status');
                if (status === 'updated') {
                    showAdminToast('Intern profile has been updated successfully!', 'success');
                } else if (status === 'deleted') {
                    showAdminToast('Intern record has been permanently deleted.', 'success');
                } else if (status === 'deleted_batch') {
                    showAdminToast('Successfully deleted ' + urlParams.get('count') + ' intern record(s).', 'success');
                } else if (status === 'hours_reset') {
                    showAdminToast('Intern simulated hours have been successfully queued for reset!', 'success');
                }
                if (err === 'update_failed') {
                    showAdminToast('Failed to update intern profile. Please try again.', 'danger');
                } else if (err === 'delete_failed') {
                    showAdminToast('Failed to delete intern record. Please try again.', 'danger');
                } else if (err === 'delete_self_blocked') {
                    showAdminToast('You cannot delete your own admin account.', 'danger');
                } else if (err === 'hours_reset_failed') {
                    showAdminToast('Failed to queue simulated hours reset. Please try again.', 'danger');
                } else if (err === 'missing_old_password') {
                    showAdminToast('Old Password is required when updating to a new password.', 'danger');
                } else if (err === 'incorrect_old_password') {
                    showAdminToast('Incorrect Old Password. Password update rejected.', 'danger');
                } else if (err === 'invalid_new_password') {
                    showAdminToast('New password does not meet complexity requirements.', 'danger');
                } else if (err === 'user_not_found') {
                    showAdminToast('User account not found.', 'danger');
                }
                pollUnreadMessagesCount();
            });

            function showAdminToast(message, type = "success") {
                // Ensure a toast container exists
                let container = document.getElementById('admin-toast-container');
                if (!container) {
                    container = document.createElement('div');
                    container.id = 'admin-toast-container';
                    Object.assign(container.style, {
                        position: 'fixed',
                        top: '85px',
                        right: '24px',
                        zIndex: '9999',
                        display: 'flex',
                        flexDirection: 'column',
                        gap: '12px',
                        pointerEvents: 'none'
                    });
                    document.body.appendChild(container);
                }

                // Create individual toast element
                const toast = document.createElement('div');
                toast.className = "admin-toast-alert animate-fade-in";

                // Color configuration
                let bgColor = "#198754"; // Success green
                let icon = "fa-circle-check";
                if (type === "danger" || type === "error") {
                    bgColor = "#dc3545"; // Danger red
                    icon = "fa-circle-exclamation";
                } else if (type === "warning") {
                    bgColor = "#ffc107"; // Warning yellow
                    icon = "fa-triangle-exclamation";
                }

                Object.assign(toast.style, {
                    background: '#1b1c23',
                    borderLeft: '4px solid ' + bgColor,
                    color: '#ffffff',
                    padding: '16px 20px',
                    borderRadius: '8px',
                    boxShadow: '0 8px 30px rgba(0,0,0,0.35)',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '12px',
                    minWidth: '320px',
                    maxWidth: '450px',
                    pointerEvents: 'auto',
                    opacity: '1',
                    transform: 'translateY(0)',
                    transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)'
                });

                // Icon Wrap
                const iconWrap = document.createElement('i');
                iconWrap.className = "fa-solid " + icon;
                iconWrap.style.color = bgColor;
                iconWrap.style.fontSize = "1.2rem";

                // Text wrap
                const textWrap = document.createElement('span');
                textWrap.innerText = message;
                textWrap.style.fontFamily = "'Inter', sans-serif";
                textWrap.style.fontSize = "0.92rem";
                textWrap.style.fontWeight = "500";

                toast.appendChild(iconWrap);
                toast.appendChild(textWrap);
                container.appendChild(toast);

                // Auto dismiss after 4.5 seconds
                setTimeout(() => {
                    toast.style.opacity = '0';
                    toast.style.transform = 'translateY(-15px)';
                    setTimeout(() => toast.remove(), 350);
                }, 4500);
            }

            // --- INTERN MANAGEMENT OPERATIONS EXTENSION ---

            function openEditInternModal(rowElement) {
                // Extract metadata values mapped from your custom HTML5 data- attributes
                const id = rowElement.getAttribute("data-id");
                const firstName = rowElement.getAttribute("data-firstname");
                const middleName = rowElement.getAttribute("data-middlename");
                const lastName = rowElement.getAttribute("data-lastname");
                const email = rowElement.getAttribute("data-email");
                const university = rowElement.getAttribute("data-university");
                const city = rowElement.getAttribute("data-city");
                const role = rowElement.getAttribute("data-role");
                const roleCode = rowElement.getAttribute("data-rolecode");
                const office = rowElement.getAttribute("data-office");

                // Reset error states
                document.getElementById("editFormError").style.display = "none";
                document.querySelectorAll('#editInternForm .form-control, #editInternForm .form-select').forEach(el => el.classList.remove('is-invalid'));

                // Populate the Edit Form Input Fields
                document.getElementById("editInternId").value = id;
                let displayId = id;
                const fullName = ((firstName || "") + " " + (lastName || "")).trim();
                if (fullName.toLowerCase() === 'james smith' || fullName.toLowerCase() === 'system admin profile' || (id && id.startsWith('ADM')) || id === 'ADM2020-0001' || id === 'ADM2026-0001') {
                    if (id && id.startsWith('ADM')) {
                        displayId = id;
                    } else {
                        displayId = "ADM2020-0001";
                    }
                } else if (/^\d+$/.test(id)) {
                    displayId = "INT2026-7" + String(id).padStart(4, "0");
                }
                document.getElementById("editInternIdDisplay").innerText = displayId;
                document.getElementById("editFirstName").value = firstName;
                document.getElementById("editMiddleName").value = middleName;
                document.getElementById("editLastName").value = lastName;
                document.getElementById("editEmail").value = email;
                document.getElementById("editEmailDisplay").value = email;
                document.getElementById("editUniversity").value = university;
                document.getElementById("editPassword").value = "";
                document.getElementById("editOldPassword").value = "";
                document.getElementById("editOldPasswordContainer").style.display = "none";
                document.getElementById("editOldPassword").removeAttribute("required");
                document.getElementById("edit-password-policies").style.display = "none";
                
                // Clear rule indicators
                updateRuleIndicator("edit-rule-upper", false);
                updateRuleIndicator("edit-rule-lower", false);
                updateRuleIndicator("edit-rule-number", false);
                updateRuleIndicator("edit-rule-special", false);
                updateRuleIndicator("edit-rule-length", false);

                // Set city dropdown value
                const citySelect = document.getElementById("editCity");
                citySelect.value = city;
                if (citySelect.value !== city) {
                    // If city is not in dropdown, add it as selected option
                    const opt = document.createElement('option');
                    opt.value = city;
                    opt.text = city;
                    opt.selected = true;
                    citySelect.appendChild(opt);
                }

                // Set role dropdown value and auto-fill office
                const roleSelect = document.getElementById("editRole");
                roleSelect.value = role;
                document.getElementById("editOffice").value = office;

                // Instantiate and display the Bootstrap Modal frame safely
                const editModal = new bootstrap.Modal(document.getElementById('editInternModal'));
                editModal.show();
            }

            function handleEditRoleAssignment() {
                const roleSelect = document.getElementById("editRole");
                if (roleSelect.selectedIndex <= 0) return;
                const chosenOpt = roleSelect.options[roleSelect.selectedIndex];
                document.getElementById("editOffice").value = chosenOpt.getAttribute("data-office");
                updateEditEmail();
            }

            function updateEditEmail() {
                const fName = document.getElementById("editFirstName").value.trim().replace(/\s+/g, "");
                const lName = document.getElementById("editLastName").value.trim().replace(/\s+/g, "");
                const roleSelect = document.getElementById("editRole");
                let code = "";
                if (roleSelect.selectedIndex > 0) {
                    code = roleSelect.options[roleSelect.selectedIndex].getAttribute("data-code");
                }
                const emailBox = document.getElementById("editEmailDisplay");
                const emailHidden = document.getElementById("editEmail");
                if (fName !== "" && lName !== "" && code !== "") {
                    const generatedEmail = (fName + "." + lName + "." + code).toLowerCase() + "@gmail.com";
                    emailBox.value = generatedEmail;
                    emailHidden.value = generatedEmail;
                }
            }

            function validateAndSubmitEditForm() {
                const errBox = document.getElementById("editFormError");
                errBox.style.display = "none";
                errBox.innerText = "";

                const inputs = document.querySelectorAll('#editInternForm .form-control, #editInternForm .form-select');
                inputs.forEach(input => input.classList.remove('is-invalid'));

                let errors = [];
                const fName = document.getElementById("editFirstName");
                const lName = document.getElementById("editLastName");
                const university = document.getElementById("editUniversity");
                const city = document.getElementById("editCity");
                const role = document.getElementById("editRole");

                if (!fName.value.trim()) { fName.classList.add('is-invalid'); errors.push('First Name is required.'); }
                if (!lName.value.trim()) { lName.classList.add('is-invalid'); errors.push('Last Name is required.'); }
                if (!university.value.trim()) { university.classList.add('is-invalid'); errors.push('University is required.'); }
                if (!city.value) { city.classList.add('is-invalid'); errors.push('City selection is required.'); }
                if (!role.value) { role.classList.add('is-invalid'); errors.push('Role selection is required.'); }

                // Password Validation logic for edits
                const editPwd = document.getElementById("editPassword");
                const editOldPwd = document.getElementById("editOldPassword");
                if (editPwd.value.length > 0) {
                    if (!editOldPwd.value.trim()) {
                        editOldPwd.classList.add('is-invalid');
                        errors.push('Old Password is required when setting a new password.');
                    }
                    const val = editPwd.value;
                    const hasUpper = /[A-Z]/.test(val);
                    const hasLower = /[a-z]/.test(val);
                    const hasNumber = /[0-9]/.test(val);
                    const hasSpecial = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(val);
                    const hasLength = val.length >= 8 && val.length <= 30;

                    if (!hasLength) {
                        editPwd.classList.add('is-invalid');
                        errors.push('New Password must be between 8 and 30 characters.');
                    }
                    if (!hasUpper || !hasLower || !hasNumber || !hasSpecial) {
                        editPwd.classList.add('is-invalid');
                        errors.push('New Password criteria verification failed (must contain uppercase, lowercase, digit, and special symbol).');
                    }
                }

                if (errors.length > 0) {
                    errBox.innerHTML = errors.map(e => '<i class="fas fa-exclamation-circle me-1"></i>' + e).join('<br>');
                    errBox.style.display = "block";
                    return;
                }

                // Ensure tabId is included for session management
                let tabInput = document.querySelector('#editInternForm input[name="tabId"]');
                if (!tabInput) {
                    tabInput = document.createElement('input');
                    tabInput.type = 'hidden';
                    tabInput.name = 'tabId';
                    document.getElementById('editInternForm').appendChild(tabInput);
                }
                tabInput.value = window.name || sessionStorage.getItem('tabId') || '';

                // Submit the form
                document.getElementById('editInternForm').submit();
            }

            function openDeleteInternModal(internId, internFullName) {
                // Check if admin is deleting their own account
                const currentUserId = '<%= user.getId() %>';
                if (internId === currentUserId) {
                    showAdminToast("You cannot delete your own admin account.", "danger");
                    return;
                }

                // Map target properties to confirmation tracking tags
                document.getElementById("deleteInternId").value = internId;
                document.getElementById("deleteTargetName").innerText = internFullName;

                // Set tabId for session management
                document.getElementById("deleteTabId").value = window.name || sessionStorage.getItem('tabId') || '';

                // Open confirmation frame modal context
                const deleteModal = new bootstrap.Modal(document.getElementById('deleteInternModal'));
                deleteModal.show();
            }

            function confirmResetHours(internId, internFullName) {
                // Map target properties to confirmation tracking tags
                document.getElementById("resetInternId").value = internId;
                document.getElementById("resetTargetName").innerText = internFullName;

                // Set tabId for session management
                document.getElementById("resetTabId").value = window.name || sessionStorage.getItem('tabId') || '';

                // Open confirmation frame modal context
                const resetModal = new bootstrap.Modal(document.getElementById('resetHoursModal'));
                resetModal.show();
            }

            let internDetailsModalObj = null;
            let currentDetailsRow = null;

            function openLogDetailsModal(subId, internId, identity, dateSub, desc, learnRef, origFile, suppFile) {
                document.getElementById("modalSubId").innerText = "#" + subId;
                document.getElementById("modalInternId").innerText = "ID: #" + internId;
                document.getElementById("modalInternIdentity").innerText = identity;
                document.getElementById("modalDateSubmitted").innerText = dateSub;
                document.getElementById("modalDescription").innerText = desc;
                document.getElementById("modalLearningReflection").innerText = learnRef || "No learning reflection provided.";
                document.getElementById("modalOriginalFile").innerText = origFile;
                document.getElementById("modalSupportingFile").innerText = "Storage path reference: " + suppFile;

                const previewContainer = document.getElementById("modalFilePreviewContainer");
                const previewImg = document.getElementById("modalFilePreview");
                if (suppFile && suppFile !== "stopwatch_sync_timestamp" && (suppFile.toLowerCase().endsWith(".png") || suppFile.toLowerCase().endsWith(".jpg") || suppFile.toLowerCase().endsWith(".jpeg"))) {
                    previewImg.src = "${pageContext.request.contextPath}/uploads/" + encodeURIComponent(suppFile);
                    previewContainer.style.display = "block";
                } else {
                    previewImg.src = "";
                    previewContainer.style.display = "none";
                }

                if (!detailsModalObj) {
                    detailsModalObj = new bootstrap.Modal(document.getElementById('logDetailsModal'));
                }
                detailsModalObj.show();
            }

            function openInternDetailsModal(rowElement) {
                currentDetailsRow = rowElement;

                // Extract fields from custom HTML5 data- attributes
                const id = rowElement.getAttribute("data-id");
                const dispid = rowElement.getAttribute("data-dispid") || id;
                const firstName = rowElement.getAttribute("data-firstname") || "";
                const middleName = rowElement.getAttribute("data-middlename") || "";
                const lastName = rowElement.getAttribute("data-lastname") || "";
                const email = rowElement.getAttribute("data-email") || "";
                const university = rowElement.getAttribute("data-university") || "";
                const city = rowElement.getAttribute("data-city") || "";
                const role = rowElement.getAttribute("data-role") || "";
                const office = rowElement.getAttribute("data-office") || "";
                const createdAt = rowElement.getAttribute("data-createdat") || "N/A";
                const latestFile = rowElement.getAttribute("data-latestfile") || "";
                const latestFileOrig = rowElement.getAttribute("data-latestfileorig") || "";
                const avatarpath = rowElement.getAttribute("data-avatarpath") || "";

                const fullName = ((firstName ? firstName + " " : "") + (middleName ? middleName + " " : "") + lastName).trim();

                const avatarImg = document.getElementById("internModalAvatar");
                if (avatarImg) {
                    if (avatarpath) {
                        avatarImg.src = "${pageContext.request.contextPath}" + avatarpath;
                    } else {
                        avatarImg.src = "https://ui-avatars.com/api/?name=" + encodeURIComponent(fullName) + "&background=d63384&color=fff";
                    }
                }

                // Populate file preview if exists
                const previewContainer = document.getElementById("internModalFilePreviewContainer");
                const previewImg = document.getElementById("internModalFilePreview");
                const previewOrigFile = document.getElementById("internModalOriginalFile");
                const previewSuppFile = document.getElementById("internModalSupportingFile");

                if (latestFile && latestFile !== "stopwatch_sync_timestamp" && (latestFile.toLowerCase().endsWith(".png") || latestFile.toLowerCase().endsWith(".jpg") || latestFile.toLowerCase().endsWith(".jpeg"))) {
                    previewImg.src = "${pageContext.request.contextPath}/uploads/" + encodeURIComponent(latestFile);
                    previewOrigFile.innerText = latestFileOrig;
                    previewSuppFile.innerText = "Storage path reference: " + latestFile;
                    previewContainer.style.display = "block";
                } else {
                    previewImg.src = "";
                    previewOrigFile.innerText = "";
                    previewSuppFile.innerText = "";
                    previewContainer.style.display = "none";
                }

                // Populate elements in modal
                document.getElementById("internModalId").innerText = dispid;
                document.getElementById("internModalName").innerText = fullName;
                document.getElementById("internModalEmail").innerText = email;
                document.getElementById("internModalUniversity").innerText = university || "N/A";
                document.getElementById("internModalCity").innerText = city || "N/A";
                document.getElementById("internModalRole").innerText = role || "N/A";
                document.getElementById("internModalOffice").innerText = office || "N/A";
                document.getElementById("internModalRegistered").innerText = createdAt;

                // Configure buttons in modal
                const downloadBtn = document.getElementById("internModalDownloadBtn");
                const tabId = window.name || sessionStorage.getItem('tabId') || '';
                downloadBtn.href = "${pageContext.request.contextPath}/ReportServlet?type=INTERN_RECORD&internId=" + encodeURIComponent(id) + "&tabId=" + encodeURIComponent(tabId);

                // Configure Edit button
                const editBtn = document.getElementById("internModalEditBtn");
                editBtn.onclick = function() {
                    internDetailsModalObj.hide();
                    openEditInternModal(currentDetailsRow);
                };

                // Configure Reset button
                const resetBtn = document.getElementById("internModalResetBtn");
                resetBtn.onclick = function() {
                    internDetailsModalObj.hide();
                    confirmResetHours(id, firstName + " " + lastName);
                };

                // Configure Delete button
                const deleteBtn = document.getElementById("internModalDeleteBtn");
                const currentAdminId = "<%= user.getId() %>";
                if (id && id.toLowerCase() === currentAdminId.toLowerCase()) {
                    deleteBtn.disabled = true;
                    deleteBtn.innerText = "Cannot Delete Self";
                } else {
                    deleteBtn.disabled = false;
                    deleteBtn.innerHTML = '<i class="fas fa-trash-alt"></i> <span>Delete Profile</span>';
                    deleteBtn.onclick = function() {
                        internDetailsModalObj.hide();
                        openDeleteInternModal(id, firstName + " " + lastName);
                    };
                }

                if (!internDetailsModalObj) {
                    internDetailsModalObj = new bootstrap.Modal(document.getElementById('internDetailsModal'));
                }
                internDetailsModalObj.show();
            }

            function updateLogStatusDatabase(submissionId, selectElement) {
                const newStatus = selectElement.value;
                selectElement.className = "form-select form-select-sm status-select status-" + newStatus;

                fetch("UpdateLogStatusServlet", {
                    method: "POST",
                    headers: {"Content-Type": "application/x-www-form-urlencoded"},
                    body: "submissionId=" + encodeURIComponent(submissionId) + 
                          "&status=" + encodeURIComponent(newStatus) + 
                          "&tabId=" + encodeURIComponent(window.name) + 
                          "&csrfToken=" + encodeURIComponent("<%= CsrfUtil.getToken(session) %>")
                })
                        .then(response => {
                            if (response.ok) {
                                console.log("Database parameters operational flag synchronization completed.");
                                refreshPendingCounters();
                            } else {
                                alert("System failed to execute server parameter database save operations cycles.");
                            }
                        })
                        .catch(err => console.error("Pipeline Sync Connection Interrupted Exception: ", err));
            }

            function refreshPendingCounters() {
                let pendingCount = 0;
                document.querySelectorAll(".status-select").forEach(select => {
                    if (select.value === "Pending")
                        pendingCount++;
                });
                const badge = document.getElementById("sidebarPendingBadge");
                const dashCount = document.getElementById("dashboardPendingCount");
                if (badge)
                    badge.innerText = pendingCount;
                if (dashCount)
                    dashCount.innerText = pendingCount;
            }

            function sortLogTable(columnIndex, toggle = true) {
                if (columnIndex === 3)
                    return;
                const tbody = document.getElementById("logReviewTableBody");
                const rows = Array.from(document.querySelectorAll(".log-row"));

                if (toggle) {
                    if (logSortColumn === columnIndex)
                        logSortAsc = !logSortAsc;
                    else
                        logSortAsc = true;
                }
                logSortColumn = columnIndex;

                rows.sort((a, b) => {
                    let vA, vB;

                    if (columnIndex === 5) {
                        const selectA = a.cells[columnIndex].querySelector("select");
                        const selectB = b.cells[columnIndex].querySelector("select");
                        vA = selectA ? selectA.value.toUpperCase() : "";
                        vB = selectB ? selectB.value.toUpperCase() : "";
                    } else {
                        vA = a.cells[columnIndex].innerText.replace("#", "").trim().toUpperCase();
                        vB = b.cells[columnIndex].innerText.replace("#", "").trim().toUpperCase();
                    }

                    return logSortAsc ? vA.localeCompare(vB) : vB.localeCompare(vA);
                });
                rows.forEach(r => tbody.appendChild(r));
                filterTable();
            }

            function applyLogStatusFilter(value, displayLabel) {
                logStatusFilter = value.toUpperCase().trim();
                const trigger = document.getElementById("statusLabel");
                if (trigger) {
                    trigger.querySelector("span").innerText = displayLabel;
                    if (value !== "")
                        trigger.classList.add('active-filter');
                    else
                        trigger.classList.remove('active-filter');
                }
                resetToFirstPageAndFilter();
            }

            function applyLogOfficeFilter(value, displayLabel) {
                logOfficeFilter = value.toUpperCase().trim();
                const trigger = document.getElementById("logOfficeLabel");
                if (trigger) {
                    trigger.querySelector("span").innerText = displayLabel;
                    if (value !== "")
                        trigger.classList.add('active-filter');
                    else
                        trigger.classList.remove('active-filter');
                }
                resetToFirstPageAndFilter();
            }

            function toggleSelectAllInterns(headerChk) {
                const rows = Array.from(document.querySelectorAll(".intern-row"));
                rows.forEach(row => {
                    if (row.style.display !== "none") {
                        const chk = row.querySelector(".intern-select-chk");
                        if (chk) chk.checked = headerChk.checked;
                    }
                });
            }

            function deleteSelectedInterns() {
                const selectedChks = document.querySelectorAll(".intern-select-chk:checked");
                if (selectedChks.length === 0) {
                    showAdminToast("Please select at least one intern to delete.", "danger");
                    return;
                }
                const ids = Array.from(selectedChks).map(chk => chk.value);
                if (!confirm(`Are you sure you want to delete the ${ids.length} selected intern(s)?`)) return;
                const tabId = window.name || sessionStorage.getItem('tabId') || '';
                const form = document.createElement("form");
                form.method = "POST"; form.action = "DeleteInternServlet";
                const idsInput = document.createElement("input");
                idsInput.type = "hidden"; idsInput.name = "internIds"; idsInput.value = ids.join(",");
                const tabInput = document.createElement("input");
                tabInput.type = "hidden"; tabInput.name = "tabId"; tabInput.value = tabId;
                form.appendChild(idsInput); form.appendChild(tabInput);
                document.body.appendChild(form); form.submit();
            }

            function handleDeleteModeClick() {
                const table = document.getElementById("internTable");
                const btn = document.getElementById("btnDeleteSelected");
                
                if (!table.classList.contains("delete-mode-active")) {
                    // Turn mode ON
                    table.classList.add("delete-mode-active");
                    btn.innerHTML = '<i class="fas fa-trash-alt me-1"></i> Delete Selected';
                    btn.style.backgroundColor = '#dc3545';
                    btn.style.borderColor = '#dc3545';
                } else {
                    // Mode is already ON, so trigger deletion or cancel if nothing checked
                    const selectedChks = document.querySelectorAll(".intern-select-chk:checked");
                    if (selectedChks.length === 0) {
                        // Nothing checked, turn mode OFF
                        table.classList.remove("delete-mode-active");
                        btn.innerHTML = '<i class="fas fa-trash-alt me-1"></i> Delete Intern';
                        btn.style.backgroundColor = '#6c757d';
                        btn.style.borderColor = '#6c757d';
                        // Also clear Select All checkbox
                        const selectAll = document.getElementById("selectAllInterns");
                        if (selectAll) selectAll.checked = false;
                    } else {
                        // Trigger batch deletion
                        deleteSelectedInterns();
                    }
                }
            }

            function sortInternTable(columnIndex, toggle = true) {
                const tbody = document.getElementById("internTableBody");
                const rows = Array.from(document.querySelectorAll(".intern-row"));
                if (toggle) {
                    if (internSortColumn === columnIndex)
                        internSortAsc = !internSortAsc;
                    else
                        internSortAsc = (columnIndex !== 1);
                }
                internSortColumn = columnIndex;
                rows.sort((a, b) => {
                    let vA = a.cells[columnIndex].innerText.trim().toUpperCase();
                    let vB = b.cells[columnIndex].innerText.trim().toUpperCase();

                    return internSortAsc ? vA.localeCompare(vB) : vB.localeCompare(vA);
                });
                rows.forEach(r => tbody.appendChild(r));
                filterTable();
            }

            function filterTable() {
                const searchVal = document.getElementById("internSearch").value.trim().toUpperCase();

                // Clear select all checkboxes and uncheck row checkboxes when filtering
                const selectAll = document.getElementById("selectAllInterns");
                if (selectAll) {
                    selectAll.checked = false;
                }
                document.querySelectorAll(".intern-select-chk").forEach(chk => chk.checked = false);

                // 1. Process Intern Management Registry Table Chunk Logic
                const internRows = Array.from(document.querySelectorAll(".intern-row"));
                if (internRows.length > 0) {
                    let visibleRows = [];
                    internRows.forEach(row => {
                        const rId = row.querySelector(".col-id").innerText.toUpperCase().trim();
                        const rName = row.querySelector(".col-name").innerText.toUpperCase().trim();
                        const rUni = row.querySelector(".col-uni").innerText.toUpperCase().trim();
                        const rCity = row.querySelector(".col-city").innerText.toUpperCase().trim();
                        const rRole = row.querySelector(".col-role").innerText.toUpperCase().trim();
                        const rOffice = row.querySelector(".col-office").innerText.toUpperCase().trim();

                        const matchesSearch = searchVal === "" || rId.includes(searchVal) || rName.includes(searchVal) || rUni.includes(searchVal) || rCity.includes(searchVal) || rRole.includes(searchVal) || rOffice.includes(searchVal);
                        const matchesFilters = (activeFilters.university === "" || rUni === activeFilters.university) &&
                                (activeFilters.city === "" || rCity === activeFilters.city) &&
                                (activeFilters.role === "" || rRole === activeFilters.role) &&
                                (activeFilters.office === "" || rOffice === activeFilters.office);

                        if (matchesSearch && matchesFilters) {
                            visibleRows.push(row);
                        } else {
                            row.style.display = "none";
                        }
                    });

                    const totalEntries = visibleRows.length;
                    const totalPages = Math.ceil(totalEntries / internPageSize) || 1;
                    if (internCurrentPage > totalPages)
                        internCurrentPage = totalPages;

                    const startIdx = (internCurrentPage - 1) * internPageSize;
                    const endIdx = Math.min(startIdx + internPageSize, totalEntries);

                    visibleRows.forEach((row, index) => {
                        row.style.display = (index >= startIdx && index < endIdx) ? "" : "none";
                    });

                    document.getElementById("pageStart").innerText = totalEntries === 0 ? 0 : startIdx + 1;
                    document.getElementById("pageEnd").innerText = endIdx;
                    document.getElementById("totalEntries").innerText = totalEntries;
                    renderPaginationControls(totalPages, 'intern');
                    updateNoDataMessage(totalEntries);
                }

                // 2. Process OJT Activity Submission Table Chunk Logic
                const logRows = Array.from(document.querySelectorAll(".log-row"));
                if (logRows.length > 0) {
                    let visibleLogs = [];
                    logRows.forEach(row => {
                        const selectEl = row.querySelector("select");
                        const selectVal = selectEl ? selectEl.value.toUpperCase() : "";
                        const rOffice = row.cells[4].innerText.toUpperCase().trim();
                        const textContent = row.innerText.toUpperCase() + " " + selectVal;

                        const matchesSearch = searchVal === "" || textContent.includes(searchVal);
                        const matchesStatus = logStatusFilter === "" || selectVal === logStatusFilter;
                        const matchesOffice = logOfficeFilter === "" || rOffice === logOfficeFilter;

                        if (matchesSearch && matchesStatus && matchesOffice) {
                            visibleLogs.push(row);
                        } else {
                            row.style.display = "none";
                        }
                    });

                    const totalEntries = visibleLogs.length;
                    const totalPages = Math.ceil(totalEntries / logPageSize) || 1;
                    if (logCurrentPage > totalPages)
                        logCurrentPage = totalPages;

                    const startIdx = (logCurrentPage - 1) * logPageSize;
                    const endIdx = Math.min(startIdx + logPageSize, totalEntries);

                    visibleLogs.forEach((row, index) => {
                        row.style.display = (index >= startIdx && index < endIdx) ? "" : "none";
                    });

                    document.getElementById("logPageStart").innerText = totalEntries === 0 ? 0 : startIdx + 1;
                    document.getElementById("logPageEnd").innerText = endIdx;
                    document.getElementById("logTotalEntries").innerText = totalEntries;
                    renderPaginationControls(totalPages, 'log');
                    updateLogNoDataMessage(totalEntries);
                }
            }

            function renderPaginationControls(totalPages, type) {
                const container = document.getElementById(type === 'intern' ? "paginationButtons" : "logPaginationButtons");
                if (!container)
                    return;

                container.innerHTML = "";
                if (totalPages <= 1)
                    return;

                const curr = type === 'intern' ? internCurrentPage : logCurrentPage;

                const prevLi = document.createElement("li");
                prevLi.className = "page-item " + (curr === 1 ? "disabled" : "");
                prevLi.innerHTML = '<a class="page-link" href="#" onclick="goToPage(' + (curr - 1) + ', \'' + type + '\'); return false;"><i class="fas fa-chevron-left"></i></a>';
                container.appendChild(prevLi);

                for (let i = 1; i <= totalPages; i++) {
                    const pageLi = document.createElement("li");
                    pageLi.className = "page-item " + (curr === i ? "active" : "");
                    pageLi.innerHTML = '<a class="page-link" href="#" onclick="goToPage(' + i + ', \'' + type + '\'); return false;">' + i + '</a>';
                    container.appendChild(pageLi);
                }

                const nextLi = document.createElement("li");
                nextLi.className = "page-item " + (curr === totalPages ? "disabled" : "");
                nextLi.innerHTML = '<a class="page-link" href="#" onclick="goToPage(' + (curr + 1) + ', \'' + type + '\'); return false;"><i class="fas fa-chevron-right"></i></a>';
                container.appendChild(nextLi);
            }

            function goToPage(pageNumber, type) {
                if (type === 'intern')
                    internCurrentPage = pageNumber;
                else
                    logCurrentPage = pageNumber;
                filterTable();
            }

            function changePageSize(value, type) {
                if (type === 'intern') {
                    internPageSize = parseInt(value);
                    internCurrentPage = 1;
                } else if (type === 'audit') {
                    auditPageSize = parseInt(value);
                    auditCurrentPage = 1;
                    renderAuditTable();
                    return;
                } else {
                    logPageSize = parseInt(value);
                    logCurrentPage = 1;
                }
                filterTable();
            }

            // Client filter clean initialization reset chain trigger
            function resetToFirstPageAndFilter() {
                internCurrentPage = 1;
                logCurrentPage = 1;
                filterTable();
            }

            function switchView(viewId) {
                document.getElementById("internSearch").value = "";
                stopMessagingPolling();

                const searchContainer = document.querySelector(".search-container");
                if (searchContainer) {
                    if (viewId === 'dashboard' || viewId === 'report-center' || viewId === 'audit-trail') {
                        searchContainer.style.display = 'none';
                    } else {
                        searchContainer.style.display = 'block';
                    }
                }

                document.getElementById('dashboard-view').style.display = 'none';
                document.getElementById('intern-management-view').style.display = 'none';
                document.getElementById('log-review-view').style.display = 'none';
                document.getElementById('report-center-view').style.display = 'none';
                document.getElementById('audit-trail-view').style.display = 'none';

                document.getElementById('nav-dashboard').classList.remove('active');
                document.getElementById('nav-interns').classList.remove('active');
                document.getElementById('nav-logs').classList.remove('active');
                document.getElementById('nav-reports').classList.remove('active');
                document.getElementById('nav-audit').classList.remove('active');

                if (viewId === 'dashboard') {
                    document.getElementById('dashboard-view').style.display = 'block';
                    document.getElementById('nav-dashboard').classList.add('active');
                    document.getElementById('mainPageTitle').innerText = "Coordinator's Dashboard";
                    const messagingPanel = document.getElementById("sub-messaging");
                    if (messagingPanel && messagingPanel.style.display === "block") {
                        startMessagingPolling();
                        loadContacts();
                    }
                } else if (viewId === 'intern-management') {
                    document.getElementById('intern-management-view').style.display = 'block';
                    document.getElementById('nav-interns').classList.add('active');
                    document.getElementById('mainPageTitle').innerText = "Intern Accounts Registry";
                    filterTable();
                } else if (viewId === 'log-review') {
                    document.getElementById('log-review-view').style.display = 'block';
                    document.getElementById('nav-logs').classList.add('active');
                    document.getElementById('mainPageTitle').innerText = "Log Review Center";
                    filterTable();
                } else if (viewId === 'report-center') {
                    document.getElementById('report-center-view').style.display = 'block';
                    document.getElementById('nav-reports').classList.add('active');
                    document.getElementById('mainPageTitle').innerText = "PDF Report Center";
                } else if (viewId === 'audit-trail') {
                    document.getElementById('audit-trail-view').style.display = 'block';
                    document.getElementById('nav-audit').classList.add('active');
                    document.getElementById('mainPageTitle').innerText = "System Audit Trail";
                    if (!auditLoaded)
                        loadAuditTrail();
                } else {
                    document.getElementById(viewId + '-view').style.display = 'block';
                    document.getElementById('nav-' + viewId.split('-')[0]).classList.add('active');
                }
                document.body.classList.remove("show-sidebar");
            }

            function populateDropdowns() {
                const rows = Array.from(document.querySelectorAll(".intern-row"));
                const data = {uni: new Set(), role: new Set(), office: new Set(), city: new Set()};
                rows.forEach(row => {
                    const colUni = row.querySelector(".col-uni");
                    const colCity = row.querySelector(".col-city");
                    const colRole = row.querySelector(".col-role");
                    const colOffice = row.querySelector(".col-office");
                    if (colUni) data.uni.add(colUni.innerText.trim());
                    if (colCity) data.city.add(colCity.innerText.trim());
                    if (colRole) data.role.add(colRole.innerText.trim());
                    if (colOffice) data.office.add(colOffice.innerText.trim());
                });
                renderMenu("uniOptions", "university", "University", data.uni, "fa-university");
                renderMenu("cityOptions", "city", "City", data.city, "fa-map-marker-alt");
                renderMenu("roleOptions", "role", "Role", data.role, "fa-user-tag");
                renderMenu("officeOptions", "office", "Office", data.office, "fa-building");

                const logRows = Array.from(document.querySelectorAll(".log-row"));
                const logOffices = new Set();
                logRows.forEach(row => {
                    logOffices.add(row.cells[4].innerText.trim());
                });
                renderLogOfficeMenu("logOfficeOptions", "Office", logOffices, "fa-building");
            }

            function renderMenu(containerId, filterKey, labelDefault, valueSet, icon) {
                const container = document.getElementById(containerId);
                container.innerHTML = "";
                const allOpt = document.createElement("div");
                allOpt.className = "filter-option reset-opt";
                allOpt.innerText = "All " + labelDefault;
                allOpt.onclick = () => applyFilter(filterKey, "", labelDefault, icon);
                container.appendChild(allOpt);

                Array.from(valueSet).sort().forEach(val => {
                    if (!val || val === "N/A")
                        return;
                    const opt = document.createElement("div");
                    opt.className = "filter-option";
                    opt.innerText = val;
                    opt.onclick = () => applyFilter(filterKey, val, val, icon);
                    container.appendChild(opt);
                });
            }

            function renderLogOfficeMenu(containerId, labelDefault, valueSet, icon) {
                const container = document.getElementById(containerId);
                if (!container)
                    return;
                container.innerHTML = "";
                const allOpt = document.createElement("div");
                allOpt.className = "filter-option reset-opt";
                allOpt.innerText = "All " + labelDefault;
                allOpt.onclick = () => applyLogOfficeFilter("", "Assigned Office");
                container.appendChild(allOpt);

                Array.from(valueSet).sort().forEach(val => {
                    if (!val || val === "N/A")
                        return;
                    const opt = document.createElement("div");
                    opt.className = "filter-option";
                    opt.innerText = val;
                    opt.onclick = () => applyLogOfficeFilter(val, val);
                    container.appendChild(opt);
                });
            }

            function applyFilter(key, value, displayLabel, icon) {
                activeFilters[key] = value.toUpperCase().trim();
                const labelId = (key === "university") ? "uniLabel" : (key === "city") ? "cityLabel" : key + "Label";
                const trigger = document.getElementById(labelId);
                if (trigger) {
                    trigger.querySelector("span").innerText = displayLabel;
                    if (value !== "")
                        trigger.classList.add('active-filter');
                    else
                        trigger.classList.remove('active-filter');
                }
                resetToFirstPageAndFilter();
            }

            function openAddInternModal() {
                if (!addInternModalObj)
                    addInternModalObj = new bootstrap.Modal(document.getElementById('addInternModal'));
                document.getElementById("addInternForm").reset();

                const inputs = document.querySelectorAll('#addInternForm .form-control, #addInternForm .form-select');
                inputs.forEach(input => input.classList.remove('is-invalid', 'is-valid'));

                document.getElementById("intAgeDisplay").value = "N/A";
                document.getElementById("intOfficeDisplay").value = "";
                document.getElementById("intEmailDisplay").value = "";
                document.getElementById("modalFormError").style.display = "none";

                document.getElementById("phoneValidCheck").classList.add("d-none");
                document.getElementById("phoneErrorMsg").style.display = "none";

                handlePasswordInput(document.getElementById("intPassword"));
                addInternModalObj.show();
            }

            function clearInvalidState(element) {
                element.classList.remove('is-invalid');
            }

            function handlePhoneInput(element) {
                const val = element.value.trim();
                const checkWrapper = document.getElementById("phoneValidCheck");
                const errorMsg = document.getElementById("phoneErrorMsg");
                const digitsRegex = /^[0-9]+$/;

                element.classList.remove("is-valid", "is-invalid");
                errorMsg.style.display = "none";
                checkWrapper.classList.add("d-none");

                if (val.length === 0)
                    return;

                if (!digitsRegex.test(val)) {
                    element.classList.add("is-invalid");
                    checkWrapper.classList.remove("d-none");
                    checkWrapper.innerHTML = '<i class="fas fa-times-circle text-danger"></i>';
                    errorMsg.innerText = "Contact number must contain numbers only.";
                    errorMsg.style.display = "block";
                    return;
                }

                if (val.length > 10) {
                    element.classList.add("is-invalid");
                    checkWrapper.classList.remove("d-none");
                    checkWrapper.innerHTML = '<i class="fas fa-times-circle text-danger"></i>';
                    errorMsg.innerText = "Contact number exceeds the maximum limit of 10 digits.";
                    errorMsg.style.display = "block";
                } else if (val.length === 10) {
                    if (val.startsWith("9")) {
                        checkWrapper.classList.remove("d-none");
                        checkWrapper.innerHTML = '<i class="fas fa-check-circle text-success"></i>';
                        element.classList.add("is-valid");
                    } else {
                        element.classList.add("is-invalid");
                        checkWrapper.classList.remove("d-none");
                        checkWrapper.innerHTML = '<i class="fas fa-times-circle text-danger"></i>';
                        errorMsg.innerText = "PH Mobile Number must start with 9.";
                        errorMsg.style.display = "block";
                    }
                } else {
                    if (!val.startsWith("9")) {
                        element.classList.add("is-invalid");
                        checkWrapper.classList.remove("d-none");
                        checkWrapper.innerHTML = '<i class="fas fa-times-circle text-danger"></i>';
                        errorMsg.innerText = "PH Mobile Number must start with 9.";
                        errorMsg.style.display = "block";
                    }
                }
            }

            function handlePasswordInput(element) {
                const val = element.value;
                const hasUpper = /[A-Z]/.test(val);
                const hasLower = /[a-z]/.test(val);
                const hasNumber = /[0-9]/.test(val);
                const hasSpecial = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(val);
                const hasLength = val.length >= 8 && val.length <= 30;

                updateRuleIndicator("rule-upper", hasUpper);
                updateRuleIndicator("rule-lower", hasLower);
                updateRuleIndicator("rule-number", hasNumber);
                updateRuleIndicator("rule-special", hasSpecial);
                updateRuleIndicator("rule-length", hasLength);
            }

            function handleEditPasswordInput(element) {
                const val = element.value;
                const oldContainer = document.getElementById("editOldPasswordContainer");
                const oldInput = document.getElementById("editOldPassword");
                const policyWrapper = document.getElementById("edit-password-policies");

                if (val.length > 0) {
                    oldContainer.style.display = "block";
                    oldInput.setAttribute("required", "required");
                    policyWrapper.style.display = "block";
                } else {
                    oldContainer.style.display = "none";
                    oldInput.removeAttribute("required");
                    oldInput.value = "";
                    policyWrapper.style.display = "none";
                }

                const hasUpper = /[A-Z]/.test(val);
                const hasLower = /[a-z]/.test(val);
                const hasNumber = /[0-9]/.test(val);
                const hasSpecial = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(val);
                const hasLength = val.length >= 8 && val.length <= 30;

                updateRuleIndicator("edit-rule-upper", hasUpper);
                updateRuleIndicator("edit-rule-lower", hasLower);
                updateRuleIndicator("edit-rule-number", hasNumber);
                updateRuleIndicator("edit-rule-special", hasSpecial);
                updateRuleIndicator("edit-rule-length", hasLength);
            }

            function updateRuleIndicator(id, isMet) {
                const item = document.getElementById(id);
                if (!item)
                    return;
                const icon = item.querySelector("i");
                if (isMet) {
                    icon.className = "fas fa-check-circle text-success";
                    item.classList.add("text-success");
                } else {
                    icon.className = "far fa-circle text-muted";
                    item.classList.remove("text-success");
                }
            }

            function calculateAge() {
                const birthYearInput = document.getElementById("intBirthYear").value.trim();
                const display = document.getElementById("intAgeDisplay");
                const parsedYear = parseInt(birthYearInput);
                const currentYear = new Date().getFullYear();

                if (!isNaN(parsedYear) && birthYearInput.length === 4 && parsedYear <= currentYear && parsedYear >= 1900) {
                    display.value = currentYear - parsedYear;
                } else {
                    display.value = "N/A";
                }
            }

            function handleRoleAssignment() {
                const roleSelect = document.getElementById("intRole");
                if (roleSelect.selectedIndex <= 0)
                    return;
                const chosenOpt = roleSelect.options[roleSelect.selectedIndex];
                document.getElementById("intOfficeDisplay").value = chosenOpt.getAttribute("data-office");
                updateAutoGeneratedFields();
            }

            function updateAutoGeneratedFields() {
                const fName = document.getElementById("intFirstName").value.trim().replace(/\s+/g, "");
                const lName = document.getElementById("intLastName").value.trim().replace(/\s+/g, "");
                const roleSelect = document.getElementById("intRole");

                let code = "";
                if (roleSelect.selectedIndex > 0) {
                    code = roleSelect.options[roleSelect.selectedIndex].getAttribute("data-code");
                }

                const emailBox = document.getElementById("intEmailDisplay");
                if (fName !== "" && lName !== "" && code !== "") {
                    emailBox.value = (fName + "." + lName + "." + code).toLowerCase() + "@gmail.com";
                } else {
                    emailBox.value = "";
                }
            }

            function validateAndProcessInternForm() {
                const errBox = document.getElementById("modalFormError");
                errBox.style.display = "none";
                errBox.innerText = "";

                const inputs = document.querySelectorAll('#addInternForm .form-control, #addInternForm .form-select');
                inputs.forEach(input => input.classList.remove('is-invalid'));

                let errors = [];
                const fNameField = document.getElementById("intFirstName");
                const mNameField = document.getElementById("intMiddleName");
                const lNameField = document.getElementById("intLastName");
                const bMonthField = document.getElementById("intBirthMonth");
                const bDateField = document.getElementById("intBirthDate");
                const bYearField = document.getElementById("intBirthYear");
                const cityField = document.getElementById("intCity");
                const phoneField = document.getElementById("intContactNum");
                const uniField = document.getElementById("intUniversity");
                const roleField = document.getElementById("intRole");
                const passField = document.getElementById("intPassword");

                if (!fNameField.value.trim()) {
                    fNameField.classList.add('is-invalid');
                    errors.push("First Name is required.");
                }
                if (!mNameField.value.trim()) {
                    mNameField.classList.add('is-invalid');
                    errors.push("Middle Name is required.");
                }
                if (!lNameField.value.trim()) {
                    lNameField.classList.add('is-invalid');
                    errors.push("Last Name is required.");
                }
                if (!bMonthField.value) {
                    bMonthField.classList.add('is-invalid');
                    errors.push("Birth Month is required.");
                }
                if (!bDateField.value) {
                    bDateField.classList.add('is-invalid');
                    errors.push("Birth Date is required.");
                }

                const bYear = parseInt(bYearField.value);
                if (isNaN(bYear) || bYearField.value.trim().length !== 4 || bYear < 1900 || bYear > 2026) {
                    bYearField.classList.add('is-invalid');
                    errors.push("Provide a valid 4-digit Birth Year (1900-2026).");
                }
                if (!cityField.value) {
                    cityField.classList.add('is-invalid');
                    errors.push("City Selection is required.");
                }
                if (!uniField.value.trim()) {
                    uniField.classList.add('is-invalid');
                    errors.push("University Name is required.");
                }
                if (!roleField.value) {
                    roleField.classList.add('is-invalid');
                    errors.push("Technical Intern Role is required.");
                }

                const digitsRegex = /^[0-9]+$/;
                const phoneNum = phoneField.value.trim();
                if (!phoneNum) {
                    phoneField.classList.add('is-invalid');
                    errors.push("Contact Number is required.");
                } else if (!digitsRegex.test(phoneNum)) {
                    phoneField.classList.add('is-invalid');
                    errors.push("Contact Number must contain numbers only.");
                } else if (phoneNum.length !== 10 || !phoneNum.startsWith("9")) {
                    phoneField.classList.add('is-invalid');
                    errors.push("PH Mobile Number must be exactly 10 digits starting with 9.");
                }

                const pass = passField.value;
                if (!pass) {
                    passField.classList.add('is-invalid');
                    errors.push("Access Security Password is required.");
                } else {
                    if (pass.length < 8 || pass.length > 30) {
                        passField.classList.add('is-invalid');
                        errors.push("Password must be between 8 and 30 characters.");
                    }
                    if (!/[A-Z]/.test(pass) || !/[a-z]/.test(pass) || !/[0-9]/.test(pass)) {
                        passField.classList.add('is-invalid');
                        errors.push("Password criteria verification failed.");
                    }
                }

                if (errors.length > 0) {
                    errBox.innerText = errors.join(" | ");
                    errBox.style.display = "block";
                    return;
                }

                // Ensure tabId is included for session management
                let tabInput = document.querySelector('#addInternForm input[name="tabId"]');
                if (!tabInput) {
                    tabInput = document.createElement('input');
                    tabInput.type = 'hidden';
                    tabInput.name = 'tabId';
                    document.getElementById('addInternForm').appendChild(tabInput);
                }
                tabInput.value = window.name || sessionStorage.getItem('tabId') || '';

                addInternModalObj.hide();
                document.getElementById("addInternForm").submit();
            }

            function updateNoDataMessage(visibleCount) {
                const tbody = document.getElementById("internTableBody");
                let msg = document.getElementById("filterNoData");
                if (visibleCount === 0) {
                    if (!msg) {
                        msg = document.createElement("tr");
                        msg.id = "filterNoData";
                        msg.innerHTML = '<td colspan="6" style="text-align:center; padding:40px; color:#888;">No matches found.</td>';
                        tbody.appendChild(msg);
                    }
                } else if (msg)
                    msg.remove();
            }

            function updateLogNoDataMessage(visibleCount) {
                const tbody = document.getElementById("logReviewTableBody");
                let msg = document.getElementById("logFilterNoData");
                if (visibleCount === 0) {
                    if (!msg) {
                        msg = document.createElement("tr");
                        msg.id = "logFilterNoData";
                        msg.innerHTML = '<td colspan="6" style="text-align:center; padding:40px; color:#888;">No matching records found.</td>';
                        tbody.appendChild(msg);
                    }
                } else if (msg)
                    msg.remove();
            }

            function customChangePageSize(value, type) {
                let labelId;
                if (type === 'intern')
                    labelId = 'internSizeLabel';
                else if (type === 'audit')
                    labelId = 'auditSizeLabel';
                else
                    labelId = 'logSizeLabel';
                document.querySelector("#" + labelId + " span").innerText = value;
                changePageSize(value, type);
            }

            // ══════════════════════════════════════════════════════════
            // REPORT DOWNLOAD FUNCTIONS
            // ══════════════════════════════════════════════════════════

            function downloadReport(type) {
                window.location.href = 'ReportServlet?type=' + type + '&tabId=<%= tabId %>';
            }

            function downloadOjtReport() {
                const from = document.getElementById('ojtFromDate').value;
                const to = document.getElementById('ojtToDate').value;
                let url = 'ReportServlet?type=OJTLOGS&tabId=<%= tabId %>';
                if (from || to) {
                    if (from && to && from > to) {
                        alert('"From" date must be before or equal to the "To" date.');
                        return;
                    }
                    url += '&from=' + encodeURIComponent(from) + '&to=' + encodeURIComponent(to);
                }
                window.location.href = url;
            }

            function refreshLogReview() {
                window.location.href = 'admin.jsp?tabId=<%= tabId %>&view=log-review';
            }

            // ══════════════════════════════════════════════════════════
            // AUDIT TRAIL TABLE (AJAX from PostgreSQL via AuditServlet)
            // ══════════════════════════════════════════════════════════

            function loadAuditTrail() {
                const tbody = document.getElementById('auditTableBody');
                tbody.innerHTML = '<tr><td colspan="6" class="text-center text-muted py-4"><i class="fas fa-spinner fa-spin me-2"></i>Loading audit data from PostgreSQL...</td></tr>';

                fetch('AuditServlet?tabId=' + encodeURIComponent(window.name))
                        .then(response => {
                            if (!response.ok)
                                throw new Error('Server returned ' + response.status);
                            return response.json();
                        })
                        .then(data => {
                            auditData = data;
                            auditLoaded = true;
                            auditCurrentPage = 1;
                            renderAuditTable();
                        })
                        .catch(err => {
                            console.error('Audit trail fetch error:', err);
                            tbody.innerHTML = '<tr><td colspan="6" class="text-center text-danger py-4"><i class="fas fa-exclamation-triangle me-2"></i>Failed to load audit data. Check PostgreSQL connection.</td></tr>';
                        });
            }

            function renderAuditTable() {
                const tbody = document.getElementById('auditTableBody');
                tbody.innerHTML = '';

                if (auditData.length === 0) {
                    tbody.innerHTML = '<tr><td colspan="6" class="text-center text-muted py-4">No audit log entries found.</td></tr>';
                    document.getElementById('auditPageStart').innerText = '0';
                    document.getElementById('auditPageEnd').innerText = '0';
                    document.getElementById('auditTotalEntries').innerText = '0';
                    return;
                }

                const totalEntries = auditData.length;
                const totalPages = Math.ceil(totalEntries / auditPageSize) || 1;
                if (auditCurrentPage > totalPages)
                    auditCurrentPage = totalPages;

                const startIdx = (auditCurrentPage - 1) * auditPageSize;
                const endIdx = Math.min(startIdx + auditPageSize, totalEntries);

                for (let i = startIdx; i < endIdx; i++) {
                    const log = auditData[i];
                    const tr = document.createElement('tr');
                    tr.className = 'audit-row';

                    // Action badge color
                    let actionBadge = '';
                    if (log.action === 'LOGIN')
                        actionBadge = '<span class="badge bg-success">' + log.action + '</span>';
                    else if (log.action === 'LOGOUT')
                        actionBadge = '<span class="badge bg-secondary">' + log.action + '</span>';
                    else
                        actionBadge = '<span class="badge bg-primary">' + log.action + '</span>';

                    let dispUserId = log.user_id;
                    if (log.username === 'James Smith' || log.username === 'System Administrator' || (dispUserId && dispUserId.startsWith('ADM')) || dispUserId === 'ADM2020-0001' || dispUserId === 'ADM2026-0001') {
                        if (dispUserId && dispUserId.startsWith('ADM')) {
                            // Keep it
                        } else {
                            dispUserId = 'ADM2020-0001';
                        }
                    } else if (dispUserId && /^\d+$/.test(dispUserId)) {
                        dispUserId = 'INT2026-7' + String(dispUserId).padStart(4, '0');
                    }

                    tr.innerHTML = '<td>' + log.created_at + '</td>' +
                            '<td><span style="font-family: monospace; font-size: 12px;">' + dispUserId + '</span></td>' +
                            '<td>' + log.username + '</td>' +
                            '<td>' + actionBadge + '</td>' +
                            '<td><small class="text-muted">' + log.details + '</small></td>' +
                            '<td><small>' + log.ip_address + '</small></td>';
                    tbody.appendChild(tr);
                }

                document.getElementById('auditPageStart').innerText = totalEntries === 0 ? 0 : startIdx + 1;
                document.getElementById('auditPageEnd').innerText = endIdx;
                document.getElementById('auditTotalEntries').innerText = totalEntries;
                renderAuditPagination(totalPages);
            }

            function renderAuditPagination(totalPages) {
                const container = document.getElementById('auditPaginationButtons');
                container.innerHTML = '';
                if (totalPages <= 1)
                    return;

                const prevLi = document.createElement('li');
                prevLi.className = 'page-item ' + (auditCurrentPage === 1 ? 'disabled' : '');
                prevLi.innerHTML = '<a class="page-link" href="#" onclick="goToAuditPage(' + (auditCurrentPage - 1) + '); return false;"><i class="fas fa-chevron-left"></i></a>';
                container.appendChild(prevLi);

                for (let i = 1; i <= totalPages; i++) {
                    const pageLi = document.createElement('li');
                    pageLi.className = 'page-item ' + (auditCurrentPage === i ? 'active' : '');
                    pageLi.innerHTML = '<a class="page-link" href="#" onclick="goToAuditPage(' + i + '); return false;">' + i + '</a>';
                    container.appendChild(pageLi);
                }

                const nextLi = document.createElement('li');
                nextLi.className = 'page-item ' + (auditCurrentPage === totalPages ? 'disabled' : '');
                nextLi.innerHTML = '<a class="page-link" href="#" onclick="goToAuditPage(' + (auditCurrentPage + 1) + '); return false;"><i class="fas fa-chevron-right"></i></a>';
                container.appendChild(nextLi);
            }

            function goToAuditPage(pageNumber) {
                auditCurrentPage = pageNumber;
                renderAuditTable();
            }

            function sortAuditTable(columnIndex) {
                if (auditSortColumn === columnIndex)
                    auditSortAsc = !auditSortAsc;
                else
                    auditSortAsc = true;
                auditSortColumn = columnIndex;

                const keys = ['created_at', 'user_id', 'username', 'action'];
                const key = keys[columnIndex];

                auditData.sort((a, b) => {
                    let vA = (a[key] || '').toString().toUpperCase();
                    let vB = (b[key] || '').toString().toUpperCase();
                    return auditSortAsc ? vA.localeCompare(vB) : vB.localeCompare(vA);
                });

                auditCurrentPage = 1;
                renderAuditTable();
            }

            // Dashboard Sub-tabs & Features
            let messagingPollingInterval = null;
            let activeContactId = null;
            let activeContactName = "";
            let chatPollInterval = null;
            let contactPollInterval = null;

            function switchSubDashboard(tabId) {
                document.querySelectorAll('.sub-dashboard-panel').forEach(el => el.style.display = 'none');
                document.querySelectorAll('.sub-tab-btn').forEach(btn => btn.classList.remove('active'));

                document.getElementById(tabId).style.display = 'block';
                if (tabId === 'sub-overview') {
                    document.getElementById('btn-sub-overview').classList.add('active');
                    stopMessagingPolling();
                } else if (tabId === 'sub-announcements') {
                    document.getElementById('btn-sub-announcements').classList.add('active');
                    stopMessagingPolling();
                    loadAnnouncements();
                } else if (tabId === 'sub-messaging') {
                    document.getElementById('btn-sub-messaging').classList.add('active');
                    loadContacts();
                    startMessagingPolling();
                }
            }

            function handleTargetTypeChange() {
                const targetType = document.getElementById("annTargetType").value;
                const valueGroup = document.getElementById("annTargetValueGroup");
                const valueLabel = document.getElementById("annTargetValueLabel");
                const valueSelect = document.getElementById("annTargetValue");

                if (targetType === "ALL") {
                    valueGroup.classList.add("d-none");
                    valueSelect.removeAttribute("required");
                } else {
                    valueGroup.classList.remove("d-none");
                    valueSelect.setAttribute("required", "required");
                    valueSelect.innerHTML = "";

                    if (targetType === "OFFICE") {
                        valueLabel.innerText = "Target Office";
                    } else if (targetType === "ROLE") {
                        valueLabel.innerText = "Target Role";
                    } else if (targetType === "CITY") {
                        valueLabel.innerText = "Target City";
                    }

                    const rows = Array.from(document.querySelectorAll(".intern-row"));
                    const values = new Set();
                    rows.forEach(row => {
                        if (targetType === "OFFICE") {
                            const col = row.querySelector(".col-office");
                            if (col) values.add(col.innerText.trim());
                        } else if (targetType === "ROLE") {
                            const col = row.querySelector(".col-role");
                            if (col) values.add(col.innerText.trim());
                        } else if (targetType === "CITY") {
                            const col = row.querySelector(".col-city");
                            if (col) values.add(col.innerText.trim());
                        }
                    });

                    Array.from(values).sort().forEach(val => {
                        if (val && val !== "N/A" && val !== "") {
                            const opt = document.createElement("option");
                            opt.value = val;
                            opt.innerText = val;
                            valueSelect.appendChild(opt);
                        }
                    });
                }
            }

            function loadAnnouncements() {
                const tbody = document.getElementById("announcementHistoryBody");
                const tabId = window.name || sessionStorage.getItem('tabId') || '';
                fetch("announcements_api.jsp?tabId=" + encodeURIComponent(tabId))
                    .then(r => r.json())
                    .then(data => {
                        if (data.length === 0) {
                            tbody.innerHTML = '<tr><td colspan="4" class="text-center py-4 text-muted">No announcements posted yet.</td></tr>';
                            return;
                        }

                        let html = "";
                        data.forEach(ann => {
                            const targetDisp = ann.targetType === "ALL" 
                                ? "All Interns" 
                                : ann.targetType + ": " + ann.targetValue;
                            
                            html += '<tr>' +
                                '<td><small class="text-muted">' + ann.createdAt + '</small></td>' +
                                '<td><span class="badge bg-light text-dark border">' + targetDisp + '</span></td>' +
                                '<td><strong>' + escapeHtml(ann.title) + '</strong><div class="text-muted small">' + escapeHtml(ann.content) + '</div></td>' +
                                '<td class="text-end">' +
                                    '<button type="button" class="btn btn-sm btn-outline-danger" onclick="deleteAnnouncement(' + ann.id + ')">' +
                                        '<i class="fas fa-trash-alt"></i>' +
                                    '</button>' +
                                '</td>' +
                            '</tr>';
                        });
                        tbody.innerHTML = html;
                    })
                    .catch(e => {
                        tbody.innerHTML = '<tr><td colspan="4" class="text-center py-4 text-danger">Failed to load announcement history.</td></tr>';
                    });
            }

            function submitAnnouncement(event) {
                event.preventDefault();
                const title = document.getElementById("annTitle").value.trim();
                const content = document.getElementById("annContent").value.trim();
                const targetType = document.getElementById("annTargetType").value;
                const targetValue = document.getElementById("annTargetValue") ? document.getElementById("annTargetValue").value : "";
                const tabId = window.name || sessionStorage.getItem('tabId') || '';

                const params = new URLSearchParams();
                params.append("action", "add");
                params.append("title", title);
                params.append("content", content);
                params.append("targetType", targetType);
                params.append("targetValue", targetValue);
                params.append("tabId", tabId);

                fetch("announcements_api.jsp", {
                    method: "POST",
                    headers: { "Content-Type": "application/x-www-form-urlencoded" },
                    body: params.toString()
                })
                .then(r => r.json())
                .then(res => {
                    if (res.success) {
                        showAdminToast("Announcement published successfully!", "success");
                        document.getElementById("announcementForm").reset();
                        handleTargetTypeChange();
                        loadAnnouncements();
                    } else {
                        showAdminToast("Failed to publish: " + (res.error || ""), "danger");
                    }
                })
                .catch(e => showAdminToast("Error publishing announcement", "danger"));
            }

            function deleteAnnouncement(id) {
                if (!confirm("Are you sure you want to permanently delete this announcement?")) return;
                const tabId = window.name || sessionStorage.getItem('tabId') || '';

                const params = new URLSearchParams();
                params.append("action", "delete");
                params.append("id", id);
                params.append("tabId", tabId);

                fetch("announcements_api.jsp", {
                    method: "POST",
                    headers: { "Content-Type": "application/x-www-form-urlencoded" },
                    body: params.toString()
                })
                .then(r => r.json())
                .then(res => {
                    if (res.success) {
                        showAdminToast("Announcement deleted.", "success");
                        loadAnnouncements();
                    } else {
                        showAdminToast("Failed to delete announcement: " + (res.error || ""), "danger");
                    }
                })
                .catch(e => showAdminToast("Error deleting announcement", "danger"));
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
                const listContainer = document.getElementById("chatContactsList");
                const tabId = window.name || sessionStorage.getItem('tabId') || '';
                fetch("messages_api.jsp?action=contacts&tabId=" + encodeURIComponent(tabId))
                    .then(r => r.json())
                    .then(data => renderContactsList(data))
                    .catch(e => {
                        listContainer.innerHTML = '<div class="text-center py-4 text-danger">Failed to load contacts.</div>';
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
                const listContainer = document.getElementById("chatContactsList");
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
                    updateUnreadBadgeCount(totalUnread);
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
                    const avatarUrl = c.avatarPath ? ('${pageContext.request.contextPath}' + c.avatarPath) : ('https://ui-avatars.com/api/?name=' + encodeURIComponent(c.name) + '&background=d63384&color=fff');
                    html += '<div class="contact-item ' + isActive + '" data-id="' + c.id + '" onclick="selectContact(\'' + c.id + '\', \'' + c.name.replace(/'/g, "\\'") + '\')">' +
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

                updateUnreadBadgeCount(totalUnread);
            }

            function updateUnreadBadgeCount(totalUnread) {
                const unreadBadge = document.getElementById("dashboardUnreadBadge");
                if (unreadBadge) {
                    unreadBadge.innerText = totalUnread;
                    if (totalUnread > 0) {
                        unreadBadge.classList.remove("d-none");
                    } else {
                        unreadBadge.classList.add("d-none");
                    }
                }
                const sidebarBadge = document.getElementById("sidebarDashboardUnreadBadge");
                if (sidebarBadge) {
                    sidebarBadge.innerText = totalUnread;
                    if (totalUnread > 0) {
                        sidebarBadge.classList.remove("d-none");
                    } else {
                        sidebarBadge.classList.add("d-none");
                    }
                }
            }

            function filterContacts() {
                renderContactsList();
            }

            function selectContact(contactId, contactName) {
                activeContactId = contactId;
                activeContactName = contactName;

                // Mark as read in client-side cache immediately
                const contact = allContactsData.find(c => c.id === contactId);
                if (contact) {
                    contact.unreadCount = 0;
                }

                renderContactsList();

                const avatarPath = contact ? (contact.avatarPath || "") : "";
                const avatarUrl = avatarPath ? ('${pageContext.request.contextPath}' + avatarPath) : ('https://ui-avatars.com/api/?name=' + encodeURIComponent(contactName) + '&background=d63384&color=fff');

                const conversationArea = document.getElementById("chatConversationArea");
                conversationArea.innerHTML = `
                    <div class="chat-header" style="flex-shrink:0;">
                        <div class="chat-header-info" style="display:flex;flex-direction:row;align-items:center;gap:12px;">
                            <img src="\${avatarUrl}" class="chat-avatar" alt="Avatar" style="width:42px;height:42px;border-radius:50%;object-fit:cover;flex-shrink:0;">
                            <div>
                                <h6 class="mb-0 fw-bold">\${contactName}</h6>
                                <small class="text-muted">\${contactId}</small>
                            </div>
                        </div>
                    </div>
                    <div class="chat-messages-container" id="chatMessagesList" style="flex:1 1 0;min-height:0;overflow-y:auto;">
                        <div class="text-center py-4 text-muted"><i class="fas fa-spinner fa-spin me-2"></i>Loading messages...</div>
                    </div>
                    <div class="chat-templates" style="flex-shrink:0;">
                        <button type="button" class="btn btn-xs btn-outline-secondary template-btn" onclick="useTemplate('Please submit your outstanding log reflection as soon as possible.')">Reminder: Log Submission</button>
                        <button type="button" class="btn btn-xs btn-outline-secondary template-btn" onclick="useTemplate('Great work on your weekly OJT tasks! Your logs are approved.')">Approve Logs</button>
                        <button type="button" class="btn btn-xs btn-outline-secondary template-btn" onclick="useTemplate('Please upload the correct supporting document for your recent submission.')">Ref Reflection correction</button>
                    </div>
                    <form class="chat-input-bar" onsubmit="submitChatMessage(event)" style="flex-shrink:0;display:flex;gap:12px;padding:16px 24px;border-top:1px solid #e2e8f0;background:#fff;">
                        <input type="text" id="chatMessageText" placeholder="Type a message..." required autocomplete="off" style="flex-grow:1;border:1px solid #cbd5e1;border-radius:8px;padding:10px 16px;font-size:0.92rem;outline:none;min-width:0;">
                        <button type="submit" class="btn btn-pink text-white fw-bold" style="padding:10px 20px;border-radius:8px;border:none;"><i class="fas fa-paper-plane"></i></button>
                    </form>
                `;

                loadChat(contactId);
            }

            function useTemplate(text) {
                const input = document.getElementById("chatMessageText");
                if (input) {
                    input.value = text;
                    input.focus();
                }
            }

            function loadChat(contactId) {
                const msgsContainer = document.getElementById("chatMessagesList");
                const tabId = window.name || sessionStorage.getItem('tabId') || '';
                fetch("messages_api.jsp?action=history&contactId=" + encodeURIComponent(contactId) + "&tabId=" + encodeURIComponent(tabId))
                    .then(r => r.json())
                    .then(data => {
                        renderChatMessages(data);
                        scrollToBottom("chatMessagesList");
                    })
                    .catch(e => {
                        msgsContainer.innerHTML = '<div class="text-center py-4 text-danger">Failed to load chat history.</div>';
                    });
            }

            function loadChatSilent(contactId) {
                const tabId = window.name || sessionStorage.getItem('tabId') || '';
                fetch("messages_api.jsp?action=history&contactId=" + encodeURIComponent(contactId) + "&tabId=" + encodeURIComponent(tabId))
                    .then(r => r.json())
                    .then(data => {
                        const msgsContainer = document.getElementById("chatMessagesList");
                        if (msgsContainer) {
                            const currentHtml = msgsContainer.innerHTML;
                            renderChatMessages(data);
                            if (msgsContainer.innerHTML !== currentHtml) {
                                scrollToBottom("chatMessagesList");
                            }
                        }
                    })
                    .catch(e => console.error("Chat polling failed", e));
            }

            function renderChatMessages(data) {
                const msgsContainer = document.getElementById("chatMessagesList");
                if (!msgsContainer) return;
                if (data.length === 0) {
                    msgsContainer.innerHTML = '<div class="text-center py-4 text-muted">No messages yet. Send a message to start the conversation!</div>';
                    return;
                }

                let html = "";
                data.forEach(m => {
                    const isSelf = m.senderId === activeUserId;
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

            function escapeHtml(text) {
                return text
                    .replace(/&/g, "&amp;")
                    .replace(/</g, "&lt;")
                    .replace(/>/g, "&gt;")
                    .replace(/"/g, "&quot;")
                    .replace(/'/g, "&#039;");
            }

            function scrollToBottom(containerId) {
                const el = document.getElementById(containerId);
                if (el) {
                    el.scrollTop = el.scrollHeight;
                }
            }

            function submitChatMessage(event) {
                event.preventDefault();
                const input = document.getElementById("chatMessageText");
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
                        showAdminToast("Failed to send message: " + (res.error || ""), "danger");
                    }
                })
                .catch(e => showAdminToast("Error sending message", "danger"));
            }

            function pollUnreadMessagesCount() {
                const tabId = window.name || sessionStorage.getItem('tabId') || '';
                fetch("messages_api.jsp?action=contacts&tabId=" + encodeURIComponent(tabId))
                    .then(r => r.json())
                    .then(data => {
                        let totalUnread = 0;
                        const dashboardView = document.getElementById("dashboard-view");
                        const messagingPanel = document.getElementById("sub-messaging");
                        const isMessagingActive = dashboardView && dashboardView.style.display === "block" &&
                                                 messagingPanel && messagingPanel.style.display === "block";
                        data.forEach(c => {
                            let unread = (isMessagingActive && c.id === activeContactId) ? 0 : c.unreadCount;
                            totalUnread += unread;
                        });
                        updateUnreadBadgeCount(totalUnread);
                    })
                    .catch(e => console.log("Background badge poll failed", e));
            }

            // Silent background badge poll when not on messaging tab
            setInterval(() => {
                const dashboardView = document.getElementById("dashboard-view");
                const messagingPanel = document.getElementById("sub-messaging");
                const isMessagingActive = dashboardView && dashboardView.style.display === "block" &&
                                         messagingPanel && messagingPanel.style.display === "block";
                if (!isMessagingActive) {
                    pollUnreadMessagesCount();
                }
            }, 8000);


        </script>
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    </body>
</html>