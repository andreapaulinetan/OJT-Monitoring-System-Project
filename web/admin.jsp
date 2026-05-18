<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@page import="model.User"%>
<%@page import="model.UserDAO"%>
<%@page import="model.ActivitySubmission"%>
<%@page import="java.util.List"%>
<%
    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    User user = (User) session.getAttribute("user");
    if (user == null || !"admin".equalsIgnoreCase(user.getRole())) {
        response.sendRedirect("login.jsp");
        return;
    }

    List<User> internList = UserDAO.getAllInterns(getServletContext());
    List<ActivitySubmission> submissionList = UserDAO.getAllSubmissions(getServletContext());

    int totalInterns = (internList != null) ? internList.size() : 0;
    int pendingLogs = UserDAO.getPendingLogsCount(getServletContext());
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Coordinator's Dashboard | Active Learning</title>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
        <link rel="stylesheet" type="text/css" href="${pageContext.request.contextPath}/css/admin.css">
        
        <style>
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
            .col-id, .intern-row td:first-child, #logReviewTable tbody td:nth-child(3) {
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
        </style>
    </head>
    <body>
        <div class="dashboard-wrapper">
            <aside class="sidebar">
                <div class="sidebar-header"><h4 class="brand-name">Active Learning</h4></div>
                <nav class="sidebar-nav">
                    <a href="#" id="nav-dashboard" class="nav-item active" onclick="switchView('dashboard')">
                        <i class="fas fa-th-large"></i> Dashboard
                    </a>
                    <a href="#" id="nav-interns" class="nav-item" onclick="switchView('intern-management')">
                        <i class="fas fa-users"></i> Intern Management
                    </a>
                    <a href="#" id="nav-logs" class="nav-item" onclick="switchView('log-review')">
                        <i class="fas fa-file-alt"></i> Log Review <span class="badge bg-danger ms-2" id="sidebarPendingBadge"><%= pendingLogs%></span>
                    </a>
                    <a href="#" id="nav-reports" class="nav-item" onclick="switchView('report-center')">
                        <i class="fas fa-chart-bar"></i> Report Center
                    </a>
                    <a href="#" id="nav-audit" class="nav-item" onclick="switchView('audit-trail')">
                        <i class="fas fa-history"></i> Audit Trail
                    </a>
                    <a href="LogoutServlet" class="nav-item logout"><i class="fas fa-sign-out-alt"></i> Log out</a>
                </nav>
            </aside>

            <main class="main-content">
                <header class="top-bar">
                    <h2 class="page-title" id="mainPageTitle">Coordinator's Dashboard</h2>
                    <div class="search-container">
                        <input type="text" id="internSearch" class="search-input" placeholder="Search across columns..." onkeyup="resetToFirstPageAndFilter()">
                    </div>
                    <div class="user-profile">
                        <div class="profile-chip">
                            <span><%= user.getFullName()%></span>
                            <img src="https://ui-avatars.com/api/?name=<%= user.getFullName()%>&background=d63384&color=fff" alt="Admin">
                        </div>
                    </div>
                </header>

                <div id="dashboard-view" class="view-section">
                    <section class="stats-row mb-4">
                        <div class="stat-card yellow"><span class="label">Total Interns</span><h1 class="value"><%= totalInterns%></h1></div>
                        <div class="stat-card pink"><span class="label">Pending Logs</span><h1 class="value" id="dashboardPendingCount"><%= pendingLogs%></h1></div>
                        <div class="stat-card green"><span class="label">Completion Rate</span><h1 class="value">68%</h1></div>
                        <div class="stat-card blue"><span class="label">Quick Reports</span><button class="btn-report mt-2 w-100 btn btn-sm btn-dark">Generate All</button></div>
                    </section>
                    <div class="p-4 text-muted text-center" style="margin-top: 50px;">
                        <i class="fas fa-chart-pie fa-3x mb-3"></i>
                        <p>Dashboard analytics, performance metrics, and system data visualizations render engine container.</p>
                    </div>
                </div>

                <div id="intern-management-view" class="view-section" style="display: none;">
                    <section class="table-section p-0 overflow-hidden">
                        <div class="section-header p-4 pb-2 d-flex justify-content-between align-items-center">
                            <h3>Master Intern Accounts Registry (DBMS 1)</h3>
                            <div class="header-btns">
                                <button class="btn-add" onclick="openAddInternModal()">Add New Intern</button>
                                <button class="btn-import">Import Batch</button>
                            </div>
                        </div>

                        <div class="table-responsive px-4">
                            <table class="data-table" id="internTable">
                                <thead>
                                    <tr>
                                        <th class="col-id" onclick="sortInternTable(0)" style="cursor:pointer;">Intern ID <i class="fas fa-sort"></i></th>
                                        <th class="col-name" onclick="sortInternTable(1)" style="cursor:pointer;">Intern Profile <i class="fas fa-sort"></i></th>
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
                                    </tr>
                                </thead>
                                <tbody id="internTableBody">
                                    <% if (internList != null && !internList.isEmpty()) {
                                            for (User u : internList) {%>
                                    <tr class="intern-row">
                                        <td class="col-id"><%= u.getId()%></td>
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

                <div id="log-review-view" class="view-section" style="display: none;">
                    <section class="table-section p-0 overflow-hidden">
                        <div class="section-header p-4 pb-2">
                            <h3>OJT Activity Submissions Queue (DBMS 2)</h3>
                            <p class="text-muted small">Verify submitted proof files and update processing workflow operational status flags inside MySQL parameters storage.</p>
                        </div>
                        <div class="table-responsive px-4">
                            <table class="data-table" id="logReviewTable">
                                <thead class="sticky-top bg-white">
                                    <tr>
                                        <th onclick="sortLogTable(0)" style="cursor:pointer;">Submitted on <i class="fas fa-sort"></i></th>
                                        <th onclick="sortLogTable(1)" style="cursor:pointer;">Submission ID <i class="fas fa-sort"></i></th>
                                        <th onclick="sortLogTable(2)" style="cursor:pointer;">Intern ID <i class="fas fa-sort"></i></th>
                                        <th onclick="sortLogTable(3)" style="cursor:pointer;">Intern Name <i class="fas fa-sort"></i></th>
                                        <th>Attached Files</th>
                                        <th class="col-office">
                                            <div class="filter-dropdown">
                                                <div class="filter-trigger" id="logOfficeLabel"><span>Assigned Office</span> <i class="fas fa-building"></i></div>
                                                <div class="filter-content" id="logOfficeOptions"></div>
                                            </div>
                                        </th>
                                        <th class="col-status">
                                            <div class="filter-dropdown">
                                                <div class="filter-trigger" id="statusLabel" onclick="sortLogTable(6)" style="cursor:pointer;">
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
                                                String dateSub = s.getDateSubmitted().toString();
                                                String desc = s.getDescription() != null ? s.getDescription().replace("'", "\\'") : "";
                                                String origFile = s.getOriginalFileName();
                                                String suppFile = s.getSupportingFile();
                                                String office = s.getAssignedOffice();
                                                String status = (s.getStatus() != null) ? s.getStatus() : "Pending";
                                    %>
                                    <tr class="log-row log-row-clickable" onclick="openLogDetailsModal('<%= subId%>', '<%= internId%>', '<%= internName%>', '<%= dateSub%>', '<%= desc%>', '<%= origFile%>', '<%= suppFile%>')">
                                        <td><%= dateSub%></td>
                                        <td><span class="sub-id-badge"><%= subId%></span></td>
                                        <td><%= internId%></td>
                                        <td><%= internName%></td>
                                        <td>
                                            <span class="badge bg-light text-dark border file-badge-container" title="<%= origFile %>">
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

                <div id="report-center-view" class="view-section" style="display: none;">
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

                <div id="audit-trail-view" class="view-section" style="display: none;">
                    <section class="table-section p-0 overflow-hidden">
                        <div class="section-header p-4 pb-2 d-flex justify-content-between align-items-center">
                            <div>
                                <h3>System Security Audit Trail (DBMS 3 — PostgreSQL)</h3>
                                <p class="text-muted small">Real-time authentication cycles, report generation events, and session tracking from the auditdb database.</p>
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
                            <small class="text-muted d-block fw-bold mb-1" style="font-size:11px;">Task Description</small>
                            <p id="modalDescription" class="mb-0 text-dark small style-prose" style="line-height:1.5;"></p>
                        </div>
                        <div>
                            <small class="text-muted d-block fw-bold mb-1" style="font-size:11px;">Attached Cryptographic Files</small>
                            <div class="d-flex align-items-center gap-2 p-2 border rounded bg-white small mb-2">
                                <i class="fas fa-file-pdf text-danger fa-lg"></i>
                                <div class="overflow-hidden">
                                    <strong id="modalOriginalFile" class="d-block text-truncate"></strong>
                                    <small id="modalSupportingFile" class="text-muted text-truncate d-block"></small>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer border-0">
                        <button type="button" class="btn btn-sm btn-secondary w-100" data-bs-dismiss="modal">Close Window Details</button>
                    </div>
                </div>
            </div>
        </div>

        <div class="modal fade" id="addInternModal" data-bs-backdrop="static" tabindex="-1" aria-hidden="true">
            <div class="modal-dialog modal-lg modal-dialog-scrollable">
                <div class="modal-content style-form-card">
                    <div class="modal-header">
                        <h5 class="modal-title fw-bold text-brand-pink"><i class="fas fa-user-plus me-2"></i>Add New Intern</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body p-4">
                        <form id="addInternForm" action="AddInternServlet" method="POST" novalidate>
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
                        <button type="button" class="btn btn-sm btn-success px-4" data-bs-dismiss="modal" onclick="window.location.href='admin.jsp'">Close Account Details</button>
                    </div>
                </div>
            </div>
        </div>

        <script>
            let activeFilters = {university: "", role: "", office: "", city: ""};
            let internSortColumn = 0, internSortAsc = false;
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
                sortInternTable(0, false);
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
            });

            function openLogDetailsModal(subId, internId, identity, dateSub, desc, origFile, suppFile) {
                document.getElementById("modalSubId").innerText = "#" + subId;
                document.getElementById("modalInternId").innerText = "ID: #" + internId;
                document.getElementById("modalInternIdentity").innerText = identity;
                document.getElementById("modalDateSubmitted").innerText = dateSub;
                document.getElementById("modalDescription").innerText = desc;
                document.getElementById("modalOriginalFile").innerText = origFile;
                document.getElementById("modalSupportingFile").innerText = "Storage path reference: " + suppFile;

                if (!detailsModalObj) {
                    detailsModalObj = new bootstrap.Modal(document.getElementById('logDetailsModal'));
                }
                detailsModalObj.show();
            }

            function updateLogStatusDatabase(submissionId, selectElement) {
                const newStatus = selectElement.value;
                selectElement.className = "form-select form-select-sm status-select status-" + newStatus;

                fetch("UpdateLogStatusServlet", {
                    method: "POST",
                    headers: {"Content-Type": "application/x-www-form-urlencoded"},
                    body: "submissionId=" + encodeURIComponent(submissionId) + "&status=" + encodeURIComponent(newStatus)
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
                if (columnIndex === 4) return;
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

                    if (columnIndex === 6) {
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

            function sortInternTable(columnIndex, toggle = true) {
                const tbody = document.getElementById("internTableBody");
                const rows = Array.from(document.querySelectorAll(".intern-row"));
                if (toggle) {
                    if (internSortColumn === columnIndex)
                        internSortAsc = !internSortAsc;
                    else
                        internSortAsc = (columnIndex !== 0);
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

                // 1. Process Intern Management Registry Table Chunk Logic
                const internRows = Array.from(document.querySelectorAll(".intern-row"));
                if (internRows.length > 0) {
                    let visibleRows = [];
                    internRows.forEach(row => {
                        const rId = row.querySelector(".col-id").innerText.toUpperCase().trim();
                        const rName = row.querySelector(".col-name").innerText.toUpperCase().trim();
                        const rUni = row.cells[2].innerText.toUpperCase().trim();
                        const rCity = row.cells[3].innerText.toUpperCase().trim();
                        const rRole = row.cells[4].innerText.toUpperCase().trim();
                        const rOffice = row.cells[5].innerText.toUpperCase().trim();

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
                        const rOffice = row.cells[5].innerText.toUpperCase().trim();
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
                if (!container) return;

                container.innerHTML = "";
                if (totalPages <= 1) return;

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
                    if (!auditLoaded) loadAuditTrail();
                } else {
                    document.getElementById(viewId + '-view').style.display = 'block';
                    document.getElementById('nav-' + viewId.split('-')[0]).classList.add('active');
                }
            }

            function populateDropdowns() {
                const rows = Array.from(document.querySelectorAll(".intern-row"));
                const data = {uni: new Set(), role: new Set(), office: new Set(), city: new Set()};
                rows.forEach(row => {
                    data.uni.add(row.cells[2].innerText.trim());
                    data.city.add(row.cells[3].innerText.trim());
                    data.role.add(row.cells[4].innerText.trim());
                    data.office.add(row.cells[5].innerText.trim());
                });
                renderMenu("uniOptions", "university", "University", data.uni, "fa-university");
                renderMenu("cityOptions", "city", "City", data.city, "fa-map-marker-alt");
                renderMenu("roleOptions", "role", "Role", data.role, "fa-user-tag");
                renderMenu("officeOptions", "office", "Office", data.office, "fa-building");

                const logRows = Array.from(document.querySelectorAll(".log-row"));
                const logOffices = new Set();
                logRows.forEach(row => {
                    logOffices.add(row.cells[5].innerText.trim());
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
                if (!container) return;
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

                if (!fNameField.value.trim()) { fNameField.classList.add('is-invalid'); errors.push("First Name is required."); }
                if (!mNameField.value.trim()) { mNameField.classList.add('is-invalid'); errors.push("Middle Name is required."); }
                if (!lNameField.value.trim()) { lNameField.classList.add('is-invalid'); errors.push("Last Name is required."); }
                if (!bMonthField.value) { bMonthField.classList.add('is-invalid'); errors.push("Birth Month is required."); }
                if (!bDateField.value) { bDateField.classList.add('is-invalid'); errors.push("Birth Date is required."); }

                const bYear = parseInt(bYearField.value);
                if (isNaN(bYear) || bYearField.value.trim().length !== 4 || bYear < 1900 || bYear > 2026) {
                    bYearField.classList.add('is-invalid');
                    errors.push("Provide a valid 4-digit Birth Year (1900-2026).");
                }
                if (!cityField.value) { cityField.classList.add('is-invalid'); errors.push("City Selection is required."); }
                if (!uniField.value.trim()) { uniField.classList.add('is-invalid'); errors.push("University Name is required."); }
                if (!roleField.value) { roleField.classList.add('is-invalid'); errors.push("Technical Intern Role is required."); }

                const digitsRegex = /^[0-9]+$/;
                const phoneNum = phoneField.value.trim();
                if (!phoneNum) { phoneField.classList.add('is-invalid'); errors.push("Contact Number is required."); }
                else if (!digitsRegex.test(phoneNum)) { phoneField.classList.add('is-invalid'); errors.push("Contact Number must contain numbers only."); }
                else if (phoneNum.length !== 10 || !phoneNum.startsWith("9")) { phoneField.classList.add('is-invalid'); errors.push("PH Mobile Number must be exactly 10 digits starting with 9."); }

                const pass = passField.value;
                if (!pass) { passField.classList.add('is-invalid'); errors.push("Access Security Password is required."); }
                else {
                    if (pass.length < 8 || pass.length > 30) { passField.classList.add('is-invalid'); errors.push("Password must be between 8 and 30 characters."); }
                    if (!/[A-Z]/.test(pass) || !/[a-z]/.test(pass) || !/[0-9]/.test(pass)) { passField.classList.add('is-invalid'); errors.push("Password criteria verification failed."); }
                }

                if (errors.length > 0) {
                    errBox.innerText = errors.join(" | ");
                    errBox.style.display = "block";
                    return;
                }

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
                        msg.innerHTML = '<td colspan="7" style="text-align:center; padding:40px; color:#888;">No matching records found.</td>';
                        tbody.appendChild(msg);
                    }
                } else if (msg)
                    msg.remove();
            }

            function customChangePageSize(value, type) {
                let labelId;
                if (type === 'intern') labelId = 'internSizeLabel';
                else if (type === 'audit') labelId = 'auditSizeLabel';
                else labelId = 'logSizeLabel';
                document.querySelector("#" + labelId + " span").innerText = value;
                changePageSize(value, type);
            }

            // ══════════════════════════════════════════════════════════
            // REPORT DOWNLOAD FUNCTIONS
            // ══════════════════════════════════════════════════════════

            function downloadReport(type) {
                window.location.href = 'ReportServlet?type=' + type;
            }

            function downloadOjtReport() {
                const from = document.getElementById('ojtFromDate').value;
                const to = document.getElementById('ojtToDate').value;
                let url = 'ReportServlet?type=OJTLOGS';
                if (from && to) {
                    if (from > to) {
                        alert('"From" date must be before or equal to the "To" date.');
                        return;
                    }
                    url += '&from=' + from + '&to=' + to;
                }
                window.location.href = url;
            }

            // ══════════════════════════════════════════════════════════
            // AUDIT TRAIL TABLE (AJAX from PostgreSQL via AuditServlet)
            // ══════════════════════════════════════════════════════════

            function loadAuditTrail() {
                const tbody = document.getElementById('auditTableBody');
                tbody.innerHTML = '<tr><td colspan="6" class="text-center text-muted py-4"><i class="fas fa-spinner fa-spin me-2"></i>Loading audit data from PostgreSQL...</td></tr>';

                fetch('AuditServlet')
                    .then(response => {
                        if (!response.ok) throw new Error('Server returned ' + response.status);
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
                if (auditCurrentPage > totalPages) auditCurrentPage = totalPages;

                const startIdx = (auditCurrentPage - 1) * auditPageSize;
                const endIdx = Math.min(startIdx + auditPageSize, totalEntries);

                for (let i = startIdx; i < endIdx; i++) {
                    const log = auditData[i];
                    const tr = document.createElement('tr');
                    tr.className = 'audit-row';

                    // Action badge color
                    let actionBadge = '';
                    if (log.action === 'LOGIN') actionBadge = '<span class="badge bg-success">' + log.action + '</span>';
                    else if (log.action === 'LOGOUT') actionBadge = '<span class="badge bg-secondary">' + log.action + '</span>';
                    else actionBadge = '<span class="badge bg-primary">' + log.action + '</span>';

                    tr.innerHTML = '<td>' + log.created_at + '</td>' +
                        '<td><span style="font-family: monospace; font-size: 12px;">' + log.user_id + '</span></td>' +
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
                if (totalPages <= 1) return;

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
                if (auditSortColumn === columnIndex) auditSortAsc = !auditSortAsc;
                else auditSortAsc = true;
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
        </script>
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    </body>
</html>