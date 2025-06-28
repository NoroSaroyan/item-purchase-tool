/**
 * @description
 * This class handles logic for managing PurchaseLine__c records:
 * - Fetching lines by Purchase ID
 * - Saving (inserting or updating) purchase lines
 * - Deleting purchase lines
 * 
 * It also ensures business rules such as price calculations and total updates to parent Purchase.
 */
public with sharing class PurchaseLineService {

    /**
     * @description
     * Retrieves all PurchaseLine__c records for a given Purchase__c.
     *
     * @param purchaseId ID of the parent Purchase__c
     * @return List of PurchaseLine__c sorted by CreatedDate
     */
    @AuraEnabled(cacheable=true)
    public static List<PurchaseLine__c> getLinesByPurchase(Id purchaseId) {
        PurchaseToolUtils.requireNonNull(purchaseId, 'Purchase Id');
        try {
            return [
                SELECT Id, Purchase__c, Item__c, Quantity__c, Unit_Price__c, Total_Price__c
                FROM PurchaseLine__c
                WHERE Purchase__c = :purchaseId
                ORDER BY CreatedDate
            ];
        } catch (Exception e) {
            PurchaseToolUtils.throwException('Error retrieving purchase lines: ' + e.getMessage());
            return null; 
        }
    }

    /**
     * @description
     * Saves or updates a PurchaseLine__c record. Also recalculates the total on the parent Purchase__c.
     *
     * @param line The PurchaseLine__c to save
     * @return The saved PurchaseLine__c with calculated Total_Price__c
     */
    @AuraEnabled
    public static PurchaseLine__c saveLine(PurchaseLine__c line) {
        validateLine(line);
        try {
            line.Total_Price__c = line.Quantity__c * line.Unit_Price__c;
            upsert line;
            PurchaseService.recalcPurchaseTotal(line.Purchase__c);
            return line;
        } catch (DmlException e) {
            PurchaseToolUtils.throwException('Failed to save purchase line: ' + e.getMessage());
            return null;
        }
    }

    /**
     * @description
     * Deletes a list of PurchaseLine__c records and updates totals on affected Purchase__c records.
     *
     * @param lineIds List of PurchaseLine__c record IDs to delete
     */
    @AuraEnabled
    public static void deleteLines(List<Id> lineIds) {
        if (lineIds == null || lineIds.isEmpty()) {
            PurchaseToolUtils.throwException('No purchase lines specified for deletion.');
        }
        try {
            Set<Id> purchaseIds = new Set<Id>();
            for (PurchaseLine__c pl : [SELECT Purchase__c FROM PurchaseLine__c WHERE Id IN :lineIds]) {
                purchaseIds.add(pl.Purchase__c);
            }

            delete [SELECT Id FROM PurchaseLine__c WHERE Id IN :lineIds];

            for (Id pid : purchaseIds) {
                PurchaseService.recalcPurchaseTotal(pid);
            }
        } catch (DmlException e) {
            PurchaseToolUtils.throwException('Failed to delete purchase lines: ' + e.getMessage());
        }
    }

    /**
     * @description
     * Validates a PurchaseLine__c record before saving.
     *
     * @param line The line to validate
     */
    private static void validateLine(PurchaseLine__c line) {
        PurchaseToolUtils.requireNonNull(line.Purchase__c, 'Purchase reference');
        PurchaseToolUtils.requireNonNull(line.Item__c, 'Item reference');
        PurchaseToolUtils.requirePositive(line.Quantity__c, 'Quantity');
        PurchaseToolUtils.requirePositive(line.Unit_Price__c, 'Unit Price');
    }
}
