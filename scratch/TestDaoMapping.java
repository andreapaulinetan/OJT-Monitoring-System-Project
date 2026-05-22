package scratch;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.servlet.ServletContext;
import model.ActivitySubmission;
import model.User;
import model.UserDAO;

public class TestDaoMapping {

    @SuppressWarnings("rawtypes")
    public static ServletContext createMockContext() {
        final Map<String, String> params = new HashMap<>();
        params.put("derby.driver", "org.apache.derby.jdbc.ClientDriver");
        params.put("derby.url", "jdbc:derby://localhost:1527/ojt_AuthenticationDB");
        params.put("derby.username", "app");
        params.put("derby.password", "app");

        params.put("mysql.driver", "com.mysql.cj.jdbc.Driver");
        params.put("mysql.url", "jdbc:mysql://localhost:3306/ojt_monitoringdb");
        params.put("mysql.username", "root");
        params.put("mysql.password", "");

        InvocationHandler handler = new InvocationHandler() {
            @Override
            public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
                if (method.getName().equals("getInitParameter")) {
                    String key = (String) args[0];
                    return params.get(key);
                }
                return null;
            }
        };

        return (ServletContext) Proxy.newProxyInstance(
            ServletContext.class.getClassLoader(),
            new Class[] { ServletContext.class },
            handler
        );
    }

    public static void main(String[] args) {
        ServletContext context = createMockContext();
        
        System.out.println("=================================================");
        System.out.println("DIAGNOSTIC TEST: CROSS-DATABASE INTERN ID MAPPING");
        System.out.println("=================================================");

        // Test 1: Map raw ID helper
        System.out.println("\n--- Test 1: mapToDerbyInternId helper parsing ---");
        String[] testIds = { "INT2020-10001", "INT2024-50003", "INT2026-70009", "INT2026-70010", "9", "25" };
        for (String id : testIds) {
            System.out.println("Raw ID: " + id + " -> Mapped Derby ID: " + UserDAO.mapToDerbyInternId(id));
        }

        // Test 2: Fetch all activity submissions (maps MySQL user ID to Derby profile in-memory)
        System.out.println("\n--- Test 2: Fetching All Submissions (getAllSubmissions) ---");
        try {
            List<ActivitySubmission> submissions = UserDAO.getAllSubmissions(context);
            if (submissions != null && !submissions.isEmpty()) {
                System.out.printf("%-15s | %-15s | %-20s | %-30s | %-30s\n", 
                    "Submission ID", "Intern ID", "Intern Name", "Description", "Assigned Office");
                System.out.println("----------------------------------------------------------------------------------------------------------------------");
                int successCount = 0;
                for (ActivitySubmission sub : submissions) {
                    System.out.printf("%-15s | %-15s | %-20s | %-30s | %-30s\n",
                        sub.getSubmissionId(),
                        sub.getUserId(),
                        sub.getInternName(),
                        sub.getDescription().length() > 28 ? sub.getDescription().substring(0, 25) + "..." : sub.getDescription(),
                        sub.getAssignedOffice()
                    );
                    if (!"System Admin Profile".equals(sub.getInternName())) {
                        successCount++;
                    }
                }
                System.out.println("----------------------------------------------------------------------------------------------------------------------");
                System.out.println("Successfully matched " + successCount + " of " + submissions.size() + " submissions to Derby profiles!");
            } else {
                System.out.println("No submissions found or database error.");
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        // Test 3: Fetch individual submissions by mapped or raw ID (getSubmissionsByUserId)
        System.out.println("\n--- Test 3: Fetching Submissions by ID (getSubmissionsByUserId) ---");
        String testInternId = "9"; // Antonio Luna in Derby
        System.out.println("Querying with Derby ID: \"" + testInternId + "\"...");
        try {
            List<ActivitySubmission> subs = UserDAO.getSubmissionsByUserId(testInternId, context);
            System.out.println("Found " + subs.size() + " submissions for intern ID \"" + testInternId + "\":");
            for (ActivitySubmission s : subs) {
                System.out.println("  - " + s.getSubmissionId() + " | " + s.getUserId() + " | " + s.getInternName() + " | " + s.getDescription());
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        String testFormattedId = "INT2026-70009"; // Antonio Luna in MySQL format
        System.out.println("\nQuerying with Formatted ID: \"" + testFormattedId + "\"...");
        try {
            List<ActivitySubmission> subs = UserDAO.getSubmissionsByUserId(testFormattedId, context);
            System.out.println("Found " + subs.size() + " submissions for intern ID \"" + testFormattedId + "\":");
            for (ActivitySubmission s : subs) {
                System.out.println("  - " + s.getSubmissionId() + " | " + s.getUserId() + " | " + s.getInternName() + " | " + s.getDescription());
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
