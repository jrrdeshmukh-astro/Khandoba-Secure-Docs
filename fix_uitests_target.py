#!/usr/bin/env python3
"""
Fix UITests target configuration by adding fileSystemSynchronizedGroups.
"""

import re
import sys
from pathlib import Path
import random
import string

PROJECT_FILE = Path("Khandoba Secure Docs.xcodeproj/project.pbxproj")

# UUIDs from project
UITESTS_TARGET_UUID = "24FB388C2EDF354C00BA1227"
UITESTS_SOURCES_PHASE_UUID = "24FB38892EDF354C00BA1227"

def generate_uuid():
    """Generate a 24-character hex UUID for Xcode project format."""
    chars = string.ascii_uppercase + string.digits
    return ''.join(random.choices(chars, k=24))

def main():
    print("🔧 Fixing UITests target configuration...")
    
    # Read project file
    content = PROJECT_FILE.read_text()
    original_content = content
    
    # Step 1: Create PBXFileSystemSynchronizedRootGroup for UITests folder
    uitests_folder_uuid = generate_uuid()
    uitests_exceptions_uuid = generate_uuid()
    
    # Check if UITests folder group already exists
    uitests_folder_match = re.search(r'(\w+) /\* Khandoba Secure DocsUITests \*/ = \{.*?isa = PBXFileSystemSynchronizedRootGroup', content, re.DOTALL)
    if uitests_folder_match:
        uitests_folder_uuid = uitests_folder_match.group(1)
        print(f"✓ Found existing UITests folder UUID: {uitests_folder_uuid}")
    else:
        # Create new UITests folder group
        uitests_folder_section = f"""\t\t{uitests_folder_uuid} /* Khandoba Secure DocsUITests */ = {{
\t\t\tisa = PBXFileSystemSynchronizedRootGroup;
\t\t\texceptions = (
\t\t\t\t{uitests_exceptions_uuid} /* Exceptions for "Khandoba Secure DocsUITests" folder in "Khandoba Secure DocsUITests" target */,
\t\t\t);
\t\t\tpath = "Khandoba Secure DocsUITests";
\t\t\tsourceTree = "<group>";
\t\t}};"""
        
        # Insert before "/* End PBXFileSystemSynchronizedRootGroup section */"
        end_marker = "/* End PBXFileSystemSynchronizedRootGroup section */"
        content = content.replace(end_marker, uitests_folder_section + "\n" + end_marker)
        print(f"✓ Created UITests folder group: {uitests_folder_uuid}")
    
    # Step 2: Add UITests folder to main group children
    main_group_pattern = r'(24FB38692EDF354B00BA1227 = \{.*?children = \()([^)]+)(\);.*?sourceTree = "<group>";)'
    main_group_match = re.search(main_group_pattern, content, re.DOTALL)
    if main_group_match:
        children = main_group_match.group(2)
        if uitests_folder_uuid not in children:
            # Add UITests folder to children
            new_children = children.rstrip() + f"\n\t\t\t\t{uitests_folder_uuid} /* Khandoba Secure DocsUITests */,"
            content = content.replace(main_group_match.group(0), 
                                    main_group_match.group(1) + new_children + main_group_match.group(3))
            print(f"✓ Added UITests folder to main group")
    
    # Step 3: Add fileSystemSynchronizedGroups to UITests target
    uitests_target_pattern = rf'({UITESTS_TARGET_UUID} /\* Khandoba Secure DocsUITests \*/ = \{{[^}}]*name = "Khandoba Secure DocsUITests";[^}}]*)'
    
    uitests_target_match = re.search(uitests_target_pattern, content, re.DOTALL)
    if uitests_target_match:
        target_section = uitests_target_match.group(1)
        # Add fileSystemSynchronizedGroups before productName
        if "fileSystemSynchronizedGroups" not in target_section:
            new_section = target_section.replace(
                'name = "Khandoba Secure DocsUITests";',
                f'fileSystemSynchronizedGroups = (\n\t\t\t\t{uitests_folder_uuid} /* Khandoba Secure DocsUITests */,\n\t\t\t);\n\t\t\tname = "Khandoba Secure DocsUITests";'
            )
            content = content.replace(target_section, new_section)
            print(f"✓ Added fileSystemSynchronizedGroups to UITests target")
    
    # Write back if changed
    if content != original_content:
        # Create backup
        backup_file = PROJECT_FILE.with_suffix('.pbxproj.backup_before_uitests_fix')
        backup_file.write_text(original_content)
        print(f"✓ Created backup: {backup_file.name}")
        
        # Write updated content
        PROJECT_FILE.write_text(content)
        print("✅ UITests target configuration fixed!")
        print("\nNext steps:")
        print("1. Open Xcode (close if already open to reload project)")
        print("2. Clean build folder (⌘⇧K)")
        print("3. Build UITests target")
        print("4. Run tests")
        return 0
    else:
        print("⚠️  No changes needed - configuration may already be correct")
        return 1

if __name__ == "__main__":
    sys.exit(main())

