@IsTest
private class PurchaseLineServiceTest {

    // Helper method to create test Purchase
    private static Purchase__c createTestPurchase() {
        Purchase__c p = new Purchase__c(Name='Test Purchase');
        insert p;
        return p;
    }

    // Helper method to create test Item
    private static Item__c createTestItem() {
        Item__c i = new Item__c(Name='Test Item');
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

        PurchaseLine__c line = new PurchaseLine__c(
            PurchaseId__c = p.Id,
            ItemId__c = i.Id,
            Amount__c = 2,
            UnitCost__c = 10
        );
        insert line;

        Test.startTest();
        List<PurchaseLine__c> lines = PurchaseLineService.getLinesByPurchase(p.Id);
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
            System.assert(e.getMessage().contains('Purchase Id'), 'Unexpected error message: ' + e.getMessage());
        }
    }

    @IsTest
    static void testSaveLine_valid() {
        Purchase__c p = createTestPurchase();
        Item__c i = createTestItem();

        PurchaseLine__c line = new PurchaseLine__c(
            PurchaseId__c = p.Id,
            ItemId__c = i.Id,
            Amount__c = 3,
            UnitCost__c = 15
        );

        Test.startTest();
        PurchaseLine__c savedLine = PurchaseLineService.saveLine(line);
        Test.stopTest();

        System.assertNotEquals(null, savedLine.Id, 'Line should be saved and have Id');
        System.assertEquals(3, savedLine.Amount__c);
        System.assertEquals(15, savedLine.UnitCost__c);
    }

    @IsTest
    static void testSaveLine_invalid_missingFields_throws() {
        PurchaseLine__c line = new PurchaseLine__c(); // no fields set
        try {
            PurchaseLineService.saveLine(line);
            System.assert(false, 'Expected validation exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Purchase reference') || e.getMessage().contains('Item reference'), 
                          'Unexpected error message: ' + e.getMessage());
        }
    }

    @IsTest
    static void testBatchSaveLines_valid() {
        Purchase__c p = createTestPurchase();
        Item__c i1 = createTestItem();
        Item__c i2 = createTestItem();

        List<PurchaseLine__c> lines = new List<PurchaseLine__c>{
            new PurchaseLine__c(PurchaseId__c = p.Id, ItemId__c = i1.Id, Amount__c=1, UnitCost__c=5),
            new PurchaseLine__c(PurchaseId__c = p.Id, ItemId__c = i2.Id, Amount__c=2, UnitCost__c=10)
        };

        Test.startTest();
        List<PurchaseLine__c> savedLines = PurchaseLineService.batchSaveLines(lines);
        Test.stopTest();

        System.assertEquals(2, savedLines.size());
        System.assertNotEquals(null, savedLines[0].Id);
        System.assertNotEquals(null, savedLines[1].Id);
    }

    @IsTest
    static void testBatchSaveLines_emptyList_throws() {
        try {
            PurchaseLineService.batchSaveLines(new List<PurchaseLine__c>());
            System.assert(false, 'Expected exception for empty list');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('cannot be empty'));
        }
    }

    @IsTest
    static void testBatchSaveLines_invalidLine_throws() {
        Purchase__c p = createTestPurchase();
        List<PurchaseLine__c> lines = new List<PurchaseLine__c>{
            new PurchaseLine__c(PurchaseId__c = p.Id, ItemId__c = null, Amount__c=1, UnitCost__c=5)
        };
        try {
            PurchaseLineService.batchSaveLines(lines);
            System.assert(false, 'Expected validation exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Item reference'));
        }
    }

    @IsTest
    static void testDeleteLines_valid() {
        Purchase__c p = createTestPurchase();
        Item__c i = createTestItem();
        PurchaseLine__c line = new PurchaseLine__c(
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

        System.assertEquals(0, [SELECT count() FROM PurchaseLine__c WHERE Id = :line.Id]);
    }

    @IsTest
    static void testDeleteLines_emptyList_throws() {
        try {
            PurchaseLineService.deleteLines(new List<Id>());
            System.assert(false, 'Expected exception for empty list');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('No purchase lines'));
        }
    }
}
