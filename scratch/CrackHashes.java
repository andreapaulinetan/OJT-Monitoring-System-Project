package scratch;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HashSet;
import java.util.Set;

public class CrackHashes {
    private static final String TARGET1 = "dc80322dd14238969c8766559f9fb8bf650e78654215941d01cd7a39656e41c6";
    private static final String TARGET2 = "b31c2a7be37ef96288fa4086329ccb29d58de967943fe19b5ef5756bdcc79480";

    public static void main(String[] args) throws Exception {
        Set<String> words = new HashSet<>();
        
        // Add name parts
        String[] nameParts = {
            "andrea", "pauline", "tan", "cyprus", "torres", "be", "fe", "uiux", "intern", "admin", "ojt",
            "password", "pass", "student", "user", "cruz", "juan", "maria", "clara", "jose", "rizal",
            "andres", "bonifacio", "emilio", "aguinaldo", "apolinario", "mabini", "melchora", "aquino",
            "gabriela", "silang", "antonio", "luna", "marcelo", "delpilar", "juan", "luna", "gregorio",
            "emilio", "jacinto", "mariano", "gomez", "jose", "burgos", "jacinto", "zamora", "lapu", "lapu",
            "francisco", "baltazar", "graciano", "jaena", "diego", "teresa", "magbanua", "felipe", "agoncillo",
            "gliceria", "villavicencio", "librada", "avelino", "delfina", "herbosa"
        };
        
        for (String w : nameParts) {
            words.add(w.toLowerCase());
            words.add(w.toUpperCase());
            words.add(w.substring(0, 1).toUpperCase() + w.substring(1).toLowerCase());
        }

        // Combinations of 2 words
        Set<String> combined = new HashSet<>();
        for (String w1 : words) {
            for (String w2 : words) {
                combined.add(w1 + w2);
                combined.add(w1 + "." + w2);
                combined.add(w1 + "-" + w2);
                combined.add(w1 + "_" + w2);
                combined.add(w1 + " " + w2);
            }
        }
        
        // Combinations of 3 words
        Set<String> triple = new HashSet<>();
        // Only do common ones to save memory
        String[] select1 = {"andrea", "Andrea"};
        String[] select2 = {"pauline", "Pauline"};
        String[] select3 = {"tan", "Tan"};
        for (String s1 : select1) {
            for (String s2 : select2) {
                for (String s3 : select3) {
                    triple.add(s1 + s2 + s3);
                    triple.add(s1 + "." + s2 + "." + s3);
                    triple.add(s1 + "-" + s2 + "-" + s3);
                    triple.add(s1 + " " + s2 + " " + s3);
                }
            }
        }
        
        Set<String> allBases = new HashSet<>();
        allBases.addAll(words);
        allBases.addAll(combined);
        allBases.addAll(triple);
        
        // Add prefixes/suffixes
        String[] suffixes = {
            "", "1", "2", "3", "12", "123", "1234", "12345", "123456", "12345678", "2026", "2020", "2024", "2025", "70011", "70012",
            "!", "@", "#", "!123", "123!", "12345!", "1!", "2!", "3!", "2026!", "2026-70011", "2026-70011!", "70011!", "70012!",
            "1234567890", "1234567890!", "password", "password123", "pass123", "pass123!"
        };
        
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        System.out.println("Starting hash checks...");
        long count = 0;
        
        // Check simple candidates first
        for (String base : allBases) {
            for (String suf : suffixes) {
                String candidate = base + suf;
                check(candidate, md);
                count++;
                
                String candidate2 = suf + base;
                check(candidate2, md);
                count++;
            }
        }
        
        System.out.println("Checked " + count + " candidates.");
    }
    
    private static void check(String candidate, MessageDigest md) {
        byte[] hashBytes = md.digest(candidate.getBytes(StandardCharsets.UTF_8));
        StringBuilder sb = new StringBuilder();
        for (byte b : hashBytes) {
            String hex = Integer.toHexString(0xff & b);
            if (hex.length() == 1) sb.append('0');
            sb.append(hex);
        }
        String hex = sb.toString();
        if (hex.equals(TARGET1)) {
            System.out.println("FOUND MATCH FOR TARGET 1 (INT2026-70011): " + candidate);
        }
        if (hex.equals(TARGET2)) {
            System.out.println("FOUND MATCH FOR TARGET 2 (INT2026-70012): " + candidate);
        }
    }
}
