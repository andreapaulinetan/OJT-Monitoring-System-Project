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
                    
                    // Let's also check if table activity_submissions exists
                    try (ResultSet rs = conn.getMetaData().getTables(null, null, "activity_submissions", null)) {
                        if (rs.next()) {
                            out.println("<p class='success'>SUCCESS: activity_submissions table exists.</p>");
                        } else {
                            out.println("<p class='failure'>WARNING: activity_submissions table NOT found in metadata.</p>");
                        }
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
</body>
</html>
