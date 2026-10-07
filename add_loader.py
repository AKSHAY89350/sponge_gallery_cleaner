import re

with open(r'lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

target = r'''                  children: \[
                    const Column\(
                      crossAxisAlignment: CrossAxisAlignment\.start,
                      children: \[
                        Text\(
                          'Sponge 🧽',
                          style: TextStyle\(
                            color: Colors\.white,
                            fontSize: 28,
                            fontWeight: FontWeight\.w800,
                            letterSpacing: -0\.5,
                          \),
                        \),
                        Text\(
                          'Gallery Cleaner',
                          style: TextStyle\(color: Colors\.white54, fontSize: 14\),
                        \),
                      \],
                    \),
                    // Trash bin badge
                    if \(provider\.stagingBin\.isNotEmpty\)
                      GestureDetector\('''

replacement = r'''                  children: [
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
                    Row(
                      children: [
                        // Background Sync Loader
                        if (provider.isBackgroundLoading)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Tooltip(
                              message: 'Syncing gallery in background...',
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white54,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                        // Trash bin badge
                        if (provider.stagingBin.isNotEmpty)
                          GestureDetector('''

content = re.sub(target, replacement, content)

target_end = r'''                            ],
                          \),
                        \),
                      \),
                  \],
                \),
              \),'''

replacement_end = r'''                            ],
                          ),
                        ),
                      ),
                      ],
                    ),
                  ],
                ),
              ),'''

content = re.sub(target_end, replacement_end, content)

with open(r'lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Loader injected")
