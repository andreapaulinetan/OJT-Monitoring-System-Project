package scratch;

import javax.servlet.ServletContext;
import model.User;
import model.UserDAO;

public class TestAddIntern {
    public static void main(String[] args) {
        ServletContext context = TestDaoMapping.createMockContext();
        
        System.out.println("=== Testing Add Intern ===");
        User intern = new User();
        intern.setFirstName("Test");
        intern.setMiddleName("Middle");
        intern.setLastName("Intern");
        intern.setCity("Manila");
        intern.setUniversity("UST");
        intern.setRole("Backend Developer Intern");
        intern.setRoleCode("be");
        intern.setOffice("Office 3 - Systems & Infrastructure");
        intern.setEmail("test.intern.be@gmail.com");
        intern.setPassword("hashedpassword123");
        
        // Let's delete if already exists to make test repeatable
        try {
            User existing = UserDAO.findUserByEmail(intern.getEmail(), context);
            if (existing != null) {
                System.out.println("Found existing test intern with ID: " + existing.getId() + ". Deleting...");
                boolean deleted = UserDAO.deleteIntern(existing.getId(), context);
                System.out.println("Deleted existing test intern: " + deleted);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        
        boolean saved = UserDAO.addIntern(intern, "May", 22, 2000, 26, "09123456789", context);
        System.out.println("Intern added: " + saved);
        if (saved) {
            System.out.println("Newly added Intern ID: " + intern.getId());
            User fetched = UserDAO.getInternById(intern.getId(), context);
            if (fetched != null) {
                System.out.println("Successfully fetched newly added intern from database!");
                System.out.println("Name: " + fetched.getFullName());
                System.out.println("Email: " + fetched.getEmail());
                System.out.println("University: " + fetched.getUniversity());
                
                // Now clean up/delete the test intern to leave database pristine
                boolean cleaned = UserDAO.deleteIntern(intern.getId(), context);
                System.out.println("Cleaned up/deleted test intern: " + cleaned);
            } else {
                System.out.println("Failed to fetch newly added intern from database!");
            }
        }
    }
}
