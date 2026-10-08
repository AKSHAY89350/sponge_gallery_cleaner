import sys

with open(r'lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

target = r'''            if (provider.whatsappGroup == null || provider.whatsappGroup!.totalItems == 0) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No WhatsApp junk found!')));
              return;
            }'''

new_code = r'''            if (provider.whatsappGroup == null || provider.whatsappGroup!.totalItems == 0) {
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  backgroundColor: const Color(0xFF1C1C1C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle_rounded, color: Color(0xFF25D366), size: 64),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Squeaky Clean!',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No WhatsApp junk found on your device. Great job keeping your gallery tidy!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Awesome', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
              return;
            }'''

if target in content:
    content = content.replace(target, new_code)
    with open(r'lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)
    print("Beautiful empty state added for WhatsApp")
else:
    print("Target not found in home_screen")
