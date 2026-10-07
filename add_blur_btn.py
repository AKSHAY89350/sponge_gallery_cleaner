import re

with open(r'lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
if "import 'blurry_photos_screen.dart';" not in content:
    content = content.replace("import 'staging_bin_screen.dart';", "import 'staging_bin_screen.dart';\nimport 'blurry_photos_screen.dart';")

# Add QuickCard under WhatsApp
target = r'''        if \(provider.whatsappGroup != null && provider.whatsappGroup!.totalItems > 0\)
          _QuickCard\(
            label: 'WhatsApp Junk',
            count: provider.whatsappGroup!.totalItems,
            icon: Icons.chat_bubble_outline_rounded,
            color: const Color\(0xFF25D366\), // WhatsApp Green
            onTap: \(\) \{
              provider.whatsappGroup!.recalculateCurrentIndex\(\);
              Navigator.push\(
                context,
                MaterialPageRoute\(
                  builder: \(_\) => SwipeScreen\(group: provider.whatsappGroup!\),
                \),
              \);
            \},
          \),'''

new_target = r'''        if (provider.whatsappGroup != null && provider.whatsappGroup!.totalItems > 0)
          _QuickCard(
            label: 'WhatsApp Junk',
            count: provider.whatsappGroup!.totalItems,
            icon: Icons.chat_bubble_outline_rounded,
            color: const Color(0xFF25D366), // WhatsApp Green
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
        const SizedBox(height: 12),
        _QuickCard(
          label: 'Blurry Photos',
          count: 0,
          icon: Icons.blur_on_rounded,
          color: Colors.orangeAccent,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BlurryPhotosScreen()),
          ),
        ),'''

content = re.sub(target, new_target, content)

with open(r'lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Blurry photos button added")
