/**
 * @description
 * This service class handles operations related to Purchase__c and its lines:
 * - Search/filter purchases
 * - Save and delete purchases
 * - Manage purchase lines
 * - Automatically recalculate totals
 */
public with sharing class PurchaseService {

    /**
     * @description
     * Searches for Purchase__c records matching the search term in Purchase name or Account name.
     * 
     * @param searchTerm Term to match in Name or Account__r.Name
     * @return List of matching Purchase__c records
     */
    @AuraEnabled(cacheable=true)
    public static List<Purchase__c> getPurchases(String searchTerm) {
        PurchaseToolUtils.requireNonNullOrEmpty(searchTerm, 'Search Term');
        String filter = '%' + String.escapeSingleQuotes(searchTerm) + '%';

        try {
            return [
                SELECT Id, Name, Account__c, Account__r.Name, Purchase_Date__c, Status__c, Total_Amount__c
                FROM Purchase__c
                WHERE Name LIKE :filter OR Account__r.Name LIKE :filter
                ORDER BY Purchase_Date__c DESC
                LIMIT 100
            ];
        } catch (Exception e) {
            PurchaseToolUtils.throwException('Error fetching purchases: ' + e.getMessage());
            return null;
        }
    }

    /**
     * @description
     * Saves or updates a Purchase__c record. Validates input before persisting.
     * 
     * @param purchase Purchase__c record to save
     * @return Saved Purchase__c
     */
    @AuraEnabled
    public static Purchase__c savePurchase(Purchase__c purchase) {
        try {
            validatePurchase(purchase);
            upsert purchase;
            return purchase;
        } catch (DmlException e) {
            PurchaseToolUtils.throwException('Failed to save Purchase: ' + e.getMessage());
            return null;
        }
    }

    /**
     * @description
     * Internal validation for Purchase__c record.
     * Enforces: non-null fields, valid date, allowed status values.
     */
    private static void validatePurchase(Purchase__c purchase) {
        PurchaseToolUtils.requireNonNull(purchase.Purchase_Date__c, 'Purchase Date');
        PurchaseToolUtils.requireNonNull(purchase.Account__c, 'Account');

        if (purchase.Purchase_Date__c > Date.today()) {
            PurchaseToolUtils.throwException('Purchase Date cannot be in the future.');
        }

        Set<String> allowedStatuses = new Set<String>{'New', 'Approved', 'Cancelled'};
        if (purchase.Status__c != null && !allowedStatuses.contains(purchase.Status__c)) {
            PurchaseToolUtils.throwException('Invalid purchase status: ' + purchase.Status__c);
        }

        // Future extension: validate Account status, role-based permissions, etc.
    }

    /**
     * @description
     * Fetches all PurchaseLine__c records related to a specific Purchase__c.
     * 
     * @param purchaseId ID of the Purchase__c
     * @return List of PurchaseLine__c records
     */
    @AuraEnabled(cacheable=true)
    public static List<PurchaseLine__c> getPurchaseLines(Id purchaseId) {
        PurchaseToolUtils.requireNonNull(purchaseId, 'Purchase Id');
        try {
            return [
                SELECT Id, Purchase__c, Item__c, Quantity__c, Unit_Price__c, Total_Price__c
                FROM PurchaseLine__c
                WHERE Purchase__c = :purchaseId
                ORDER BY CreatedDate
            ];
        } catch (Exception e) {
            PurchaseToolUtils.throwException('Error fetching purchase lines: ' + e.getMessage());
            return null;
        }
    }

    /**
     * @description
     * Saves a list of PurchaseLine__c records and updates the parent Purchase total.
     * 
     * @param lines List of PurchaseLine__c to save
     */
    @AuraEnabled
    public static void savePurchaseLines(List<PurchaseLine__c> lines) {
        if (lines == null || lines.isEmpty()) {
            PurchaseToolUtils.throwException('Purchase lines list cannot be empty.');
        }

        try {
            for (PurchaseLine__c line : lines) {
                PurchaseToolUtils.requireNonNull(line.Quantity__c, 'Quantity');
                PurchaseToolUtils.requirePositive(line.Quantity__c, 'Quantity');
                PurchaseToolUtils.requireNonNull(line.Unit_Price__c, 'Unit Price');
                PurchaseToolUtils.requirePositive(line.Unit_Price__c, 'Unit Price');
                line.Total_Price__c = line.Quantity__c * line.Unit_Price__c;
            }

            upsert lines;
            recalcPurchaseTotal(lines[0].Purchase__c);
        } catch (DmlException e) {
            PurchaseToolUtils.throwException('Failed to save Purchase Lines: ' + e.getMessage());
        }
    }

    /**
     * @description
     * Deletes a Purchase__c record and all its related PurchaseLine__c records.
     * 
     * @param purchaseId ID of Purchase__c to delete
     */
    @AuraEnabled
    public static void deletePurchase(Id purchaseId) {
        PurchaseToolUtils.requireNonNull(purchaseId, 'Purchase Id');

        try {
            List<PurchaseLine__c> linesToDelete = [
                SELECT Id FROM PurchaseLine__c WHERE Purchase__c = :purchaseId
            ];

            delete linesToDelete;
            delete [SELECT Id FROM Purchase__c WHERE Id = :purchaseId];
        } catch (DmlException e) {
            PurchaseToolUtils.throwException('Failed to delete Purchase: ' + e.getMessage());
        }
    }

    /**
     * @description
     * Recalculates and updates the Total_Amount__c on Purchase__c
     * by summing its PurchaseLine__c.Total_Price__c values.
     * 
     * @param purchaseId ID of the Purchase__c
     */
    public static void recalcPurchaseTotal(Id purchaseId) {
        AggregateResult result = [
            SELECT SUM(Total_Price__c) total
            FROM PurchaseLine__c
            WHERE Purchase__c = :purchaseId
        ];

        Decimal total = (Decimal)result.get('total');
        if (total == null) total = 0;

        update new Purchase__c(Id = purchaseId, Total_Amount__c = total);
    }
}
