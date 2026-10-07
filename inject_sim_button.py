import re

with open(r'lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

target = r'''        // Quick Clean section
        const SizedBox(height: 8),
        const Text(
          'Quick Clean',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),'''

replacement = r'''        // Quick Clean section
        const SizedBox(height: 8),
        const Text(
          'Smart AI Clean',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (provider.similarPhotoGroups.isNotEmpty)
          _QuickActionCard(
            title: 'Similar & Burst Photos',
            subtitle: '${provider.similarPhotoGroups.length} groups found',
            icon: Icons.filter_none_rounded,
            color: const Color(0xFFE83A59),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SimilarPhotosScreen()),
            ),
          ),
        if (provider.similarPhotoGroups.isNotEmpty)
          const SizedBox(height: 12),'''

content = content.replace(target, replacement)

with open(r'lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Button injected")
