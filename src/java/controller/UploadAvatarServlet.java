package controller;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;

import model.User;
import model.UserDAO;
import util.TabSessionHelper;

@WebServlet("/UploadAvatarServlet")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024 * 1,  // 1 MB
    maxFileSize = 1024 * 1024 * 10,       // 10 MB
    maxRequestSize = 1024 * 1024 * 15     // 15 MB
)
public class UploadAvatarServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        String tabId = TabSessionHelper.getTabId(request);
        User user = (session != null && tabId != null) ? TabSessionHelper.getUser(session, tabId) : null;

        if (user == null) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Unauthorized. Session expired.");
            return;
        }

        try {
            Part filePart = request.getPart("avatarFile");
            if (filePart == null || filePart.getSize() <= 0) {
                response.sendRedirect("guest.jsp?view=coordinator&status=avatar_failed&tabId=" + (tabId != null ? tabId : ""));
                return;
            }

            String contentType = filePart.getContentType();
            if (contentType == null || (!contentType.equals("image/png") && !contentType.equals("image/jpeg") && !contentType.equals("image/jpg"))) {
                response.sendRedirect("guest.jsp?view=coordinator&status=avatar_invalid_type&tabId=" + (tabId != null ? tabId : ""));
                return;
            }

            // Determine extension
            String ext = "png";
            if (contentType.equals("image/jpeg") || contentType.equals("image/jpg")) {
                ext = "jpg";
            }

            String uploadPath = getServletContext().getRealPath("/uploads/avatars");
            if (uploadPath == null) {
                uploadPath = System.getProperty("user.home") + File.separator + "OJT_Monitoring_System_Uploads" + File.separator + "avatars";
            }
            File uploadDir = new File(uploadPath);
            if (!uploadDir.exists()) {
                uploadDir.mkdirs();
            }

            String fileName = user.getId() + "_avatar." + ext;
            File targetFile = new File(uploadPath + File.separator + fileName);
            try (InputStream input = filePart.getInputStream()) {
                Files.copy(input, targetFile.toPath(), StandardCopyOption.REPLACE_EXISTING);
            }

            // Save relative path in database
            String relativePath = "/uploads/avatars/" + fileName;
            boolean updated = UserDAO.updateAvatarPath(user.getId(), relativePath, getServletContext());

            if (updated) {
                // Update user object in session
                User dbUser = UserDAO.getInternById(user.getId(), getServletContext());
                if (dbUser != null) {
                    TabSessionHelper.setUser(session, tabId, dbUser);
                }
                response.sendRedirect("guest.jsp?view=coordinator&status=avatar_success&tabId=" + (tabId != null ? tabId : ""));
            } else {
                response.sendRedirect("guest.jsp?view=coordinator&status=avatar_failed&tabId=" + (tabId != null ? tabId : ""));
            }

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("guest.jsp?view=coordinator&status=avatar_failed&tabId=" + (tabId != null ? tabId : ""));
        }
    }
}
