import re

path = 'lib/features/gallery_core/providers/gallery_provider.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# I will find the randomGroup initialization and place whatsappGroup initialization right above it.
target = """      // Random group - pick 20 random items
      if (allItems.length > 5) {"""

replacement = """      if (whatsappItems.isNotEmpty) {
        whatsappGroup = MonthGroup(
          label: 'WhatsApp Junk',
          yearMonthKey: 'whatsapp',
          items: whatsappItems,
        )..recalculateCurrentIndex();
      }

      // Random group - pick 20 random items
      if (allItems.length > 5) {"""

if target in content:
    content = content.replace(target, replacement)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Added whatsappGroup init.")
else:
    print("Target not found.")
