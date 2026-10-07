import sys

with open(r'lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

start_idx = -1
end_idx = -1

for i, line in enumerate(lines):
    if "if (provider.similarPhotoGroups.isNotEmpty) ...[" in line:
        start_idx = i
    if "Builder(" in line and start_idx != -1 and end_idx == -1:
        end_idx = i

if start_idx == -1 or end_idx == -1:
    print(f"Failed to find markers: start={start_idx}, end={end_idx}")
    sys.exit(1)

# Backtrack to find the Row(
row_idx = -1
for i in range(start_idx, -1, -1):
    if "Row(" in lines[i]:
        row_idx = i
        break

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

lines[row_idx:end_idx] = [new_code]

with open(r'lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("Icons fixed line by line")
