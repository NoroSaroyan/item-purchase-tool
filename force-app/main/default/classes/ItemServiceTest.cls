@IsTest
private class ItemServiceTest {

    // Helper method to create test items
    private static List<Item__c> createTestItems() {
        List<Item__c> items = new List<Item__c>();
        for (Integer i = 1; i <= 5; i++) {
            items.add(new Item__c(
                Name = 'TestItem ' + i,
                Description__c = 'Description for item ' + i,
                Price__c = 10 * i
            ));
        }
        insert items;
        return items;
    }

    @IsTest
    static void testSearchItems_nullKeyword_returnsItems() {
        createTestItems();

        Test.startTest();
        List<Item__c> results = ItemService.searchItems(null);
        Test.stopTest();

        System.assertNotEquals(0, results.size(), 'Should return items when keyword is null');
        System.assert(results.size() <= 50, 'Should return max 50 items');
    }

    @IsTest
    static void testSearchItems_emptyKeyword_returnsItems() {
        createTestItems();

        Test.startTest();
        List<Item__c> results = ItemService.searchItems('');
        Test.stopTest();

        System.assertNotEquals(0, results.size(), 'Should return items when keyword is empty');
    }

    @IsTest
    static void testSearchItems_keywordFiltersResults() {
        List<Item__c> items = createTestItems();

        Test.startTest();
        List<Item__c> results = ItemService.searchItems('Item 1');
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return 1 item matching keyword');
        System.assert(results[0].Name.contains('Item 1'), 'Returned item name should contain keyword');
    }

    @IsTest
    static void testGetItemById_validId() {
        List<Item__c> items = createTestItems();

        Test.startTest();
        Item__c item = ItemService.getItemById(items[0].Id);
        Test.stopTest();

        System.assertNotEquals(null, item);
        System.assertEquals(items[0].Id, item.Id);
    }

    @IsTest
    static void testGetItemById_nullId_throws() {
        try {
            Test.startTest();
            ItemService.getItemById(null);
            Test.stopTest();
            System.assert(false, 'Expected exception for null Id');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Item Id is required'));
        }
    }

    @IsTest
    static void testGetItemById_nonExistingId_returnsNoRecord() {
        Id fakeId = Id.valueOf('001000000000000AAA'); // valid Id format, but no record
        try {
            Test.startTest();
            Item__c item = ItemService.getItemById(fakeId);
            Test.stopTest();
            System.assert(item == null, 'Should return null for non-existing Id');
        } catch (Exception e) {
            // Depending on behavior, it might throw exception or return null
            System.assert(e.getMessage().contains('List has no rows'), 'Unexpected exception: ' + e.getMessage());
        }
    }
}
