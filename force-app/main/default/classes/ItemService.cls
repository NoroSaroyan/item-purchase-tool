public with sharing class ItemService {

    /**
     * Searches items by keyword. 
     * If keyword is null or empty, returns first 50 items sorted by name.
     */
    @AuraEnabled(cacheable=true)
    public static List<Item__c> searchItems(String keyword) {
        String searchTerm = '%' + String.escapeSingleQuotes(keyword == null ? '' : keyword.trim()) + '%';

        return [
            SELECT Id, Name, Description__c, Price__c, Image__c, Family__c, Type__c
            FROM Item__c
            WHERE Name LIKE :searchTerm
            ORDER BY Name
            LIMIT 50
        ];
    }

    /**
     * Fetches a specific Item by Id.
     */
    @AuraEnabled(cacheable=true)
    public static Item__c getItemById(Id itemId) {
        if (itemId == null) {
            throw new AuraHandledException('Item Id is required');
        }

        List<Item__c> items = [
            SELECT Id, Name, Description__c, Price__c, Image__c, Family__c, Type__c
            FROM Item__c
            WHERE Id = :itemId
            LIMIT 1
        ];
        
        return items.isEmpty() ? null : items[0];
    }
}
