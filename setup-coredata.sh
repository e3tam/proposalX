#!/bin/bash

# Script to set up the Core Data model for ProposalCRM

echo "Setting up Core Data model for ProposalCRM"

# Get the project directory (assuming script is run from the project root)
PROJECT_DIR=$(pwd)
echo "Project directory: $PROJECT_DIR"

# Create model directory structure
MODEL_DIR="$PROJECT_DIR/ProposalCRM/ProposalCRM.xcdatamodeld/ProposalCRM.xcdatamodel"
mkdir -p "$MODEL_DIR"
echo "Created model directory: $MODEL_DIR"

# Create the contents XML file that defines the Core Data model
cat > "$MODEL_DIR/contents" << 'EOL'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<model type="com.apple.IDECoreDataModeler.DataModel" documentVersion="1.0" lastSavedToolsVersion="21513" systemVersion="23E214" minimumToolsVersion="Automatic" sourceLanguage="Swift" usedWithCloudKit="true" userDefinedModelVersionIdentifier="">
    <entity name="Customer" representedClassName="Customer" syncable="YES" codeGenerationType="class">
        <attribute name="address" optional="YES" attributeType="String"/>
        <attribute name="email" optional="YES" attributeType="String"/>
        <attribute name="id" attributeType="UUID" usesScalarValueType="NO"/>
        <attribute name="name" optional="YES" attributeType="String"/>
        <attribute name="phone" optional="YES" attributeType="String"/>
        <relationship name="proposals" optional="YES" toMany="YES" deletionRule="Nullify" destinationEntity="Proposal" inverseName="customer" inverseEntity="Proposal"/>
    </entity>
    <entity name="CustomTax" representedClassName="CustomTax" syncable="YES" codeGenerationType="class">
        <attribute name="amount" attributeType="Double" defaultValueString="0.0" usesScalarValueType="YES"/>
        <attribute name="id" attributeType="UUID" usesScalarValueType="NO"/>
        <attribute name="name" optional="YES" attributeType="String"/>
        <attribute name="rate" attributeType="Double" defaultValueString="0.0" usesScalarValueType="YES"/>
        <relationship name="proposal" optional="YES" maxCount="1" deletionRule="Nullify" destinationEntity="Proposal" inverseName="taxes" inverseEntity="Proposal"/>
    </entity>
    <entity name="Engineering" representedClassName="Engineering" syncable="YES" codeGenerationType="class">
        <attribute name="amount" attributeType="Double" defaultValueString="0.0" usesScalarValueType="YES"/>
        <attribute name="days" attributeType="Double" defaultValueString="0.0" usesScalarValueType="YES"/>
        <attribute name="description" optional="YES" attributeType="String"/>
        <attribute name="id" attributeType="UUID" usesScalarValueType="NO"/>
        <attribute name="rate" attributeType="Double" defaultValueString="0.0" usesScalarValueType="YES"/>
        <relationship name="proposal" optional="YES" maxCount="1" deletionRule="Nullify" destinationEntity="Proposal" inverseName="engineering" inverseEntity="Proposal"/>
    </entity>
    <entity name="Expense" representedClassName="Expense" syncable="YES" codeGenerationType="class">
        <attribute name="amount" attributeType="Double" defaultValueString="0.0" usesScalarValueType="YES"/>
        <attribute name="description" optional="YES" attributeType="String"/>
        <attribute name="id" attributeType="UUID" usesScalarValueType="NO"/>
        <relationship name="proposal" optional="YES" maxCount="1" deletionRule="Nullify" destinationEntity="Proposal" inverseName="expenses" inverseEntity="Proposal"/>
    </entity>
    <entity name="Item" representedClassName="Item" syncable="YES" codeGenerationType="class">
        <attribute name="timestamp" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
    </entity>
    <entity name="Product" representedClassName="Product" syncable="YES" codeGenerationType="class">
        <attribute name="category" optional="YES" attributeType="String"/>
        <attribute name="code" optional="YES" attributeType="String"/>
        <attribute name="desc" optional="YES" attributeType="String"/>
        <attribute name="id" attributeType="UUID" usesScalarValueType="NO"/>
        <attribute name="listPrice" attributeType="Double" defaultValueString="0.0" usesScalarValueType="YES"/>
        <attribute name="name" optional="YES" attributeType="String"/>
        <attribute name="partnerPrice" attributeType="Double" defaultValueString="0.0" usesScalarValueType="YES"/>
        <relationship name="proposalItems" optional="YES" toMany="YES" deletionRule="Nullify" destinationEntity="ProposalItem" inverseName="product" inverseEntity="ProposalItem"/>
    </entity>
    <entity name="Proposal" representedClassName="Proposal" syncable="YES" codeGenerationType="class">
        <attribute name="creationDate" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
        <attribute name="id" attributeType="UUID" usesScalarValueType="NO"/>
        <attribute name="notes" optional="YES" attributeType="String"/>
        <attribute name="number" optional="YES" attributeType="String"/>
        <attribute name="status" optional="YES" attributeType="String"/>
        <attribute name="totalAmount" attributeType="Double" defaultValueString="0.0" usesScalarValueType="YES"/>
        <relationship name="customer" optional="YES" maxCount="1" deletionRule="Nullify" destinationEntity="Customer" inverseName="proposals" inverseEntity="Customer"/>
        <relationship name="engineering" optional="YES" toMany="YES" deletionRule="Nullify" destinationEntity="Engineering" inverseName="proposal" inverseEntity="Engineering"/>
        <relationship name="expenses" optional="YES" toMany="YES" deletionRule="Nullify" destinationEntity="Expense" inverseName="proposal" inverseEntity="Expense"/>
        <relationship name="items" optional="YES" toMany="YES" deletionRule="Nullify" destinationEntity="ProposalItem" inverseName="proposal" inverseEntity="ProposalItem"/>
        <relationship name="taxes" optional="YES" toMany="YES" deletionRule="Nullify" destinationEntity="CustomTax" inverseName="proposal" inverseEntity="CustomTax"/>
    </entity>
    <entity name="ProposalItem" representedClassName="ProposalItem" syncable="YES" codeGenerationType="class">
        <attribute name="amount" attributeType="Double" defaultValueString="0.0" usesScalarValueType="YES"/>
        <attribute name="discount" attributeType="Double" defaultValueString="0.0" usesScalarValueType="YES"/>
        <attribute name="id" attributeType="UUID" usesScalarValueType="NO"/>
        <attribute name="quantity" attributeType="Double" defaultValueString="0.0" usesScalarValueType="YES"/>
        <attribute name="unitPrice" attributeType="Double" defaultValueString="0.0" usesScalarValueType="YES"/>
        <relationship name="product" optional="YES" maxCount="1" deletionRule="Nullify" destinationEntity="Product" inverseName="proposalItems" inverseEntity="Product"/>
        <relationship name="proposal" optional="YES" maxCount="1" deletionRule="Nullify" destinationEntity="Proposal" inverseName="items" inverseEntity="Proposal"/>
    </entity>
    <elements>
        <element name="Customer" positionX="-63" positionY="-18" width="128" height="119"/>
        <element name="CustomTax" positionX="695" positionY="134" width="128" height="104"/>
        <element name="Engineering" positionX="395" positionY="134" width="128" height="119"/>
        <element name="Expense" positionX="545" positionY="134" width="128" height="89"/>
        <element name="Item" positionX="-63" positionY="-18" width="128" height="44"/>
        <element name="Product" positionX="95" positionY="-18" width="128" height="149"/>
        <element name="Proposal" positionX="245" positionY="-18" width="128" height="194"/>
        <element name="ProposalItem" positionX="245" positionY="134" width="128" height="134"/>
    </elements>
</model>
EOL

echo "Created Core Data model contents file"

# Fix duplicate files
if [ -f "$PROJECT_DIR/ProposalCRM/ContentView.swift" ]; then
    echo "Removing duplicate ContentView.swift"
    rm "$PROJECT_DIR/ProposalCRM/ContentView.swift"
fi

if [ -f "$PROJECT_DIR/ProposalCRM/ProposalCRMApp.swift" ]; then
    echo "Removing duplicate ProposalCRMApp.swift"
    rm "$PROJECT_DIR/ProposalCRM/ProposalCRMApp.swift"
fi

# Comment out the duplicate PersistenceController in CoreDataModel.swift
if [ -f "$PROJECT_DIR/ProposalCRM/Models/CoreDataModel.swift" ]; then
    echo "Creating backup of CoreDataModel.swift"
    cp "$PROJECT_DIR/ProposalCRM/Models/CoreDataModel.swift" "$PROJECT_DIR/ProposalCRM/Models/CoreDataModel.swift.bak"
    
    echo "Commenting out PersistenceController in CoreDataModel.swift"
    sed -i '' 's/class PersistenceController {/\/\/ COMMENTED OUT TO AVOID DUPLICATION WITH Persistence.swift\n\/\*\nclass PersistenceController {/' "$PROJECT_DIR/ProposalCRM/Models/CoreDataModel.swift"
    
    # Add closing comment mark before extensions
    sed -i '' 's/extension PersistenceController {/\*\/\n\nextension PersistenceController {/' "$PROJECT_DIR/ProposalCRM/Models/CoreDataModel.swift"
fi

echo "All tasks completed successfully!"
echo
echo "Next steps:"
echo "1. Open your project in Xcode"
echo "2. Clean the project (Shift+Cmd+K)"
echo "3. Build the project (Cmd+B)"
echo "4. If any issues persist, check the console for specific errors"
