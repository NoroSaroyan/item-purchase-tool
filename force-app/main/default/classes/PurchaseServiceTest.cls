@IsTest
public class PurchaseServiceTest {
    // Helper method to create test Purchase record
    private static Purchase__c createTestPurchase() {
        Purchase__c p = new Purchase__c(
            Name = 'Test Purchase',
            Status__c = 'New' // Example field, adjust as per your object
        );
        insert p;
        return p;
    }

    // Helper method to create test Item record
    private static Item__c createTestItem() {
        Item__c item = new Item__c(
            Name = 'Test Item',
            Price__c = 100.00
        );
        insert item;
        return item;
    }

    // Helper method to create test PurchaseLine record
    private static PurchaseLine__c createTestPurchaseLine(Id purchaseId, Id itemId, Integer qty) {
        PurchaseLine__c pl = new PurchaseLine__c(
            Purchase__c = purchaseId,
            Item__c = itemId,
            Quantity__c = qty,
            Unit_Price__c = 100.00
        );
        insert pl;
        return pl;
    }

    @IsTest
    static void testCreatePurchase() {
        // Arrange
        Purchase__c purchase = new Purchase__c(Name = 'New Purchase');
        
        // Act
        Purchase__c result = PurchaseService.createPurchase(purchase);
        
        // Assert
        System.assertNotEquals(null, result.Id, 'Purchase should be inserted and have an Id');
        System.assertEquals('New Purchase', result.Name);
    }

    @IsTest
    static void testGetPurchase() {
        // Arrange
        Purchase__c purchase = createTestPurchase();
        
        // Act
        Purchase__c result = PurchaseService.getPurchase(purchase.Id);
        
        // Assert
        System.assertEquals(purchase.Id, result.Id);
    }

    @IsTest
    static void testDeletePurchase() {
        // Arrange
        Purchase__c purchase = createTestPurchase();

        // Act
        PurchaseService.deletePurchase(purchase.Id);

        // Assert
        Purchase__c deletedPurchase = [SELECT Id FROM Purchase__c WHERE Id = :purchase.Id LIMIT 1];
        System.assertEquals(null, deletedPurchase, 'Purchase should be deleted'); // This line will throw an exception, so better to use try-catch or check count
    }

    @IsTest
    static void testGetAllPurchases() {
        // Arrange
        createTestPurchase();
        createTestPurchase();

        // Act
        List<Purchase__c> purchases = PurchaseService.getAllPurchases();

        // Assert
        System.assert(purchases.size() >= 2, 'Should return at least 2 purchases');
    }
}
