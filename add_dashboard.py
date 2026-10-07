import re

with open(r'lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Locate ListView children start
listview_start = r'''          child: ListView\(
            padding: const EdgeInsets\.symmetric\(horizontal: 20, vertical: 24\),
            children: \['''

dashboard_code = r'''          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              // Dashboard Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StorageCircleWidget(provider: provider),
                  _MonthsReviewedWidget(provider: provider),
                ],
              ),
              const SizedBox(height: 32),'''

content = re.sub(listview_start, dashboard_code, content)

# Append widgets at EOF
widgets_code = r'''
class _StorageCircleWidget extends StatelessWidget {
  final GalleryProvider provider;
  const _StorageCircleWidget({required this.provider});

  @override
  Widget build(BuildContext context) {
    final total = provider.totalDiskSpaceMB ?? 0.0;
    final free = provider.freeDiskSpaceMB ?? 0.0;
    final used = total > 0 ? total - free : 0.0;
    
    final percent = total > 0 ? (used / total) : 0.0;
    
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 90,
              height: 90,
              child: CircularProgressIndicator(
                value: percent,
                backgroundColor: Colors.white10,
                color: const Color(0xFF6C63FF),
                strokeWidth: 8,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(percent * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Used',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Storage', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        if (total > 0)
           Text('${(free / 1024).toStringAsFixed(1)} GB Free', style: const TextStyle(color: Colors.white54, fontSize: 12)),
        if (total == 0)
           const Text('Calculating...', style: TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}

class _MonthsReviewedWidget extends StatelessWidget {
  final GalleryProvider provider;
  const _MonthsReviewedWidget({required this.provider});

  @override
  Widget build(BuildContext context) {
    final totalMonths = provider.monthGroups.length;
    final reviewedMonths = provider.monthGroups.where((g) => g.isComplete).length;
    
    final percent = totalMonths > 0 ? (reviewedMonths / totalMonths) : 0.0;
    
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 90,
              height: 90,
              child: CircularProgressIndicator(
                value: percent,
                backgroundColor: Colors.white10,
                color: const Color(0xFF10B981),
                strokeWidth: 8,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$reviewedMonths / $totalMonths',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Months',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Reviewed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        const Text('Keep it up!', style: TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}
'''

content += widgets_code

with open(r'lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Dashboard added to HomeScreen")
