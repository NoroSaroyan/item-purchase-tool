@IsTest
private class PurchaseLineTriggerTest {

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
    }

    @IsTest 
    static void testInsertRecalc() {
        // Get test data
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        List<Item__c> items = [SELECT Id FROM Item__c ORDER BY Name LIMIT 2];
        
        // Setup Purchase
        Purchase__c p = new Purchase__c(
            Name = 'Test Purchase', 
            ClientId__c = testAccount.Id
        );
        insert p;

        Test.startTest();
        // Insert PurchaseLine records - this should trigger the PurchaseLineTrigger
        List<Purchase_Line__c> lines = new List<Purchase_Line__c>{
            new Purchase_Line__c(
                PurchaseId__c = p.Id, 
                ItemId__c = items[0].Id, 
                Amount__c = 2, 
                UnitCost__c = 10
            ),
            new Purchase_Line__c(
                PurchaseId__c = p.Id, 
                ItemId__c = items[1].Id, 
                Amount__c = 3, 
                UnitCost__c = 20
            )
        };
        insert lines;
        Test.stopTest();

        // Reload purchase and assert totals were recalculated by the trigger
        p = [SELECT TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id = :p.Id];
        System.assertEquals(5, p.TotalItems__c, 'TotalItems__c should be 2+3=5');
        System.assertEquals(80, p.GrandTotal__c, 'GrandTotal__c should be 2*10 + 3*20 = 80');
    }

    @IsTest 
    static void testUpdateRecalc() {
        // Get test data
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        List<Item__c> items = [SELECT Id FROM Item__c ORDER BY Name LIMIT 2];
        
        // Setup Purchase and initial line
        Purchase__c p = new Purchase__c(
            Name = 'Test Purchase', 
            ClientId__c = testAccount.Id
        );
        insert p;

        Purchase_Line__c line = new Purchase_Line__c(
            PurchaseId__c = p.Id, 
            ItemId__c = items[0].Id, 
            Amount__c = 1, 
            UnitCost__c = 10
        );
        insert line;

        Test.startTest();
        // Update the line - this should trigger recalculation
        line.Amount__c = 5;
        line.UnitCost__c = 15;
        update line;
        Test.stopTest();

        // Reload purchase and assert totals were recalculated
        p = [SELECT TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id = :p.Id];
        System.assertEquals(5, p.TotalItems__c, 'TotalItems__c should be updated to 5');
        System.assertEquals(75, p.GrandTotal__c, 'GrandTotal__c should be updated to 5*15 = 75');
    }

    @IsTest 
    static void testDeleteRecalc() {
        // Get test data
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        List<Item__c> items = [SELECT Id FROM Item__c ORDER BY Name LIMIT 2];
        
        // Setup Purchase and lines
        Purchase__c p = new Purchase__c(
            Name = 'Test Purchase', 
            ClientId__c = testAccount.Id
        );
        insert p;

        List<Purchase_Line__c> lines = new List<Purchase_Line__c>{
            new Purchase_Line__c(
                PurchaseId__c = p.Id, 
                ItemId__c = items[0].Id, 
                Amount__c = 2, 
                UnitCost__c = 10
            ),
            new Purchase_Line__c(
                PurchaseId__c = p.Id, 
                ItemId__c = items[1].Id, 
                Amount__c = 3, 
                UnitCost__c = 20
            )
        };
        insert lines;

        Test.startTest();
        // Delete one line - this should trigger recalculation
        delete lines[0];
        Test.stopTest();

        // Reload purchase and assert totals were recalculated
        p = [SELECT TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id = :p.Id];
        System.assertEquals(3, p.TotalItems__c, 'TotalItems__c should be 3 after deletion');
        System.assertEquals(60, p.GrandTotal__c, 'GrandTotal__c should be 3*20 = 60 after deletion');
    }
}
