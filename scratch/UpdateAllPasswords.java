package scratch;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import util.CryptoUtil;

public class UpdateAllPasswords {
    private static final String[] URLS = {
        "jdbc:derby://localhost:1527/ojt_AuthenticationDB",
        "jdbc:derby://localhost:1527/C:/Users/andre/OneDrive/Documents/NetBeansProjects/FinalProject_2CSD_DelaCruz_Hernandez_Mejia_Tan/database/ojt_AuthenticationDB",
        "jdbc:derby://localhost:1527/c:/Users/andre/OneDrive/Documents/NetBeansProjects/FinalProject_2CSD_DelaCruz_Hernandez_Mejia_Tan/database/ojt_AuthenticationDB"
    };

    public static void main(String[] args) {
        String rawAdminPass = "Admin123#";
        String rawInternPass = "Pass123#";
        
        String encAdminPass = CryptoUtil.hashPassword(rawAdminPass);
        String encInternPass = CryptoUtil.hashPassword(rawInternPass);
        
        System.out.println("Admin plain: " + rawAdminPass + " | encrypted: " + encAdminPass);
        System.out.println("Intern plain: " + rawInternPass + " | encrypted: " + encInternPass);

        try {
            Class.forName("org.apache.derby.jdbc.ClientDriver");
            
            for (String url : URLS) {
                System.out.println("\nConnecting to: " + url);
                try (Connection conn = DriverManager.getConnection(url, "app", "app")) {
                    
                    // Update ADMINS
                    try {
                        String sqlAdmin = "UPDATE ADMIN SET PASSWORD = ?";
                        try (PreparedStatement ps = conn.prepareStatement(sqlAdmin)) {
                            ps.setString(1, encAdminPass);
                            int rows = ps.executeUpdate();
                            System.out.println("  Updated ADMIN table: " + rows + " row(s).");
                        }
                    } catch (Exception e) {
                        try {
                            String sqlAdminApp = "UPDATE APP.ADMIN SET PASSWORD = ?";
                            try (PreparedStatement ps = conn.prepareStatement(sqlAdminApp)) {
                                ps.setString(1, encAdminPass);
                                int rows = ps.executeUpdate();
                                System.out.println("  Updated APP.ADMIN table: " + rows + " row(s).");
                            }
                        } catch (Exception ex) {
                            System.out.println("  Admin update failed: " + ex.getMessage());
                        }
                    }

                    // Update INTERNS
                    try {
                        String sqlIntern = "UPDATE INTERN SET PASSWORD = ?";
                        try (PreparedStatement ps = conn.prepareStatement(sqlIntern)) {
                            ps.setString(1, encInternPass);
                            int rows = ps.executeUpdate();
                            System.out.println("  Updated INTERN table: " + rows + " row(s).");
                        }
                    } catch (Exception e) {
                        try {
                            String sqlInternApp = "UPDATE APP.INTERN SET PASSWORD = ?";
                            try (PreparedStatement ps = conn.prepareStatement(sqlInternApp)) {
                                ps.setString(1, encInternPass);
                                int rows = ps.executeUpdate();
                                System.out.println("  Updated APP.INTERN table: " + rows + " row(s).");
                            }
                        } catch (Exception ex) {
                            System.out.println("  Intern update failed: " + ex.getMessage());
                        }
                    }
                    
                } catch (Exception e) {
                    System.out.println("  Database connection skipped/failed: " + e.getMessage());
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
