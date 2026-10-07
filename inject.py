import re

with open(r'lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

target = r'''  Widget _buildGroupList\(BuildContext context, GalleryProvider provider\) \{
    return ListView\(
      padding: const EdgeInsets\.all\(24\),
      children: \['''

replacement = r'''  Widget _buildGroupList(BuildContext context, GalleryProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StorageCircleWidget(provider: provider),
            _MonthsReviewedWidget(provider: provider),
          ],
        ),
        const SizedBox(height: 32),'''

content = re.sub(target, replacement, content)

with open(r'lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Dashboard injected")
