import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gallery_provider.dart';
import '../models/gallery_media_item.dart';
import 'swipe_screen.dart';
import 'staging_bin_screen.dart';
import 'large_files_menu_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showAllMonths = false;

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
    final provider = context.watch<GalleryProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
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
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Gallery Cleaner',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ],
                  ),
                  // Trash bin badge
                  if (provider.stagingBin.isNotEmpty)
                    GestureDetector(
                      onTap: () => _goToStagingBin(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.red.withValues(alpha: 0.4), width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.delete_rounded,
                                color: Colors.red, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${provider.stagingBin.length}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Storage Freed Banner ──
            if (provider.isInitialized && provider.totalTrashedBytes > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: GestureDetector(
                  onTap: () => _goToStagingBin(context),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cleaning_services_rounded,
                            color: Colors.white, size: 32),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Ready to free up',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            Text(
                              provider.totalFreedFormatted,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            color: Colors.white70, size: 16),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Content ──
            Expanded(
              child: provider.isLoading
                  ? _buildLoading()
                  : !provider.isInitialized
                      ? _buildNotLoaded(provider)
                      : _buildGroupList(context, provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF6C63FF)),
          SizedBox(height: 20),
          Text(
            'Scanning your gallery...',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildNotLoaded(GalleryProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.photo_library_outlined,
              color: Colors.white24, size: 72),
          const SizedBox(height: 20),
          const Text('Your gallery is not loaded yet',
              style: TextStyle(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: provider.loadGallery,
            child: const Text('Scan Gallery'),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupList(BuildContext context, GalleryProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StorageCircleWidget(provider: provider),
            _MonthsReviewedWidget(provider: provider),
          ],
        ),
        const SizedBox(height: 32),
        // Quick Clean section
        const SizedBox(height: 8),
        const Text(
          'Quick Clean',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Builder(
          builder: (context) {
            final cards = <Widget>[
              if (provider.randomGroup != null)
                Expanded(
                  child: _QuickCard(
                    icon: Icons.shuffle_rounded,
                    label: 'Random\nClean',
                    count: provider.randomGroup!.totalItems,
                    color: const Color(0xFF10B981),
                    onTap: () => _openGroup(context, provider.randomGroup!),
                  ),
                ),
              if (provider.screenshotsGroup != null)
                Expanded(
                  child: _QuickCard(
                    icon: Icons.screenshot_rounded,
                    label: 'Screenshots',
                    count: provider.screenshotsGroup!.totalItems,
                    color: const Color(0xFFF59E0B),
                    onTap: () => _openGroup(context, provider.screenshotsGroup!),
                  ),
                ),
              if (provider.totalLargeFilesCount > 0)
                Expanded(
                  child: _QuickCard(icon: Icons.video_library_rounded, label: 'Large\nFiles', count: provider.totalLargeFilesCount, color: const Color(0xFFEF4444), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LargeFilesMenuScreen())),),
                ),
            ];

            if (cards.isEmpty) return const SizedBox.shrink();

            final rowChildren = <Widget>[];
            for (var i = 0; i < cards.length; i++) {
              rowChildren.add(cards[i]);
              if (i < cards.length - 1) {
                rowChildren.add(const SizedBox(width: 10));
              }
            }
            return Row(children: rowChildren);
          },
        ),
        const SizedBox(height: 28),
        // Monthly groups
        Row(
          children: [
            const Text(
              'By Month',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            Text(
              '${provider.monthGroups.length} months',
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (provider.monthGroups.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Center(
              child: Text('No photos found',
                  style: TextStyle(color: Colors.white38)),
            ),
          )
        else
          ...(() {
             if (_showAllMonths) {
               final cards = provider.monthGroups.map<Widget>((g) => _MonthCard(group: g, onTap: () => _openGroup(context, g))).toList();
               cards.add(
                 Padding(
                   padding: const EdgeInsets.only(top: 8.0, bottom: 20),
                   child: TextButton(
                     onPressed: () => setState(() => _showAllMonths = false),
                     style: TextButton.styleFrom(
                       foregroundColor: const Color(0xFF6C63FF),
                     ),
                     child: const Text('Hide Months', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                   ),
                 )
               );
               return cards;
             } else {
               final visibleGroups = <MonthGroup>[];
               if (provider.monthGroups.isNotEmpty) {
                 visibleGroups.add(provider.monthGroups.first);
               }
               for (var i = 1; i < provider.monthGroups.length; i++) {
                 final g = provider.monthGroups[i];
                 if (g.currentIndex > 0 && g.currentIndex < g.items.length) {
                   visibleGroups.add(g);
                 }
               }
               
               final cards = visibleGroups.map<Widget>((g) => _MonthCard(group: g, onTap: () => _openGroup(context, g))).toList();
               
               if (provider.monthGroups.length > visibleGroups.length) {
                 cards.add(
                   Padding(
                     padding: const EdgeInsets.only(top: 8.0, bottom: 20),
                     child: TextButton(
                       onPressed: () => setState(() => _showAllMonths = true),
                       style: TextButton.styleFrom(
                         foregroundColor: const Color(0xFF6C63FF),
                       ),
                       child: const Text('View All Months', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                     ),
                   )
                 );
               }
               return cards;
             }
          })(),

          if (_showAllMonths && provider.isBackgroundLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                   children: [
                      CircularProgressIndicator(color: Color(0xFF6C63FF), strokeWidth: 2),
                      SizedBox(height: 12),
                      Text("Loading older months in background...", style: TextStyle(color: Colors.white54, fontSize: 13)),
                   ]
                )
              )
            ),
      ],
    );
  }

  void _openGroup(BuildContext context, MonthGroup group) {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => SwipeScreen(group: group)));
  }

  void _goToStagingBin(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const StagingBinScreen()));
  }
}

// ── Quick Mode Card ──────────────────────────────────────────────────────────

class _QuickCard extends StatelessWidget {
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
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
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
        ),
      ),
    );
  }
}

// ── Monthly Group Card ───────────────────────────────────────────────────────

class _MonthCard extends StatelessWidget {
  final MonthGroup group;
  final VoidCallback onTap;

  const _MonthCard({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Month info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${group.totalItems} items',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                // Status / progress
                Row(
                  children: [
                    if (group.isComplete)
                      const Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: Color(0xFF10B981), size: 18),
                          SizedBox(width: 4),
                          Text('Done',
                              style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ],
                      )
                    else if (group.progressPercent > 0)
                      Text(
                        '${(group.progressPercent * 100).toInt()}%',
                        style: const TextStyle(
                            color: Color(0xFF6C63FF),
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
                      ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white24, size: 14),
                  ],
                ),
              ],
            ),
            // Progress bar
            if (group.progressPercent > 0) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: group.progressPercent,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation(group.isComplete
                      ? const Color(0xFF10B981)
                      : const Color(0xFF6C63FF)),
                  minHeight: 4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


class _StorageCircleWidget extends StatelessWidget {
  final GalleryProvider provider;
  const _StorageCircleWidget({required this.provider});

  @override
  Widget build(BuildContext context) {
    final total = provider.totalDiskSpaceMB ?? 0.0;
    final free = provider.freeDiskSpaceMB ?? 0.0;
    final used = total > 0 ? total - free : 0.0;
    
    final percent = total > 0 ? (used / total) : 0.0;
    
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 90,
              height: 90,
              child: CircularProgressIndicator(
                value: percent,
                backgroundColor: Colors.white10,
                color: const Color(0xFF6C63FF),
                strokeWidth: 8,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(percent * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Used',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Storage', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        if (total > 0)
           Text('${(free / 1024).toStringAsFixed(1)} GB Free', style: const TextStyle(color: Colors.white54, fontSize: 12)),
        if (total == 0)
           const Text('Calculating...', style: TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}

class _MonthsReviewedWidget extends StatelessWidget {
  final GalleryProvider provider;
  const _MonthsReviewedWidget({required this.provider});

  @override
  Widget build(BuildContext context) {
    final totalMonths = provider.monthGroups.length;
    final reviewedMonths = provider.monthGroups.where((g) => g.isComplete).length;
    
    final percent = totalMonths > 0 ? (reviewedMonths / totalMonths) : 0.0;
    
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 90,
              height: 90,
              child: CircularProgressIndicator(
                value: percent,
                backgroundColor: Colors.white10,
                color: const Color(0xFF10B981),
                strokeWidth: 8,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$reviewedMonths / $totalMonths',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Months',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Reviewed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        const Text('Keep it up!', style: TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}

