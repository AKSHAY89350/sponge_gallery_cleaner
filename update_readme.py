import re

with open(r'README.md', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    '* **Location:** `releases/app-release.apk`',
    '* **Direct Download:** [Download app-release.apk](https://github.com/AKSHAY89350/sponge_gallery_cleaner/raw/master/releases/app-release.apk)'
)

with open(r'README.md', 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated README")
