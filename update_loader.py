import re

with open(r'lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update the Header Loader
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
                                  style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold),
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

# 2. Update the Quick Cards Section
# To do this safely, I'll extract everything between "Quick Clean section" and the end of the cards
start_marker = r'// Quick Clean section'
end_marker = r'// "?'
# wait, what comes after blurry photos card?
# Let's check what comes after.

