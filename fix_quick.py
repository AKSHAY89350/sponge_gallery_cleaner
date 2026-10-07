import re

with open(r'lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

target = r'''        if \(provider\.similarPhotoGroups\.isNotEmpty\)
          _QuickCard\(
            title: 'Similar & Burst Photos',
            subtitle: '\$\{provider\.similarPhotoGroups\.length\} groups found',
            icon: Icons\.filter_none_rounded,
            color: const Color\(0xFFE83A59\),
            onTap: \(\) => Navigator\.push\(
              context,
              MaterialPageRoute\(builder: \(_\) => const SimilarPhotosScreen\(\)\),
            \),
          \),'''

replacement = r'''        if (provider.similarPhotoGroups.isNotEmpty)
          _QuickCard(
            label: 'Similar Photos',
            count: provider.similarPhotoGroups.length,
            icon: Icons.filter_none_rounded,
            color: const Color(0xFFE83A59),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SimilarPhotosScreen()),
            ),
          ),'''

content = re.sub(target, replacement, content)

with open(r'lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Fixed QuickCard")
