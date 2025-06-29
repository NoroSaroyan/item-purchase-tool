@IsTest
private class PurchaseLineServiceTest {

    // Helper method to create test Purchase
    private static Purchase__c createTestPurchase() {
        // Create test account for ClientId__c lookup
        Account testAccount = new Account(
            Name = 'Test Client Account',
            Type = 'Customer'
        );
        insert testAccount;
        
        Purchase__c p = new Purchase__c(
            Name='Test Purchase',
            ClientId__c = testAccount.Id
        );
        insert p;
        return p;
    }

    // Helper method to create test Item
    private static Item__c createTestItem() {
        Item__c i = new Item__c(
            Name='Test Item',
            Description__c = 'Test Description',
            Price__c = 10,
            Type__c = 'Hardware',
            Family__c = 'Electronics'
        );
        insert i;
        return i;
    }

    // Stub the external PurchaseService.recalcPurchaseTotal method
    @TestSetup
    static void setup() {
        // Can't mock static method directly, so either leave it or create a way to bypass in real code
        // For now we rely on no exception thrown when called
    }

    @IsTest
    static void testGetLinesByPurchase_valid() {
        Purchase__c p = createTestPurchase();
        Item__c i = createTestItem();

        Purchase_Line__c line = new Purchase_Line__c(
            PurchaseId__c = p.Id,
            ItemId__c = i.Id,
            Amount__c = 2,
            UnitCost__c = 10
        );
        insert line;

        Test.startTest();
        List<Purchase_Line__c> lines = PurchaseLineService.getLinesByPurchase(p.Id);
        Test.stopTest();

        System.assertNotEquals(null, lines);
        System.assertEquals(1, lines.size());
        System.assertEquals(line.Id, lines[0].Id);
    }

    @IsTest
    static void testGetLinesByPurchase_nullId_throws() {
        try {
            PurchaseLineService.getLinesByPurchase(null);
            System.assert(false, 'Expected exception not thrown');
        } catch (Exception e) {
            // AuraHandledException may be wrapped in test context
            System.assert(e.getMessage().contains('Purchase Id') || e.getMessage().contains('Script-thrown exception'), 
                         'Unexpected error message: ' + e.getMessage());
        }
    }

    @IsTest
    static void testSaveLine_valid() {
        Purchase__c p = createTestPurchase();
        Item__c i = createTestItem();

        Purchase_Line__c line = new Purchase_Line__c(
            PurchaseId__c = p.Id,
            ItemId__c = i.Id,
            Amount__c = 3,
            UnitCost__c = 15
        );

        Test.startTest();
        Purchase_Line__c savedLine = PurchaseLineService.saveLine(line);
        Test.stopTest();

        System.assertNotEquals(null, savedLine.Id, 'Line should be saved and have Id');
        System.assertEquals(3, savedLine.Amount__c);
        System.assertEquals(15, savedLine.UnitCost__c);
    }

    @IsTest
    static void testSaveLine_invalid_missingFields_throws() {
        Purchase_Line__c line = new Purchase_Line__c(); // no fields set
        try {
            PurchaseLineService.saveLine(line);
            System.assert(false, 'Expected validation exception');
        } catch (Exception e) {
            // AuraHandledException may be wrapped in test context, so we just check that an exception was thrown
            System.assert(e.getMessage().contains('Purchase reference') || e.getMessage().contains('Item reference') || 
                         e.getMessage().contains('Script-thrown exception'), 
                         'Unexpected error message: ' + e.getMessage());
        }
    }

    @IsTest
    static void testBatchSaveLines_valid() {
        Purchase__c p = createTestPurchase();
        Item__c i1 = createTestItem();
        Item__c i2 = createTestItem();

        List<Purchase_Line__c> lines = new List<Purchase_Line__c>{
            new Purchase_Line__c(PurchaseId__c = p.Id, ItemId__c = i1.Id, Amount__c=1, UnitCost__c=5),
            new Purchase_Line__c(PurchaseId__c = p.Id, ItemId__c = i2.Id, Amount__c=2, UnitCost__c=10)
        };

        Test.startTest();
        List<Purchase_Line__c> savedLines = PurchaseLineService.batchSaveLines(lines);
        Test.stopTest();

        System.assertEquals(2, savedLines.size());
        System.assertNotEquals(null, savedLines[0].Id);
        System.assertNotEquals(null, savedLines[1].Id);
    }

    @IsTest
    static void testBatchSaveLines_emptyList_throws() {
        try {
            PurchaseLineService.batchSaveLines(new List<Purchase_Line__c>());
            System.assert(false, 'Expected exception for empty list');
        } catch (Exception e) {
            // AuraHandledException may be wrapped in test context
            System.assert(e.getMessage().contains('cannot be empty') || e.getMessage().contains('Script-thrown exception'), 
                         'Unexpected error message: ' + e.getMessage());
        }
    }

    @IsTest
    static void testBatchSaveLines_invalidLine_throws() {
        Purchase__c p = createTestPurchase();
        List<Purchase_Line__c> lines = new List<Purchase_Line__c>{
            new Purchase_Line__c(PurchaseId__c = p.Id, ItemId__c = null, Amount__c=1, UnitCost__c=5)
        };
        try {
            PurchaseLineService.batchSaveLines(lines);
            System.assert(false, 'Expected validation exception');
        } catch (Exception e) {
            // AuraHandledException may be wrapped in test context
            System.assert(e.getMessage().contains('Item reference') || e.getMessage().contains('Script-thrown exception'), 
                         'Unexpected error message: ' + e.getMessage());
        }
    }

    @IsTest
    static void testDeleteLines_valid() {
        Purchase__c p = createTestPurchase();
        Item__c i = createTestItem();
        Purchase_Line__c line = new Purchase_Line__c(
            PurchaseId__c = p.Id,
            ItemId__c = i.Id,
            Amount__c = 1,
            UnitCost__c = 1
        );
        insert line;

        List<Id> idsToDelete = new List<Id>{ line.Id };

        Test.startTest();
        PurchaseLineService.deleteLines(idsToDelete);
        Test.stopTest();

        System.assertEquals(0, [SELECT count() FROM Purchase_Line__c WHERE Id = :line.Id]);
    }

    @IsTest
    static void testDeleteLines_emptyList_throws() {
        try {
            PurchaseLineService.deleteLines(new List<Id>());
            System.assert(false, 'Expected exception for empty list');
        } catch (Exception e) {
            // AuraHandledException may be wrapped in test context
            System.assert(e.getMessage().contains('No purchase lines') || e.getMessage().contains('Script-thrown exception'), 
                         'Unexpected error message: ' + e.getMessage());
        }
    }
}
