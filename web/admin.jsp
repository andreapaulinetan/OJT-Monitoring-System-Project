<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="model.User"%>
<%@page import="model.UserDAO"%>
<%@page import="java.util.List"%>
<%
    // 1. Security Check
    User user = (User) session.getAttribute("user");
    if (user == null || !"admin".equalsIgnoreCase(user.getRole())) {
        response.sendRedirect("login.jsp");
        return;
    }

    // 2. Fetch Data
    List<User> internList = UserDAO.getAllInterns(getServletContext());
    int totalInterns = (internList != null) ? internList.size() : 0;
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
                <div class="sidebar-header">
                    <h4 class="brand-name">Active Learning</h4>
                </div>
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
                    <div class="user-actions">
                        <input type="text" class="search-input" placeholder="Search Interns...">
                        <div class="profile-chip">
                            <span><%= user.getFirstName() %></span>
                            <img src="https://ui-avatars.com/api/?name=<%= user.getFirstName() %>&background=random" alt="Admin">
                        </div>
                    </div>
                </header>

                <section class="stats-row">
                    <div class="stat-card yellow">
                        <span class="label">Total Interns</span>
                        <h1 class="value"><%= totalInterns %></h1>
                    </div>
                    <div class="stat-card pink">
                        <span class="label">Pending Logs</span>
                        <h1 class="value">12</h1>
                    </div>
                    <div class="stat-card green">
                        <span class="label">Completion Rate</span>
                        <h1 class="value">68%</h1>
                    </div>
                    <div class="stat-card blue">
                        <span class="label">Quick Reports</span>
                        <button class="btn-report">Generate All</button>
                    </div>
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
                        <table class="data-table">
                            <thead>
                                <tr>
                                    <th>Name</th>
                                    <th>University</th>
                                    <th>Role</th>
                                    <th>Office</th>
                                    <th>Status</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% if (internList != null && !internList.isEmpty()) {
                                    for (User u : internList) { %>
                                <tr>
                                    <td class="name-col">
                                        <strong><%= u.getFirstName() %> <%= u.getLastName() %></strong>
                                        <small><%= u.getEmail() %></small>
                                    </td>
                                    <td><%= u.getUniversity() %></td>
                                    <td><%= u.getRole() %></td>
                                    <td><%= u.getOffice() %></td>
                                    <td><span class="badge-pending">Pending</span></td>
                                    <td>
                                        <div class="action-btns">
                                            <button title="View"><i class="fas fa-eye"></i></button>
                                            <button title="Edit"><i class="fas fa-edit"></i></button>
                                            <button title="Delete"><i class="fas fa-trash"></i></button>
                                        </div>
                                    </td>
                                </tr>
                                <% } 
                                } else { %>
                                <tr>
                                    <td colspan="6" class="text-center">No interns found in the database.</td>
                                </tr>
                                <% } %>
                            </tbody>
                        </table>
                    </div>

                    <footer class="table-footer">
                        <span>Showing Page 1 of 1</span>
                        <div class="pagination">
                            <button disabled>Prev</button>
                            <button class="active">1</button>
                            <button disabled>Next</button>
                        </div>
                    </footer>
                </section>
            </main>
        </div>

        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    </body>
</html>