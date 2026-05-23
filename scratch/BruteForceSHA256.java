package scratch;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

public class BruteForceSHA256 {
    public static void main(String[] args) throws Exception {
        String target = "dc80322dd14238969c8766559f9fb8bf650e78654215941d01cd7a39656e41c6";
        String[] candidates = {
            "pass123", "password", "password123", "admin123", "12345678", "123456", "12345",
            "andreapauline", "tan", "andreapauline.tan", "andreapaulinetan", "be", "intern",
            "Ojt123!", "Ojt123", "Ojt12345!", "Ojt12345", "Ojtpassword1!", "Ojtpassword!",
            "Password123!", "Password123"
        };
        
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        for (String c : candidates) {
            byte[] hash = md.digest(c.getBytes(StandardCharsets.UTF_8));
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }
            if (hexString.toString().equals(target)) {
                System.out.println("FOUND MATCH: " + c);
                return;
            }
        }
        System.out.println("No match found in candidates list.");
    }
}
