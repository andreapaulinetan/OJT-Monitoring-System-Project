package scratch;

import java.sql.*;
import util.CryptoUtil;

public class RunMigrationAndVerify {
    private static final String[] URLS = {
        "jdbc:derby://localhost:1527/ojt_AuthenticationDB",
        "jdbc:derby://localhost:1527/C:/Users/andre/OneDrive/Documents/NetBeansProjects/FinalProject_2CSD_DelaCruz_Hernandez_Mejia_Tan/database/ojt_AuthenticationDB",
        "jdbc:derby://localhost:1527/c:/Users/andre/OneDrive/Documents/NetBeansProjects/FinalProject_2CSD_DelaCruz_Hernandez_Mejia_Tan/database/ojt_AuthenticationDB"
    };
    private static final String USER = "app";
    private static final String PWD = "app";

    public static void main(String[] args) {
        try {
            Class.forName("org.apache.derby.jdbc.ClientDriver");
            
            for (String url : URLS) {
                System.out.println("\n========================================================");
                System.out.println("PROCESSING DATABASE: " + url);
                System.out.println("========================================================");
                
                try (Connection conn = DriverManager.getConnection(url, USER, PWD)) {
                    System.out.println("SUCCESS: Connected to database.");
                    
                    System.out.println("\n--- BEFORE MIGRATION ---");
                    printUsers(conn);

                    System.out.println("\n--- RUNNING MIGRATION ---");
                    migrate(conn, url);

                    System.out.println("\n--- AFTER MIGRATION ---");
                    printUsers(conn);

                    System.out.println("\n--- VERIFYING LOGINS ---");
                    verifyLogins(conn);
                } catch (SQLException e) {
                    System.out.println("DATABASE SKIP: Could not process database: " + e.getMessage());
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private static void printUsers(Connection conn) throws SQLException {
        String selectAdmin = "SELECT ADMIN_ID, EMAIL, PASSWORD FROM ADMIN";
        try (Statement stmt = conn.createStatement(); ResultSet rs = stmt.executeQuery(selectAdmin)) {
            // works
        } catch (SQLException e) {
            selectAdmin = "SELECT ADMIN_ID, EMAIL, PASSWORD FROM APP.ADMIN";
        }
        
        System.out.println("ADMINS:");
        try (Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(selectAdmin)) {
            int count = 0;
            while (rs.next()) {
                System.out.printf("  ID: %s | Email: %s | Pwd: %s\n", 
                    rs.getString("ADMIN_ID"), rs.getString("EMAIL"), rs.getString("PASSWORD"));
                count++;
            }
            if (count == 0) System.out.println("  (No admins found)");
        }

        String selectIntern = "SELECT INTERN_ID, EMAIL, PASSWORD FROM INTERN";
        try (Statement stmt = conn.createStatement(); ResultSet rs = stmt.executeQuery(selectIntern)) {
            // works
        } catch (SQLException e) {
            selectIntern = "SELECT INTERN_ID, EMAIL, PASSWORD FROM APP.INTERN";
        }

        System.out.println("INTERNS:");
        try (Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(selectIntern)) {
            int count = 0;
            while (rs.next() && count < 5) { // Print first 5 for brevity
                System.out.printf("  ID: %s | Email: %s | Pwd: %s\n", 
                    rs.getString("INTERN_ID"), rs.getString("EMAIL"), rs.getString("PASSWORD"));
                count++;
            }
            if (count == 0) System.out.println("  (No interns found)");
        }
    }

    private static void migrate(Connection conn, String url) throws SQLException {
        String selectAdmin = "SELECT ADMIN_ID, PASSWORD FROM ADMIN";
        String updateAdmin = "UPDATE ADMIN SET PASSWORD = ? WHERE ADMIN_ID = ?";
        boolean useSchema = false;
        
        try (Statement stmt = conn.createStatement(); ResultSet rs = stmt.executeQuery(selectAdmin)) {
            // works
        } catch (SQLException e) {
            selectAdmin = "SELECT ADMIN_ID, PASSWORD FROM APP.ADMIN";
            updateAdmin = "UPDATE APP.ADMIN SET PASSWORD = ? WHERE ADMIN_ID = ?";
            useSchema = true;
        }

        try (Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(selectAdmin)) {
            while (rs.next()) {
                String id = rs.getString("ADMIN_ID");
                String pwd = rs.getString("PASSWORD");
                if (pwd != null && !pwd.startsWith("enc:")) {
                    String encrypted = CryptoUtil.hashPassword(pwd);
                    try (PreparedStatement ps = conn.prepareStatement(updateAdmin)) {
                        ps.setString(1, encrypted);
                        ps.setString(2, id);
                        ps.executeUpdate();
                        System.out.printf("  Migrated ADMIN ID %s: %s -> %s\n", id, pwd, encrypted);
                    }
                }
            }
        }

        String selectIntern = "SELECT INTERN_ID, PASSWORD FROM INTERN";
        String updateIntern = "UPDATE INTERN SET PASSWORD = ? WHERE INTERN_ID = ?";
        if (useSchema) {
            selectIntern = "SELECT INTERN_ID, PASSWORD FROM APP.INTERN";
            updateIntern = "UPDATE APP.INTERN SET PASSWORD = ? WHERE INTERN_ID = ?";
        }

        try (Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(selectIntern)) {
            int count = 0;
            while (rs.next()) {
                String id = rs.getString("INTERN_ID");
                String pwd = rs.getString("PASSWORD");
                if (pwd != null && !pwd.startsWith("enc:")) {
                    String encrypted = CryptoUtil.hashPassword(pwd);
                    try (PreparedStatement ps = conn.prepareStatement(updateIntern)) {
                        ps.setString(1, encrypted);
                        ps.setString(2, id);
                        ps.executeUpdate();
                        count++;
                    }
                }
            }
            System.out.printf("  Migrated %d legacy INTERN records to AES.\n", count);
        }
    }

    private static void verifyLogins(Connection conn) throws SQLException {
        String selectAdmin = "SELECT EMAIL, PASSWORD FROM ADMIN";
        try (Statement stmt = conn.createStatement(); ResultSet rs = stmt.executeQuery(selectAdmin)) {
            // works
        } catch (SQLException e) {
            selectAdmin = "SELECT EMAIL, PASSWORD FROM APP.ADMIN";
        }

        try (Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(selectAdmin)) {
            if (rs.next()) {
                String email = rs.getString("EMAIL");
                String stored = rs.getString("PASSWORD");
                System.out.println("  Testing verifier on admin: " + email);
                
                boolean verifyWrong = CryptoUtil.verifyPassword("wrong_pwd", stored);
                System.out.println("    verifyPassword('wrong_pwd') = " + verifyWrong + " (Expected: false)");

                if (stored != null && stored.startsWith("enc:")) {
                    String plain = CryptoUtil.decrypt(stored.substring(4));
                    boolean verifyCorrect = CryptoUtil.verifyPassword(plain, stored);
                    System.out.println("    verifyPassword('" + plain + "') = " + verifyCorrect + " (Expected: true)");
                }
            }
        }
    }
}
