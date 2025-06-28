public class Constants {
    // Object API Names
    public static final String PURCHASE_OBJECT = 'Purchase__c';
    public static final String PURCHASE_LINE_OBJECT = 'PurchaseLine__c';
    public static final String ITEM_OBJECT = 'Item__c';

    // Purchase__c Fields
    public static final String PURCHASE_NAME = 'Name';
    public static final String PURCHASE_CLIENT = 'ClientId__c';
    public static final String PURCHASE_GRAND_TOTAL = 'GrandTotal__c';
    public static final String PURCHASE_TOTAL_ITEMS = 'TotalItems__c';
    public static final String PURCHASE_OWNER = 'OwnerId';

    // PurchaseLine__c Fields
    public static final String PURCHASE_LINE_NAME = 'Name';
    public static final String PURCHASE_LINE_PURCHASE = 'PurchaseId__c';
    public static final String PURCHASE_LINE_ITEM = 'ItemId__c';
    public static final String PURCHASE_LINE_AMOUNT = 'Amount__c';
    public static final String PURCHASE_LINE_UNIT_COST = 'UnitCost__c';

    // Item__c Fields
    public static final String ITEM_NAME = 'Name';
    public static final String ITEM_DESCRIPTION = 'Description__c';
    public static final String ITEM_FAMILY = 'Family__c';
    public static final String ITEM_IMAGE = 'Image__c';
    public static final String ITEM_PRICE = 'Price__c';
    public static final String ITEM_TYPE = 'Type__c';

    // Error Messages
    public static final String ERR_INVALID_AMOUNT = 'Amount must be a positive number.';
    public static final String ERR_ITEM_NOT_FOUND = 'Item record not found.';
    public static final String ERR_PURCHASE_NOT_FOUND = 'Purchase record not found.';
    public static final String ERR_PURCHASE_LINE_NOT_FOUND = 'Purchase Line record not found.';
}
