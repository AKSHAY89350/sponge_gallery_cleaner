import re

path = 'README.md'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target = """## dY" Download Latest Build
You can download the latest production-ready APK directly from this repository.
* **Direct Download:** [Download Sponge Cleaner v4.1](https://github.com/AKSHAY89350/sponge_gallery_cleaner/raw/master/release_apk/sponge_gallery_cleaner_v4.1.apk)"""

replacement = """## dY" Download Latest Build
You can download the latest production-ready APK directly from this repository.
* **Direct Download:** [Download Sponge Cleaner v4.2](https://github.com/AKSHAY89350/sponge_gallery_cleaner/raw/master/releases/Sponge_Gallery_Cleaner_V4.2.apk)"""

if target in content:
    content = content.replace(target, replacement)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Updated README.")
else:
    print("Target not found.")
