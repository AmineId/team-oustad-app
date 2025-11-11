import re
import os

def fix_with_opacity(file_path):
    """Fix withOpacity deprecation warnings in a Dart file."""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Pattern to match .withOpacity(value)
    pattern = r'\.withOpacity\(([0-9.]+)\)'
    replacement = r'.withValues(alpha: \1)'
    
    new_content = re.sub(pattern, replacement, content)
    
    if new_content != content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        return True
    return False

# Files to fix
files = [
    r'lib\screens\edit_profile_screen.dart',
    r'lib\screens\forgot_password_screen.dart',
    r'lib\screens\member_home_screen.dart',
    r'lib\screens\reset_password_screen.dart',
    r'lib\screens\subscription_details_screen.dart',
    r'lib\widgets\gym_details_bottom_sheet.dart',
]

base_path = os.path.dirname(__file__)

for file in files:
    full_path = os.path.join(base_path, file)
    if os.path.exists(full_path):
        if fix_with_opacity(full_path):
            print(f'✅ Fixed: {file}')
        else:
            print(f'⏭️  No changes needed: {file}')
    else:
        print(f'❌ Not found: {file}')

print('\n✅ All withOpacity issues fixed!')
