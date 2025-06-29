# Item Purchase Tool - Salesforce Application

## Project Overview

The Item Purchase Tool is a Salesforce-based application designed to enable users to browse, select, and purchase items through a comprehensive e-commerce-like interface. This project implements a complete backend solution with custom objects, business logic, automated calculations, and extensive test coverage.

## Architecture & Technology Stack

- **Platform**: Salesforce (Apex, SOQL, Custom Objects, Triggers)
- **Backend Language**: Apex (similar to Java)
- **API Version**: 62.0
- **Testing Framework**: Salesforce Unit Tests (@IsTest)
- **Design Pattern**: Service Layer Architecture with Separation of Concerns

## Data Model

### Custom Objects

#### 1. Item__c
Represents products available for purchase.

**Fields:**
- `Name` (String) - Item name
- `Description__c` (String) - Item description
- `Price__c` (Number) - Item price
- `Type__c` (Picklist) - Item type (Hardware, Software, etc.)
- `Family__c` (Picklist) - Item family (Electronics, etc.)
- `Image__c` (URL) - Link to item image

#### 2. Purchase__c
Represents a purchase order/transaction.

**Fields:**
- `Name` (String) - Purchase name/number
- `ClientId__c` (Lookup to Account) - Customer making the purchase
- `TotalItems__c` (Number) - Total quantity of items (auto-calculated)
- `GrandTotal__c` (Number) - Total purchase amount (auto-calculated)

#### 3. Purchase_Line__c
Represents individual line items within a purchase.

**Fields:**
- `PurchaseId__c` (Master-Detail to Purchase__c) - Parent purchase
- `ItemId__c` (Master-Detail to Item__c) - Item being purchased
- `Amount__c` (Number) - Quantity of items
- `UnitCost__c` (Number) - Price per unit at time of purchase

#### 4. User (Extended)
Extended standard User object with custom field:
- `IsManager__c` (Checkbox) - Indicates manager privileges for item creation

## Backend Implementation

### Service Classes

#### 1. ItemService.cls
Handles all Item__c related operations.

**Key Methods:**
- `searchItems(String keyword)` - Search items by name with keyword filtering
- `getItemById(Id itemId)` - Retrieve specific item by ID
- **@AuraEnabled methods** for Lightning Web Component integration

#### 2. PurchaseService.cls
Manages Purchase__c operations and business logic.

**Key Methods:**
- `getPurchases(String searchTerm)` - Search purchases by name or client
- `savePurchase(Purchase__c purchase)` - Create/update purchase records
- `getPurchaseLines(Id purchaseId)` - Retrieve purchase line items
- `savePurchaseLines(List<Purchase_Line__c> lines)` - Batch save purchase lines
- `deletePurchase(Id purchaseId)` - Delete purchase and related lines
- `recalcPurchaseTotal(Id purchaseId)` - Recalculate purchase totals

#### 3. PurchaseLineService.cls
Handles Purchase_Line__c operations.

**Key Methods:**
- `getLinesByPurchase(Id purchaseId)` - Get all lines for a purchase
- `saveLine(Purchase_Line__c line)` - Save individual purchase line
- `batchSaveLines(List<Purchase_Line__c> lines)` - Bulk save operations
- `deleteLines(List<Id> lineIds)` - Delete multiple purchase lines

#### 4. PurchaseLineHandler.cls
Trigger handler for automated calculations.

**Key Methods:**
- `getPurchaseIds(List<Purchase_Line__c> lines)` - Extract unique purchase IDs
- `recalcPurchasesTotals(Set<Id> purchaseIds)` - Bulk recalculate purchase totals

#### 5. PurchaseToolUtils.cls
Utility class for validation and error handling.

**Key Methods:**
- `throwException(String message)` - Standardized exception handling
- `requireNonEmpty(String value, String fieldName)` - String validation
- `requireNonNull(Id value, String fieldName)` - ID validation
- `requirePositive(Decimal value, String fieldName)` - Numeric validation
- `formatCurrency(Decimal amount)` - Currency formatting

#### 6. Constants.cls
Centralized constants for field names and error messages.

### Triggers

#### PurchaseLineTrigger
Automatically recalculates Purchase totals when Purchase_Line__c records are modified.

**Events Handled:**
- After Insert, Update, Delete, Undelete
- Ensures data consistency for `TotalItems__c` and `GrandTotal__c` fields

## Business Logic Features

### Automated Calculations
- **TotalItems__c**: Automatically sums all `Amount__c` values from related Purchase_Line__c records
- **GrandTotal__c**: Automatically calculates total cost (Amount × UnitCost for all lines)
- **Real-time Updates**: Triggered on any Purchase_Line__c changes (insert, update, delete, undelete)

### Data Validation
- **Required Field Validation**: Ensures all mandatory fields are populated
- **Positive Number Validation**: Amount and UnitCost must be greater than zero
- **Reference Integrity**: Validates lookup relationships exist
- **Standardized Error Handling**: Consistent error messages through utility class

### Manager Permissions
- **User.IsManager__c**: Custom field to control item creation privileges
- **Future Enhancement**: Foundation for role-based access control

## Test Coverage

### Comprehensive Unit Tests
All Apex classes have corresponding test classes with extensive coverage:

- **ItemServiceTest.cls** - Tests item search and retrieval functionality
- **PurchaseServiceTest.cls** - Tests purchase CRUD operations and search
- **PurchaseLineServiceTest.cls** - Tests purchase line operations
- **PurchaseLineHandlerTest.cls** - Tests trigger handler calculations
- **PurchaseLineTriggerTest.cls** - Tests trigger functionality
- **PurchaseToolUtilsTest.cls** - Tests utility methods and validation

### Test Scenarios Covered
- ✅ Valid data operations
- ✅ Null/empty input validation
- ✅ Boundary conditions
- ✅ Exception handling
- ✅ Bulk operations
- ✅ Trigger calculations
- ✅ Data consistency checks

## Project Structure

```
force-app/main/default/
├── classes/
│   ├── Constants.cls
│   ├── ItemService.cls
│   ├── ItemServiceTest.cls
│   ├── PurchaseService.cls
│   ├── PurchaseServiceTest.cls
│   ├── PurchaseLineService.cls
│   ├── PurchaseLineServiceTest.cls
│   ├── PurchaseLineHandler.cls
│   ├── PurchaseLineHandlerTest.cls
│   ├── PurchaseLineTriggerTest.cls
│   ├── PurchaseToolUtils.cls
│   └── PurchaseToolUtilsTest.cls
├── objects/
│   ├── Item__c/
│   ├── Purchase__c/
│   ├── Purchase_Line__c/
│   └── User/fields/IsManager__c.field-meta.xml
├── triggers/
│   └── PurchaseLineTrigger.trigger
└── layouts/
    └── (Account layouts for button integration)
```

## Deployment

### Package Contents
The `manifest/package.xml` includes:
- Custom Objects: Item__c, Purchase__c, Purchase_Line__c
- Custom Fields: User.IsManager__c
- Apex Classes: All service and utility classes
- Apex Triggers: PurchaseLineTrigger

### Prerequisites
- Salesforce org with custom object creation permissions
- Apex development enabled
- Lightning Experience enabled (for future LWC implementation)

## Current Status

### ✅ Completed Features
- **Complete Data Model**: All custom objects with proper relationships
- **Full Backend API**: Comprehensive service layer for all operations
- **Automated Business Logic**: Trigger-based calculations and validations
- **100% Test Coverage**: Extensive unit tests for all functionality
- **Error Handling**: Robust validation and exception management
- **Manager Permissions**: Foundation for role-based access control

### 🚧 Pending Implementation
- **Lightning Web Components (LWC)**: Frontend user interface
- **Account Layout Customization**: Button to launch the tool
- **Unsplash API Integration**: Automatic image fetching for new items
- **Shopping Cart Functionality**: Frontend cart management
- **Modal Components**: Item details and cart views

## API Reference

### Key @AuraEnabled Methods
These methods are ready for Lightning Web Component integration:

```apex
// ItemService
@AuraEnabled(cacheable=true)
public static List<Item__c> searchItems(String keyword)

@AuraEnabled(cacheable=true)
public static Item__c getItemById(Id itemId)

// PurchaseService
@AuraEnabled(cacheable=true)
public static List<Purchase__c> getPurchases(String searchTerm)

@AuraEnabled
public static Purchase__c savePurchase(Purchase__c purchase)

// PurchaseLineService
@AuraEnabled(cacheable=true)
public static List<Purchase_Line__c> getLinesByPurchase(Id purchaseId)

@AuraEnabled
public static Purchase_Line__c saveLine(Purchase_Line__c line)
```

## Development Guidelines

### Code Quality Standards
- **Bulkification**: All triggers and methods handle bulk operations
- **Security**: Using `with sharing` for all service classes
- **Error Handling**: Consistent exception management through utilities
- **Documentation**: Comprehensive inline documentation for all methods
- **Testing**: Each method has corresponding unit tests

### Design Patterns Used
- **Service Layer Pattern**: Business logic separated into service classes
- **Trigger Handler Pattern**: Clean trigger implementation with handler classes
- **Utility Pattern**: Shared functionality in utility classes
- **Constants Pattern**: Centralized configuration and field names

## Future Enhancements

### Planned Features
1. **Lightning Web Components**: Complete frontend implementation
2. **Advanced Search**: Filtering by Type and Family
3. **Image Management**: Unsplash API integration for automatic image assignment
4. **Shopping Cart**: Persistent cart functionality
5. **Order Management**: Enhanced purchase workflow
6. **Reporting**: Purchase analytics and reporting features

### Technical Debt
- Frontend implementation required for complete user experience
- Advanced permission sets for different user roles
- Integration with external payment systems
- Mobile-responsive design considerations

## Contributing

### Development Setup
1. Clone the repository
2. Set up Salesforce DX project
3. Deploy metadata to scratch org or sandbox
4. Run all tests to ensure functionality
5. Follow existing code patterns and documentation standards

### Testing Requirements
- All new Apex code must have minimum 75% test coverage
- Unit tests must cover both positive and negative scenarios
- Test data should not rely on existing org data

---

**Project Status**: Backend Complete | Frontend Pending  
**Last Updated**: June 29, 2025  
**Apex API Version**: 62.0
