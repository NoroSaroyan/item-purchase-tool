/**
 * @description
 * This service class handles operations related to Purchase__c and its lines:
 * - Search/filter purchases
 * - Save and delete purchases
 * - Manage purchase lines
 * - Automatically recalculate totals
 */
public with sharing class PurchaseService {

    @AuraEnabled(cacheable=true)
    public static List<Purchase__c> getPurchases(String searchTerm) {
        PurchaseToolUtils.requireNonEmpty(searchTerm, 'Search Term');
        String filter = '%' + String.escapeSingleQuotes(searchTerm) + '%';

        try {
            return [
                SELECT Id, Name, ClientId__c, ClientId__r.Name, 
                       GrandTotal__c, TotalItems__c
                FROM Purchase__c
                WHERE Name LIKE :filter OR ClientId__r.Name LIKE :filter
                ORDER BY CreatedDate DESC
                LIMIT 100
            ];
        } catch (Exception e) {
            PurchaseToolUtils.throwException('Error fetching purchases: ' + e.getMessage());
            return null;
        }
    }

    @AuraEnabled
    public static Purchase__c savePurchase(Purchase__c purchase) {
        validatePurchase(purchase);

        try {
            upsert purchase;
            return purchase;
        } catch (DmlException e) {
            PurchaseToolUtils.throwException('Failed to save Purchase: ' + e.getMessage());
            return null;
        }
    }

    private static void validatePurchase(Purchase__c purchase) {
        PurchaseToolUtils.requireNonNull(purchase.ClientId__c, 'Client');
        // Additional validation can be added here as needed
    }

    @AuraEnabled(cacheable=true)
    public static List<Purchase_Line__c> getPurchaseLines(Id purchaseId) {
        PurchaseToolUtils.requireNonNull(purchaseId, 'Purchase Id');

        try {
            return [
                SELECT Id, PurchaseId__c, ItemId__c, Amount__c, UnitCost__c
                FROM Purchase_Line__c
                WHERE PurchaseId__c = :purchaseId
                ORDER BY CreatedDate
            ];
        } catch (Exception e) {
            PurchaseToolUtils.throwException('Error fetching purchase lines: ' + e.getMessage());
            return null;
        }
    }

    @AuraEnabled
    public static void savePurchaseLines(List<Purchase_Line__c> lines) {
        if (lines == null || lines.isEmpty()) {
            PurchaseToolUtils.throwException('Purchase lines list cannot be empty.');
        }

        try {
            Id purchaseId;
            for (Purchase_Line__c line : lines) {
                PurchaseToolUtils.requireNonNull(line.PurchaseId__c, 'Purchase');
                PurchaseToolUtils.requireNonNull(line.ItemId__c, 'Item');
                PurchaseToolUtils.requirePositive(line.Amount__c, 'Amount');
                PurchaseToolUtils.requirePositive(line.UnitCost__c, 'Unit Cost');

                purchaseId = line.PurchaseId__c;
            }

            upsert lines;

            if (purchaseId != null) {
                recalcPurchaseTotal(purchaseId);
            }
        } catch (DmlException e) {
            PurchaseToolUtils.throwException('Failed to save Purchase Lines: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void deletePurchase(Id purchaseId) {
        PurchaseToolUtils.requireNonNull(purchaseId, 'Purchase Id');

        try {
            List<Purchase_Line__c> linesToDelete = [
                SELECT Id FROM Purchase_Line__c WHERE PurchaseId__c = :purchaseId
            ];

            delete linesToDelete;

            delete new Purchase__c(Id = purchaseId);
        } catch (DmlException e) {
            PurchaseToolUtils.throwException('Failed to delete Purchase: ' + e.getMessage());
        }
    }

    public static void recalcPurchaseTotal(Id purchaseId) {
        try {
            // Get all purchase lines for this purchase
            List<Purchase_Line__c> lines = [
                SELECT Amount__c, UnitCost__c
                FROM Purchase_Line__c
                WHERE PurchaseId__c = :purchaseId
            ];

            Decimal totalItems = 0;
            Decimal grandTotal = 0;
            
            for (Purchase_Line__c line : lines) {
                Decimal amount = line.Amount__c != null ? line.Amount__c : 0;
                Decimal unitCost = line.UnitCost__c != null ? line.UnitCost__c : 0;
                
                totalItems += amount;
                grandTotal += amount * unitCost;
            }

            update new Purchase__c(
                Id = purchaseId, 
                TotalItems__c = totalItems,
                GrandTotal__c = grandTotal
            );
        } catch (Exception e) {
            PurchaseToolUtils.throwException('Failed to recalculate Purchase total: ' + e.getMessage());
        }
    }
}
