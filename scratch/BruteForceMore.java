package scratch;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.List;

public class BruteForceMore {
    private static final String TARGET1 = "dc80322dd14238969c8766559f9fb8bf650e78654215941d01cd7a39656e41c6";
    private static final String TARGET2 = "b31c2a7be37ef96288fa4086329ccb29d58de967943fe19b5ef5756bdcc79480";

    public static void main(String[] args) throws Exception {
        List<String> list = new ArrayList<>();
        
        String[] templates = {
            "UST-9755642038",
            "UST-70011",
            "UST-70012",
            "OJT-70011",
            "OJT-70012",
            "OJT2026-70011",
            "OJT2026-70012",
            "INT2026-70011",
            "INT2026-70012",
            "70011",
            "70012",
            "2026-70011",
            "2026-70012",
            "October 7, 2002",
            "October 15, 2002",
            "October 7 2002",
            "October 15 2002",
            "10/7/2002",
            "10/15/2002",
            "10-7-2002",
            "10-15-2002",
            "10/07/2002",
            "10/15/2002",
            "10-07-2002",
            "10-15-2002",
            "October072002",
            "October152002",
            "andreapauline",
            "andreacyprus",
            "andreapaulinetan",
            "andreacyprustan",
            "andreapauline.tan",
            "andreacyprus.tan",
            "andreapauline_tan",
            "andreacyprus_tan",
            "9755642038",
            "09755642038",
            "+639755642038"
        };
        
        for (String t : templates) {
            list.add(t);
            list.add(t.toLowerCase());
            list.add(t.toUpperCase());
        }
        
        // Let's add combinations of UST, OJT, Tan, Torres, Andrea, Pauline, Cyprus, 2002, 2026, 70011, 70012, 9755642038
        String[] parts = {
            "UST", "OJT", "Tan", "Torres", "Andrea", "Pauline", "Cyprus", "2002", "2026", "70011", "70012", "9755642038",
            "ust", "ojt", "tan", "torres", "andrea", "pauline", "cyprus", "pass123", "pass", "password"
        };
        
        for (String p1 : parts) {
            for (String p2 : parts) {
                list.add(p1 + p2);
                list.add(p1 + "-" + p2);
                list.add(p1 + "_" + p2);
                list.add(p1 + "." + p2);
                list.add(p1 + " " + p2);
                
                for (String p3 : parts) {
                    list.add(p1 + p2 + p3);
                    list.add(p1 + "-" + p2 + "-" + p3);
                    list.add(p1 + "_" + p2 + "_" + p3);
                    list.add(p1 + "." + p2 + "." + p3);
                }
            }
        }
        
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        System.out.println("Checking " + list.size() + " candidates...");
        for (String c : list) {
            byte[] hashBytes = md.digest(c.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : hashBytes) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) sb.append('0');
                sb.append(hex);
            }
            String hex = sb.toString();
            if (hex.equals(TARGET1)) {
                System.out.println("FOUND MATCH FOR TARGET 1: " + c);
            }
            if (hex.equals(TARGET2)) {
                System.out.println("FOUND MATCH FOR TARGET 2: " + c);
            }
        }
        System.out.println("Done.");
    }
}
