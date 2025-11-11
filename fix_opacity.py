import re

with open('lib/screens/member_home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(r'\.withOpacity\(([0-9.]+)\)', r'.withValues(alpha: \1)', content)

with open('lib/screens/member_home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed all withOpacity calls!")
