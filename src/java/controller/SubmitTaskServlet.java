package controller;

import java.io.File;
import java.io.IOException;
import java.sql.Date;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;
import model.ActivitySubmission;
import model.User;
import model.UserDAO;

@WebServlet("/SubmitTaskServlet")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024 * 2, // 2MB
    maxFileSize = 1024 * 1024 * 10,      // 10MB
    maxRequestSize = 1024 * 1024 * 50   // 50MB
)
public class SubmitTaskServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        // 1. Session verification check
        HttpSession session = request.getSession(false);
        String tabId = util.TabSessionHelper.getTabId(request);
        User user = (session != null && tabId != null) ? util.TabSessionHelper.getUser(session, tabId) : null;
        
        if (user == null) {
            util.ErrorLogger.logError("UNAUTHORIZED ACCESS", "Attempted task submission without a valid authenticated user session (Tab ID: " + tabId + ")", null, session, getServletContext());
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Active session credentials required.");
            return;
        }

        String userId = user.getId();

        String hoursStr = "";
        String description = "";
        String originalFileName = "";
        String supportingFile = "";

        boolean isMultipart = request.getContentType() != null && request.getContentType().startsWith("multipart/form-data");

        if (isMultipart) {
            // A. Multipart file upload case (Manual simulated form)
            try {
                hoursStr = request.getParameter("simulatedHours");
                description = request.getParameter("taskDescription");

                Part filePart = request.getPart("attendancePhoto");
                if (filePart != null && filePart.getSize() > 0) {
                    originalFileName = getSubmittedFileName(filePart);
                    if (originalFileName != null && !originalFileName.isEmpty()) {
                        String contentType = filePart.getContentType();
                        String lowerName = originalFileName.toLowerCase();
                        boolean isSupportedExtension = lowerName.endsWith(".png") || lowerName.endsWith(".jpg") || lowerName.endsWith(".jpeg");
                        boolean isSupportedMime = contentType != null && (contentType.equalsIgnoreCase("image/png") || contentType.equalsIgnoreCase("image/jpeg") || contentType.equalsIgnoreCase("image/jpg"));
                        
                        if (!isSupportedExtension || !isSupportedMime) {
                            util.ErrorLogger.logError("INPUT VALIDATION ERROR", 
                                "Invalid file type uploaded. Expected PNG or JPEG image. Filename: '" + originalFileName + "', Content-Type: '" + contentType + "' for user ID: " + userId, 
                                null, session, getServletContext());
                            response.sendRedirect("guest.jsp?status=invalid_file");
                            return;
                        }

                        String uploadPath = getServletContext().getRealPath("/uploads");
                        if (uploadPath == null) {
                            uploadPath = System.getProperty("user.home") + File.separator + "OJT_Monitoring_System_Uploads";
                        }
                        File uploadDir = new File(uploadPath);
                        if (!uploadDir.exists()) {
                            uploadDir.mkdirs();
                        }
                        // Create a clean filename
                        String cleanName = new File(originalFileName).getName();
                        supportingFile = System.currentTimeMillis() + "_" + cleanName;
                        filePart.write(uploadPath + File.separator + supportingFile);
                    }
                }
            } catch (Exception e) {
                util.ErrorLogger.logError("SERVLET UPLOAD ERROR", "Error occurred while handling multipart task submission", e, session, getServletContext());
                e.printStackTrace();
                response.sendRedirect("guest.jsp?status=db_error");
                return;
            }
        } else {
            // B. Plain AJAX/URL-encoded case (Stopwatch timer clock out)
            hoursStr = request.getParameter("simulatedHours");
            description = request.getParameter("taskDescription");
            originalFileName = "stopwatch_log.txt";
            supportingFile = "stopwatch_sync_timestamp";
        }

        // Parse hours and append to description so admin can see details in log reviews
        double hours = 0.0;
        try {
            if (hoursStr != null && !hoursStr.trim().isEmpty()) {
                hours = Double.parseDouble(hoursStr);
            }
        } catch (NumberFormatException e) {
            util.ErrorLogger.logError("INPUT VALIDATION ERROR", "Failed parsing simulatedHours. Invalid format: '" + hoursStr + "'", e, session, getServletContext());
        }

        // Refine description with hours metadata
        String refinedDesc = description;
        if (hours > 0) {
            refinedDesc = description + " (Hours Spent: " + String.format("%.2f", hours) + "h)";
        }

        // Construct ActivitySubmission model
        ActivitySubmission sub = new ActivitySubmission();
        sub.setUserId(userId);
        sub.setDateSubmitted(new Date(System.currentTimeMillis()));
        sub.setDescription(refinedDesc);
        sub.setSupportingFile(supportingFile);
        sub.setOriginalFileName(originalFileName);
        sub.setStatus("Pending");

        boolean success = UserDAO.addActivitySubmission(sub, getServletContext());

        if (isMultipart) {
            if (success) {
                response.sendRedirect("guest.jsp?status=success&approvedHours=" + hours);
            } else {
                util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Task submission database write failed for user: " + userId + ". File: " + originalFileName, null, session, getServletContext());
                response.sendRedirect("guest.jsp?status=db_error");
            }
        } else {
            // AJAX responses
            if (success) {
                response.setStatus(HttpServletResponse.SC_OK);
                response.getWriter().write("Sync Live Complete.");
            } else {
                util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Stopwatch session sync database write failed for user: " + userId, null, session, getServletContext());
                response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Database record insertion failure.");
            }
        }
    }

    private String getSubmittedFileName(Part part) {
        try {
            return part.getSubmittedFileName();
        } catch (NoSuchMethodError e) {
            String contentDisp = part.getHeader("content-disposition");
            if (contentDisp != null) {
                for (String content : contentDisp.split(";")) {
                    if (content.trim().startsWith("filename")) {
                        return content.substring(content.indexOf('=') + 1).trim().replace("\"", "");
                    }
                }
            }
        }
        return null;
    }
}
