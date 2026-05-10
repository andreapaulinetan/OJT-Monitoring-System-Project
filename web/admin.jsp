<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="model.User"%>
<%@page import="model.UserDAO"%>
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
</head>
<body>
    <div class="dashboard-wrapper">
        <aside class="sidebar">
            <div class="sidebar-header"><h4 class="brand-name">Active Learning</h4></div>
            <nav class="sidebar-nav">
                <a href="#" class="nav-item active"><i class="fas fa-th-large"></i> Dashboard</a>
                <a href="#" class="nav-item"><i class="fas fa-users"></i> Intern Management</a>
                <a href="#" class="nav-item"><i class="fas fa-file-alt"></i> Log Review</a>
                <a href="#" class="nav-item"><i class="fas fa-chart-bar"></i> Report Center</a>
                <a href="#" class="nav-item"><i class="fas fa-history"></i> Audit Trail</a>
                <a href="LogoutServlet" class="nav-item logout"><i class="fas fa-sign-out-alt"></i> Log out</a>
            </nav>
        </aside>

        <main class="main-content">
           <header class="top-bar">
    <h2 class="page-title">Coordinator's Dashboard</h2>
    <div class="search-container">
        <input type="text" id="internSearch" class="search-input" placeholder="Search by ID, Name, University..." onkeyup="filterTable()">
    </div>
    <div class="user-profile">
        <div class="profile-chip">
            <span><%= user.getFullName()%></span>
            <img src="https://ui-avatars.com/api/?name=<%= user.getFullName()%>&background=d63384&color=fff" alt="Admin">
        </div>
    </div>
</header>

            <section class="stats-row">
                <div class="stat-card yellow"><span class="label">Total Interns</span><h1 class="value"><%= totalInterns%></h1></div>
                <div class="stat-card pink"><span class="label">Pending Logs</span><h1 class="value"><%= pendingLogs%></h1></div>
                <div class="stat-card green"><span class="label">Completion Rate</span><h1 class="value">68%</h1></div>
                <div class="stat-card blue"><span class="label">Quick Reports</span><button class="btn-report">Generate All</button></div>
            </section>

            <section class="table-section">
                <div class="section-header">
                    <h3>Master Intern List</h3>
                    <div class="header-btns">
                        <button class="btn-add">Add New Intern</button>
                        <button class="btn-import">Import Batch</button>
                    </div>
                </div>

                <div class="table-responsive">
                    <table class="data-table" id="internTable">
                        <thead>
    <tr>
        <th class="col-id" onclick="sortTable(0)">ID <i class="fas fa-sort"></i></th>
        <th class="col-name" onclick="sortTable(1)">NAME <i class="fas fa-sort"></i></th>
        <th class="col-uni">
            <div class="filter-dropdown">
                <div class="filter-trigger" id="uniLabel"><span>University</span> <i class="fas fa-university"></i></div>
                <div class="filter-content" id="uniOptions"></div>
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
        <th class="col-status">
            <div class="filter-dropdown">
                <div class="filter-trigger" id="statusLabel"><span>Status</span> <i class="fas fa-info-circle"></i></div>
                <div class="filter-content" id="statusOptions"></div>
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
                <small><%= u.getEmail()%></small>
            </div>
        </td>
        <td class="col-uni"><%= u.getUniversity()%></td>
        <td class="col-role"><%= (u.getRole() != null) ? u.getRole() : "N/A"%></td>
        <td class="col-office"><%= u.getOffice()%></td>
        <td class="col-status">
            <span class="badge-<%= u.getLogStatus().toLowerCase().replace(" ", "-")%>">
                <%= u.getLogStatus()%>
            </span>
        </td>
    </tr>
    <% } } %>
</tbody>
                       
                    </table>
                </div>
            </section>
        </main>
    </div>

    <script>
        let activeFilters = { university: "", role: "", office: "", status: "" };
        let currentSortColumn = 0;
        let currentSortAsc = false;

        document.addEventListener("DOMContentLoaded", () => {
            populateDropdowns();
            sortTable(0, false); 
        });

        function getRows() {
            return Array.from(document.querySelectorAll(".intern-row"));
        }

        function populateDropdowns() {
            const rows = getRows();
            const data = { uni: new Set(), role: new Set(), office: new Set(), status: new Set() };

            rows.forEach(row => {
                data.uni.add(row.querySelector("td:nth-child(3)").innerText.trim());
                data.role.add(row.querySelector("td:nth-child(4)").innerText.trim());
                data.office.add(row.querySelector("td:nth-child(5)").innerText.trim());
                data.status.add(row.querySelector("td:nth-child(6) span").textContent.trim());
            });

            renderMenu("uniOptions", "university", "University", data.uni, "fa-university");
            renderMenu("roleOptions", "role", "Role", data.role, "fa-user-tag");
            renderMenu("officeOptions", "office", "Office", data.office, "fa-building");
            renderMenu("statusOptions", "status", "Status", data.status, "fa-info-circle");
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
                if (!val || val === "N/A") return;
                const opt = document.createElement("div");
                opt.className = "filter-option";
                opt.innerText = val;
                opt.onclick = () => applyFilter(filterKey, val, val, icon);
                container.appendChild(opt);
            });
        }

        function applyFilter(key, value, displayLabel, icon) {
            activeFilters[key] = value.toUpperCase().trim();
            const labelId = (key === "university") ? "uniLabel" : key + "Label";
            const trigger = document.getElementById(labelId);

            if (trigger) {
                trigger.querySelector("span").innerText = displayLabel;
                if (value !== "") {
                    trigger.classList.add('active-filter');
                } else {
                    trigger.classList.remove('active-filter');
                }
            }
            filterTable();
        }

    function filterTable() {
    const searchVal = document.getElementById("internSearch").value.trim().toUpperCase();
    
    getRows().forEach(row => {
        // Capture all column data
        const rId     = row.querySelector(".col-id").innerText.toUpperCase().trim();
        const rName   = row.querySelector(".col-name").innerText.toUpperCase().trim();
        const rUni    = row.querySelector("td:nth-child(3)").innerText.toUpperCase().trim();
        const rRole   = row.querySelector("td:nth-child(4)").innerText.toUpperCase().trim();
        const rOffice = row.querySelector("td:nth-child(5)").innerText.toUpperCase().trim();
        const rStatus = row.querySelector("td:nth-child(6) span").textContent.toUpperCase().trim();

        // 1. Check if the search term matches ANY of the columns
        const matchesSearch = searchVal === "" || 
                             rId.includes(searchVal) || 
                             rName.includes(searchVal) || 
                             rUni.includes(searchVal) || 
                             rRole.includes(searchVal) || 
                             rOffice.includes(searchVal) || 
                             rStatus.includes(searchVal);
        // 2. Check if the active dropdown filters also match
        const matchesFilters = (activeFilters.university === "" || rUni === activeFilters.university) &&
                               (activeFilters.role === "" || rRole === activeFilters.role) &&
                               (activeFilters.office === "" || rOffice === activeFilters.office) &&
                               (activeFilters.status === "" || rStatus === activeFilters.status);

        // Row is visible only if it satisfies both the global search AND the dropdown filters
        row.style.display = (matchesSearch && matchesFilters) ? "" : "none";
    });
    
    updateNoDataMessage();
}
        function updateNoDataMessage() {
            const tbody = document.getElementById("internTableBody");
            const visible = getRows().filter(r => r.style.display !== "none").length;
            let msg = document.getElementById("filterNoData");
            if (visible === 0) {
                if (!msg) {
                    msg = document.createElement("tr");
                    msg.id = "filterNoData";
                    msg.innerHTML = `<td colspan="7" style="text-align:center; padding:40px; color:#888;">No matches found.</td>`;
                    tbody.appendChild(msg);
                }
            } else if (msg) msg.remove();
        }

        function sortTable(columnIndex, toggle = true) {
            const tbody = document.getElementById("internTableBody");
            const rows = getRows();
            if (toggle) {
                if (currentSortColumn === columnIndex) currentSortAsc = !currentSortAsc;
                else currentSortAsc = (columnIndex !== 0);
            }
            currentSortColumn = columnIndex;
            rows.sort((a, b) => {
                let vA = a.cells[columnIndex].innerText.trim().toUpperCase();
                let vB = b.cells[columnIndex].innerText.trim().toUpperCase();
                if (columnIndex === 0) return currentSortAsc ? parseInt(vA) - parseInt(vB) : parseInt(vB) - parseInt(vA);
                return currentSortAsc ? vA.localeCompare(vB) : vB.localeCompare(vA);
            });
            rows.forEach(r => tbody.appendChild(r));
        }
    </script>
</body>
</html>