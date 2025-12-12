#!/usr/bin/env python3
"""
Remove Reductio package dependency from Xcode project.
Removes all references to Reductio from project.pbxproj.
"""

import re
import sys
from pathlib import Path

PROJECT_ROOT = Path("/Users/jaideshmukh/Desktop/Khandoba Secure Docs")
PROJECT_FILE = PROJECT_ROOT / "Khandoba Secure Docs.xcodeproj/project.pbxproj"

# Reductio UUIDs (from grep output)
REDUCTIO_BUILDFILE_UUID = "24D2EBBC2EE304A9004257B4"
REDUCTIO_PRODUCT_UUID = "24D2EBBB2EE304A9004257B4"
REDUCTIO_PACKAGE_UUID = "24D2EBBA2EE304A9004257B4"

def main():
    print("🗑️  Removing Reductio dependency...")
    print("")
    
    if not PROJECT_FILE.exists():
        print(f"❌ Project file not found: {PROJECT_FILE}")
        sys.exit(1)
    
    # Read project file
    with open(PROJECT_FILE, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Backup
    backup_file = PROJECT_FILE.with_suffix('.pbxproj.backup_before_remove_reductio')
    with open(backup_file, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"✅ Backup created: {backup_file.name}")
    print("")
    
    # Count occurrences
    reductio_count = content.count(REDUCTIO_PACKAGE_UUID)
    print(f"Found {reductio_count} references to Reductio")
    
    # Remove from PBXBuildFile section
    print("📝 Removing from PBXBuildFile section...")
    buildfile_pattern = rf'(\s*{re.escape(REDUCTIO_BUILDFILE_UUID)} /\* Reductio in Frameworks \*/ = \{{isa = PBXBuildFile;.*?\}};\s*\n)'
    content = re.sub(buildfile_pattern, '', content, flags=re.DOTALL)
    
    # Remove from Frameworks build phase
    print("📝 Removing from Frameworks build phase...")
    frameworks_pattern = rf'(\s*{re.escape(REDUCTIO_BUILDFILE_UUID)} /\* Reductio in Frameworks \*/,\s*\n)'
    content = re.sub(frameworks_pattern, '', content)
    
    # Remove from packageProductDependencies
    print("📝 Removing from packageProductDependencies...")
    dependencies_pattern = rf'(\s*{re.escape(REDUCTIO_PRODUCT_UUID)} /\* Reductio \*/,\s*\n)'
    content = re.sub(dependencies_pattern, '', content)
    
    # Remove from packageReferences
    print("📝 Removing from packageReferences...")
    package_ref_pattern = rf'(\s*{re.escape(REDUCTIO_PACKAGE_UUID)} /\* XCRemoteSwiftPackageReference "Reductio" \*/,\s*\n)'
    content = re.sub(package_ref_pattern, '', content)
    
    # Remove XCRemoteSwiftPackageReference section
    print("📝 Removing XCRemoteSwiftPackageReference section...")
    package_ref_section_pattern = rf'(\s*{re.escape(REDUCTIO_PACKAGE_UUID)} /\* XCRemoteSwiftPackageReference "Reductio" \*/ = \{{.*?\}};\s*\n)'
    content = re.sub(package_ref_section_pattern, '', content, flags=re.DOTALL)
    
    # Remove XCSwiftPackageProductDependency section
    print("📝 Removing XCSwiftPackageProductDependency section...")
    product_dep_section_pattern = rf'(\s*{re.escape(REDUCTIO_PRODUCT_UUID)} /\* Reductio \*/ = \{{.*?\}};\s*\n)'
    content = re.sub(product_dep_section_pattern, '', content, flags=re.DOTALL)
    
    # Write back
    with open(PROJECT_FILE, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("")
    print("✅ Reductio dependency removed!")
    print("")
    print("⚠️  Next steps:")
    print("   1. Close Xcode if open")
    print("   2. Reopen Xcode project")
    print("   3. Build (⌘+B)")
    print("")

if __name__ == "__main__":
    main()
