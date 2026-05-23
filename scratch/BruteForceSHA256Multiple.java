package scratch;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.List;

public class BruteForceSHA256Multiple {
    private static final String HASH1 = "dc80322dd14238969c8766559f9fb8bf650e78654215941d01cd7a39656e41c6";
    private static final String HASH2 = "b31c2a7be37ef96288fa4086329ccb29d58de967943fe19b5ef5756bdcc79480";

    public static void main(String[] args) throws Exception {
        List<String> candidates = new ArrayList<>();
        
        // Generate words
        String[] bases = {
            "andrea", "pauline", "tan", "cyprus", "torres", "be", "fe", "uiux", "intern", "admin", "ojt",
            "password", "pass", "student", "user", "cruz", "juan", "maria", "clara", "jose", "rizal",
            "andres", "bonifacio", "emilio", "aguinaldo", "apolinario", "mabini", "melchora", "aquino",
            "gabriela", "silang", "antonio", "luna", "marcelo", "delpilar", "juan", "luna", "gregorio",
            "emilio", "jacinto", "mariano", "gomez", "jose", "burgos", "jacinto", "zamora", "lapu", "lapu",
            "francisco", "baltazar", "graciano", "jaena", "diego", "teresa", "magbanua", "felipe", "agoncillo",
            "gliceria", "villavicencio", "librada", "avelino", "delfina", "herbosa"
        };
        
        String[] capitals = new String[bases.length];
        for (int i = 0; i < bases.length; i++) {
            capitals[i] = bases[i].substring(0, 1).toUpperCase() + bases[i].substring(1);
        }
        
        String[] suffixes = {
            "", "1", "2", "3", "12", "123", "1234", "12345", "123456", "12345678", "2026", "2020", "2024", "2025", "70011", "70012",
            "!", "@", "#", "!123", "123!", "12345!", "1!", "2!", "3!"
        };

        // Combine bases and suffixes with various capitalizations
        for (String base : bases) {
            for (String suf : suffixes) {
                candidates.add(base + suf);
                candidates.add(base.toUpperCase() + suf);
                String cap = base.substring(0, 1).toUpperCase() + base.substring(1);
                candidates.add(cap + suf);
            }
        }
        
        // Add double-word combinations
        String[] doubleBases = {
            "andreapauline", "andreacyprus", "andreapaulinetan", "andreacyprustan", "andreatan",
            "juan.cruz", "maria.clara", "jose.rizal", "andres.bonifacio", "emilio.aguinaldo",
            "apolinario.mabini", "melchora.aquino", "gabriela.silang", "antonio.luna",
            "marcelo.delpilar", "juan.luna", "gregorio.delpilar", "emilio.jacinto",
            "mariano.gomez", "jose.burgos", "jacinto.zamora", "lapu.lapu", "francisco.baltazar",
            "graciano.jaena", "diego.silang", "teresa.magbanua", "felipe.agoncillo",
            "gliceria.villavicencio", "librada.avelino", "delfina.herbosa"
        };
        
        for (String db : doubleBases) {
            for (String suf : suffixes) {
                candidates.add(db + suf);
                candidates.add(db.toLowerCase() + suf);
                candidates.add(db.toUpperCase() + suf);
                // capitalize first letters
                String[] parts = db.split("\\.");
                if (parts.length == 2) {
                    String capDb = parts[0].substring(0,1).toUpperCase() + parts[0].substring(1) + "." + 
                                   parts[1].substring(0,1).toUpperCase() + parts[1].substring(1);
                    candidates.add(capDb + suf);
                    
                    String joined = parts[0] + parts[1];
                    candidates.add(joined + suf);
                    candidates.add(joined.toLowerCase() + suf);
                    candidates.add(joined.toUpperCase() + suf);
                    String capJoined = parts[0].substring(0,1).toUpperCase() + parts[0].substring(1) + 
                                       parts[1].substring(0,1).toUpperCase() + parts[1].substring(1);
                    candidates.add(capJoined + suf);
                }
            }
        }

        // Add some explicit ones
        candidates.add("andreapauline.tan.be@gmail.com");
        candidates.add("andreacyprus.tan.fe@gmail.com");
        candidates.add("andreapauline.tan");
        candidates.add("andreacyprus.tan");

        MessageDigest md = MessageDigest.getInstance("SHA-256");
        boolean found1 = false;
        boolean found2 = false;

        System.out.println("Checking " + candidates.size() + " candidates...");
        for (String c : candidates) {
            byte[] hash = md.digest(c.getBytes(StandardCharsets.UTF_8));
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }
            String hex = hexString.toString();
            if (hex.equals(HASH1)) {
                System.out.println("FOUND MATCH FOR HASH 1 (INT2026-70011): " + c);
                found1 = true;
            }
            if (hex.equals(HASH2)) {
                System.out.println("FOUND MATCH FOR HASH 2 (INT2026-70012): " + c);
                found2 = true;
            }
            if (found1 && found2) {
                break;
            }
        }
        
        if (!found1) System.out.println("Hash 1 not found in local candidates.");
        if (!found2) System.out.println("Hash 2 not found in local candidates.");
    }
}
