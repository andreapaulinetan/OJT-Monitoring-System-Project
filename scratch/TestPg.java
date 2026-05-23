package scratch;

import java.sql.Connection;
import java.sql.DriverManager;

public class TestPg {
    public static void main(String[] args) {
        String[] passwords = {"app", "postgres", "110705", "admin", "root"};
        String url = "jdbc:postgresql://localhost:5432/ojt_auditdb";
        try {
            Class.forName("org.postgresql.Driver");
            for (String pwd : passwords) {
                System.out.println("Trying password: '" + pwd + "'...");
                try (Connection conn = DriverManager.getConnection(url, "postgres", pwd)) {
                    System.out.println("SUCCESS: Connected to PostgreSQL with password '" + pwd + "'");
                    return;
                } catch (Exception e) {
                    System.out.println("FAILED: " + e.getMessage());
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
