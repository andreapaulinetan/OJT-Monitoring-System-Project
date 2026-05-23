<%@ page import="java.sql.*" %>
<%@ page import="util.DBConnection" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
<head>
    <title>Raw Intern Data Diagnostic</title>
</head>
<body>
    <h1>Raw Intern Data in Derby</h1>
    <table border="1" cellpadding="5">
        <thead>
            <tr>
                <th>INTERN_ID</th>
                <th>FIRST_NAME</th>
                <th>LAST_NAME</th>
                <th>EMAIL</th>
                <th>CITY</th>
                <th>ROLE</th>
                <th>OFFICE</th>
            </tr>
        </thead>
        <tbody>
        <%
            try {
                Connection conn = DBConnection.getDerbyConnection(getServletContext());
                if (conn != null) {
                    Statement stmt = conn.createStatement();
                    ResultSet rs = stmt.executeQuery("SELECT INTERN_ID, FIRST_NAME, LAST_NAME, EMAIL, CITY, ROLE, OFFICE FROM APP.INTERN");
                    while (rs.next()) {
                        %>
                        <tr>
                            <td><%= rs.getString("INTERN_ID") %></td>
                            <td><%= rs.getString("FIRST_NAME") %></td>
                            <td><%= rs.getString("LAST_NAME") %></td>
                            <td><%= rs.getString("EMAIL") %></td>
                            <td><%= rs.getString("CITY") %></td>
                            <td><%= rs.getString("ROLE") %></td>
                            <td><%= rs.getString("OFFICE") %></td>
                        </tr>
                        <%
                    }
                    rs.close();
                    stmt.close();
                    conn.close();
                } else {
                    out.println("<tr><td colspan='7'>Derby Connection is null</td></tr>");
                }
            } catch (Exception e) {
                out.println("<tr><td colspan='7'>Error: " + e.getMessage() + "</td></tr>");
                e.printStackTrace(new java.io.PrintWriter(out));
            }
        %>
        </tbody>
    </table>
</body>
</html>
