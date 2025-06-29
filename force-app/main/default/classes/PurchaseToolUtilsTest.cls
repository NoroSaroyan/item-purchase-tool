@IsTest
private class PurchaseToolUtilsTest {

    @IsTest
    static void testThrowException() {
        try {
            PurchaseToolUtils.throwException('test error');
            System.assert(false, 'Exception expected');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().startsWith('Purchase Tool Error:'));
        }
    }

    @IsTest
    static void testRequireNonEmpty() {
        // Throws on null or empty string
        for (String val : new String[]{null, '', '  '}) {
            try {
                PurchaseToolUtils.requireNonEmpty(val, 'Field');
                System.assert(false, 'Exception expected');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('Field is required'));
            }
        }
        // Does not throw on valid string
        PurchaseToolUtils.requireNonEmpty('valid', 'Field');
    }

    @IsTest
    static void testRequireNonNull() {
        try {
            PurchaseToolUtils.requireNonNull(null, 'IdField');
            System.assert(false, 'Exception expected');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('IdField is required'));
        }

        // Does not throw if not null
        PurchaseToolUtils.requireNonNull(UserInfo.getUserId(), 'IdField');
    }

    @IsTest
    static void testRequirePositiveDecimal() {
        for (Decimal val : new Decimal[]{null, 0, -1}) {
            try {
                PurchaseToolUtils.requirePositive(val, 'DecField');
                System.assert(false, 'Exception expected');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('DecField must be greater than zero'));
            }
        }
        PurchaseToolUtils.requirePositive(0.01, 'DecField');
    }

    @IsTest
    static void testRequirePositiveInteger() {
        for (Integer val : new Integer[]{null, 0, -1}) {
            try {
                PurchaseToolUtils.requirePositive(val, 'IntField');
                System.assert(false, 'Exception expected');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('IntField must be greater than zero'));
            }
        }
        PurchaseToolUtils.requirePositive(1, 'IntField');
    }

    @IsTest
    static void testFormatCurrency() {
        System.assertEquals('$123.45', PurchaseToolUtils.formatCurrency(123.45));
        System.assertEquals('$123.00', PurchaseToolUtils.formatCurrency(123));
        System.assertEquals('', PurchaseToolUtils.formatCurrency(null));
    }
}
