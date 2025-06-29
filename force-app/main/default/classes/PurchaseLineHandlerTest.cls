@IsTest
private class PurchaseLineHandlerTest {

    @TestSetup
    static void setup() {
        // Create test account for ClientId__c lookup
        Account testAccount = new Account(
            Name = 'Test Client Account',
            Type = 'Customer'
        );
        insert testAccount;
        
        // Create test items for ItemId__c lookup
        List<Item__c> items = new List<Item__c>();
        for (Integer i = 1; i <= 3; i++) {
            items.add(new Item__c(
                Name = 'Test Item ' + i,
                Description__c = 'Description for test item ' + i,
                Price__c = 10 * i,
                Type__c = 'Hardware',
                Family__c = 'Electronics'
            ));
        }
        insert items;
        
        List<Purchase__c> purchases = new List<Purchase__c>();
        for (Integer i = 0; i < 2; i++) {
            purchases.add(new Purchase__c(
                Name = 'Test Purchase ' + i, 
                ClientId__c = testAccount.Id
            ));
        }
        insert purchases;

        List<Purchase_Line__c> lines = new List<Purchase_Line__c>();
        // For first purchase - 2 lines
        lines.add(new Purchase_Line__c(
            PurchaseId__c = purchases[0].Id, 
            ItemId__c = items[0].Id,
            Amount__c = 3, 
            UnitCost__c = 10
        ));
        lines.add(new Purchase_Line__c(
            PurchaseId__c = purchases[0].Id, 
            ItemId__c = items[1].Id,
            Amount__c = 2, 
            UnitCost__c = 5
        ));

        // For second purchase - 1 line
        lines.add(new Purchase_Line__c(
            PurchaseId__c = purchases[1].Id, 
            ItemId__c = items[2].Id,
            Amount__c = 4, 
            UnitCost__c = 7
        ));

        insert lines;
    }

    // Helper method to get test data
    private static Map<Id, Purchase__c> getTestData() {
        List<Purchase__c> purchases = [SELECT Id, Name FROM Purchase__c];
        return new Map<Id, Purchase__c>(purchases);
    }

    @IsTest
    static void testGetPurchaseIds() {
        Map<Id, Purchase__c> purchases = getTestData();
        List<Purchase_Line__c> lines = [SELECT Id, PurchaseId__c FROM Purchase_Line__c];

        Set<Id> purchaseIds = PurchaseLineHandler.getPurchaseIds(lines);

        System.assertEquals(purchases.keySet().size(), purchaseIds.size(), 'Should get unique purchase IDs');
        System.assert(purchaseIds.containsAll(purchases.keySet()), 'Should contain all purchase IDs');
    }

    @IsTest
    static void testRecalcPurchasesTotals() {
        Map<Id, Purchase__c> purchases = getTestData();

        // Call method
        Test.startTest();
        PurchaseLineHandler.recalcPurchasesTotals(purchases.keySet());
        Test.stopTest();

        // Reload purchases and verify totals
        List<Purchase__c> updatedPurchases = [
            SELECT Id, TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id IN :purchases.keySet()
        ];

        for (Purchase__c p : updatedPurchases) {

            List<Id> idList = new List<Id>(purchases.keySet());
            if (p.Id == idList[0]) {
                // For purchase 1: TotalItems = 3+2=5; GrandTotal = 3*10 + 2*5 = 40
                System.assertEquals(5, p.TotalItems__c, 'TotalItems__c should be 5');
                System.assertEquals(40, p.GrandTotal__c, 'GrandTotal__c should be 40');
            } else {
                // For purchase 2: TotalItems = 4; GrandTotal = 4*7 = 28
                System.assertEquals(4, p.TotalItems__c, 'TotalItems__c should be 4');
                System.assertEquals(28, p.GrandTotal__c, 'GrandTotal__c should be 28');
            }
        }
    }

    @IsTest
    static void testRecalcPurchasesTotals_emptyOrNull() {
        // Should do nothing and not throw exceptions
        Test.startTest();
        PurchaseLineHandler.recalcPurchasesTotals(new Set<Id>());
        PurchaseLineHandler.recalcPurchasesTotals(null);
        Test.stopTest();
    }

    @IsTest
    static void testRecalcPurchasesTotals_handlesZeroValues() {
        // Create test account for ClientId__c lookup
        Account testAccount = new Account(
            Name = 'Test Client Account',
            Type = 'Customer'
        );
        insert testAccount;
        
        // Create test items for ItemId__c lookup
        List<Item__c> items = new List<Item__c>();
        for (Integer i = 1; i <= 2; i++) {
            items.add(new Item__c(
                Name = 'Test Item ' + i,
                Description__c = 'Description for test item ' + i,
                Price__c = 10 * i,
                Type__c = 'Hardware',
                Family__c = 'Electronics'
            ));
        }
        insert items;
        
        Purchase__c p = new Purchase__c(
            Name='Test Zero Values', 
            ClientId__c = testAccount.Id
        );
        insert p;
        
        Map<Id, Purchase__c> purchases = new Map<Id, Purchase__c>();
        purchases.put(p.Id, p);

        // Test with zero values instead of null since Amount__c and UnitCost__c are required
        Purchase_Line__c pl1 = new Purchase_Line__c(
            PurchaseId__c = p.Id, 
            ItemId__c = items[0].Id,
            Amount__c = 0, 
            UnitCost__c = 10
        );
        Purchase_Line__c pl2 = new Purchase_Line__c(
            PurchaseId__c = p.Id, 
            ItemId__c = items[1].Id,
            Amount__c = 2, 
            UnitCost__c = 0
        );
        insert new List<Purchase_Line__c>{pl1, pl2};

        Test.startTest();
        PurchaseLineHandler.recalcPurchasesTotals(purchases.keySet());
        Test.stopTest();

        p = [SELECT TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id = :p.Id];
        // Amount 0 + Amount 2 = 2; GrandTotal = 0*10 + 2*0 = 0
        System.assertEquals(2, p.TotalItems__c, 'TotalItems__c should sum amounts including zero');
        System.assertEquals(0, p.GrandTotal__c, 'GrandTotal__c should be zero when amounts or unit costs are zero');
    }
}
