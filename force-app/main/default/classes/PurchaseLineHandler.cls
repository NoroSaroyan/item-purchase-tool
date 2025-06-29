public class PurchaseLineHandler {

    /**
     * Extracts all unique PurchaseId__c values from a list of Purchase_Line__c records
     */
    public static Set<Id> getPurchaseIds(List<Purchase_Line__c> lines) {
        Set<Id> purchaseIds = new Set<Id>();
        for (Purchase_Line__c line : lines) {
            if (line.PurchaseId__c != null) {
                purchaseIds.add(line.PurchaseId__c);
            }
        }
        return purchaseIds;
    }

    /**
     * Recalculates TotalItems__c and GrandTotal__c for each Purchase__c
     * based on current Purchase_Line__c child records
     */
    public static void recalcPurchasesTotals(Set<Id> purchaseIds) {
        if (purchaseIds == null || purchaseIds.isEmpty()) {
            return;
        }

        // Step 1: Load all purchase lines for given purchase IDs
        List<Purchase_Line__c> lines = [
            SELECT PurchaseId__c, Amount__c, UnitCost__c
            FROM Purchase_Line__c
            WHERE PurchaseId__c IN :purchaseIds
        ];

        // Step 2: Prepare maps to hold calculated totals
        Map<Id, Decimal> totalItemsMap = new Map<Id, Decimal>();
        Map<Id, Decimal> grandTotalMap = new Map<Id, Decimal>();

        // Step 3: Calculate totals per PurchaseId__c
        for (Purchase_Line__c line : lines) {
            Id pId = line.PurchaseId__c;
            Decimal amount = line.Amount__c != null ? line.Amount__c : 0;
            Decimal unitCost = line.UnitCost__c != null ? line.UnitCost__c : 0;
            Decimal lineTotal = amount * unitCost;

            totalItemsMap.put(pId, totalItemsMap.get(pId) != null ? totalItemsMap.get(pId) + amount : amount);
            grandTotalMap.put(pId, grandTotalMap.get(pId) != null ? grandTotalMap.get(pId) + lineTotal : lineTotal);
        }

        // Step 4: Create list of purchases to update
        List<Purchase__c> purchasesToUpdate = new List<Purchase__c>();

        for (Id pId : purchaseIds) {
            purchasesToUpdate.add(new Purchase__c(
                Id = pId,
                TotalItems__c = totalItemsMap.get(pId) != null ? totalItemsMap.get(pId) : 0,
                GrandTotal__c = grandTotalMap.get(pId) != null ? grandTotalMap.get(pId) : 0
            ));
        }

        // Step 5: Update in bulk
        if (!purchasesToUpdate.isEmpty()) {
            try {
                update purchasesToUpdate;
            } catch (DmlException e) {
                throw new AuraHandledException('Failed to update Purchase totals: ' + e.getMessage());
            }
        }
    }
}
