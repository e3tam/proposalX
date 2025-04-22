#!/bin/bash

# Script to update Core Data model with Task and Activity entities
# Usage: ./update_core_data_model.sh path/to/ProposalCRM.xcdatamodeld

# Check if the model path is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 path/to/ProposalCRM.xcdatamodeld"
    exit 1
fi

MODEL_PATH=$1
LATEST_MODEL=$(ls -t "$MODEL_PATH"/*.xcdatamodel | head -1)

if [ ! -d "$LATEST_MODEL" ]; then
    echo "Error: Could not find Core Data model at $MODEL_PATH"
    exit 1
fi

echo "Found model at: $LATEST_MODEL"

# Create a backup
BACKUP_DIR="$MODEL_PATH/backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r "$LATEST_MODEL"/* "$BACKUP_DIR/"
echo "Created backup at: $BACKUP_DIR"

# Create a Python script to modify the contents.xml file
cat > update_model.py << 'EOF'
#!/usr/bin/env python3
import sys
import xml.etree.ElementTree as ET
import os

def add_task_activity_entities(model_path):
    contents_path = os.path.join(model_path, 'contents')
    tree = ET.parse(contents_path)
    root = tree.getroot()
    
    # Check if entities already exist
    existing_entities = [e.get('name') for e in root.findall('./entity')]
    
    if 'Task' not in existing_entities:
        # Add Task entity
        task_entity = ET.SubElement(root, 'entity')
        task_entity.set('name', 'Task')
        task_entity.set('representedClassName', 'Task')
        task_entity.set('syncable', 'YES')
        task_entity.set('codeGenerationType', 'class')
        
        # Add Task attributes
        attributes = [
            ('id', 'UUID', 'NO'),
            ('title', 'String', 'YES'),
            ('desc', 'String', 'YES'),
            ('dueDate', 'Date', 'YES'),
            ('creationDate', 'Date', 'YES'),
            ('priority', 'String', 'YES'),
            ('status', 'String', 'YES'),
            ('notes', 'String', 'YES')
        ]
        
        for attr_name, attr_type, optional in attributes:
            attribute = ET.SubElement(task_entity, 'attribute')
            attribute.set('name', attr_name)
            attribute.set('optional', optional)
            attribute.set('attributeType', attr_type)
            if attr_type == 'UUID':
                attribute.set('usesScalarValueType', 'NO')
        
        # Add Task to Proposal relationship
        task_proposal_rel = ET.SubElement(task_entity, 'relationship')
        task_proposal_rel.set('name', 'proposal')
        task_proposal_rel.set('optional', 'YES')
        task_proposal_rel.set('maxCount', '1')
        task_proposal_rel.set('deletionRule', 'Nullify')
        task_proposal_rel.set('destinationEntity', 'Proposal')
        task_proposal_rel.set('inverseName', 'tasks')
        task_proposal_rel.set('inverseEntity', 'Proposal')
        
        print("Added Task entity")
    
    if 'Activity' not in existing_entities:
        # Add Activity entity
        activity_entity = ET.SubElement(root, 'entity')
        activity_entity.set('name', 'Activity')
        activity_entity.set('representedClassName', 'Activity')
        activity_entity.set('syncable', 'YES')
        activity_entity.set('codeGenerationType', 'class')
        
        # Add Activity attributes
        attributes = [
            ('id', 'UUID', 'NO'),
            ('timestamp', 'Date', 'YES'),
            ('type', 'String', 'YES'),
            ('description', 'String', 'YES'),
            ('userPerformed', 'String', 'YES'),
            ('details', 'String', 'YES')
        ]
        
        for attr_name, attr_type, optional in attributes:
            attribute = ET.SubElement(activity_entity, 'attribute')
            attribute.set('name', attr_name)
            attribute.set('optional', optional)
            attribute.set('attributeType', attr_type)
            if attr_type == 'UUID':
                attribute.set('usesScalarValueType', 'NO')
        
        # Add Activity to Proposal relationship
        activity_proposal_rel = ET.SubElement(activity_entity, 'relationship')
        activity_proposal_rel.set('name', 'proposal')
        activity_proposal_rel.set('optional', 'YES')
        activity_proposal_rel.set('maxCount', '1')
        activity_proposal_rel.set('deletionRule', 'Nullify')
        activity_proposal_rel.set('destinationEntity', 'Proposal')
        activity_proposal_rel.set('inverseName', 'activities')
        activity_proposal_rel.set('inverseEntity', 'Proposal')
        
        print("Added Activity entity")
    
    # Add relationships to Proposal entity if it exists
    proposal_entity = None
    for entity in root.findall('./entity'):
        if entity.get('name') == 'Proposal':
            proposal_entity = entity
            break
    
    if proposal_entity is not None:
        # Check if relationships already exist
        existing_relationships = [r.get('name') for r in proposal_entity.findall('./relationship')]
        
        if 'tasks' not in existing_relationships:
            # Add tasks relationship to Proposal
            proposal_tasks_rel = ET.SubElement(proposal_entity, 'relationship')
            proposal_tasks_rel.set('name', 'tasks')
            proposal_tasks_rel.set('optional', 'YES')
            proposal_tasks_rel.set('toMany', 'YES')
            proposal_tasks_rel.set('deletionRule', 'Nullify')
            proposal_tasks_rel.set('destinationEntity', 'Task')
            proposal_tasks_rel.set('inverseName', 'proposal')
            proposal_tasks_rel.set('inverseEntity', 'Task')
            print("Added tasks relationship to Proposal entity")
        
        if 'activities' not in existing_relationships:
            # Add activities relationship to Proposal
            proposal_activities_rel = ET.SubElement(proposal_entity, 'relationship')
            proposal_activities_rel.set('name', 'activities')
            proposal_activities_rel.set('optional', 'YES')
            proposal_activities_rel.set('toMany', 'YES')
            proposal_activities_rel.set('deletionRule', 'Nullify')
            proposal_activities_rel.set('destinationEntity', 'Activity')
            proposal_activities_rel.set('inverseName', 'proposal')
            proposal_activities_rel.set('inverseEntity', 'Activity')
            print("Added activities relationship to Proposal entity")
    
    # Save the updated model
    tree.write(contents_path)
    print("Core Data model updated successfully")
    return True

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python update_model.py /path/to/model.xcdatamodel")
        sys.exit(1)
    
    model_path = sys.argv[1]
    if not os.path.exists(model_path):
        print(f"Error: Model path does not exist: {model_path}")
        sys.exit(1)
    
    if add_task_activity_entities(model_path):
        print("Model updated successfully!")
    else:
        print("Failed to update model")
        sys.exit(1)
EOF

chmod +x update_model.py

# Run the Python script to update the model
python3 ./update_model.py "$LATEST_MODEL"

# If mogenerator is installed, use it to generate classes
if command -v mogenerator &> /dev/null; then
    echo "Generating model classes with mogenerator..."
    MODEL_NAME=$(basename "$MODEL_PATH" .xcdatamodeld)
    mogenerator --model "$LATEST_MODEL" --output-dir "./Generated" --swift --template-var arc=true
    echo "Generated model classes in ./Generated directory"
else
    echo "mogenerator not found - skipping class generation"
    echo "If you want to generate classes, install mogenerator with: brew install mogenerator"
fi

# Create a Swift file with model extensions
cat > TaskActivityExtensions.swift << 'EOF'
// TaskActivityExtensions.swift
// Extensions for Task and Activity entities

import Foundation
import CoreData
import SwiftUI

extension Task {
    var formattedDueDate: String {
        guard let date = dueDate else {
            return "No due date"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var priorityColor: Color {
        switch priority {
        case "High": return .red
        case "Medium": return .orange
        case "Low": return .blue
        default: return .gray
        }
    }
    
    var statusColor: Color {
        switch status {
        case "New": return .blue
        case "In Progress": return .orange
        case "Completed": return .green
        case "Deferred": return .gray
        default: return .gray
        }
    }
    
    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return dueDate < Date() && status != "Completed"
    }
}

extension Activity {
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp ?? Date())
    }
    
    var typeIcon: String {
        switch type {
        case "Created": return "plus.circle"
        case "Updated": return "pencil.circle"
        case "StatusChanged": return "arrow.triangle.swap"
        case "CommentAdded": return "text.bubble"
        case "TaskAdded": return "checkmark.circle"
        case "TaskCompleted": return "checkmark.circle.fill"
        case "DocumentAdded": return "doc.fill"
        default: return "circle"
        }
    }
    
    var typeColor: Color {
        switch type {
        case "Created": return .green
        case "Updated": return .blue
        case "StatusChanged": return .orange
        case "CommentAdded": return .purple
        case "TaskAdded": return .blue
        case "TaskCompleted": return .green
        case "DocumentAdded": return .gray
        default: return .gray
        }
    }
}

extension Proposal {
    var tasksArray: [Task] {
        let set = tasks as? Set<Task> ?? []
        return set.sorted {
            if $0.status == "Completed" && $1.status != "Completed" {
                return false
            } else if $0.status != "Completed" && $1.status == "Completed" {
                return true
            } else if let date0 = $0.dueDate, let date1 = $1.dueDate {
                return date0 < date1
            } else if $0.dueDate != nil && $1.dueDate == nil {
                return true
            } else if $0.dueDate == nil && $1.dueDate != nil {
                return false
            } else {
                return $0.creationDate ?? Date() > $1.creationDate ?? Date()
            }
        }
    }
    
    var activitiesArray: [Activity] {
        let set = activities as? Set<Activity> ?? []
        return set.sorted {
            $0.timestamp ?? Date() > $1.timestamp ?? Date()
        }
    }
    
    var pendingTasksCount: Int {
        return tasksArray.filter { $0.status != "Completed" }.count
    }
    
    var hasOverdueTasks: Bool {
        return tasksArray.contains { $0.isOverdue }
    }
    
    var lastActivity: Activity? {
        return activitiesArray.first
    }
}
EOF

echo "Created TaskActivityExtensions.swift"
echo ""
echo "Core Data model update completed successfully!"
echo "Please add the extensions file to your Xcode project"
echo "You may need to restart Xcode for changes to take effect"
