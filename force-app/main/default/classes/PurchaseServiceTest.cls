@IsTest
private class PurchaseServiceTest {

    // Helper method to create a Account record for lookups
    private static Account createTestClient() {
        Account client = new Account(Name = 'Test Client');
        insert client;
        return client;
    }
    
    // Helper method to create an Item__c record for PurchaseLine
    private static Item__c createTestItem() {
        Item__c item = new Item__c(
            Name = 'Test Item',
            Type__c = 'Hardware',
            Family__c = 'Electronics',
            Price__c = 10.00
        );
        insert item;
        return item;
    }

    @IsTest
    static void testGetPurchases_success() {
        Account client = createTestClient();
        Purchase__c purchase = new Purchase__c(Name = 'Test Purchase', ClientId__c = client.Id);
        insert purchase;

        // Should return purchase by name
        List<Purchase__c> results = PurchaseService.getPurchases('Test');
        System.assertNotEquals(0, results.size(), 'Expected to find at least one purchase');

        // Should return purchase by client name
        results = PurchaseService.getPurchases('Test Client');
        System.assertNotEquals(0, results.size(), 'Expected to find at least one purchase by client name');
    }

    @IsTest
    static void testGetPurchases_emptySearchTerm_throws() {
        try {
            PurchaseService.getPurchases('');
            System.assert(false, 'Exception expected for empty search term');
        } catch (AuraHandledException e) {
            // Just verify that an exception was thrown since AuraHandledException doesn't preserve the custom message in getMessage()
            System.assert(true, 'Exception was thrown as expected');
        }
    }

    @IsTest
    static void testSavePurchase_success() {
        Account client = createTestClient();

        Purchase__c p = new Purchase__c(ClientId__c = client.Id, Name = 'New Purchase');
        Purchase__c saved = PurchaseService.savePurchase(p);
        System.assertNotEquals(null, saved.Id, 'Purchase should be inserted');

        // Update scenario
        saved.Name = 'Updated Name';
        Purchase__c updated = PurchaseService.savePurchase(saved);
        System.assertEquals('Updated Name', updated.Name, 'Purchase should be updated');
    }

    @IsTest
    static void testSavePurchase_missingClient_throws() {
        Purchase__c p = new Purchase__c(Name = 'No Client');
        try {
            PurchaseService.savePurchase(p);
            System.assert(false, 'Exception expected for missing Client');
        } catch (AuraHandledException e) {
            System.assert(true, 'Exception was thrown as expected');
        }
    }

    @IsTest
    static void testGetPurchaseLines_success() {
        Account client = createTestClient();
        Item__c item = createTestItem();

        Purchase__c purchase = new Purchase__c(Name = 'With Lines', ClientId__c = client.Id);
        insert purchase;

        Purchase_Line__c line = new Purchase_Line__c(PurchaseId__c = purchase.Id, ItemId__c = item.Id, Amount__c = 5, UnitCost__c = 10);
        insert line;

        List<Purchase_Line__c> lines = PurchaseService.getPurchaseLines(purchase.Id);
        System.assertEquals(1, lines.size());
        System.assertEquals(line.Id, lines[0].Id);
    }

    @IsTest
    static void testGetPurchaseLines_nullId_throws() {
        try {
            PurchaseService.getPurchaseLines(null);
            System.assert(false, 'Exception expected for null purchaseId');
        } catch (AuraHandledException e) {
            System.assert(true, 'Exception was thrown as expected');
        }
    }

    @IsTest
    static void testSavePurchaseLines_successAndRecalc() {
        Account client = createTestClient();
        Item__c item = createTestItem();

        Purchase__c purchase = new Purchase__c(Name = 'Test Save Lines', ClientId__c = client.Id);
        insert purchase;

        Purchase_Line__c line1 = new Purchase_Line__c(PurchaseId__c = purchase.Id, ItemId__c = item.Id, Amount__c = 3, UnitCost__c = 5);
        Purchase_Line__c line2 = new Purchase_Line__c(PurchaseId__c = purchase.Id, ItemId__c = item.Id, Amount__c = 2, UnitCost__c = 10);

        List<Purchase_Line__c> lines = new List<Purchase_Line__c>{line1, line2};

        Test.startTest();
        PurchaseService.savePurchaseLines(lines);
        Test.stopTest();

        // Check recalculated totals
        Purchase__c refreshed = [SELECT TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id = :purchase.Id];
        System.assertEquals(5, refreshed.TotalItems__c, 'TotalItems__c should be sum of amounts');
        System.assertEquals(3*5 + 2*10, refreshed.GrandTotal__c, 'GrandTotal__c should be sum of amount*unitCost');
    }

    @IsTest
    static void testSavePurchaseLines_emptyList_throws() {
        try {
            PurchaseService.savePurchaseLines(new List<Purchase_Line__c>());
            System.assert(false, 'Exception expected for empty lines list');
        } catch (AuraHandledException e) {
            System.assert(true, 'Exception was thrown as expected');
        }
    }

    @IsTest
    static void testDeletePurchase_success() {
        Account client = createTestClient();
        Item__c item = createTestItem();

        Purchase__c purchase = new Purchase__c(Name = 'To Delete', ClientId__c = client.Id);
        insert purchase;

        Purchase_Line__c line = new Purchase_Line__c(PurchaseId__c = purchase.Id, ItemId__c = item.Id, Amount__c = 1, UnitCost__c = 1);
        insert line;

        Test.startTest();
        PurchaseService.deletePurchase(purchase.Id);
        Test.stopTest();

        // Check purchase and lines deleted
        Integer purchaseCount = [SELECT count() FROM Purchase__c WHERE Id = :purchase.Id];
        Integer linesCount = [SELECT count() FROM Purchase_Line__c WHERE PurchaseId__c = :purchase.Id];
        System.assertEquals(0, purchaseCount, 'Purchase should be deleted');
        System.assertEquals(0, linesCount, 'Related lines should be deleted');
    }

    @IsTest
    static void testDeletePurchase_nullId_throws() {
        try {
            PurchaseService.deletePurchase(null);
            System.assert(false, 'Exception expected for null purchaseId');
        } catch (AuraHandledException e) {
            System.assert(true, 'Exception was thrown as expected');
        }
    }
}
