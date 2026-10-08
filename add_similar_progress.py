import sys

with open(r'lib/screens/similar_photos_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

target = r'''        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Similar & Burst', style: TextStyle(fontWeight: FontWeight.w700)),
          centerTitle: true,
        ),'''

new_code = r'''        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Similar & Burst', style: TextStyle(fontWeight: FontWeight.w700)),
          centerTitle: true,
          actions: [
            if (provider.similarPhotoGroups.isNotEmpty)
              Builder(
                builder: (context) {
                  final totalGroups = provider.similarPhotoGroups.where((g) => g.length > 1).length;
                  if (totalGroups == 0) return const SizedBox.shrink();
                  
                  final resolvedCount = totalGroups - liveGroups.length;
                  final percent = resolvedCount / totalGroups;
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 38,
                            height: 38,
                            child: CircularProgressIndicator(
                              value: percent,
                              backgroundColor: Colors.white10,
                              color: const Color(0xFFE83A59),
                              strokeWidth: 3,
                            ),
                          ),
                          Text(
                            '${(percent * 100).toInt()}%',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              ),
          ],
        ),'''

if target in content:
    content = content.replace(target, new_code)
    with open(r'lib/screens/similar_photos_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)
    print("Percentage circle added successfully")
else:
    print("Target not found")
