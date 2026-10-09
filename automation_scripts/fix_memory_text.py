import re

path = 'lib/features/staging_bin/staging_bin_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Make the text much more prominent
old_text = """                // Size freed info
                Text(
                  'Frees ${provider.totalFreedFormatted} of storage',
                  style: const TextStyle(color: Colors.white38, fontSize: 13),
                ),"""

new_text = """                // Size freed info
                Text(
                  'Will Free: ${provider.totalFreedFormatted}',
                  style: const TextStyle(
                      color: Color(0xFF10B981), // Emerald Green
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5),
                ),"""

content = content.replace(old_text, new_text)

# And update the button text to just have the count
old_btn = "Permanently Delete ${items.length} Items"
new_btn = "Permanently Delete All (${items.length})"

content = content.replace(old_btn, new_btn)


with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated text")
