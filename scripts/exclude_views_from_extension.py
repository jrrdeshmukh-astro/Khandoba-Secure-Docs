#!/usr/bin/env python3
"""
Exclude all Views files from iMessage extension target
"""

import os
import re

project_file = "Khandoba Secure Docs.xcodeproj/project.pbxproj"

# Read project file
with open(project_file, "r") as f:
    content = f.read()

# Find all Swift files in Views directory
views_dir = "Khandoba Secure Docs/Views"
view_files = []
for root, dirs, files in os.walk(views_dir):
    for file in files:
        if file.endswith(".swift"):
            rel_path = os.path.relpath(os.path.join(root, file), "Khandoba Secure Docs")
            view_files.append(rel_path)

# Find the exception set
pattern = r'(OWRZA7VISHT0FFJ857KLAZAO.*?membershipExceptions = \{[^}]*\})'
match = re.search(pattern, content, re.DOTALL)

if match:
    exception_block = match.group(0)
    
    # Get current exceptions
    current_exceptions = re.findall(r'(\S+),', exception_block.split("membershipExceptions = (")[1].split(")")[0])
    
    # Add all view files
    all_exceptions = set(current_exceptions)
    all_exceptions.update(view_files)
    
    # Rebuild exception list
    exception_list = "\n\t\t\t\t" + ",\n\t\t\t\t".join(sorted(all_exceptions)) + ",\n\t\t\t"
    
    # Replace
    new_exception_block = re.sub(
        r'membershipExceptions = \{[^}]*\}',
        f'membershipExceptions = ({exception_list})',
        exception_block,
        flags=re.DOTALL
    )
    
    content = content.replace(exception_block, new_exception_block)
    
    # Write back
    with open(project_file, "w") as f:
        f.write(content)
    
    print(f"✅ Excluded {len(view_files)} view files from extension target")
else:
    print("❌ Could not find exception set")
