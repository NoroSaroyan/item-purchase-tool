/**
 * @description
 * Utility class for the Purchase Tool project. Centralized methods for:
 * - Input validation
 * - Standardized exception handling
 * - Formatting
 */
public with sharing class PurchaseToolUtils {

    /**
     * @description
     * Throws a standardized AuraHandledException with a unified prefix.
     * 
     * @param message The custom error message to include
     */
    public static void throwException(String message) {
        throw new AuraHandledException('Purchase Tool Error: ' + message);
    }

    /**
     * @description
     * Ensures a non-null and non-empty string value.
     * 
     * @param value The string to check
     * @param fieldName Name of the field for the error message
     */
    public static void requireNonEmpty(String value, String fieldName) {
        if (value == null || value.trim().isEmpty()) {
            throwException(fieldName + ' is required and cannot be empty.');
        }
    }

    /**
     * @description
     * Ensures a required Id value (lookup field) is not null.
     * 
     * @param value The Id to validate
     * @param fieldName Name of the field for the error message
     */
    public static void requireNonNull(Id value, String fieldName) {
        if (value == null) {
            throwException(fieldName + ' is required.');
        }
    }

    /**
     * @description
     * Ensures a Decimal field has a positive value.
     * 
     * @param value The Decimal value
     * @param fieldName Field name for error message
     */
    public static void requirePositive(Decimal value, String fieldName) {
        if (value == null || value <= 0) {
            throwException(fieldName + ' must be greater than zero.');
        }
    }

    /**
     * @description
     * Ensures an Integer field has a positive value.
     * 
     * @param value The Integer value
     * @param fieldName Field name for error message
     */
    public static void requirePositive(Integer value, String fieldName) {
        if (value == null || value <= 0) {
            throwException(fieldName + ' must be greater than zero.');
        }
    }

    /**
     * @description
     * Formats a Decimal amount as a currency string.
     * 
     * @param amount The amount to format
     * @return Formatted currency string (e.g., "$123.45")
     */
    public static String formatCurrency(Decimal amount) {
        if (amount == null) return '';
        return '$' + String.valueOf(amount.setScale(2));
    }
}
