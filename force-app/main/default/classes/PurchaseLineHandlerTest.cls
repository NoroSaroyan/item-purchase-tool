@IsTest
private class PurchaseLineHandlerTest {

    // Helper method to create purchases and purchase lines
    private static Map<Id, Purchase__c> createTestData() {
        List<Purchase__c> purchases = new List<Purchase__c>();
        for (Integer i = 0; i < 2; i++) {
            purchases.add(new Purchase__c(Name = 'Test Purchase ' + i));
        }
        insert purchases;

        List<PurchaseLine__c> lines = new List<PurchaseLine__c>();
        // For first purchase - 2 lines
        lines.add(new PurchaseLine__c(PurchaseId__c = purchases[0].Id, Amount__c = 3, UnitCost__c = 10));
        lines.add(new PurchaseLine__c(PurchaseId__c = purchases[0].Id, Amount__c = 2, UnitCost__c = 5));

        // For second purchase - 1 line
        lines.add(new PurchaseLine__c(PurchaseId__c = purchases[1].Id, Amount__c = 4, UnitCost__c = 7));

        insert lines;

        return new Map<Id, Purchase__c>(purchases);
    }

    @IsTest
    static void testGetPurchaseIds() {
        Map<Id, Purchase__c> purchases = createTestData();
        List<PurchaseLine__c> lines = [SELECT Id, PurchaseId__c FROM PurchaseLine__c];

        Set<Id> purchaseIds = PurchaseLineHandler.getPurchaseIds(lines);

        System.assertEquals(purchases.keySet().size(), purchaseIds.size(), 'Should get unique purchase IDs');
        System.assert(purchaseIds.containsAll(purchases.keySet()), 'Should contain all purchase IDs');
    }

    @IsTest
    static void testRecalcPurchasesTotals() {
        Map<Id, Purchase__c> purchases = createTestData();

        // Call method
        Test.startTest();
        PurchaseLineHandler.recalcPurchasesTotals(purchases.keySet());
        Test.stopTest();

        // Reload purchases and verify totals
        List<Purchase__c> updatedPurchases = [
            SELECT Id, TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id IN :purchases.keySet()
        ];

        for (Purchase__c p : updatedPurchases) {
            if (p.Id == purchases.keySet().toList()[0]) {
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
    static void testRecalcPurchasesTotals_handlesNullAmountsAndUnitCosts() {
        Map<Id, Purchase__c> purchases = new Map<Id, Purchase__c>();

        Purchase__c p = new Purchase__c(Name='Test Null Fields');
        insert p;
        purchases.put(p.Id, p);

        PurchaseLine__c pl1 = new PurchaseLine__c(PurchaseId__c = p.Id, Amount__c = null, UnitCost__c = 10);
        PurchaseLine__c pl2 = new PurchaseLine__c(PurchaseId__c = p.Id, Amount__c = 2, UnitCost__c = null);
        insert new List<PurchaseLine__c>{pl1, pl2};

        Test.startTest();
        PurchaseLineHandler.recalcPurchasesTotals(purchases.keySet());
        Test.stopTest();

        p = [SELECT TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id = :p.Id];
        // Amount null treated as 0, UnitCost null treated as 0
        System.assertEquals(2, p.TotalItems__c, 'TotalItems__c should count only non-null amounts');
        System.assertEquals(0, p.GrandTotal__c, 'GrandTotal__c should be zero due to null unit cost or amount');
    }
}
