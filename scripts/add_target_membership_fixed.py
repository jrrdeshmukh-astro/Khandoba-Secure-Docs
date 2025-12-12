#!/usr/bin/env python3
"""
Add target membership for shared files to iMessage extension target.
This project uses PBXFileSystemSynchronizedRootGroup, so we need to:
1. Add exception set for the extension target
2. Add exception to "Khandoba Secure Docs" folder
3. Add "Khandoba Secure Docs" folder to extension target's fileSystemSynchronizedGroups
"""

import re
import sys
from pathlib import Path

PROJECT_ROOT = Path("/Users/jaideshmukh/Desktop/Khandoba Secure Docs")
PROJECT_FILE = PROJECT_ROOT / "Khandoba Secure Docs.xcodeproj/project.pbxproj"

# Extension target UUID (from project.pbxproj)
EXTENSION_TARGET_UUID = "24807B7C2EEB52F1008E3E1E"
EXTENSION_TARGET_NAME = "KhandobaSecureDocsMessageApp MessagesExtension"

# Main app folder UUID
MAIN_APP_FOLDER_UUID = "24FB38742EDF354B00BA1227"
MAIN_APP_FOLDER_NAME = "Khandoba Secure Docs"

def generate_uuid():
    """Generate a 24-character hex UUID for Xcode project format."""
    import random
    import string
    chars = string.ascii_uppercase + string.digits
    return ''.join(random.choices(chars, k=24))

def main():
    print("🔧 Adding target membership for shared files...")
    print("   Using PBXFileSystemSynchronizedRootGroup approach")
    print("")
    
    if not PROJECT_FILE.exists():
        print(f"❌ Project file not found: {PROJECT_FILE}")
        sys.exit(1)
    
    # Read project file
    with open(PROJECT_FILE, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Step 1: Create exception set for extension target
    print("📝 Step 1: Creating exception set for extension target...")
    
    # Generate UUID for new exception set
    exception_uuid = generate_uuid()
    exception_name = f'Exceptions for "{MAIN_APP_FOLDER_NAME}" folder in "{EXTENSION_TARGET_NAME}" target'
    
    # Check if exception already exists
    if exception_name in content:
        print(f"   ✅ Exception set already exists")
        # Extract existing UUID
        pattern = rf'(\w+) /\* {re.escape(exception_name)} \*/'
        match = re.search(pattern, content)
        if match:
            exception_uuid = match.group(1)
            print(f"   Found existing UUID: {exception_uuid}")
    else:
        # Find the exception sets section
        exception_start = content.find('/* Begin PBXFileSystemSynchronizedBuildFileExceptionSet section */')
        exception_end = content.find('/* End PBXFileSystemSynchronizedBuildFileExceptionSet section */')
        
        if exception_start == -1 or exception_end == -1:
            print("   ⚠️  Could not find exception sets section")
            sys.exit(1)
        
        exception_section = content[exception_start:exception_end]
        
        # Create new exception set (similar to existing ones)
        new_exception = f'''\t\t{exception_uuid} /* {exception_name} */ = {{
\t\t\tisa = PBXFileSystemSynchronizedBuildFileExceptionSet;
\t\t\tmembershipExceptions = (
\t\t\t\tInfo.plist,
\t\t\t);
\t\t\ttarget = {EXTENSION_TARGET_UUID} /* {EXTENSION_TARGET_NAME} */;
\t\t}};'''
        
        # Add to exception section (before the end marker)
        insert_pos = exception_end
        content = content[:insert_pos] + new_exception + "\n" + content[insert_pos:]
        print(f"   ✅ Created exception set: {exception_uuid}")
    
    # Step 2: Add exception to "Khandoba Secure Docs" folder
    print("")
    print("📝 Step 2: Adding exception to 'Khandoba Secure Docs' folder...")
    
    # Find the main app folder definition
    folder_search = f'{MAIN_APP_FOLDER_UUID} /* {MAIN_APP_FOLDER_NAME} */'
    folder_start = content.find(folder_search)
    
    if folder_start == -1:
        print("   ❌ Could not find 'Khandoba Secure Docs' folder definition")
        sys.exit(1)
    
    # Find the exceptions = ( section within this folder definition
    # Look for it after the folder start, but before the next section
    exceptions_start = content.find('exceptions = (', folder_start)
    if exceptions_start == -1:
        print("   ❌ Could not find exceptions section")
        sys.exit(1)
    
    # Find the closing ); for exceptions (look for the first ); after exceptions_start)
    exceptions_end = content.find(');', exceptions_start)
    if exceptions_end == -1:
        print("   ❌ Could not find end of exceptions section")
        sys.exit(1)
    
    exceptions_list = content[exceptions_start:exceptions_end]
    
    # Check if exception already in list
    if exception_uuid in exceptions_list or exception_name in exceptions_list:
        print(f"   ✅ Exception already in folder exceptions")
    else:
        # Add exception to list (before the closing )
        new_exception_entry = f"\n\t\t\t\t{exception_uuid} /* {exception_name} */,"
        insert_pos = exceptions_end
        content = content[:insert_pos] + new_exception_entry + "\n\t\t\t" + content[insert_pos:]
        print(f"   ✅ Added exception to folder")
    
    # Step 3: Add "Khandoba Secure Docs" folder to extension target's fileSystemSynchronizedGroups
    print("")
    print("📝 Step 3: Adding 'Khandoba Secure Docs' folder to extension target...")
    
    # Find extension target definition
    target_search = f'{EXTENSION_TARGET_UUID} /* {EXTENSION_TARGET_NAME} */'
    target_start = content.find(target_search)
    
    if target_start == -1:
        print("   ❌ Could not find extension target definition")
        sys.exit(1)
    
    # Find fileSystemSynchronizedGroups = ( section within target
    groups_start = content.find('fileSystemSynchronizedGroups = (', target_start)
    if groups_start == -1:
        print("   ❌ Could not find fileSystemSynchronizedGroups section")
        sys.exit(1)
    
    # Find the closing ); for groups
    groups_end = content.find(');', groups_start)
    if groups_end == -1:
        print("   ❌ Could not find end of fileSystemSynchronizedGroups section")
        sys.exit(1)
    
    groups_list = content[groups_start:groups_end]
    
    # Check if folder already in list
    if MAIN_APP_FOLDER_UUID in groups_list:
        print(f"   ✅ Folder already in target's fileSystemSynchronizedGroups")
    else:
        # Add folder to list (before the closing )
        new_group_entry = f"\n\t\t\t\t{MAIN_APP_FOLDER_UUID} /* {MAIN_APP_FOLDER_NAME} */,"
        insert_pos = groups_end
        content = content[:insert_pos] + new_group_entry + "\n\t\t\t" + content[insert_pos:]
        print(f"   ✅ Added folder to target")
    
    # Write back
    print("")
    print("💾 Saving changes...")
    
    # Backup original
    backup_file = PROJECT_FILE.with_suffix('.pbxproj.backup_target_membership')
    with open(backup_file, 'w', encoding='utf-8') as f:
        with open(PROJECT_FILE, 'r', encoding='utf-8') as original:
            f.write(original.read())
    print(f"   ✅ Backup saved: {backup_file.name}")
    
    # Write modified content
    with open(PROJECT_FILE, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("")
    print("✅ Target membership configured!")
    print("")
    print("📋 Summary:")
    print("   - Exception set created for extension target")
    print("   - Exception added to 'Khandoba Secure Docs' folder")
    print("   - Folder added to extension target's fileSystemSynchronizedGroups")
    print("")
    print("⚠️  Next steps:")
    print("   1. Close Xcode if open")
    print("   2. Reopen Xcode project")
    print("   3. Build extension target (⌘+B)")
    print("   4. Verify files appear in Build Phases → Compile Sources")
    print("")

if __name__ == "__main__":
    main()
