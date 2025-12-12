#!/usr/bin/env python3
"""
Remove the old MessageExtension target from Xcode project.
This fixes the "Multiple commands produce Info.plist" error.
"""

import re
import sys
from pathlib import Path

PROJECT_ROOT = Path("/Users/jaideshmukh/Desktop/Khandoba Secure Docs")
PROJECT_FILE = PROJECT_ROOT / "Khandoba Secure Docs.xcodeproj/project.pbxproj"

# MessageExtension target UUIDs (from grep output)
MESSAGE_EXTENSION_TARGET_UUID = "245C556C2EE4B61400270A37"
MESSAGE_EXTENSION_APPEX_UUID = "245C556D2EE4B61400270A37"
MESSAGE_EXTENSION_FOLDER_UUID = "245C556F2EE4B61400270A37"
MESSAGE_EXTENSION_EXCEPTION_UUID = "245C55A02EE4C0D700270A37"

def main():
    print("🗑️  Removing old MessageExtension target...")
    print("")
    
    if not PROJECT_FILE.exists():
        print(f"❌ Project file not found: {PROJECT_FILE}")
        sys.exit(1)
    
    # Read project file
    with open(PROJECT_FILE, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Backup
    backup_file = PROJECT_FILE.with_suffix('.pbxproj.backup_before_remove_extension')
    with open(backup_file, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"✅ Backup created: {backup_file.name}")
    print("")
    
    # Count occurrences
    target_count = content.count(MESSAGE_EXTENSION_TARGET_UUID)
    print(f"Found {target_count} references to MessageExtension target")
    
    # Remove from Products group
    print("📝 Removing from Products group...")
    products_pattern = rf'(\t\t\t{re.escape(MESSAGE_EXTENSION_APPEX_UUID)} /\* MessageExtension\.appex \*/,\s*\n)'
    content = re.sub(products_pattern, '', content)
    
    # Remove from main group
    print("📝 Removing from main group...")
    main_group_pattern = rf'(\s*{re.escape(MESSAGE_EXTENSION_FOLDER_UUID)} /\* MessageExtension \*/,\s*\n)'
    content = re.sub(main_group_pattern, '', content)
    
    # Remove exception from "Khandoba Secure Docs" folder
    print("📝 Removing exception from 'Khandoba Secure Docs' folder...")
    exception_pattern = rf'(\s*{re.escape(MESSAGE_EXTENSION_EXCEPTION_UUID)} /\* Exceptions for "Khandoba Secure Docs" folder in "MessageExtension" target \*/,\s*\n)'
    content = re.sub(exception_pattern, '', content)
    
    # Remove target definition (entire section)
    print("📝 Removing target definition...")
    target_start = content.find(f'{MESSAGE_EXTENSION_TARGET_UUID} /* MessageExtension */ = {{')
    if target_start != -1:
        # Find the closing }; for the target
        brace_count = 0
        target_end = target_start
        in_target = False
        
        for i in range(target_start, len(content)):
            if content[i] == '{':
                brace_count += 1
                in_target = True
            elif content[i] == '}':
                brace_count -= 1
                if in_target and brace_count == 0:
                    target_end = i + 2  # Include }; and newline
                    break
        
        if target_end > target_start:
            content = content[:target_start] + content[target_end:]
            print("   ✅ Target definition removed")
    
    # Write back
    with open(PROJECT_FILE, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("")
    print("✅ MessageExtension target references removed!")
    print("")
    print("⚠️  Note: You may still need to:")
    print("   1. Remove target in Xcode (if it still appears)")
    print("   2. Clean build folder (⇧⌘K)")
    print("   3. Delete DerivedData if errors persist")
    print("")

if __name__ == "__main__":
    main()
