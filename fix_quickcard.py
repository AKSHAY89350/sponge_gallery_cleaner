import sys

with open(r'lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update _QuickCard definition
targetCard = """class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
  });"""

replacementCard = """class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final VoidCallback onTap;
  final double? progress;

  const _QuickCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
    this.progress,
  });"""
content = content.replace(targetCard, replacementCard)

# 2. Update _QuickCard build method to show progress
targetBuild = """          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 10),
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('$count items',
                  style:
                      TextStyle(color: color.withValues(alpha: 0.6), fontSize: 11)),
            ],
          ),"""

replacementBuild = """          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 26),
                  if (progress != null)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        value: progress,
                        backgroundColor: color.withValues(alpha: 0.2),
                        color: color,
                        strokeWidth: 3,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('$count items',
                  style:
                      TextStyle(color: color.withValues(alpha: 0.6), fontSize: 11)),
            ],
          ),"""
content = content.replace(targetBuild, replacementBuild)

# 3. Add variables to build method
targetBuildStart = """  Widget build(BuildContext context) {
    final provider = context.watch<GalleryProvider>();

    if (provider.isLoading) {"""
replacementBuildStart = """  Widget build(BuildContext context) {
    final provider = context.watch<GalleryProvider>();

    // Calculate Similar Photos Progress
    final simTotalGroups = provider.similarPhotoGroups.where((g) => g.length > 1).length;
    final simLiveGroups = provider.similarPhotoGroups.where((g) => g.length > 1 && g.any((i) => i.decision == null)).length;
    final simProgress = simTotalGroups > 0 ? (simTotalGroups - simLiveGroups) / simTotalGroups : null;

    // Calculate Blurry Photos Progress
    final blurryTotal = provider.blurryGroup?.totalItems ?? 0;
    final blurryLive = provider.blurryGroup?.items.where((i) => i.decision == null).length ?? 0;
    final blurryProgress = blurryTotal > 0 ? (blurryTotal - blurryLive) / blurryTotal : null;

    if (provider.isLoading) {"""
content = content.replace(targetBuildStart, replacementBuildStart)

# 4. Update the _QuickCard calls
targetCalls = """            Row(
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
replacementCalls = """            Row(
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
content = content.replace(targetCalls, replacementCalls)

with open(r'lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated QuickCards")
