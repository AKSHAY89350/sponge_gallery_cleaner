import re

with open(r'lib/providers/gallery_provider.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add whatsappGroup
target_vars = r'''  MonthGroup\? screenshotsGroup;
  MonthGroup\? randomGroup;'''
new_vars = r'''  MonthGroup? screenshotsGroup;
  MonthGroup? whatsappGroup;
  MonthGroup? randomGroup;'''
content = re.sub(target_vars, new_vars, content)

# Add to _loadInitial
target_init_lists = r'''      final Map<String, List<GalleryMediaItem>> byMonth = \{\};
      final List<GalleryMediaItem> screenshots = \[\];'''
new_init_lists = r'''      final Map<String, List<GalleryMediaItem>> byMonth = {};
      final List<GalleryMediaItem> screenshots = [];
      final List<GalleryMediaItem> whatsappItems = [];'''
content = re.sub(target_init_lists, new_init_lists, content)

target_init_add = r'''          // Screenshots filter \(by path or mime type\)
          final pathLower = item.path.toLowerCase\(\);
          if \(pathLower.contains\('screenshot'\) \|\|
              pathLower.contains\('screen_record'\)\) \{
            screenshots.add\(item\);
          \}'''
new_init_add = r'''          // Screenshots filter (by path or mime type)
          final pathLower = item.path.toLowerCase();
          if (pathLower.contains('screenshot') ||
              pathLower.contains('screen_record')) {
            screenshots.add(item);
          }
          if (item.isWhatsApp) {
            whatsappItems.add(item);
          }'''
content = re.sub(target_init_add, new_init_add, content)

target_init_group = r'''      if \(screenshots.isNotEmpty\) \{
        screenshotsGroup = MonthGroup\(
          label: 'Screenshots',
          yearMonthKey: 'screenshots',
          items: screenshots,
          isScreenshots: true,
        \);
      \}'''
new_init_group = r'''      if (screenshots.isNotEmpty) {
        screenshotsGroup = MonthGroup(
          label: 'Screenshots',
          yearMonthKey: 'screenshots',
          items: screenshots,
          isScreenshots: true,
        );
      }
      if (whatsappItems.isNotEmpty) {
        whatsappGroup = MonthGroup(
          label: 'WhatsApp Junk',
          yearMonthKey: 'whatsapp',
          items: whatsappItems,
        );
      }'''
content = re.sub(target_init_group, new_init_group, content)

# Add to _loadRemainingBackground
target_bg_add = r'''          if \(pathLower.contains\('screenshot'\) \|\|
              pathLower.contains\('screen_record'\)\) \{
            newScreenshots.add\(item\);
          \}'''
new_bg_add = r'''          if (pathLower.contains('screenshot') ||
              pathLower.contains('screen_record')) {
            newScreenshots.add(item);
          }
          if (item.isWhatsApp) {
            if (whatsappGroup == null) {
              whatsappGroup = MonthGroup(
                 label: 'WhatsApp Junk',
                 yearMonthKey: 'whatsapp',
                 items: [item],
              );
            } else {
              whatsappGroup!.items.add(item);
            }
          }'''
content = re.sub(target_bg_add, new_bg_add, content)

# Delete items
target_delete = r'''    screenshotsGroup\?\.items\.removeWhere\(\(i\) => deletedIds\.contains\((i\.id)\)\);'''
new_delete = r'''    screenshotsGroup?.items.removeWhere((i) => deletedIds.contains(i.id));
    whatsappGroup?.items.removeWhere((i) => deletedIds.contains(i.id));'''
content = re.sub(target_delete, new_delete, content)

with open(r'lib/providers/gallery_provider.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("WhatsApp logic added to provider")
