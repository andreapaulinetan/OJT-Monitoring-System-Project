package controller;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import model.User;
import model.UserDAO;
import util.CryptoUtil;

@WebServlet("/UpdateInternServlet")
public class UpdateInternServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        // Enforce UTF-8 Character Encoding to support regional characters/names smoothly
        request.setCharacterEncoding("UTF-8");
        
        // Security validation & multi-tab session instance extraction sequence
        HttpSession session = request.getSession(false);
        String tabId = util.TabSessionHelper.getTabId(request);
        User user = (session != null && tabId != null) ? util.TabSessionHelper.getUser(session, tabId) : null;
        
        if (user == null || !"admin".equalsIgnoreCase(user.getRole())) {
            util.ErrorLogger.logError(
                "SECURITY VIOLATION", 
                "Unauthorized attempt to update intern profile. Active user: " + (user != null ? user.getEmail() : "anonymous") + " (Tab ID: " + tabId + ")", 
                null, 
                session, 
                getServletContext()
            );
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Admin privileges required.");
            return;
        }

        try {
            // 1. Extract form parameters forwarded from your front-end modal execution script
            String internId = request.getParameter("internId");
            String firstName = request.getParameter("firstName");
            String middleName = request.getParameter("middleName");
            String lastName = request.getParameter("lastName");
            String birthMonth = request.getParameter("birthMonth");
            
            // Clean up numbers safely to prevent primitive data parsing exceptions
            int birthDate = 0;
            if (request.getParameter("birthDate") != null && !request.getParameter("birthDate").trim().isEmpty()) {
                birthDate = Integer.parseInt(request.getParameter("birthDate").trim());
            }
            
            int birthYear = 0;
            if (request.getParameter("birthYear") != null && !request.getParameter("birthYear").trim().isEmpty()) {
                birthYear = Integer.parseInt(request.getParameter("birthYear").trim());
            }
            
            int age = 0;
            if (request.getParameter("age") != null && !request.getParameter("age").trim().isEmpty()) {
                age = Integer.parseInt(request.getParameter("age").trim());
            }
            
            String city = request.getParameter("city");
            String contactNum = request.getParameter("contactNum");
            String university = request.getParameter("university");
            String role = request.getParameter("role");
            String email = request.getParameter("email");
            String plainPassword = request.getParameter("password");

            // 2. Map the technical role choices down to structural codes and office mapping parameters
            String roleCode = "";
            String office = "";
            
            if ("Data Engineer Intern".equals(role)) {
                roleCode = "da";
                office = "Office 1 - Data & Analytics";
            } else if ("UI/UX Intern".equals(role)) {
                roleCode = "uiux";
                office = "Office 2 - Creative Design";
            } else if ("Front-end Developer Intern".equals(role)) {
                roleCode = "fe";
                office = "Office 2 - Creative Design";
            } else if ("Backend Developer Intern".equals(role)) {
                roleCode = "be";
                office = "Office 3 - Systems & Infrastructure";
            } else if ("Quality Assurance Intern".equals(role)) {
                roleCode = "qa";
                office = "Office 4 - Quality Control";
            } else {
                // Fail-safe default fallback configuration parameter setting if role does not perfectly match
                roleCode = "intern";
                office = "General Operations Registry Office";
            }

            // 3. Determine if password field update requirements have been met
            boolean changePassword = (plainPassword != null && !plainPassword.trim().isEmpty());

            // 4. Construct data values inside the primary structural object layer container
            User internUser = new User();
            internUser.setId(internId);
            internUser.setFirstName(firstName);
            internUser.setMiddleName(middleName);
            internUser.setLastName(lastName);
            internUser.setCity(city);
            internUser.setUniversity(university);
            internUser.setRole(role);
            internUser.setRoleCode(roleCode);
            internUser.setOffice(office);
            internUser.setEmail(email);

            if (changePassword) {
                // Fire utility routine class password hashing algorithms
                String encryptedPassword = CryptoUtil.hashPassword(plainPassword.trim());
                internUser.setPassword(encryptedPassword);
            }

            // 5. Fire operational persistent data update transaction layer statement
            boolean isUpdated = UserDAO.updateIntern(
                internUser, 
                birthMonth, 
                birthDate, 
                birthYear, 
                age, 
                contactNum, 
                changePassword, 
                getServletContext()
            );
            
            // 6. Direct server context execution routing response logic back to interface views
            if (isUpdated) {
                response.sendRedirect("admin.jsp?view=intern-management&status=updated&tabId=" + (tabId != null ? tabId : ""));
            } else {
                util.ErrorLogger.logError(
                    "DATABASE TRANSACTION ERROR", 
                    "Failed to execute profile adjustments via database update transaction routines for ID: " + internId, 
                    null, 
                    request.getSession(false), 
                    getServletContext()
                );
                response.sendRedirect("admin.jsp?view=intern-management&err=update_failed&tabId=" + (tabId != null ? tabId : ""));
            }
            
        } catch (Exception e) {
            util.ErrorLogger.logError(
                "SERVLET UPDATE ERROR", 
                "System raised an execution or structural processing processing exception during intern adjustment. Target ID: " + request.getParameter("internId"), 
                e, 
                request.getSession(false), 
                getServletContext()
            );
            e.printStackTrace();
            response.sendRedirect("admin.jsp?view=intern-management&err=update_failed&tabId=" + (tabId != null ? tabId : ""));
        }
    }
}