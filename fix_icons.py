import re

with open(r'lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

target = r'''        Row\(
          children: \[
            if \(provider\.similarPhotoGroups\.isNotEmpty\) \.\.\.\[
              Expanded\(
                child: _QuickCard\(
                  label: 'Similar\nPhotos',
                  count: provider\.similarPhotoGroups\.length,
                  icon: Icons\.filter_none_rounded,
                  color: const Color\(0xFFE83A59\),
                  onTap: \(\) => Navigator\.push\(
                    context,
                    MaterialPageRoute\(builder: \(_\) => const SimilarPhotosScreen\(\)\),
                  \),
                \),
              \),
              const SizedBox\(width: 12\),
            \],
            Expanded\(
              child: _QuickCard\(
                label: 'Blurry\nPhotos',
                count: 0,
                icon: Icons\.blur_on_rounded,
                color: Colors\.orangeAccent,
                onTap: \(\) => Navigator\.push\(
                  context,
                  MaterialPageRoute\(builder: \(_\) => const BlurryPhotosScreen\(\)\),
                \),
              \),
            \),
          \],
        \),
        if \(provider\.whatsappGroup != null && provider\.whatsappGroup!\.totalItems > 0\) \.\.\.\[
          const SizedBox\(height: 12\),
          _QuickCard\(
            label: 'WhatsApp Junk',
            count: provider\.whatsappGroup!\.totalItems,
            icon: Icons\.chat_bubble_outline_rounded,
            color: const Color\(0xFF25D366\),
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
        \],'''

new_cards = r'''        Row(
          children: [
            Expanded(
              child: _QuickCard(
                label: 'Similar\nPhotos',
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
        const SizedBox(height: 12),
        _QuickCard(
          label: 'WhatsApp Junk',
          count: provider.whatsappGroup?.totalItems ?? 0,
          icon: Icons.chat_bubble_outline_rounded,
          color: const Color(0xFF25D366),
          onTap: () {
            if (provider.whatsappGroup == null || provider.whatsappGroup!.totalItems == 0) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No WhatsApp junk found!')));
              return;
            }
            provider.whatsappGroup!.recalculateCurrentIndex();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SwipeScreen(group: provider.whatsappGroup!),
              ),
            );
          },
        ),'''

content = re.sub(target, new_cards, content)

with open(r'lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Icons always visible")
