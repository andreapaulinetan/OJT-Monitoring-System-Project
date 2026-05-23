package scratch;

import java.util.Base64;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;
import java.util.HashSet;
import java.util.Set;

public class CrackPBKDF2 {
    private static final String TARGET = "65536:VTMKv9e6gRGvSNwhP9z8eg==:VH65JJVUmRmyb+IkM2ZsP2Eh7+4wLmquAEFBQXs+ezc=";

    public static void main(String[] args) throws Exception {
        String[] parts = TARGET.split(":");
        int iterations = Integer.parseInt(parts[0]);
        byte[] salt = Base64.getDecoder().decode(parts[1]);
        byte[] expectedHash = Base64.getDecoder().decode(parts[2]);

        Set<String> candidates = new HashSet<>();
        String[] nameParts = {
            "andrea", "pauline", "tan", "cyprus", "torres", "be", "fe", "uiux", "intern", "admin", "ojt",
            "password", "pass", "student", "user", "cruz", "juan", "maria", "clara", "jose", "rizal"
        };
        for (String w : nameParts) {
            candidates.add(w.toLowerCase());
            candidates.add(w.toUpperCase());
            candidates.add(w.substring(0, 1).toUpperCase() + w.substring(1).toLowerCase());
        }

        Set<String> combined = new HashSet<>();
        for (String w1 : candidates) {
            for (String w2 : candidates) {
                combined.add(w1 + w2);
                combined.add(w1 + "." + w2);
                combined.add(w1 + "-" + w2);
                combined.add(w1 + "_" + w2);
                combined.add(w1 + " " + w2);
            }
        }

        String[] suffixes = {
            "", "1", "2", "3", "12", "123", "1234", "12345", "123456", "12345678", "2026", "2020", "2024", "2025", "70011", "70012",
            "!", "@", "#", "!123", "123!", "12345!", "1!", "2!", "3!", "2026!", "2026-70011", "2026-70011!", "70011!", "70012!",
            "1234567890", "1234567890!", "password", "password123", "pass123", "pass123!"
        };

        Set<String> testList = new HashSet<>();
        for (String base : candidates) {
            for (String suf : suffixes) {
                testList.add(base + suf);
                testList.add(suf + base);
            }
        }
        for (String base : combined) {
            for (String suf : suffixes) {
                testList.add(base + suf);
                testList.add(suf + base);
            }
        }

        System.out.println("Checking " + testList.size() + " candidates for PBKDF2...");
        SecretKeyFactory factory = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256");
        for (String c : testList) {
            PBEKeySpec spec = new PBEKeySpec(c.toCharArray(), salt, iterations, 256);
            byte[] actualHash = factory.generateSecret(spec).getEncoded();
            if (constantTimeEquals(expectedHash, actualHash)) {
                System.out.println("FOUND MATCH FOR PBKDF2: " + c);
                return;
            }
        }
        System.out.println("No match found for PBKDF2.");
    }

    private static boolean constantTimeEquals(byte[] a, byte[] b) {
        if (a.length != b.length) {
            return false;
        }
        int result = 0;
        for (int i = 0; i < a.length; i++) {
            result |= a[i] ^ b[i];
        }
        return result == 0;
    }
}
