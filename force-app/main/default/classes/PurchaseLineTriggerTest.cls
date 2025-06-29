@IsTest
private class PurchaseLineTriggerTest {

    @IsTest static void testInsertRecalc() {
        // Setup Purchase
        Purchase__c p = new Purchase__c(Name = 'Test Purchase', ClientId__c = [SELECT Id FROM Account LIMIT 1].Id);
        insert p;

        // Insert PurchaseLine records
        List<PurchaseLine__c> lines = new List<PurchaseLine__c>{
            new PurchaseLine__c(PurchaseId__c = p.Id, ItemId__c = [SELECT Id FROM Product2 LIMIT 1].Id, Amount__c = 2, UnitCost__c = 10),
            new PurchaseLine__c(PurchaseId__c = p.Id, ItemId__c = [SELECT Id FROM Product2 LIMIT 1 OFFSET 1].Id, Amount__c = 3, UnitCost__c = 20)
        };
        insert lines;

        // Reload purchase and assert totals recalculated
        p = [SELECT TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id = :p.Id];
        System.assertEquals(5, p.TotalItems__c);
        System.assertEquals(2*10 + 3*20, p.GrandTotal__c);
    }
}
