import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sponge_gallery_cleaner/features/gallery_core/providers/gallery_provider.dart';
import 'package:sponge_gallery_cleaner/features/media_cleaners/swipe_screen.dart';
import 'package:sponge_gallery_cleaner/features/gallery_core/models/gallery_media_item.dart';

class LargeFilesMenuScreen extends StatelessWidget {
  const LargeFilesMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GalleryProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Large Files',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCategoryCard(
              context,
              '10 MB - 100 MB',
              'Clean up medium-large files',
              provider.largeFiles10To100,
              Colors.blue),
          _buildCategoryCard(
              context,
              '100 MB - 500 MB',
              'Clean up heavy videos',
              provider.largeFiles100To500,
              Colors.orange),
          _buildCategoryCard(context, '500 MB - 1 GB', 'Clean up massive files',
              provider.largeFiles500To1GB, Colors.redAccent),
          _buildCategoryCard(context, '> 1 GB', 'Gigantic files!',
              provider.largeFilesOver1GB, Colors.red),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, String subtitle,
      MonthGroup? group, Color iconColor) {
    final count = group?.items.where((i) => i.decision == null).length ?? 0;

    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: Icon(Icons.folder_zip_rounded, color: iconColor),
        ),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 13)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12)),
              child: Text('$count items',
                  style: const TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ],
        ),
        onTap: () {
          if (group != null && count > 0) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => SwipeScreen(group: group)));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('No files found in this category yet!'),
                  duration: Duration(seconds: 1)),
            );
          }
        },
      ),
    );
  }
}
