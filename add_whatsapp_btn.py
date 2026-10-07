import re

with open(r'lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

target = r'''        if \(provider.similarPhotoGroups.isNotEmpty\)
          _QuickCard\(
            label: 'Similar Photos',
            count: provider.similarPhotoGroups.length,
            icon: Icons.filter_none_rounded,
            color: const Color\(0xFFE83A59\),
            onTap: \(\) => Navigator.push\(
              context,
              MaterialPageRoute\(builder: \(_\) => const SimilarPhotosScreen\(\)\),
            \),
          \),'''

new_button = r'''        if (provider.similarPhotoGroups.isNotEmpty)
          _QuickCard(
            label: 'Similar Photos',
            count: provider.similarPhotoGroups.length,
            icon: Icons.filter_none_rounded,
            color: const Color(0xFFE83A59),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SimilarPhotosScreen()),
            ),
          ),
        if (provider.whatsappGroup != null && provider.whatsappGroup!.totalItems > 0)
          const SizedBox(height: 12),
        if (provider.whatsappGroup != null && provider.whatsappGroup!.totalItems > 0)
          _QuickCard(
            label: 'WhatsApp Junk',
            count: provider.whatsappGroup!.totalItems,
            icon: Icons.chat_bubble_outline_rounded,
            color: const Color(0xFF25D366), // WhatsApp Green
            onTap: () {
              provider.whatsappGroup!.recalculateCurrentIndex();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SwipeScreen(group: provider.whatsappGroup!),
                ),
              );
            },
          ),'''

content = re.sub(target, new_button, content)

with open(r'lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Added WhatsApp button to Home Screen")
