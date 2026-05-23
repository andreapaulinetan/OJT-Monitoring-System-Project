package scratch;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

public class TestHash {
    public static void main(String[] args) throws Exception {
        String target1 = "dc80322dd14238969c8766559f9fb8bf650e78654215941d01cd7a39656e41c6";
        String target2 = "b31c2a7be37ef96288fa4086329ccb29d58de967943fe19b5ef5756bdcc79480";
        
        String[] candidates = {
            "pass123",
            "pass123!",
            "pass1234",
            "password",
            "password123",
            "admin123",
            "andreapauline",
            "andreapaulinetan",
            "andreapauline.tan",
            "andreacyprus",
            "andreacyprustan",
            "andreacyprus.tan",
            "tan",
            "torres",
            "Andrea",
            "Pauline",
            "AndreaPauline",
            "AndreaPaulineTan",
            "AndreaPaulineTorresTan",
            "AndreaCyprus",
            "AndreaCyprusTan",
            "AndreaCyprusTorresTan"
        };
        
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        for (String c : candidates) {
            byte[] hash = md.digest(c.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) sb.append('0');
                sb.append(hex);
            }
            String hex = sb.toString();
            if (hex.equals(target1)) {
                System.out.println("MATCH FOR TARGET 1 (INT2026-70011): " + c);
            }
            if (hex.equals(target2)) {
                System.out.println("MATCH FOR TARGET 2 (INT2026-70012): " + c);
            }
        }
    }
}
