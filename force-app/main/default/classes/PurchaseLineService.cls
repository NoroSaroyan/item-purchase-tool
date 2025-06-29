/**
 * @description
 * This class handles logic for managing Purchase_Line__c records:
 * - Fetching lines by Purchase ID
 * - Saving (inserting or updating) purchase lines
 * - Deleting purchase lines
 * - Validating input
 * - Triggering recalculation of totals on Purchase__c
 */
public with sharing class PurchaseLineService {

    /**
     * Retrieves all Purchase_Line__c records for a given Purchase__c ID.
     */
    @AuraEnabled(cacheable=true)
    public static List<Purchase_Line__c> getLinesByPurchase(Id purchaseId) {
        PurchaseToolUtils.requireNonNull(purchaseId, 'Purchase Id');
        try {
            return [
                SELECT Id, 
                       PurchaseId__c, 
                       ItemId__c, 
                       Amount__c, 
                       UnitCost__c
                FROM Purchase_Line__c
                WHERE PurchaseId__c = :purchaseId
                ORDER BY CreatedDate
            ];
        } catch (Exception e) {
            PurchaseToolUtils.throwException('Error retrieving purchase lines: ' + e.getMessage());
            return null; 
        }
    }

    /**
     * Saves or updates a Purchase_Line__c record.
     * Updates the parent Purchase totals.
     */
    @AuraEnabled
    public static Purchase_Line__c saveLine(Purchase_Line__c line) {
        validateLine(line);

        try {
            upsert line;

            // Recalculate total on parent Purchase
            PurchaseService.recalcPurchaseTotal(line.PurchaseId__c);

            return line;

        } catch (DmlException e) {
            PurchaseToolUtils.throwException('Failed to save purchase line: ' + e.getMessage());
            return null;
        }
    }

    /**
     * Saves or updates a list o Purchase_Line__c records.
     * Updates the parent Purchase totals.
     */
    public static List<Purchase_Line__c> batchSaveLines(List<Purchase_Line__c> lines) {
        if (lines == null || lines.isEmpty()) {
            PurchaseToolUtils.throwException('List of purchase lines cannot be empty');
        }
    
        Set<Id> purchaseIds = new Set<Id>();
    
        for (Purchase_Line__c line : lines) {
            validateLine(line);
            purchaseIds.add(line.PurchaseId__c);
        }
    
        upsert lines;
    
        // Recalculate totals once per PurchaseId
        for (Id pid : purchaseIds) {
            PurchaseService.recalcPurchaseTotal(pid);
        }
    
        return lines;
    }    

    /**
     * Deletes a list of Purchase_Line__c records by IDs and updates affected parent Purchase totals.
     */
    @AuraEnabled
    public static void deleteLines(List<Id> lineIds) {
        if (lineIds == null || lineIds.isEmpty()) {
            PurchaseToolUtils.throwException('No purchase lines specified for deletion.');
        }

        try {
            // Collect related Purchase__c IDs before deletion
            Set<Id> purchaseIds = new Set<Id>();
            for (Purchase_Line__c pl : [
                SELECT PurchaseId__c 
                FROM Purchase_Line__c 
                WHERE Id IN :lineIds
            ]) {
                purchaseIds.add(pl.PurchaseId__c);
            }

            // Delete the lines
            delete [SELECT Id FROM Purchase_Line__c WHERE Id IN :lineIds];

            // Recalculate totals for each affected purchase
            for (Id pid : purchaseIds) {
                PurchaseService.recalcPurchaseTotal(pid);
            }

        } catch (DmlException e) {
            PurchaseToolUtils.throwException('Failed to delete purchase lines: ' + e.getMessage());
        }
    }

    /**
     * Validates that a Purchase_Line__c has valid references and numeric values.
     */
    private static void validateLine(Purchase_Line__c line) {
        PurchaseToolUtils.requireNonNull(line.PurchaseId__c, 'Purchase reference');
        PurchaseToolUtils.requireNonNull(line.ItemId__c, 'Item reference');
        PurchaseToolUtils.requirePositive(line.Amount__c, 'Amount');
        PurchaseToolUtils.requirePositive(line.UnitCost__c, 'Unit Cost');
    }
}
