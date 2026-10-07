import re

with open(r'lib/providers/gallery_provider.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the slow originFile fetch in loadGallery
slow_pattern = r'''          int fileSizeBytes = 0;
          String filePath = '';
          try \{
            final originFile = await asset\.originFile;
            filePath = originFile\?\.path \?\? '';
            fileSizeBytes = originFile\?\.lengthSync\(\) \?\? 0;
          \} catch \(_\) \{
            // File might be restricted or deleted from storage
          \}'''

fast_replacement = r'''          int fileSizeBytes = 0;
          String filePath = asset.title ?? '';
          // 🚀 SKIPPING await asset.file HERE FOR INSTANT STARTUP 🚀'''

content = re.sub(slow_pattern, fast_replacement, content)

with open(r'lib/providers/gallery_provider.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Startup fixed")
