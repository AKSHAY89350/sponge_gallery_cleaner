import os
import re

# 1. Rename files
folder = r'docs/screenshots'
files = [f for f in os.listdir(folder) if f.endswith('.jpeg')]
for i, file in enumerate(files):
    os.rename(os.path.join(folder, file), os.path.join(folder, f'screen_{i+1}.jpeg'))

# 2. Update README
with open(r'README.md', 'r', encoding='utf-8') as f:
    content = f.read()

screenshots_md = '''
## 📸 Screenshots

<p align="center">
  <img src="docs/screenshots/screen_1.jpeg" width="200" style="margin: 8px" />
  <img src="docs/screenshots/screen_2.jpeg" width="200" style="margin: 8px" />
  <img src="docs/screenshots/screen_3.jpeg" width="200" style="margin: 8px" />
</p>
<p align="center">
  <img src="docs/screenshots/screen_4.jpeg" width="200" style="margin: 8px" />
  <img src="docs/screenshots/screen_5.jpeg" width="200" style="margin: 8px" />
  <img src="docs/screenshots/screen_6.jpeg" width="200" style="margin: 8px" />
</p>
'''

# Insert screenshots after ✨ Key Features section
target = r'## ✨ Key Features'
replacement = screenshots_md + '\n' + target
content = re.sub(target, replacement, content)

with open(r'README.md', 'w', encoding='utf-8') as f:
    f.write(content)

print("Screenshots added and README updated")
