import re

with open(r'lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# First fix the loader
target_loader = r'''                    Row\(
                      children: \[
                        // Background Sync Loader
                        if \(provider\.isBackgroundLoading\)
                          Padding\(
                            padding: const EdgeInsets\.only\(right: 12\),
                            child: Tooltip\(
                              message: 'Syncing gallery in background\.\.\.',
                              child: SizedBox\(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator\(
                                  color: Colors\.white54,
                                  strokeWidth: 2,
                                \),
                              \),
                            \),
                          \),
                        // Trash bin badge'''

new_loader = r'''                    Row(
                      children: [
                        // Background Sync Loader with Percentage
                        if (provider.isBackgroundLoading)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Row(
                              children: [
                                Text(
                                  '${(provider.backgroundLoadProgress * 100).toInt()}%',
                                  style: const TextStyle(color: Colors.orangeAccent, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.orangeAccent,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Trash bin badge'''
content = re.sub(target_loader, new_loader, content)


# Now fix the cards
target_cards = r'''        if \(provider\.similarPhotoGroups\.isNotEmpty\)
          _QuickCard\(
            label: 'Similar Photos',
            count: provider\.similarPhotoGroups\.length,
            icon: Icons\.filter_none_rounded,
            color: const Color\(0xFFE83A59\),
            onTap: \(\) => Navigator\.push\(
              context,
              MaterialPageRoute\(builder: \(_\) => const SimilarPhotosScreen\(\)\),
            \),
          \),
        if \(provider\.whatsappGroup != null && provider\.whatsappGroup!\.totalItems > 0\)
          const SizedBox\(height: 12\),
        if \(provider\.whatsappGroup != null && provider\.whatsappGroup!\.totalItems > 0\)
          _QuickCard\(
            label: 'WhatsApp Junk',
            count: provider\.whatsappGroup!\.totalItems,
            icon: Icons\.chat_bubble_outline_rounded,
            color: const Color\(0xFF25D366\), // WhatsApp Green
            onTap: \(\) \{
              provider\.whatsappGroup!\.recalculateCurrentIndex\(\);
              Navigator\.push\(
                context,
                MaterialPageRoute\(
                  builder: \(_\) => SwipeScreen\(group: provider\.whatsappGroup!\),
                \),
              \);
            \},
          \),
        const SizedBox\(height: 12\),
        _QuickCard\(
          label: 'Blurry Photos',
          count: 0,
          icon: Icons\.blur_on_rounded,
          color: Colors\.orangeAccent,
          onTap: \(\) => Navigator\.push\(
            context,
            MaterialPageRoute\(builder: \(_\) => const BlurryPhotosScreen\(\)\),
          \),
        \),
        if \(provider\.similarPhotoGroups\.isNotEmpty\)
          const SizedBox\(height: 12\),'''

new_cards = r'''        Row(
          children: [
            if (provider.similarPhotoGroups.isNotEmpty) ...[
              Expanded(
                child: _QuickCard(
                  label: 'Similar\nPhotos',
                  count: provider.similarPhotoGroups.length,
                  icon: Icons.filter_none_rounded,
                  color: const Color(0xFFE83A59),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SimilarPhotosScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: _QuickCard(
                label: 'Blurry\nPhotos',
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
        ),
        if (provider.whatsappGroup != null && provider.whatsappGroup!.totalItems > 0) ...[
          const SizedBox(height: 12),
          _QuickCard(
            label: 'WhatsApp Junk',
            count: provider.whatsappGroup!.totalItems,
            icon: Icons.chat_bubble_outline_rounded,
            color: const Color(0xFF25D366),
            onTap: () {
              provider.whatsappGroup!.recalculateCurrentIndex();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SwipeScreen(group: provider.whatsappGroup!),
                ),
              );
            },
          ),
        ],
        const SizedBox(height: 12),'''

content = re.sub(target_cards, new_cards, content)

with open(r'lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated")
