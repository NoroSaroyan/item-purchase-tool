public class Constants {
    // Object API Names
    public static final String PURCHASE_OBJECT = 'Purchase__c';
    public static final String PURCHASE_LINE_OBJECT = 'PurchaseLine__c';
    public static final String ITEM_OBJECT = 'Item__c';

    // Purchase__c fields
    public static final String PURCHASE_NAME = 'Name';
    public static final String PURCHASE_STATUS = 'Status__c';
    public static final String PURCHASE_TOTAL_AMOUNT = 'Total_Amount__c';
    public static final String PURCHASE_DATE = 'Purchase_Date__c';
    public static final String PURCHASE_OWNER = 'OwnerId';

    // PurchaseLine__c fields
    public static final String PURCHASE_LINE_PURCHASE = 'Purchase__c';
    public static final String PURCHASE_LINE_ITEM = 'Item__c';
    public static final String PURCHASE_LINE_QUANTITY = 'Quantity__c';
    public static final String PURCHASE_LINE_UNIT_PRICE = 'Unit_Price__c';
    public static final String PURCHASE_LINE_TOTAL_PRICE = 'Total_Price__c';

    // Item__c fields
    public static final String ITEM_NAME = 'Name';
    public static final String ITEM_PRICE = 'Price__c';
    public static final String ITEM_AVAILABLE_QUANTITY = 'Available_Quantity__c';

    // Common Status values
    public static final String STATUS_NEW = 'New';
    public static final String STATUS_PROCESSING = 'Processing';
    public static final String STATUS_COMPLETED = 'Completed';

    // Error messages
    public static final String ERR_INVALID_QUANTITY = 'Quantity must be a positive number.';
    public static final String ERR_ITEM_NOT_AVAILABLE = 'Requested item is not available in the required quantity.';
    public static final String ERR_PURCHASE_NOT_FOUND = 'Purchase record not found.';
    public static final String ERR_PURCHASE_LINE_NOT_FOUND = 'Purchase Line record not found.';
    public static final String ERR_ITEM_NOT_FOUND = 'Item record not found.';
}
