import sys

with open(r'lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

targetCalls = """          Row(
              children: [
                Expanded(
                  child: _QuickCard(
                    label: 'Similar\\nPhotos',
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
                    label: 'Blurry\\nPhotos',
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
            ),"""

replacementCalls = """          Row(
              children: [
                Expanded(
                  child: _QuickCard(
                    label: 'Similar\\nPhotos',
                    count: simLiveGroups,
                    progress: simProgress,
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
                    label: 'Blurry\\nPhotos',
                    count: blurryLive,
                    progress: blurryProgress,
                    icon: Icons.blur_on_rounded,
                    color: Colors.orangeAccent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BlurryPhotosScreen()),
                    ),
                  ),
                ),
              ],
            ),"""

content = content.replace(targetCalls.replace('\\n', '\n'), replacementCalls.replace('\\n', '\n'))

with open(r'lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated QuickCards calls")
