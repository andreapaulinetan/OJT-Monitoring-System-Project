package util;

import java.util.Set;
import java.util.regex.Pattern;
import java.time.LocalDate;
import java.time.DateTimeException;

/**
 * Utility class for server-side input validation.
 * Provides reusable methods for common validation patterns.
 */
public class InputValidator {

    /** Basic email regex — checks for user@domain.tld structure. */
    private static final Pattern EMAIL_PATTERN =
            Pattern.compile("^[\\w.+%-]+@[\\w.-]+\\.[a-zA-Z]{2,}$");

    private static final Pattern NAME_PATTERN =
            Pattern.compile("^[a-zA-Z\\s.\\-']{2,100}$");

    private static final Pattern UNIVERSITY_PATTERN =
            Pattern.compile("^[a-zA-Z0-9\\s.\\-()']{2,150}$");

    private static final Pattern PHONE_PATTERN =
            Pattern.compile("^[+]?[0-9\\s-]{10,15}$");

    private static final Pattern PASSWORD_PATTERN =
            Pattern.compile("^(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z])(?=.*[@#$%^&+=!\\-_*()]).{8,100}$");

    private static final Pattern SUBMISSION_ID_PATTERN =
            Pattern.compile("^\\d{8}-[a-zA-Z]{2,4}-\\d{4,}$");

    private InputValidator() {
        // Utility class — not instantiable
    }

    /**
     * Checks if a string is null, empty, or blank after trimming.
     *
     * @param value the string to check
     * @return true if the value is null or blank
     */
    public static boolean isNullOrEmpty(String value) {
        return value == null || value.trim().isEmpty();
    }

    /**
     * Checks if a string matches a basic email format.
     *
     * @param email the email string to validate
     * @return true if the email matches the pattern
     */
    public static boolean isValidEmail(String email) {
        if (email == null) return false;
        return EMAIL_PATTERN.matcher(email.trim()).matches();
    }

    /**
     * Checks if a string's trimmed length is within the allowed range.
     *
     * @param value the string to check
     * @param minLength minimum length (inclusive)
     * @param maxLength maximum length (inclusive)
     * @return true if the trimmed length is within [minLength, maxLength]
     */
    public static boolean isValidLength(String value, int minLength, int maxLength) {
        if (value == null) return minLength == 0;
        int len = value.trim().length();
        return len >= minLength && len <= maxLength;
    }

    /**
     * Checks if a value is one of the allowed values (case-insensitive).
     *
     * @param value the string to check
     * @param allowedValues set of allowed values (should be lowercase)
     * @return true if the lowercase value is in the allowed set
     */
    public static boolean isInWhitelist(String value, Set<String> allowedValues) {
        if (value == null) return false;
        return allowedValues.contains(value.trim().toLowerCase());
    }

    /**
     * Attempts to parse a string as an integer.
     *
     * @param value the string to parse
     * @return the parsed integer, or null if parsing fails
     */
    public static Integer parseInteger(String value) {
        if (value == null) return null;
        try {
            return Integer.parseInt(value.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    /**
     * Attempts to parse a string as a double.
     *
     * @param value the string to parse
     * @return the parsed double, or null if parsing fails
     */
    public static Double parseDouble(String value) {
        if (value == null) return null;
        try {
            return Double.parseDouble(value.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    /**
     * Checks if a string can be parsed as an integer within the given range.
     *
     * @param value the string to parse
     * @param min   minimum value (inclusive)
     * @param max   maximum value (inclusive)
     * @return true if the value is a valid integer within [min, max]
     */
    public static boolean isValidIntegerInRange(String value, int min, int max) {
        Integer parsed = parseInteger(value);
        if (parsed == null) return false;
        return parsed >= min && parsed <= max;
    }

    /**
     * Checks if a string can be parsed as a double within the given range.
     *
     * @param value the string to parse
     * @param min   minimum value (inclusive)
     * @param max   maximum value (inclusive)
     * @return true if the value is a valid double within [min, max]
     */
    public static boolean isValidDoubleInRange(String value, double min, double max) {
        Double parsed = parseDouble(value);
        if (parsed == null) return false;
        return parsed >= min && parsed <= max;
    }

    /**
     * Checks if a string is a valid name (letters, spaces, dots, hyphens, single quotes).
     */
    public static boolean isValidName(String name) {
        if (isNullOrEmpty(name)) return false;
        return NAME_PATTERN.matcher(name.trim()).matches();
    }

    /**
     * Checks if a string is a valid university name.
     */
    public static boolean isValidUniversity(String university) {
        if (isNullOrEmpty(university)) return false;
        return UNIVERSITY_PATTERN.matcher(university.trim()).matches();
    }

    /**
     * Checks if a string is a valid phone number.
     */
    public static boolean isValidPhoneNumber(String phone) {
        if (isNullOrEmpty(phone)) return false;
        return PHONE_PATTERN.matcher(phone.trim()).matches();
    }

    /**
     * Checks if a password meets complexity rules.
     */
    public static boolean isValidPassword(String password) {
        if (isNullOrEmpty(password)) return false;
        return PASSWORD_PATTERN.matcher(password).matches();
    }

    /**
     * Checks if a string is a valid submission ID.
     */
    public static boolean isValidSubmissionId(String id) {
        if (isNullOrEmpty(id)) return false;
        return SUBMISSION_ID_PATTERN.matcher(id.trim()).matches();
    }

    /**
     * Validates that the inputs form a logically correct calendar date.
     */
    public static boolean isValidDate(String month, String dayStr, String yearStr) {
        if (isNullOrEmpty(month) || isNullOrEmpty(dayStr) || isNullOrEmpty(yearStr)) {
            return false;
        }
        Integer day = parseInteger(dayStr);
        Integer year = parseInteger(yearStr);
        if (day == null || year == null) return false;
        if (year < 1900 || year > 2100) return false;
        
        int monthVal;
        switch (month.trim().toLowerCase()) {
            case "january": monthVal = 1; break;
            case "february": monthVal = 2; break;
            case "march": monthVal = 3; break;
            case "april": monthVal = 4; break;
            case "may": monthVal = 5; break;
            case "june": monthVal = 6; break;
            case "july": monthVal = 7; break;
            case "august": monthVal = 8; break;
            case "september": monthVal = 9; break;
            case "october": monthVal = 10; break;
            case "november": monthVal = 11; break;
            case "december": monthVal = 12; break;
            default: return false;
        }
        
        try {
            LocalDate.of(year, monthVal, day);
            return true;
        } catch (DateTimeException e) {
            return false;
        }
    }
}

