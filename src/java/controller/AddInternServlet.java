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
        
        // CSRF Token Validation
        if (session == null || !util.CsrfUtil.validateToken(request, session)) {
            util.ErrorLogger.logError("CSRF VIOLATION", "Intern registration attempt blocked due to invalid or missing CSRF token.", null, session, getServletContext());
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid CSRF token.");
            return;
        }

        String tabId = util.TabSessionHelper.getTabId(request);
        User user = util.TabSessionHelper.getUser(session, tabId);
        
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
            String birthDateStr = request.getParameter("birthDate");
            String birthYearStr = request.getParameter("birthYear");
            String ageStr = request.getParameter("age");
            String city = request.getParameter("city");
            String contactNum = request.getParameter("contactNum");
            String university = request.getParameter("university");
            String role = request.getParameter("role");
            String email = request.getParameter("email");
            String plainPassword = request.getParameter("password");

            // Trim and fallback defaults
            firstName = (firstName == null) ? "" : firstName.trim();
            middleName = (middleName == null) ? "" : middleName.trim();
            lastName = (lastName == null) ? "" : lastName.trim();
            birthMonth = (birthMonth == null) ? "" : birthMonth.trim();
            birthDateStr = (birthDateStr == null) ? "" : birthDateStr.trim();
            birthYearStr = (birthYearStr == null) ? "" : birthYearStr.trim();
            ageStr = (ageStr == null) ? "" : ageStr.trim();
            city = (city == null) ? "" : city.trim();
            contactNum = (contactNum == null) ? "" : contactNum.trim();
            university = (university == null) ? "" : university.trim();
            role = (role == null) ? "" : role.trim();
            email = (email == null) ? "" : email.trim().toLowerCase();
            plainPassword = (plainPassword == null) ? "" : plainPassword;

            // Whitelist of valid roles
            java.util.Set<String> validRoles = new java.util.HashSet<>(java.util.Arrays.asList(
                "data engineer intern", "ui/ux intern", "front-end developer intern", "backend developer intern", "quality assurance intern"
            ));

            // 2. Validate all inputs via InputValidator
            boolean valid = util.InputValidator.isValidName(firstName)
                && (middleName.isEmpty() || util.InputValidator.isValidName(middleName))
                && util.InputValidator.isValidName(lastName)
                && util.InputValidator.isValidEmail(email)
                && util.InputValidator.isValidDate(birthMonth, birthDateStr, birthYearStr)
                && util.InputValidator.isValidIntegerInRange(ageStr, 15, 99)
                && util.InputValidator.isValidLength(city, 2, 100)
                && util.InputValidator.isValidPhoneNumber(contactNum)
                && util.InputValidator.isValidUniversity(university)
                && validRoles.contains(role.toLowerCase())
                && util.InputValidator.isValidPassword(plainPassword);

            if (!valid) {
                util.ErrorLogger.logError("INPUT VALIDATION ERROR", "Failed intern registration validation for email: " + email, null, session, getServletContext());
                response.sendRedirect("admin.jsp?view=intern-management&status=failed&err=invalid_input&tabId=" + tabId);
                return;
            }

            // Check if email already exists in Database
            if (UserDAO.findUserByEmail(email, getServletContext()) != null) {
                util.ErrorLogger.logError("INPUT VALIDATION ERROR", "Intern registration failed: Duplicate email: " + email, null, session, getServletContext());
                response.sendRedirect("admin.jsp?view=intern-management&status=failed&err=duplicate_email&tabId=" + tabId);
                return;
            }

            // 3. Map the technical role choices down to structural codes and office mapping parameters
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

            // Re-verify email generation logic to prevent client-side parameter tampering
            String cleanFirstName = firstName.replaceAll("\\s+", "");
            String cleanLastName = lastName.replaceAll("\\s+", "");
            String expectedEmail = (cleanFirstName + "." + cleanLastName + "." + roleCode).toLowerCase() + "@gmail.com";
            if (!expectedEmail.equals(email)) {
                util.ErrorLogger.logError("INPUT VALIDATION ERROR", "Intern registration failed: Tampered or invalid email address. Received: '" + email + "', Expected: '" + expectedEmail + "'", null, session, getServletContext());
                response.sendRedirect("admin.jsp?view=intern-management&status=failed&err=invalid_input&tabId=" + tabId);
                return;
            }

            // Parse safe integers now that validation succeeded
            int birthDate = Integer.parseInt(birthDateStr);
            int birthYear = Integer.parseInt(birthYearStr);
            int age = Integer.parseInt(ageStr);

            // 4. Hash verification credential password strings matching layout architecture
            String encryptedPassword = CryptoUtil.hashPassword(plainPassword); 

            // 5. Construct data values inside the primary object layer instance container
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

            // 6. Fire transaction update statement inside Derby where custom id string creation executes
            boolean isSaved = UserDAO.addIntern(newIntern, birthMonth, birthDate, birthYear, age, contactNum, getServletContext());
            
            // 7. Direct server execution response parameters using cross-boundary URL parameter formatting
            if (isSaved) {
                String safeId = newIntern.getId() != null ? newIntern.getId() : "";
                String safeName = newIntern.getFullName() != null ? newIntern.getFullName() : "";
                String safeEmail = newIntern.getEmail() != null ? newIntern.getEmail() : "";
                String safeOffice = newIntern.getOffice() != null ? newIntern.getOffice() : "";
                String safeRole = newIntern.getRole() != null ? newIntern.getRole() : "";
                String safeCity = newIntern.getCity() != null ? newIntern.getCity() : "";
                String safeContact = contactNum != null ? contactNum : "";
                String safeUni = newIntern.getUniversity() != null ? newIntern.getUniversity() : "";
                
                response.sendRedirect("admin.jsp?view=intern-management&status=success&tabId=" + tabId
                        + "&newId=" + URLEncoder.encode(safeId, "UTF-8")
                        + "&newName=" + URLEncoder.encode(safeName, "UTF-8")
                        + "&newEmail=" + URLEncoder.encode(safeEmail, "UTF-8")
                        + "&newOffice=" + URLEncoder.encode(safeOffice, "UTF-8")
                        + "&newRole=" + URLEncoder.encode(safeRole, "UTF-8")
                        + "&newCity=" + URLEncoder.encode(safeCity, "UTF-8")
                        + "&newContact=" + URLEncoder.encode(safeContact, "UTF-8")
                        + "&newUni=" + URLEncoder.encode(safeUni, "UTF-8")
                        + "&newBirthAge=" + URLEncoder.encode(birthMonth + " " + birthDate + ", " + birthYear + " (Age: " + age + ")", "UTF-8"));
            } else {
                util.ErrorLogger.logError("DATABASE TRANSACTION ERROR", "Failed to save new intern profile to database for: " + email, null, request.getSession(false), getServletContext());
                response.sendRedirect("admin.jsp?view=intern-management&status=failed&tabId=" + tabId);
            }
            
        } catch (Exception e) {
            util.ErrorLogger.logError("SERVLET REGISTER ERROR", "Failed to register new intern due to input or processing exception. Form Email: " + request.getParameter("email"), e, request.getSession(false), getServletContext());
            e.printStackTrace();
            response.sendRedirect("admin.jsp?view=intern-management&status=error&tabId=" + tabId);
        }
    }
}