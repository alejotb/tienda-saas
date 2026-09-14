# stock-update Specification

## Purpose
Managing inventory updates via a batch processing modal, including product search and quick creation.

## Requirements

### Requirement: Search Products
The system MUST allow searching for existing products by name to add them to the stock update batch.

#### Scenario: Successful product search
- GIVEN the stock update modal is open
- WHEN the user types "Coca Cola" in the search bar
- THEN the system SHALL query Supabase for products matching the name
- AND display the results in the search list

### Requirement: Add to Batch
The system MUST allow adding products from the search results to the batch queue with a specific quantity and operation type (CARGA/SALIDA).

#### Scenario: Add product to batch
- GIVEN search results are displayed
- WHEN the user clicks the "Add" button for a product
- THEN the system SHALL add the product to the `batchQueue` with quantity 1
- AND the UI MUST update to show the product in the "Cola de Carga"

### Requirement: Quick Create Product
The system SHALL allow creating a new product quickly if it doesn't exist in the database.

#### Scenario: Quick create product
- GIVEN the "Create Product" form is visible
- WHEN the user provides a name and price and clicks "Crear y Agregar"
- THEN the system MUST generate a real UUID for the new product
- AND insert it into the `productos` table in Supabase
- AND add the newly created product to the `batchQueue`

### Requirement: Process Batch
The system MUST process all items in the batch queue using the `update_product_stock` RPC call.

#### Scenario: Process batch successfully
- GIVEN the `batchQueue` is not empty
- WHEN the user clicks "Confirmar Carga"
- THEN the system SHALL iterate through the queue and call the `update_product_stock` RPC for each item
- AND display a success message upon completion
- AND clear the `batchQueue`
