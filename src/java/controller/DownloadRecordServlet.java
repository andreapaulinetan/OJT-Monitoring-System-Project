package controller;

import java.io.IOException;
import java.io.OutputStream;
import java.util.List;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import model.ActivitySubmission;
import model.User;
import model.UserDAO;
import util.ErrorLogger;
import util.PdfReportHelper;
import util.TabSessionHelper;

/**
 * Controller to handle downloading the intern's own activity submissions.
 * Generates a landscape A4 PDF report on-the-fly and streams it to the client.
 */
public class DownloadRecordServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        String tabId = TabSessionHelper.getTabId(request);
        
        User user = null;
        if (session != null && tabId != null) {
            user = TabSessionHelper.getUser(session, tabId);
        }
        if (user == null && session != null) {
            user = (User) session.getAttribute("user");
        }
        
        if (user == null) {
            response.sendRedirect("login.jsp?err=unauthorized");
            return;
        }

        String userId = user.getId();
        ServletContext context = getServletContext();
        
        try {
            // Retrieve submissions from MySQL (activity_submissions)
            List<ActivitySubmission> submissions = UserDAO.getSubmissionsByUserId(userId, context);
            
            // Retrieve branding parameters from web.xml
            String headerText = context.getInitParameter("report.header");
            String footerText = context.getInitParameter("report.footer");
            
            // Build the PDF report bytes in memory using PdfReportHelper (PageSize.A4.rotate())
            byte[] pdfBytes = PdfReportHelper.buildInternRecordReport(user, submissions, user.getFullName(), headerText, footerText);
            
            // Format dynamic filename with uppercase timestamp pattern
            String timestamp = new java.text.SimpleDateFormat("yyyyMMddHHmmss").format(new java.util.Date());
            String filename = "MYRECORD_" + timestamp + ".pdf";
            
            // Write PostgreSQL Security Audit Trail Log (DBMS 3)
            model.PostgreSQLDAO.insertAuditLog(
                context,
                userId,
                user.getFullName(),
                "REPORT_GENERATED",
                "Personal OJT log record downloaded: " + filename + " (Total Submissions: " + (submissions != null ? submissions.size() : 0) + ")",
                request.getRemoteAddr()
            );

            // Stream PDF directly to client response (NEVER saved on server disk)
            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition", "attachment; filename=\"" + filename + "\"");
            response.setContentLength(pdfBytes.length);
            
            try (OutputStream out = response.getOutputStream()) {
                out.write(pdfBytes);
                out.flush();
            }
            
        } catch (Exception e) {
            ErrorLogger.logError("SERVLET DOWNLOAD RECORD ERROR", "Failed to generate personal intern record PDF for user ID: " + userId, e, session, context);
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Failed to download record: " + e.getMessage());
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doGet(request, response);
    }
}
