import re

with open(r'lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
if "import 'similar_photos_screen.dart';" not in content:
    content = content.replace("import 'staging_bin_screen.dart';", "import 'staging_bin_screen.dart';\nimport 'similar_photos_screen.dart';")

# Add button in _buildGroupList under the Dashboard
target = r'''          // Quick Clean section
          const SizedBox\(height: 8\),
          const Text\(
            'Quick Clean',
            style: TextStyle\(
                color: Colors\.white,
                fontSize: 18,
                fontWeight: FontWeight\.w700\),
          \),
          const SizedBox\(height: 16\),'''

replacement = r'''          // Quick Clean section
          const SizedBox(height: 8),
          const Text(
            'Smart AI Clean',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
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

content = re.sub(target, replacement, content)

with open(r'lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Added Similar Photos button to Home Screen")
