package util;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Base64;
import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;

/**
 * Utility class for secure password encryption and decryption using AES.
 * 
 * Passwords are stored in the database with the format: enc:Base64_Ciphertext
 * 
 * A legacy plaintext and SHA-256 verification method is also provided for
 * compatibility and migrating existing database passwords.
 */
public class CryptoUtil {

    private static final String ALGORITHM = "AES";
    private static final String TRANSFORMATION = "AES/ECB/PKCS5Padding";
    private static final String SECRET_KEY = "1234567890123456"; // 16-byte (128-bit) secret key

    private CryptoUtil() {
        // Utility class — not instantiable
    }

    /**
     * Encrypts a string using AES.
     *
     * @param plaintext the unencrypted text
     * @return the Base64-encoded encrypted text
     */
    public static String encrypt(String plaintext) {
        if (plaintext == null) {
            return null;
        }
        try {
            SecretKeySpec keySpec = new SecretKeySpec(SECRET_KEY.getBytes(StandardCharsets.UTF_8), ALGORITHM);
            Cipher cipher = Cipher.getInstance(TRANSFORMATION);
            cipher.init(Cipher.ENCRYPT_MODE, keySpec);
            byte[] encryptedBytes = cipher.doFinal(plaintext.getBytes(StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(encryptedBytes);
        } catch (Exception e) {
            throw new RuntimeException("AES encryption failed", e);
        }
    }

    /**
     * Decrypts a Base64-encoded AES ciphertext.
     *
     * @param ciphertext the Base64-encoded encrypted text
     * @return the decrypted plaintext
     */
    public static String decrypt(String ciphertext) {
        if (ciphertext == null) {
            return null;
        }
        try {
            SecretKeySpec keySpec = new SecretKeySpec(SECRET_KEY.getBytes(StandardCharsets.UTF_8), ALGORITHM);
            Cipher cipher = Cipher.getInstance(TRANSFORMATION);
            cipher.init(Cipher.DECRYPT_MODE, keySpec);
            byte[] decryptedBytes = cipher.doFinal(Base64.getDecoder().decode(ciphertext));
            return new String(decryptedBytes, StandardCharsets.UTF_8);
        } catch (Exception e) {
            throw new RuntimeException("AES decryption failed", e);
        }
    }

    /**
     * Encrypts a password and returns it with the "enc:" prefix.
     * Keeps the original name to match the application's servlet calls.
     *
     * @param password the plaintext password
     * @return the encrypted password prefixed with "enc:"
     */
    public static String hashPassword(String password) {
        if (password == null) {
            return null;
        }
        return "enc:" + encrypt(password);
    }

    /**
     * Verifies a plaintext password against a stored password.
     * Decrypts the stored password if it starts with "enc:".
     *
     * @param password       the plaintext password to verify
     * @param storedPassword the stored password (either encrypted with "enc:" prefix, legacy SHA-256, or plaintext)
     * @return true if the password matches
     */
    public static boolean verifyPassword(String password, String storedPassword) {
        if (password == null || storedPassword == null) {
            return false;
        }

        // If the password starts with "enc:", it is encrypted with AES
        if (storedPassword.startsWith("enc:")) {
            try {
                String decrypted = decrypt(storedPassword.substring(4));
                return decrypted.equals(password);
            } catch (Exception e) {
                return false;
            }
        }

        // Support legacy SHA-256 hashes (64 hex chars) or plaintext passwords
        if (storedPassword.length() == 64 && !storedPassword.contains(":")) {
            return verifyLegacySHA256(password, storedPassword);
        }

        // Support legacy PBKDF2 hashes (contains iterations:salt:hash)
        if (storedPassword.contains(":")) {
            return verifyLegacyPBKDF2(password, storedPassword);
        }

        // Direct plaintext comparison
        return storedPassword.equals(password);
    }

    /**
     * Verifies a password against a legacy unsalted SHA-256 hex hash.
     *
     * @param password   the plaintext password
     * @param legacyHash the SHA-256 hex hash (64 chars)
     * @return true if the password matches
     */
    private static boolean verifyLegacySHA256(String password, String legacyHash) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest(password.getBytes(StandardCharsets.UTF_8));
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }
            return constantTimeEquals(
                hexString.toString().getBytes(StandardCharsets.UTF_8),
                legacyHash.getBytes(StandardCharsets.UTF_8)
            );
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256 algorithm not available", e);
        }
    }

    /**
     * Verifies a password against legacy PBKDF2 hash (iterations:salt:hash) format.
     */
    private static boolean verifyLegacyPBKDF2(String password, String storedHash) {
        String[] parts = storedHash.split(":");
        if (parts.length != 3) {
            return false;
        }
        try {
            int iterations = Integer.parseInt(parts[0]);
            byte[] salt = Base64.getDecoder().decode(parts[1]);
            byte[] expectedHash = Base64.getDecoder().decode(parts[2]);
            
            // PBKDF2 parameters from the old implementation
            char[] passwordChars = password.toCharArray();
            javax.crypto.spec.PBEKeySpec spec = new javax.crypto.spec.PBEKeySpec(passwordChars, salt, iterations, 256);
            javax.crypto.SecretKeyFactory factory = javax.crypto.SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256");
            byte[] actualHash = factory.generateSecret(spec).getEncoded();

            return constantTimeEquals(expectedHash, actualHash);
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Constant-time byte array comparison to prevent timing attacks.
     */
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