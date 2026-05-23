<%@ page import="java.sql.*" %>
<%@ page import="util.DBConnection" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
<head>
    <title>Submissions Supporting Files List</title>
</head>
<body>
    <h2>Submissions with Supporting Files</h2>
    <%
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBConnection.getMySQLMonitoringConnection(getServletContext());
            if (conn != null) {
                String sql = "SELECT SUBMISSION_ID, USER_ID, ORIGINAL_FILE_NAME, SUPPORTING_FILE FROM ACTIVITY_SUBMISSIONS";
                ps = conn.prepareStatement(sql);
                rs = ps.executeQuery();
                out.println("<table border='1'><tr><th>Sub ID</th><th>User ID</th><th>Orig File</th><th>Supp File</th></tr>");
                while (rs.next()) {
                    out.println("<tr>");
                    out.println("<td>" + rs.getString("SUBMISSION_ID") + "</td>");
                    out.println("<td>" + rs.getString("USER_ID") + "</td>");
                    out.println("<td>" + rs.getString("ORIGINAL_FILE_NAME") + "</td>");
                    out.println("<td>" + rs.getString("SUPPORTING_FILE") + "</td>");
                    out.println("</tr>");
                }
                out.println("</table>");
            } else {
                out.println("MySQL connection null");
            }
        } catch (Exception e) {
            out.println("Error: " + e.getMessage());
            e.printStackTrace(new java.io.PrintWriter(out));
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (ps != null) try { ps.close(); } catch (Exception e) {}
            if (conn != null) try { conn.close(); } catch (Exception e) {}
        }
    %>
</body>
</html>
