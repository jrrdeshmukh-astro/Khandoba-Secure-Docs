#!/usr/bin/env python3
"""
Fix test target configuration by adding fileSystemSynchronizedGroups
and Testing.framework linkage.
"""

import re
import sys
from pathlib import Path
import random
import string

PROJECT_FILE = Path("Khandoba Secure Docs.xcodeproj/project.pbxproj")

# UUIDs from project
TEST_TARGET_UUID = "24FB38822EDF354C00BA1227"
TEST_FRAMEWORKS_PHASE_UUID = "24FB38802EDF354C00BA1227"
MAIN_APP_FOLDER_UUID = "24FB38742EDF354B00BA1227"

def generate_uuid():
    """Generate a 24-character hex UUID for Xcode project format."""
    chars = string.ascii_uppercase + string.digits
    return ''.join(random.choices(chars, k=24))

def main():
    print("🔧 Fixing test target configuration...")
    
    # Read project file
    content = PROJECT_FILE.read_text()
    original_content = content
    
    # Step 1: Create PBXFileSystemSynchronizedRootGroup for test folder
    test_folder_uuid = generate_uuid()
    test_exceptions_uuid = generate_uuid()
    
    # Check if test folder group already exists
    if "Khandoba Secure DocsTests" in content and "PBXFileSystemSynchronizedRootGroup" in content:
        # Find existing test folder UUID
        test_folder_match = re.search(r'(\w+) /\* Khandoba Secure DocsTests \*/ = \{.*?isa = PBXFileSystemSynchronizedRootGroup', content, re.DOTALL)
        if test_folder_match:
            test_folder_uuid = test_folder_match.group(1)
            print(f"✓ Found existing test folder UUID: {test_folder_uuid}")
        else:
            # Create new test folder group
            test_folder_section = f"""\t\t{test_folder_uuid} /* Khandoba Secure DocsTests */ = {{
\t\t\tisa = PBXFileSystemSynchronizedRootGroup;
\t\t\texceptions = (
\t\t\t\t{test_exceptions_uuid} /* Exceptions for "Khandoba Secure DocsTests" folder in "Khandoba Secure DocsTests" target */,
\t\t\t);
\t\t\tpath = "Khandoba Secure DocsTests";
\t\t\tsourceTree = "<group>";
\t\t}};"""
            
            # Insert before "/* End PBXFileSystemSynchronizedRootGroup section */"
            end_marker = "/* End PBXFileSystemSynchronizedRootGroup section */"
            content = content.replace(end_marker, test_folder_section + "\n" + end_marker)
            print(f"✓ Created test folder group: {test_folder_uuid}")
    else:
        # Create new test folder group
        test_folder_section = f"""\t\t{test_folder_uuid} /* Khandoba Secure DocsTests */ = {{
\t\t\tisa = PBXFileSystemSynchronizedRootGroup;
\t\t\texceptions = (
\t\t\t\t{test_exceptions_uuid} /* Exceptions for "Khandoba Secure DocsTests" folder in "Khandoba Secure DocsTests" target */,
\t\t\t);
\t\t\tpath = "Khandoba Secure DocsTests";
\t\t\tsourceTree = "<group>";
\t\t}};"""
        
        # Insert before "/* End PBXFileSystemSynchronizedRootGroup section */"
        end_marker = "/* End PBXFileSystemSynchronizedRootGroup section */"
        content = content.replace(end_marker, test_folder_section + "\n" + end_marker)
        print(f"✓ Created test folder group: {test_folder_uuid}")
    
    # Step 2: Add test folder to main group children
    main_group_pattern = r'(24FB38692EDF354B00BA1227 = \{.*?children = \()([^)]+)(\);.*?sourceTree = "<group>";)'
    main_group_match = re.search(main_group_pattern, content, re.DOTALL)
    if main_group_match:
        children = main_group_match.group(2)
        if test_folder_uuid not in children:
            # Add test folder to children
            new_children = children.rstrip() + f"\n\t\t\t\t{test_folder_uuid} /* Khandoba Secure DocsTests */,"
            content = content.replace(main_group_match.group(0), 
                                    main_group_match.group(1) + new_children + main_group_match.group(3))
            print(f"✓ Added test folder to main group")
    
    # Step 3: Add fileSystemSynchronizedGroups to test target
    test_target_pattern = rf'({TEST_TARGET_UUID} /\* Khandoba Secure DocsTests \*/ = \{{[^}}]*buildRules = \([^}}]*\);[^}}]*dependencies = \([^}}]*\);[^}}]*name = "Khandoba Secure DocsTests";[^}}]*)'
    
    if "fileSystemSynchronizedGroups" not in content or f'{TEST_TARGET_UUID}.*fileSystemSynchronizedGroups' not in content:
        # Find test target and add fileSystemSynchronizedGroups
        test_target_match = re.search(rf'({TEST_TARGET_UUID} /\* Khandoba Secure DocsTests \*/ = \{{[^}}]*name = "Khandoba Secure DocsTests";[^}}]*)', content, re.DOTALL)
        if test_target_match:
            target_section = test_target_match.group(1)
            # Add fileSystemSynchronizedGroups before productName
            if "fileSystemSynchronizedGroups" not in target_section:
                new_section = target_section.replace(
                    'name = "Khandoba Secure DocsTests";',
                    f'fileSystemSynchronizedGroups = (\n\t\t\t\t{test_folder_uuid} /* Khandoba Secure DocsTests */,\n\t\t\t);\n\t\t\tname = "Khandoba Secure DocsTests";'
                )
                content = content.replace(target_section, new_section)
                print(f"✓ Added fileSystemSynchronizedGroups to test target")
    
    # Step 4: Add Testing.framework to Frameworks build phase
    frameworks_phase_pattern = rf'({TEST_FRAMEWORKS_PHASE_UUID} /\* Frameworks \*/ = \{{[^}}]*files = \()([^)]*)(\);.*?runOnlyForDeploymentPostprocessing = 0;)'
    frameworks_match = re.search(frameworks_phase_pattern, content, re.DOTALL)
    
    if frameworks_match:
        files_section = frameworks_match.group(2)
        if "Testing.framework" not in files_section:
            testing_framework_uuid = generate_uuid()
            # Add Testing.framework reference
            new_files = files_section.rstrip()
            if new_files.strip():
                new_files += f"\n\t\t\t\t{testing_framework_uuid} /* Testing.framework in Frameworks */,"
            else:
                new_files = f"\n\t\t\t\t{testing_framework_uuid} /* Testing.framework in Frameworks */,"
            
            content = content.replace(frameworks_match.group(0),
                                    frameworks_match.group(1) + new_files + frameworks_match.group(3))
            
            # Add PBXBuildFile entry for Testing.framework
            build_file_section = f"""\t\t{testing_framework_uuid} /* Testing.framework in Frameworks */ = {{
\t\t\tisa = PBXBuildFile;
\t\t\tproductReference = {generate_uuid()} /* Testing */;
\t\t\tsettings = {{
\t\t\t\tATTRIBUTES = (
\t\t\t\t\tWeak,
\t\t\t\t);
\t\t\t}};
\t\t}};"""
            
            # Find PBXBuildFile section and add entry
            build_file_marker = "/* Begin PBXBuildFile section */"
            if build_file_marker in content:
                content = content.replace(build_file_marker, build_file_marker + "\n" + build_file_section)
            
            # Add product reference
            product_ref_section = f"""\t\t{generate_uuid()} /* Testing */ = {{
\t\t\tisa = XCSwiftPackageProductDependency;
\t\t\tpackage = {generate_uuid()} /* XCRemoteSwiftPackageReference "swift-testing" */;
\t\t\tproductName = Testing;
\t\t}};"""
            
            print(f"✓ Added Testing.framework to Frameworks build phase")
    
    # Write back if changed
    if content != original_content:
        # Create backup
        backup_file = PROJECT_FILE.with_suffix('.pbxproj.backup_before_test_fix')
        backup_file.write_text(original_content)
        print(f"✓ Created backup: {backup_file.name}")
        
        # Write updated content
        PROJECT_FILE.write_text(content)
        print("✅ Test target configuration fixed!")
        print("\nNext steps:")
        print("1. Open Xcode (close if already open to reload project)")
        print("2. Clean build folder (⌘⇧K)")
        print("3. Build test target")
        print("4. Run tests")
        return 0
    else:
        print("⚠️  No changes needed - configuration may already be correct")
        return 1

if __name__ == "__main__":
    sys.exit(main())

