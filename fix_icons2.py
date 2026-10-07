import sys

with open(r'lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

start_marker = "if (provider.similarPhotoGroups.isNotEmpty) ...["
start_idx = content.find(start_marker)

end_marker = "          Builder("
end_idx = content.find(end_marker)

if start_idx == -1 or end_idx == -1:
    print("Failed to find markers")
    sys.exit(1)

# We want to replace from start_idx up to end_idx with our new code.
# But wait, start_idx is inside `children: [`, after `Row(`.
# Let's find the `Row(` before `start_idx`.
row_idx = content.rfind("Row(", 0, start_idx)

new_code = r'''        Row(
            children: [
              Expanded(
                child: _QuickCard(
                  label: 'Similar\nPhotos',
                  count: provider.similarPhotoGroups.length,
                  icon: Icons.filter_none_rounded,
                  color: const Color(0xFFE83A59),
                  onTap: () {
                    if (provider.similarPhotoGroups.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No similar photos found!')));
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SimilarPhotosScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickCard(
                  label: 'Blurry\nPhotos',
                  count: 0,
                  icon: Icons.blur_on_rounded,
                  color: Colors.orangeAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BlurryPhotosScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _QuickCard(
            label: 'WhatsApp Junk',
            count: provider.whatsappGroup?.totalItems ?? 0,
            icon: Icons.chat_bubble_outline_rounded,
            color: const Color(0xFF25D366),
            onTap: () {
              if (provider.whatsappGroup == null || provider.whatsappGroup!.totalItems == 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No WhatsApp junk found!')));
                return;
              }
              provider.whatsappGroup!.recalculateCurrentIndex();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SwipeScreen(group: provider.whatsappGroup!),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
'''

new_content = content[:row_idx] + new_code + content[end_idx:]

with open(r'lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(new_content)

print("Icons fixed completely")
