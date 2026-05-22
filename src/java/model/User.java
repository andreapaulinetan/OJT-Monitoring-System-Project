package model;

import java.io.Serializable;

/**
 * Model class representing a User (Admin or Intern). 
 * Implements Serializable as it is stored in the HttpSession.
 */
public class User implements Serializable {

    // --- SYSTEM IDENTIFICATION ---
    private String id; // Changed from int to String to support format like 'INT2026-70001'
    private String role; // e.g., 'Admin', 'Backend Developer Intern'
    private String roleCode; // e.g., 'admin', 'be', 'uiux' (Changed from role_code to camelCase)
    private String email;
    private String password;

    // --- PERSONAL INFORMATION ---
    private String firstName;
    private String middleName; // Added to match database columns
    private String lastName;
    private String city; 

    // --- INTERN SPECIFIC INFORMATION ---
    private String university;
    private String office;
    private String logStatus;
    private boolean resetHours;
    private double baselineHours = 148.5;

    // Default Constructor
    public User() {
    }

    // ==========================================
    // GETTERS AND SETTERS
    // ==========================================

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }

    public String getRoleCode() {
        return roleCode;
    }

    public void setRoleCode(String roleCode) {
        this.roleCode = roleCode;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getFirstName() {
        return firstName;
    }

    public void setFirstName(String firstName) {
        this.firstName = firstName;
    }

    public String getMiddleName() {
        return middleName;
    }

    public void setMiddleName(String middleName) {
        this.middleName = middleName;
    }

    public String getLastName() {
        return lastName;
    }

    public void setLastName(String lastName) {
        this.lastName = lastName;
    }

    public String getCity() {
        return city;
    }

    public void setCity(String city) {
        this.city = city;
    }

    public String getUniversity() {
        return university;
    }

    public void setUniversity(String university) {
        this.university = university;
    }

    public String getOffice() {
        return office;
    }

    public void setOffice(String office) {
        this.office = office;
    }

    public String getLogStatus() {
        return logStatus;
    }

    public void setLogStatus(String logStatus) {
        this.logStatus = logStatus;
    }

    public double getBaselineHours() {
        return baselineHours;
    }

    public void setBaselineHours(double baselineHours) {
        this.baselineHours = baselineHours;
    }

    // ==========================================
    // UTILITY HELPER METHODS
    // ==========================================

    /**
     * Use this in JSP like: user.getFullName()
     */
    public String getFullName() {
        StringBuilder fullName = new StringBuilder();
        
        if (firstName != null && !firstName.trim().isEmpty()) {
            fullName.append(firstName.trim()).append(" ");
        }
        
        if (middleName != null && !middleName.trim().isEmpty()) {
            fullName.append(middleName.trim()).append(" ");
        }
        
        if (lastName != null && !lastName.trim().isEmpty()) {
            fullName.append(lastName.trim());
        }
        
        return fullName.toString().trim();
    }

    public boolean isResetHours() {
        return resetHours;
    }

    public void setResetHours(boolean resetHours) {
        this.resetHours = resetHours;
    }
}