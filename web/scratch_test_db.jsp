<%@ page import="java.sql.*" %>
<%@ page import="util.DBConnection" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
<head>
    <title>Database Connection Diagnostics</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; padding: 20px; background: #f8fafc; color: #1e293b; }
        .card { background: white; border-radius: 8px; padding: 20px; box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1); margin-bottom: 20px; }
        .success { color: #15803d; font-weight: bold; }
        .failure { color: #b91c1c; font-weight: bold; }
        pre { background: #f1f5f9; padding: 10px; border-radius: 4px; overflow-x: auto; font-size: 13px; }
    </style>
</head>
<body>
    <h1>Database Diagnostics</h1>
    
    <div class="card">
        <h2>1. Apache Derby (Authentication Database)</h2>
        <%
            try {
                Connection conn = DBConnection.getDerbyConnection(getServletContext());
                if (conn != null) {
                    out.println("<p class='success'>SUCCESS: Connected to Apache Derby successfully!</p>");
                    DatabaseMetaData meta = conn.getMetaData();
                    out.println("<p>Product Name: " + meta.getDatabaseProductName() + " " + meta.getDatabaseProductVersion() + "</p>");
                    conn.close();
                } else {
                    out.println("<p class='failure'>FAILURE: Derby connection returned null.</p>");
                }
            } catch (Exception e) {
                out.println("<p class='failure'>ERROR: " + e.getMessage() + "</p>");
                out.println("<pre>");
                e.printStackTrace(new java.io.PrintWriter(out));
                out.println("</pre>");
            }
        %>
    </div>

    <div class="card">
        <h2>2. MySQL (Monitoring Database)</h2>
        <%
            try {
                Connection conn = DBConnection.getMySQLMonitoringConnection(getServletContext());
                if (conn != null) {
                    out.println("<p class='success'>SUCCESS: Connected to MySQL successfully!</p>");
                    DatabaseMetaData meta = conn.getMetaData();
                    out.println("<p>Product Name: " + meta.getDatabaseProductName() + " " + meta.getDatabaseProductVersion() + "</p>");
                    
                    ResultSet rs = null;
                    try {
                        rs = conn.getMetaData().getTables(null, null, "activity_submissions", null);
                        if (rs.next()) {
                            out.println("<p class='success'>SUCCESS: activity_submissions table exists.</p>");
                        } else {
                            out.println("<p class='failure'>WARNING: activity_submissions table NOT found in metadata.</p>");
                        }
                    } finally {
                        if (rs != null) rs.close();
                    }
                    
                    conn.close();
                } else {
                    out.println("<p class='failure'>FAILURE: MySQL connection returned null.</p>");
                }
            } catch (Exception e) {
                out.println("<p class='failure'>ERROR: " + e.getMessage() + "</p>");
                out.println("<pre>");
                e.printStackTrace(new java.io.PrintWriter(out));
                out.println("</pre>");
            }
        %>
    </div>

    <div class="card">
        <h2>3. PostgreSQL (Audit Log Database)</h2>
        <%
            try {
                Connection conn = DBConnection.getPgConnection(getServletContext());
                if (conn != null) {
                    out.println("<p class='success'>SUCCESS: Connected to PostgreSQL successfully!</p>");
                    DatabaseMetaData meta = conn.getMetaData();
                    out.println("<p>Product Name: " + meta.getDatabaseProductName() + " " + meta.getDatabaseProductVersion() + "</p>");
                    conn.close();
                } else {
                    out.println("<p class='failure'>FAILURE: PostgreSQL connection returned null.</p>");
                }
            } catch (Exception e) {
                out.println("<p class='failure'>ERROR: " + e.getMessage() + "</p>");
                out.println("<pre>");
                e.printStackTrace(new java.io.PrintWriter(out));
                out.println("</pre>");
            }
        %>
    </div>

    <div class="card">
        <h2>4. Real Path Upload Directory Diagnostic</h2>
        <%
            try {
                String uploadPath = getServletContext().getRealPath("/uploads");
                out.println("<p>RealPath /uploads: <code>" + uploadPath + "</code></p>");
                if (uploadPath == null) {
                    out.println("<p class='failure'>WARNING: getRealPath(\"/uploads\") returned null. The war might be running unpacked, or context doesn't support real paths.</p>");
                } else {
                    java.io.File uploadDir = new java.io.File(uploadPath);
                    out.println("<p>Exists: <code>" + uploadDir.exists() + "</code></p>");
                    out.println("<p>Is Directory: <code>" + uploadDir.isDirectory() + "</code></p>");
                    out.println("<p>Can Write: <code>" + uploadDir.canWrite() + "</code></p>");
                }
            } catch (Exception e) {
                out.println("<p class='failure'>ERROR: " + e.getMessage() + "</p>");
            }
        %>
    </div>

    <div class="card">
        <h2>5. Activity Submissions Diagnostic (getAllSubmissions)</h2>
        <%
            try {
                int pendingLogsDirect = -1;
                int totalLogsDirect = -1;
                Connection conn = null;
                PreparedStatement ps1 = null;
                PreparedStatement ps2 = null;
                ResultSet rs1 = null;
                ResultSet rs2 = null;
                try {
                    conn = DBConnection.getMySQLMonitoringConnection(getServletContext());
                    if (conn != null) {
                        ps1 = conn.prepareStatement("SELECT COUNT(*) FROM ACTIVITY_SUBMISSIONS");
                        rs1 = ps1.executeQuery();
                        if (rs1.next()) totalLogsDirect = rs1.getInt(1);
                        
                        ps2 = conn.prepareStatement("SELECT COUNT(*) FROM ACTIVITY_SUBMISSIONS WHERE STATUS = 'Pending'");
                        rs2 = ps2.executeQuery();
                        if (rs2.next()) pendingLogsDirect = rs2.getInt(1);
                    }
                } finally {
                    if (rs1 != null) try { rs1.close(); } catch(Exception e){}
                    if (ps1 != null) try { ps1.close(); } catch(Exception e){}
                    if (rs2 != null) try { rs2.close(); } catch(Exception e){}
                    if (ps2 != null) try { ps2.close(); } catch(Exception e){}
                    if (conn != null) try { conn.close(); } catch(Exception e){}
                }
                out.println("<p>Direct SQL count (total): <b>" + totalLogsDirect + "</b></p>");
                out.println("<p>Direct SQL count (Pending): <b>" + pendingLogsDirect + "</b></p>");
                
                int pendingDAO = model.UserDAO.getPendingLogsCount(getServletContext());
                out.println("<p>UserDAO.getPendingLogsCount: <b>" + pendingDAO + "</b></p>");
                
                java.util.List<model.ActivitySubmission> subs = model.UserDAO.getAllSubmissions(getServletContext());
                if (subs == null) {
                    out.println("<p class='failure'>FAILURE: getAllSubmissions returned null.</p>");
                } else {
                    out.println("<p class='success'>SUCCESS: getAllSubmissions returned a list of size: " + subs.size() + "</p>");
                    if (!subs.isEmpty()) {
                        out.println("<ul>");
                        for (int i = 0; i < Math.min(subs.size(), 5); i++) {
                            model.ActivitySubmission s = subs.get(i);
                            out.println("<li>ID: " + s.getSubmissionId() + ", User ID: " + s.getUserId() + ", Intern Name: " + s.getInternName() + ", Status: " + s.getStatus() + "</li>");
                        }
                        out.println("</ul>");
                        if (subs.size() > 5) {
                            out.println("<p>...and " + (subs.size() - 5) + " more.</p>");
                        }
                    }
                }
            } catch (Exception e) {
                out.println("<p class='failure'>ERROR: " + e.getMessage() + "</p>");
                out.println("<pre>");
                e.printStackTrace(new java.io.PrintWriter(out));
                out.println("</pre>");
            }
        %>
    </div>
</body>
</html>
    