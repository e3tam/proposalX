#!/bin/bash

# Script to fix UUID default values in Core Data model

echo "Fixing UUID default values in Core Data model"

# Get the project directory (assuming script is run from the project root)
PROJECT_DIR=$(pwd)
echo "Project directory: $PROJECT_DIR"

# Path to the Core Data model file
MODEL_PATH="$PROJECT_DIR/ProposalCRM/ProposalCRM.xcdatamodeld/ProposalCRM.xcdatamodel/contents"

# Check if the model file exists
if [ ! -f "$MODEL_PATH" ]; then
    echo "Error: Core Data model file not found at $MODEL_PATH"
    exit 1
fi

# Create a backup of the original file
cp "$MODEL_PATH" "$MODEL_PATH.bak"
echo "Created backup at $MODEL_PATH.bak"

# Update the model file to add default values for all UUID attributes
# We're using sed to replace all UUID attributes without default values
# The pattern looks for attribute lines with type="UUID" but no defaultValueString attribute

# Helper function to update UUID attribute in model file
update_uuid_attribute() {
    local entity=$1
    sed -i '' "s/<attribute name=\"id\" attributeType=\"UUID\" usesScalarValueType=\"NO\"/<attribute name=\"id\" attributeType=\"UUID\" defaultValueString=\"\$\{UUID\}\" usesScalarValueType=\"NO\"/g" "$MODEL_PATH"
}

# Update each entity's ID attribute
echo "Adding default UUID values to all ID attributes..."
update_uuid_attribute "Customer"
update_uuid_attribute "Product"
update_uuid_attribute "Proposal"
update_uuid_attribute "ProposalItem"
update_uuid_attribute "Engineering"
update_uuid_attribute "Expense"
update_uuid_attribute "CustomTax"

echo "UUID default values have been added successfully!"
echo
echo "Next steps:"
echo "1. Open your project in Xcode"
echo "2. Clean the project (Shift+Cmd+K)"
echo "3. Build the project (Cmd+B)"
