import re

path = 'lib/features/dashboard/home_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target = """                if (provider.randomGroup != null)
                  Expanded(
                    child: _QuickCard(
                      icon: Icons.shuffle_rounded,
                      label: 'Random\\nClean',
                      count: provider.randomGroup!.items.where((i) => i.decision == null).length,
                      color: const Color(0xFF10B981),
                      onTap: () => _openGroup(context, provider.randomGroup!),
                    ),
                  ),""".replace('\\n', '\n')

replacement = """                if (provider.randomGroup != null)
                  Expanded(
                    child: _QuickCard(
                      icon: Icons.shuffle_rounded,
                      label: 'Random\\nClean',
                      count: provider.randomGroup!.items.where((i) => i.decision == null).length,
                      color: const Color(0xFF10B981),
                      onTap: () {
                        if (provider.randomGroup!.items.where((i) => i.decision == null).isEmpty) {
                          provider.refreshRandomGroup();
                        }
                        _openGroup(context, provider.randomGroup!);
                      },
                    ),
                  ),""".replace('\\n', '\n')

if target in content:
    content = content.replace(target, replacement)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Updated home_screen.dart")
else:
    print("Target not found.")
