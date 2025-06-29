@IsTest
private class PurchaseServiceTest {

    // Helper method to create a Client__c record for lookups
    private static Client__c createTestClient() {
        Client__c client = new Client__c(Name = 'Test Client');
        insert client;
        return client;
    }
    
    // Helper method to create an Item__c record for PurchaseLine
    private static Item__c createTestItem() {
        Item__c item = new Item__c(Name = 'Test Item');
        insert item;
        return item;
    }

    @IsTest
    static void testGetPurchases_success() {
        Client__c client = createTestClient();
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
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Search Term'), 'Expected validation error on search term');
        }
    }

    @IsTest
    static void testSavePurchase_success() {
        Client__c client = createTestClient();

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
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Client'), 'Expected validation error on ClientId__c');
        }
    }

    @IsTest
    static void testGetPurchaseLines_success() {
        Client__c client = createTestClient();
        Item__c item = createTestItem();

        Purchase__c purchase = new Purchase__c(Name = 'With Lines', ClientId__c = client.Id);
        insert purchase;

        PurchaseLine__c line = new PurchaseLine__c(PurchaseId__c = purchase.Id, ItemId__c = item.Id, Amount__c = 5, UnitCost__c = 10);
        insert line;

        List<PurchaseLine__c> lines = PurchaseService.getPurchaseLines(purchase.Id);
        System.assertEquals(1, lines.size());
        System.assertEquals(line.Id, lines[0].Id);
    }

    @IsTest
    static void testGetPurchaseLines_nullId_throws() {
        try {
            PurchaseService.getPurchaseLines(null);
            System.assert(false, 'Exception expected for null purchaseId');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Purchase Id'), 'Expected validation error on purchaseId');
        }
    }

    @IsTest
    static void testSavePurchaseLines_successAndRecalc() {
        Client__c client = createTestClient();
        Item__c item = createTestItem();

        Purchase__c purchase = new Purchase__c(Name = 'Test Save Lines', ClientId__c = client.Id);
        insert purchase;

        PurchaseLine__c line1 = new PurchaseLine__c(PurchaseId__c = purchase.Id, ItemId__c = item.Id, Amount__c = 3, UnitCost__c = 5);
        PurchaseLine__c line2 = new PurchaseLine__c(PurchaseId__c = purchase.Id, ItemId__c = item.Id, Amount__c = 2, UnitCost__c = 10);

        List<PurchaseLine__c> lines = new List<PurchaseLine__c>{line1, line2};

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
            PurchaseService.savePurchaseLines(new List<PurchaseLine__c>());
            System.assert(false, 'Exception expected for empty lines list');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('cannot be empty'), 'Expected validation error for empty lines');
        }
    }

    @IsTest
    static void testDeletePurchase_success() {
        Client__c client = createTestClient();
        Item__c item = createTestItem();

        Purchase__c purchase = new Purchase__c(Name = 'To Delete', ClientId__c = client.Id);
        insert purchase;

        PurchaseLine__c line = new PurchaseLine__c(PurchaseId__c = purchase.Id, ItemId__c = item.Id, Amount__c = 1, UnitCost__c = 1);
        insert line;

        Test.startTest();
        PurchaseService.deletePurchase(purchase.Id);
        Test.stopTest();

        // Check purchase and lines deleted
        Integer purchaseCount = [SELECT count() FROM Purchase__c WHERE Id = :purchase.Id];
        Integer linesCount = [SELECT count() FROM PurchaseLine__c WHERE PurchaseId__c = :purchase.Id];
        System.assertEquals(0, purchaseCount, 'Purchase should be deleted');
        System.assertEquals(0, linesCount, 'Related lines should be deleted');
    }

    @IsTest
    static void testDeletePurchase_nullId_throws() {
        try {
            PurchaseService.deletePurchase(null);
            System.assert(false, 'Exception expected for null purchaseId');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Purchase Id'), 'Expected validation error on purchaseId');
        }
    }
}
