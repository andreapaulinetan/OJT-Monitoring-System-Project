package controller;

import java.io.IOException;
import java.net.URLEncoder;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

// Import your dynamic project user data models and query hooks securely
import model.User;
import model.UserDAO;
import util.CryptoUtil;

public class AddInternServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        // Security & session verification check
        HttpSession session = request.getSession(false);
        String tabId = util.TabSessionHelper.getTabId(request);
        User user = (session != null && tabId != null) ? util.TabSessionHelper.getUser(session, tabId) : null;
        
        if (user == null || !"admin".equalsIgnoreCase(user.getRole())) {
            util.ErrorLogger.logError("SECURITY VIOLATION", "Unauthorized attempt to register new intern. Active user: " + (user != null ? user.getEmail() : "anonymous") + " (Tab ID: " + tabId + ")", null, session, getServletContext());
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Admin privileges required.");
            return;
        }

        try {
            // 1. Extract dynamic configuration parameters submitted via the form parameters fields
            String firstName = request.getParameter("firstName");
            String middleName = request.getParameter("middleName");
            String lastName = request.getParameter("lastName");
            String birthMonth = request.getParameter("birthMonth");
            int birthDate = Integer.parseInt(request.getParameter("birthDate"));
            int birthYear = Integer.parseInt(request.getParameter("birthYear"));
            int age = Integer.parseInt(request.getParameter("age"));
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
            }

            // 3. Hash verification credential password strings matching layout architecture
            String encryptedPassword = CryptoUtil.hashPassword(plainPassword); 

            // 4. Construct data values inside the primary object layer instance container
            User newIntern = new User();
            newIntern.setFirstName(firstName);
            newIntern.setMiddleName(middleName);
            newIntern.setLastName(lastName);
            newIntern.setCity(city);
            newIntern.setUniversity(university);
            newIntern.setRole(role);
            newIntern.setRoleCode(roleCode);
            newIntern.setOffice(office);
            newIntern.setEmail(email);
            newIntern.setPassword(encryptedPassword);

            // 5. Fire transaction update statement inside Derby where custom id string creation executes
            boolean isSaved = UserDAO.addIntern(newIntern, birthMonth, birthDate, birthYear, age, contactNum, getServletContext());
            
            // 6. Direct server execution response parameters using cross-boundary URL parameter formatting
            if (isSaved) {
                response.sendRedirect("admin.jsp?status=success"
                        + "&newId=" + URLEncoder.encode(newIntern.getId(), "UTF-8")
                        + "&newName=" + URLEncoder.encode(newIntern.getFullName(), "UTF-8")
                        + "&newEmail=" + URLEncoder.encode(newIntern.getEmail(), "UTF-8")
                        + "&newOffice=" + URLEncoder.encode(newIntern.getOffice(), "UTF-8")
                        + "&newRole=" + URLEncoder.encode(newIntern.getRole(), "UTF-8")
                        + "&newCity=" + URLEncoder.encode(newIntern.getCity(), "UTF-8")
                        + "&newContact=" + URLEncoder.encode(contactNum, "UTF-8")
                        + "&newUni=" + URLEncoder.encode(newIntern.getUniversity(), "UTF-8")
                        + "&newBirthAge=" + URLEncoder.encode(birthMonth + " " + birthDate + ", " + birthYear + " (Age: " + age + ")", "UTF-8"));
            } else {
                util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed to save new intern profile to database for: " + email, null, request.getSession(false), getServletContext());
                response.sendRedirect("admin.jsp?status=failed");
            }
            
        } catch (Exception e) {
            util.ErrorLogger.logError("SERVLET REGISTER ERROR", "Failed to register new intern due to input or processing exception. Form Email: " + request.getParameter("email"), e, request.getSession(false), getServletContext());
            e.printStackTrace();
            response.sendRedirect("admin.jsp?status=error");
        }
    }
}