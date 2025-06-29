/**
 * @description
 * This class handles logic for managing PurchaseLine__c records:
 * - Fetching lines by Purchase ID
 * - Saving (inserting or updating) purchase lines
 * - Deleting purchase lines
 * - Validating input
 * - Triggering recalculation of totals on Purchase__c
 */
public with sharing class PurchaseLineService {

    /**
     * Retrieves all PurchaseLine__c records for a given Purchase__c ID.
     */
    @AuraEnabled(cacheable=true)
    public static List<PurchaseLine__c> getLinesByPurchase(Id purchaseId) {
        PurchaseToolUtils.requireNonNull(purchaseId, 'Purchase Id');
        try {
            return [
                SELECT Id, 
                       PurchaseId__c, 
                       ItemId__c, 
                       Amount__c, 
                       UnitCost__c
                FROM PurchaseLine__c
                WHERE PurchaseId__c = :purchaseId
                ORDER BY CreatedDate
            ];
        } catch (Exception e) {
            PurchaseToolUtils.throwException('Error retrieving purchase lines: ' + e.getMessage());
            return null; 
        }
    }

    /**
     * Saves or updates a PurchaseLine__c record.
     * Updates the parent Purchase totals.
     */
    @AuraEnabled
    public static PurchaseLine__c saveLine(PurchaseLine__c line) {
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
     * Saves or updates a list o PurchaseLine__c records.
     * Updates the parent Purchase totals.
     */
    public static List<PurchaseLine__c> batchSaveLines(List<PurchaseLine__c> lines) {
        if (lines == null || lines.isEmpty()) {
            throw PurchaseToolUtils.throwException('List of purchase lines cannot be empty');
        }
    
        Set<Id> purchaseIds = new Set<Id>();
    
        for (PurchaseLine__c line : lines) {
            validateLine(line); // можно вызвать reuse
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
     * Deletes a list of PurchaseLine__c records by IDs and updates affected parent Purchase totals.
     */
    @AuraEnabled
    public static void deleteLines(List<Id> lineIds) {
        if (lineIds == null || lineIds.isEmpty()) {
            PurchaseToolUtils.throwException('No purchase lines specified for deletion.');
        }

        try {
            // Collect related Purchase__c IDs before deletion
            Set<Id> purchaseIds = new Set<Id>();
            for (PurchaseLine__c pl : [
                SELECT PurchaseId__c 
                FROM PurchaseLine__c 
                WHERE Id IN :lineIds
            ]) {
                purchaseIds.add(pl.PurchaseId__c);
            }

            // Delete the lines
            delete [SELECT Id FROM PurchaseLine__c WHERE Id IN :lineIds];

            // Recalculate totals for each affected purchase
            for (Id pid : purchaseIds) {
                PurchaseService.recalcPurchaseTotal(pid);
            }

        } catch (DmlException e) {
            PurchaseToolUtils.throwException('Failed to delete purchase lines: ' + e.getMessage());
        }
    }

    /**
     * Validates that a PurchaseLine__c has valid references and numeric values.
     */
    private static void validateLine(PurchaseLine__c line) {
        PurchaseToolUtils.requireNonNull(line.PurchaseId__c, 'Purchase reference');
        PurchaseToolUtils.requireNonNull(line.ItemId__c, 'Item reference');
        PurchaseToolUtils.requirePositive(line.Amount__c, 'Amount');
        PurchaseToolUtils.requirePositive(line.UnitCost__c, 'Unit Cost');
    }
}
