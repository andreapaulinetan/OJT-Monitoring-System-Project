<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="model.User"%>
<%
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect("login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Intern Dashboard | OJT Monitor</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">

    <nav class="navbar navbar-expand-lg navbar-dark bg-primary shadow">
        <div class="container">
            <a class="navbar-brand fw-bold" href="#">Active Learning</a>
            <div class="ms-auto">
                <span class="text-white me-3 small">Logged in as: <%= user.getUsername() %></span>
                <a class="btn btn-light btn-sm" href="LogoutServlet">Logout</a>
            </div>
        </div>
    </nav>

    <div class="container mt-5">
        <div class="card p-4 shadow-sm border-0">
            <h3>Intern Learning Tracker</h3>
            <p>Your Role: <span class="badge bg-success"><%= user.getRole() %></span></p>
            <hr>
            <div class="row text-center mt-3">
                <div class="col-md-4 mb-3">
                    <div class="card bg-white p-3 border-secondary">
                        <h5>Hours Rendered</h5>
                        <h2 class="fw-bold">120 / 600</h2>
                    </div>
                </div>
                <div class="col-md-8">
                    <div class="alert alert-warning">
                        <strong>Note:</strong> Please ensure your daily progress reports are submitted by 5:00 PM.
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>