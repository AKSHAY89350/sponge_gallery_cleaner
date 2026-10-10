import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sponge_gallery_cleaner/features/gallery_core/models/gallery_media_item.dart';
import 'package:sponge_gallery_cleaner/features/gallery_core/providers/gallery_provider.dart';
import 'package:sponge_gallery_cleaner/features/media_cleaners/swipe_screen.dart';
import 'package:sponge_gallery_cleaner/features/media_cleaners/similar_photos_screen.dart';
import 'package:sponge_gallery_cleaner/features/media_cleaners/blurry_photos_screen.dart';
import 'package:sponge_gallery_cleaner/features/staging_bin/staging_bin_screen.dart';
import 'package:sponge_gallery_cleaner/features/media_cleaners/large_files_menu_screen.dart';
import 'package:sponge_gallery_cleaner/features/storage_analyzer/screens/storage_breakdown_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GalleryProvider>();
      if (!provider.isInitialized && !provider.isLoading) {
        provider.loadGallery();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _HomeTab(),
          _PeopleTab(),
          _ReviewTab(),
          _SettingsTab(),
        ],
      ),
      bottomNavigationBar: Theme(
        data: ThemeData(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF13151A),
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          selectedItemColor: const Color(0xFF7C3AED), // Purple
          unselectedItemColor: Colors.white54,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline_rounded),
              activeIcon: Icon(Icons.people_rounded),
              label: 'People',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.photo_library_outlined),
              activeIcon: Icon(Icons.photo_library_rounded),
              label: 'Review',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GalleryProvider>();

    if (provider.isLoading && provider.allItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  color: Color(0xFF7C3AED),
                  strokeWidth: 3.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Scanning your gallery for cleaning process...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Analyzing photos, videos & duplicates',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    if (provider.allItems.isEmpty && !provider.isLoading) {
      return Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED),
            foregroundColor: Colors.white,
          ),
          onPressed: provider.loadGallery,
          child: const Text('Scan Gallery'),
        ),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        color: const Color(0xFF7C3AED),
        backgroundColor: const Color(0xFF16181F),
        onRefresh: () => provider.loadGallery(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            _buildTopHeader(context, provider),
            const SizedBox(height: 32),
            _buildCircles(context, provider),
            const SizedBox(height: 36),
            _buildSmartClean(context, provider),
            const SizedBox(height: 36),
            _buildMonthList(context, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, GalleryProvider provider) {
    final trashCount = provider.stagingBin.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sponge 🧽',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Gallery Cleaner',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trashCount > 0)
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StagingBinScreen()),
                ),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.delete_rounded,
                          color: Colors.red, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '$trashCount',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFF1C1E26),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.settings_rounded,
                  color: Colors.white, size: 24),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCircles(BuildContext context, GalleryProvider provider) {
    final totalMB = provider.totalDiskSpaceMB ?? 0.0;
    final freeMB = provider.freeDiskSpaceMB ?? 0.0;
    final usedMB = totalMB > 0 ? totalMB - freeMB : 0.0;
    final storagePercent = totalMB > 0 ? (usedMB / totalMB) : 0.0;
    final freeGB = (freeMB / 1024).toStringAsFixed(1);

    final activeMonthGroups = provider.monthGroups.where((g) => g.items.isNotEmpty).toList();
    final totalMonths = activeMonthGroups.length;
    final reviewedMonths = activeMonthGroups.where((g) => 
      g.items.every((i) => i.decision != null)
    ).length;
    final reviewPercent = totalMonths > 0 ? (reviewedMonths / totalMonths) : 0.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _CircularStat(
          percent: storagePercent,
          centerTitle: '${(storagePercent * 100).toInt()}%',
          centerSub: 'used',
          bottomTitle: 'Storage',
          bottomSub: '$freeGB GB Free',
          color: const Color(0xFF7C3AED),
          showTapHint: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StorageBreakdownScreen(),
              ),
            );
          },
        ),
        _CircularStat(
          percent: reviewPercent,
          centerTitle: '$reviewedMonths / $totalMonths',
          centerSub: 'Months',
          bottomTitle: 'Reviewed',
          bottomSub: 'Keep it up!',
          color: const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _buildSmartClean(BuildContext context, GalleryProvider provider) {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Smart clean',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'See all >',
              style: TextStyle(color: Color(0xFF10B981), fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildSmartCard(
              context: context,
              title: 'Similar\nPhotos',
              count: provider.similarPhotosCount,
              icon: Icons.photo_library_rounded,
              color: const Color(0xFFC026D3),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SimilarPhotosScreen())),
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildSmartCard(
              context: context,
              title: 'Blurry\nPhotos',
              count: provider.blurryGroup?.items.where((i) => i.decision == null).length ?? 0,
              icon: Icons.blur_on_rounded,
              color: const Color(0xFFF59E0B),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BlurryPhotosScreen())),
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildSmartCard(
              context: context,
              title: 'WhatsApp\nJunk',
              count: provider.whatsappJunkCount,
              icon: Icons.chat_bubble_rounded,
              color: const Color(0xFF10B981),
              onTap: () => _openSwipeScreen(context, provider.whatsappGroup),
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildSmartCard(
              context: context,
              title: 'Random\nClean',
              count: provider.randomGroup?.items.where((i) => i.decision == null).length ?? 0,
              icon: Icons.shuffle_rounded,
              color: const Color(0xFF3B82F6),
              onTap: () {
                if (provider.randomGroup?.items.where((i) => i.decision == null).isEmpty ?? false) {
                  provider.refreshRandomGroup();
                }
                _openSwipeScreen(context, provider.randomGroup);
              },
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildSmartCard(
              context: context,
              title: 'Screenshots',
              count: provider.screenshotsCount,
              icon: Icons.screenshot_rounded,
              color: const Color(0xFFF59E0B), // Using orange-ish for screenshots
              onTap: () => _openSwipeScreen(context, provider.screenshotsGroup),
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildSmartCard(
              context: context,
              title: 'Large\nFiles',
              count: provider.totalLargeFilesCount,
              icon: Icons.video_library_rounded,
              color: const Color(0xFFEF4444),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LargeFilesMenuScreen())),
            )),
          ],
        ),
      ],
    );
  }

  void _openSwipeScreen(BuildContext context, MonthGroup? group) {
    if (group == null || group.totalItems == 0) return;
    group.recalculateCurrentIndex();
    Navigator.push(context, MaterialPageRoute(builder: (_) => SwipeScreen(group: group)));
  }

  Widget _buildSmartCard({
    required BuildContext context,
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF16181F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.replaceAll('\\n', '\n'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      height: 1.2,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count items',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthList(BuildContext context, GalleryProvider provider) {
    return Column(
      children: [
        Row(
          children: [
            const Text(
              'Browse by month',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            Text(
              '${provider.monthGroups.length} months',
              style: const TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...provider.monthGroups.map((group) {
          final total = group.items.length;
          if (total == 0) return const SizedBox.shrink();
          final remaining = group.items.where((i) => i.decision == null).length;
          final isCompleted = remaining == 0;

          final percent = ((total - remaining) / total * 100).toInt();
          final primaryColor = isCompleted ? const Color(0xFF10B981) : const Color(0xFF7C3AED);

          return GestureDetector(
            onTap: () => _openSwipeScreen(context, group),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16181F),
                borderRadius: BorderRadius.circular(16),
                border: isCompleted
                    ? Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3), width: 1)
                    : null,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isCompleted ? Icons.check_circle_rounded : Icons.calendar_month_rounded,
                          color: primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.label,
                              style: TextStyle(
                                color: isCompleted ? Colors.white54 : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                                decorationColor: const Color(0xFF10B981),
                                decorationThickness: 2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isCompleted ? 'Completed ✓' : '$remaining items',
                              style: TextStyle(
                                color: isCompleted ? const Color(0xFF10B981) : Colors.white54,
                                fontSize: 13,
                                fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        isCompleted ? '100%' : '$percent%',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent / 100,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _CircularStat extends StatelessWidget {
  final double percent;
  final String centerTitle;
  final String centerSub;
  final String bottomTitle;
  final String bottomSub;
  final Color color;
  final VoidCallback? onTap;
  final bool showTapHint;

  const _CircularStat({
    required this.percent,
    required this.centerTitle,
    required this.centerSub,
    required this.bottomTitle,
    required this.bottomSub,
    required this.color,
    this.onTap,
    this.showTapHint = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        SizedBox(
          width: 110,
          height: 110,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: percent,
                backgroundColor: const Color(0xFF1C1E26),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 8,
                strokeCap: StrokeCap.round,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    centerTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    centerSub,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              bottomTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (showTapHint) ...[
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios_rounded, color: color, size: 12),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          bottomSub,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }
    return content;
  }
}

class _ReviewTab extends StatelessWidget {
  const _ReviewTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GalleryProvider>();
    
    // Find the first month group that has remaining items
    MonthGroup? targetGroup;
    for (final g in provider.monthGroups) {
      if (g.items.any((i) => i.decision == null)) {
        targetGroup = g;
        break;
      }
    }

    if (targetGroup == null) {
      return const Center(
        child: Text('No photos to review!', style: TextStyle(color: Colors.white, fontSize: 18)),
      );
    }

    targetGroup.recalculateCurrentIndex();
    
    // Return the SwipeScreen directly inside the tab
    // We wrap it in a Navigator so it has its own routing if needed, 
    // but just placing the widget is easier. Actually SwipeScreen uses Scaffold,
    // so it's perfectly fine to place it here.
    return SwipeScreen(key: ValueKey(targetGroup.yearMonthKey), group: targetGroup, isEmbedded: true);
  }
}

class _PeopleTab extends StatelessWidget {
  const _PeopleTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'People & Collections',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.face_rounded, color: Color(0xFF7C3AED), size: 64),
            ),
            const SizedBox(height: 24),
            const Text(
              'Face Recognition & People',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Automatically detect faces, cluster people into collections, and swipe-clean duplicates.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F1115),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings_rounded, color: Colors.white24, size: 80),
            SizedBox(height: 24),
            Text(
              'Settings',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Preferences and App Info will appear here.',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
