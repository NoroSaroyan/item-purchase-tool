trigger PurchaseLineTrigger on Purchase_Line__c (after insert, after update, after delete, after undelete) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
            PurchaseLineHandler.recalcPurchasesTotals(
                PurchaseLineHandler.getPurchaseIds(Trigger.new)
            );
        }
        if (Trigger.isDelete) {
            PurchaseLineHandler.recalcPurchasesTotals(
                PurchaseLineHandler.getPurchaseIds(Trigger.old)
            );
        }
    }
}
