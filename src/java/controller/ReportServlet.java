package controller;

import java.io.IOException;
import java.io.OutputStream;
import java.sql.Date;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import model.ActivitySubmission;
import model.PostgreSQLDAO;
import model.User;
import model.UserDAO;
import util.PdfReportHelper;

/**
 * Report Servlet — PDF Generation and Client-Side Download Controller.
 * Handles GET requests with ?type=USERLIST|ADMINRECORD|OJTLOGS|AUDITLOG
 * 
 * Security: Requires active admin session.
 * Download: Streams PDF bytes directly to client via response.getOutputStream().
 * Filename: REPORTNAME_YYYYMMDDHHmmss.pdf
 * Audit: Logs REPORT_GENERATED event to PostgreSQL (DBMS 3).
 * 
 * @author Member 3 — DBMS 3 + PDF Reports
 */
public class ReportServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // 1. Session Security Check
        HttpSession session = request.getSession(false);
        String tabId = util.TabSessionHelper.getTabId(request);
        User currentUser = (session != null && tabId != null) ? util.TabSessionHelper.getUser(session, tabId) : null;

        if (currentUser == null) {
            util.ErrorLogger.logError("UNAUTHORIZED ACCESS", "Attempted access to ReportServlet without valid session (Tab ID: " + tabId + ")", null, session, getServletContext());
            response.sendRedirect("login.jsp?err=unauthorized");
            return;
        }

        // 2. Parse Report Type
        String reportType = request.getParameter("type");
        if (reportType == null || reportType.trim().isEmpty()) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Report type parameter is required.");
            return;
        }
        reportType = reportType.trim().toUpperCase();

        // Security check: Only admins can generate global reports; interns can only generate INTERN_RECORD.
        boolean isAdmin = "admin".equalsIgnoreCase(currentUser.getRole());
        if (!isAdmin && !"INTERN_RECORD".equals(reportType)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Admin access required for report generation.");
            return;
        }

        // 3. Get branding strings from web.xml context parameters
        ServletContext ctx = getServletContext();
        String headerText = ctx.getInitParameter("report.header");
        String footerText = ctx.getInitParameter("report.footer");

        try {
            byte[] pdfBytes;
            String filename;
            String internId = null;

            switch (reportType) {
                case "USERLIST":
                    pdfBytes = generateUserListReport(ctx, currentUser, headerText, footerText);
                    filename = PdfReportHelper.generateFilename("USERLIST");
                    break;

                case "ADMINRECORD":
                    pdfBytes = generateAdminRecordReport(ctx, currentUser, headerText, footerText);
                    filename = PdfReportHelper.generateFilename("ADMINRECORD");
                    break;

                case "OJTLOGS":
                    String fromDate = request.getParameter("from");
                    String toDate = request.getParameter("to");
                    
                    // Server-side Date Validation (NFR-ERR-002: Date validation for time-bound reports)
                    boolean hasFrom = fromDate != null && !fromDate.trim().isEmpty();
                    boolean hasTo = toDate != null && !toDate.trim().isEmpty();
                    
                    if (hasFrom || hasTo) {
                        if (!hasFrom || !hasTo) {
                            util.ErrorLogger.logError("INPUT VALIDATION ERROR", 
                                "Date range validation failed: Only one date parameter was provided. From: '" + fromDate + "', To: '" + toDate + "'", 
                                null, session, ctx);
                            response.sendRedirect("admin.jsp?tabId=" + tabId + "&err=malformed_dates");
                            return;
                        }
                        try {
                            Date fromVal = Date.valueOf(fromDate.trim());
                            Date toVal = Date.valueOf(toDate.trim());
                            if (fromVal.after(toVal)) {
                                util.ErrorLogger.logError("INPUT VALIDATION ERROR", 
                                    "Date range validation failed: 'From' date (" + fromDate + ") is after 'To' date (" + toDate + ")", 
                                    null, session, ctx);
                                response.sendRedirect("admin.jsp?tabId=" + tabId + "&err=invalid_date_range");
                                return;
                            }
                        } catch (IllegalArgumentException e) {
                            util.ErrorLogger.logError("INPUT VALIDATION ERROR", 
                                "Date range validation failed: Malformed date format. From: '" + fromDate + "', To: '" + toDate + "'", 
                                e, session, ctx);
                            response.sendRedirect("admin.jsp?tabId=" + tabId + "&err=malformed_dates");
                            return;
                        }
                    }
                    
                    pdfBytes = generateOjtLogsReport(ctx, currentUser, fromDate, toDate, headerText, footerText);
                    filename = PdfReportHelper.generateFilename("OJTLOGS");
                    break;

                case "AUDITLOG":
                    pdfBytes = generateAuditLogReport(ctx, currentUser, headerText, footerText);
                    filename = PdfReportHelper.generateFilename("AUDITLOG");
                    break;

                case "INTERN_RECORD":
                    if (isAdmin) {
                        internId = request.getParameter("internId");
                        if (internId == null || internId.trim().isEmpty()) {
                            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Intern ID parameter is required for administrators.");
                            return;
                        }
                    } else {
                        // Interns can only download their own record
                        internId = currentUser.getId();
                    }
                    internId = internId.trim();
                    User intern = UserDAO.getInternById(internId, ctx);
                    if (intern == null) {
                        response.sendError(HttpServletResponse.SC_NOT_FOUND, "Intern not found with ID: " + internId);
                        return;
                    }
                    List<ActivitySubmission> submissions = UserDAO.getSubmissionsByUserId(internId, ctx);
                    pdfBytes = PdfReportHelper.buildInternRecordReport(intern, submissions, currentUser.getFullName(), headerText, footerText);
                    filename = PdfReportHelper.generateFilename("INTERN_RECORD_" + internId);
                    break;

                default:
                    response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid report type: " + reportType);
                    return;
            }

            // 4. Log REPORT_GENERATED event to PostgreSQL (DBMS 3)
            String details = "Generated " + reportType + " report";
            if ("INTERN_RECORD".equals(reportType) && internId != null) {
                details += " for Intern ID: " + internId;
            }
            PostgreSQLDAO.insertAuditLog(
                ctx,
                currentUser.getId(),
                currentUser.getFullName(),
                "REPORT_GENERATED",
                details,
                request.getRemoteAddr()
            );

            // 5. Stream PDF to client — NOT saved on server
            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition", "attachment; filename=\"" + filename + "\"");
            response.setContentLength(pdfBytes.length);

            try (OutputStream out = response.getOutputStream()) {
                out.write(pdfBytes);
                out.flush();
            }

        } catch (Exception e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "PDF generation failed: " + e.getMessage());
        }
    }

    /**
     * REPORT 1: USERLIST — All registered users (admins + interns).
     * Data source: DBMS 1 (Apache Derby)
     */
    private byte[] generateUserListReport(ServletContext ctx, User currentUser,
                                           String headerText, String footerText) throws Exception {
        List<User> allUsers = new ArrayList<>();

        // Fetch all administrators from Derby
        List<User> admins = UserDAO.getAllAdmins(ctx);
        if (admins != null) {
            allUsers.addAll(admins);
        }

        // Fetch all interns from Derby
        List<User> interns = UserDAO.getAllInterns(ctx);
        if (interns != null) {
            allUsers.addAll(interns);
        }

        return PdfReportHelper.buildUserListReport(allUsers, currentUser.getId(),
                currentUser.getFullName(), headerText, footerText);
    }

    /**
     * REPORT 2: ADMINRECORD — Audit logs for the logged-in admin only.
     * Data source: DBMS 3 (PostgreSQL)
     */
    private byte[] generateAdminRecordReport(ServletContext ctx, User currentUser,
                                              String headerText, String footerText) throws Exception {
        List<Map<String, Object>> adminLogs = PostgreSQLDAO.getAuditLogsByUserId(ctx, currentUser.getId());
        return PdfReportHelper.buildAdminRecordReport(adminLogs, currentUser.getFullName(),
                currentUser.getId(), headerText, footerText);
    }

    /**
     * REPORT 3: OJTLOGS — Activity submissions, optionally filtered by date range.
     * Data source: DBMS 2 (MySQL) cross-referenced with DBMS 1 (Derby)
     */
    private byte[] generateOjtLogsReport(ServletContext ctx, User currentUser,
                                          String fromDate, String toDate,
                                          String headerText, String footerText) throws Exception {
        List<ActivitySubmission> allSubmissions = UserDAO.getAllSubmissions(ctx);
        List<ActivitySubmission> filtered = new ArrayList<>();

        if (fromDate != null && !fromDate.isEmpty() && toDate != null && !toDate.isEmpty()) {
            // Parse and filter by date range
            try {
                Date from = Date.valueOf(fromDate);
                Date to = Date.valueOf(toDate);

                for (ActivitySubmission s : allSubmissions) {
                    if (s.getDateSubmitted() != null) {
                        if (!s.getDateSubmitted().before(from) && !s.getDateSubmitted().after(to)) {
                            filtered.add(s);
                        }
                    }
                }
            } catch (IllegalArgumentException e) {
                // Invalid date format — return all records
                System.err.println("Invalid date format in OJTLOGS report: " + e.getMessage());
                filtered = allSubmissions;
                fromDate = null;
                toDate = null;
            }
        } else {
            // No date filter — return all
            filtered = allSubmissions;
        }

        return PdfReportHelper.buildOjtLogsReport(filtered, fromDate, toDate,
                currentUser.getFullName(), headerText, footerText);
    }

    /**
     * REPORT 4: AUDITLOG — Full system audit trail.
     * Data source: DBMS 3 (PostgreSQL)
     */
    private byte[] generateAuditLogReport(ServletContext ctx, User currentUser,
                                           String headerText, String footerText) throws Exception {
        List<Map<String, Object>> allLogs = PostgreSQLDAO.getAllAuditLogs(ctx);
        return PdfReportHelper.buildAuditLogReport(allLogs, currentUser.getFullName(),
                headerText, footerText);
    }
}
