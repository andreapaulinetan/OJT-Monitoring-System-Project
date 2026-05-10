package model;

import java.io.Serializable;

/**
 * Model class representing a User (Admin or Intern).
 * Implements Serializable as it is stored in the HttpSession.
 */
public class User implements Serializable {
    private int id;
    private String firstName;
    private String lastName;
    private String email;
    private String role;
    private String university;
    private String office;

    // Default Constructor
    public User() {}

    // --- GETTERS AND SETTERS ---

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getFirstName() {
        return firstName;
    }

    public void setFirstName(String firstName) {
        this.firstName = firstName;
    }

    public String getLastName() {
        return lastName;
    }

    public void setLastName(String lastName) {
        this.lastName = lastName;
    }

    /**
     * Helper method to get full name for display purposes.
     * Use this in JSP like: <%= user.getFullName() %>
     */
    public String getFullName() {
        return (firstName != null ? firstName : "") + " " + (lastName != null ? lastName : "");
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
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
}