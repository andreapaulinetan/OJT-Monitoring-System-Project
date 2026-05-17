package controller;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import util.DBConnection; // Explicitly import your utility framework package

@WebServlet("/UpdateLogStatusServlet")
public class UpdateLogStatusServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        // 1. Intercept the asynchronous parameters passed by the JavaScript fetch engine
        String submissionId = request.getParameter("submissionId");
        String status = request.getParameter("status");

        // Input guard control tracker clauses
        if (submissionId == null || status == null) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Missing parameters.");
            return;
        }

        String sqlQuery = "UPDATE activity_submissions SET status = ? WHERE submission_id = ?";

        // 2. Utilize your existing DBConnection utility class to pull from web.xml context params
        try (Connection conn = DBConnection.getMySQLMonitoringConnection(getServletContext());
             PreparedStatement pstmt = conn.prepareStatement(sqlQuery)) {
            
            if (conn == null) {
                response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Failed to establish a database pipeline connection context.");
                return;
            }
            
            pstmt.setString(1, status);
            pstmt.setString(2, submissionId);
            
            int rowsUpdated = pstmt.executeUpdate();
            
            if (rowsUpdated > 0) {
                response.setStatus(HttpServletResponse.SC_OK);
                System.out.println("SQL Synchronizer Notification: Submission #" + submissionId + " status successfully updated to " + status);
            } else {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Record entry target instance not found in row updates execution.");
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Database context write query failure execution exception: " + e.getMessage());
        }
    }
}