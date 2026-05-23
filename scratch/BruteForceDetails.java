package scratch;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.List;

public class BruteForceDetails {
    private static final String TARGET1 = "dc80322dd14238969c8766559f9fb8bf650e78654215941d01cd7a39656e41c6";
    private static final String TARGET2 = "b31c2a7be37ef96288fa4086329ccb29d58de967943fe19b5ef5756bdcc79480";

    public static void main(String[] args) throws Exception {
        List<String> list = new ArrayList<>();
        
        // Add basic elements
        String[] firsts = {"andrea", "pauline", "cyprus", "andreapauline", "andreacyprus", "Andrea", "Pauline", "Cyprus", "AndreaPauline", "AndreaCyprus"};
        String[] middles = {"torres", "Torres", ""};
        String[] lasts = {"tan", "Tan"};
        String[] birthdays = {"1007", "1015", "2002", "10072002", "10152002", "10-07-2002", "10-15-2002", "10/07/2002", "10/15/2002", "072002", "152002", "100702", "101502", "October7", "October15", "October07", "October152002", "October072002", "october7", "october15", "october72002", "october152002"};
        String[] specs = {"", "123", "123!", "1!", "!", "@", "#", "12345", "123456", "2026", "2026!"};
        
        for (String f : firsts) {
            for (String m : middles) {
                for (String l : lasts) {
                    String base1 = f + (m.isEmpty() ? "" : m) + l;
                    String base2 = f + (m.isEmpty() ? "" : "." + m) + "." + l;
                    String base3 = f + (m.isEmpty() ? "" : "_" + m) + "_" + l;
                    String base4 = f + l;
                    String base5 = f + "." + l;
                    String base6 = f + "_" + l;
                    
                    String[] bases = {base1, base2, base3, base4, base5, base6};
                    for (String base : bases) {
                        list.add(base);
                        list.add(base.toLowerCase());
                        list.add(base.toUpperCase());
                        
                        for (String spec : specs) {
                            list.add(base + spec);
                            list.add(base.toLowerCase() + spec);
                            list.add(base.toUpperCase() + spec);
                        }
                        for (String bd : birthdays) {
                            list.add(base + bd);
                            list.add(base.toLowerCase() + bd);
                            list.add(base.toUpperCase() + bd);
                            
                            for (String spec : specs) {
                                list.add(base + bd + spec);
                                list.add(base.toLowerCase() + bd + spec);
                                list.add(base.toUpperCase() + bd + spec);
                            }
                        }
                    }
                }
            }
        }
        
        // Add more explicit items
        list.add("9755642038");
        list.add("UST");
        list.add("ust");
        list.add("andreapauline.tan.be@gmail.com");
        list.add("andreacyprus.tan.fe@gmail.com");
        
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        System.out.println("Checking " + list.size() + " detail-based candidates...");
        
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
                System.out.println("FOUND MATCH FOR TARGET 1 (INT2026-70011): " + c);
            }
            if (hex.equals(TARGET2)) {
                System.out.println("FOUND MATCH FOR TARGET 2 (INT2026-70012): " + c);
            }
        }
        System.out.println("Done.");
    }
}
