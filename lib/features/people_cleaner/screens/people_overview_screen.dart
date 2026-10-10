import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sponge_gallery_cleaner/features/gallery_core/providers/gallery_provider.dart';
import 'package:sponge_gallery_cleaner/features/people_cleaner/models/person_cluster.dart';
import 'package:sponge_gallery_cleaner/features/people_cleaner/services/face_detection_service.dart';
import 'package:sponge_gallery_cleaner/features/people_cleaner/screens/person_photos_screen.dart';

class PeopleOverviewScreen extends StatefulWidget {
  const PeopleOverviewScreen({super.key});

  @override
  State<PeopleOverviewScreen> createState() => _PeopleOverviewScreenState();
}

class _PeopleOverviewScreenState extends State<PeopleOverviewScreen> {
  void _triggerScan() {
    final provider = context.read<GalleryProvider>();
    if (FaceDetectionService.isScanning) {
      FaceDetectionService.stopScanning();
      setState(() {});
    } else {
      FaceDetectionService.scanGalleryForFaces(
        allItems: provider.allItems,
        onProgress: () {
          if (mounted) setState(() {});
        },
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final clusters = FaceDetectionService.clusters;
    final isScanning = FaceDetectionService.isScanning;
    final scannedCount = FaceDetectionService.scannedCount;
    final totalToScan = FaceDetectionService.totalToScan;
    final progress = FaceDetectionService.scanProgress;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'People & Faces',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isScanning ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
              color: const Color(0xFF7C3AED),
              size: 28,
            ),
            tooltip: isScanning ? 'Pause Face Scan' : 'Start Face Scan',
            onPressed: _triggerScan,
          ),
        ],
      ),
      body: Column(
        children: [
          // Scan Status Banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF16181F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isScanning
                    ? const Color(0xFF7C3AED).withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isScanning ? Icons.sync_rounded : Icons.face_retouching_natural_rounded,
                            color: const Color(0xFF7C3AED),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isScanning ? 'Scanning for Faces...' : 'On-Device Face Scanner',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              isScanning
                                  ? '$scannedCount / $totalToScan photos analyzed'
                                  : '${clusters.length} people identified',
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isScanning
                            ? Colors.red.withValues(alpha: 0.2)
                            : const Color(0xFF7C3AED),
                        foregroundColor: isScanning ? Colors.red : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: _triggerScan,
                      child: Text(
                        isScanning ? 'Pause' : 'Scan Faces',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                if (isScanning && totalToScan > 0) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                      minHeight: 5,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // People Grid
          Expanded(
            child: clusters.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.people_alt_rounded,
                              color: Color(0xFF7C3AED),
                              size: 56,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No People Scanned Yet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap "Scan Faces" to automatically detect and group photos of your friends, family, and yourself on your device.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C3AED),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _triggerScan,
                            icon: const Icon(Icons.face_rounded, size: 18),
                            label: const Text('Start Face Scan', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.88,
                    ),
                    itemCount: clusters.length,
                    itemBuilder: (ctx, index) {
                      final person = clusters[index];
                      return _PersonCard(
                        person: person,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PersonPhotosScreen(
                                person: person,
                                onUpdated: () => setState(() {}),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final PersonCluster person;
  final VoidCallback onTap;

  const _PersonCard({required this.person, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF16181F),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.6),
                  width: 2.5,
                ),
              ),
              child: ClipOval(
                child: person.avatarBytes != null
                    ? Image.memory(
                        person.avatarBytes!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                        child: const Icon(Icons.face_rounded, color: Color(0xFF7C3AED), size: 40),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              person.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${person.photoCount} photos',
                style: const TextStyle(
                  color: Color(0xFF7C3AED),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
