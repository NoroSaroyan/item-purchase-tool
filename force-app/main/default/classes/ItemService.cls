public with sharing class ItemService {

    /**
     * Searches items by keyword. 
     * If keyword is null or empty, returns first 50 items sorted by name.
     */
    @AuraEnabled(cacheable=true)
    public static List<Item__c> searchItems(String keyword) {
        String searchTerm = '%' + String.escapeSingleQuotes(keyword == null ? '' : keyword.trim()) + '%';

        // Modify fields as needed for your UI
        return [
            SELECT Id, Name, Description__c, Price__c, Image__c
            FROM Item__c
            WHERE Name LIKE :searchTerm OR Description__c LIKE :searchTerm
            ORDER BY Name
            LIMIT 50
        ];
    }

    /**
     * Fetches a specific Item by Id — useful if you need item details in cart summary or similar
     */
    @AuraEnabled(cacheable=true)
    public static Item__c getItemById(Id itemId) {
        if (itemId == null) {
            throw new AuraHandledException('Item Id is required');
        }

        return [
            SELECT Id, Name, Description__c, Price__c, Image__c
            FROM Item__c
            WHERE Id = :itemId
            LIMIT 1
        ];
    }
}
