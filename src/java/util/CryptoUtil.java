package util;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.security.spec.InvalidKeySpecException;
import java.util.Base64;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;

/**
 * Utility class for secure password hashing using PBKDF2WithHmacSHA256.
 * 
 * Passwords are stored in the format:  iterations:salt:hash
 * where salt and hash are Base64-encoded.
 * 
 * A legacy SHA-256 verification method is also provided for migrating
 * existing password hashes.
 */
public class CryptoUtil {

    private static final int ITERATIONS = 65536;
    private static final int KEY_LENGTH = 256;       // bits
    private static final int SALT_LENGTH = 16;       // bytes
    private static final String ALGORITHM = "PBKDF2WithHmacSHA256";
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    private CryptoUtil() {
        // Utility class — not instantiable
    }

    /**
     * Hashes a plaintext password using PBKDF2 with a random salt.
     *
     * @param password the plaintext password
     * @return the hashed password in "iterations:salt:hash" format
     */
    public static String hashPassword(String password) {
        byte[] salt = new byte[SALT_LENGTH];
        SECURE_RANDOM.nextBytes(salt);

        byte[] hash = pbkdf2(password.toCharArray(), salt, ITERATIONS, KEY_LENGTH);

        String saltBase64 = Base64.getEncoder().encodeToString(salt);
        String hashBase64 = Base64.getEncoder().encodeToString(hash);

        return ITERATIONS + ":" + saltBase64 + ":" + hashBase64;
    }

    /**
     * Verifies a plaintext password against a stored PBKDF2 hash.
     *
     * @param password   the plaintext password to verify
     * @param storedHash the stored hash in "iterations:salt:hash" format
     * @return true if the password matches the stored hash
     */
    public static boolean verifyPassword(String password, String storedHash) {
        if (password == null || storedHash == null) {
            return false;
        }

        // Support legacy SHA-256 hashes (64 hex chars, no colons) or plaintext passwords
        if (!storedHash.contains(":")) {
            if (storedHash.length() == 64 && verifyLegacySHA256(password, storedHash)) {
                return true;
            }
            return storedHash.equals(password);
        }

        String[] parts = storedHash.split(":");
        if (parts.length != 3) {
            return false;
        }

        try {
            int iterations = Integer.parseInt(parts[0]);
            byte[] salt = Base64.getDecoder().decode(parts[1]);
            byte[] expectedHash = Base64.getDecoder().decode(parts[2]);
            byte[] actualHash = pbkdf2(password.toCharArray(), salt, iterations, KEY_LENGTH);

            return constantTimeEquals(expectedHash, actualHash);
        } catch (IllegalArgumentException e) {
            return false;
        }
    }

    /**
     * Verifies a password against a legacy unsalted SHA-256 hex hash.
     * Used during migration from the old hashing scheme.
     *
     * @param password   the plaintext password
     * @param legacyHash the SHA-256 hex hash (64 chars)
     * @return true if the password matches
     */
    public static boolean verifyLegacySHA256(String password, String legacyHash) {
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
     * Performs PBKDF2 key derivation.
     */
    private static byte[] pbkdf2(char[] password, byte[] salt, int iterations, int keyLength) {
        try {
            PBEKeySpec spec = new PBEKeySpec(password, salt, iterations, keyLength);
            SecretKeyFactory factory = SecretKeyFactory.getInstance(ALGORITHM);
            return factory.generateSecret(spec).getEncoded();
        } catch (NoSuchAlgorithmException | InvalidKeySpecException e) {
            throw new RuntimeException("PBKDF2 hashing failed", e);
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