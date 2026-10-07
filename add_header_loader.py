import sys

with open(r'lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

target = r'''                    // Trash bin badge
                    if \(provider\.stagingBin\.isNotEmpty\)'''

new_code = r'''                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Background Sync Loader with Percentage
                        if (provider.isBackgroundLoading)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
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
                        // Trash bin badge
                        if (provider.stagingBin.isNotEmpty)'''

if "if (provider.stagingBin.isNotEmpty)" in content:
    import re
    new_content = re.sub(target, new_code, content)
    with open(r'lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("Loader added successfully")
else:
    print("Could not find target")
