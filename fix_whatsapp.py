import sys

with open(r'lib/providers/gallery_provider.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Instantiate whatsappGroup in _loadInitial
target1 = r'''        if (screenshots.isNotEmpty) {
          screenshotsGroup = MonthGroup(
            label: 'Screenshots',
            yearMonthKey: 'screenshots',
            items: screenshots,
            isScreenshots: true,
          )..recalculateCurrentIndex();
        }'''

new1 = r'''        if (screenshots.isNotEmpty) {
          screenshotsGroup = MonthGroup(
            label: 'Screenshots',
            yearMonthKey: 'screenshots',
            items: screenshots,
            isScreenshots: true,
          )..recalculateCurrentIndex();
        }
        
        if (whatsappItems.isNotEmpty) {
          whatsappGroup = MonthGroup(
            label: 'WhatsApp Junk',
            yearMonthKey: 'whatsapp',
            items: whatsappItems,
          )..recalculateCurrentIndex();
        }'''
content = content.replace(target1, new1)

# 2. Add isWhatsApp logic to _loadRemainingBackground
target2 = r'''        final List<GalleryMediaItem> newScreenshots = [];'''
new2 = r'''        final List<GalleryMediaItem> newScreenshots = [];
        final List<GalleryMediaItem> newWhatsapp = [];'''
content = content.replace(target2, new2)

target3 = r'''          if (pathLower.contains('screenshot') || pathLower.contains('screen_record')) {
            newScreenshots.add(item);
          }'''
new3 = r'''          if (pathLower.contains('screenshot') || pathLower.contains('screen_record')) {
            newScreenshots.add(item);
          }
          if (item.isWhatsApp) {
            newWhatsapp.add(item);
          }'''
content = content.replace(target3, new3)

target4 = r'''      if (newScreenshots.isNotEmpty) {
        if (screenshotsGroup == null) {
           screenshotsGroup = MonthGroup(
             label: 'Screenshots',
             yearMonthKey: 'screenshots',
             items: newScreenshots,
             isScreenshots: true,
           );
        } else {
           screenshotsGroup!.items.addAll(newScreenshots);
        }
      }'''
new4 = r'''      if (newScreenshots.isNotEmpty) {
        if (screenshotsGroup == null) {
           screenshotsGroup = MonthGroup(
             label: 'Screenshots',
             yearMonthKey: 'screenshots',
             items: newScreenshots,
             isScreenshots: true,
           );
        } else {
           screenshotsGroup!.items.addAll(newScreenshots);
        }
      }
      
      if (newWhatsapp.isNotEmpty) {
        if (whatsappGroup == null) {
           whatsappGroup = MonthGroup(
             label: 'WhatsApp Junk',
             yearMonthKey: 'whatsapp',
             items: newWhatsapp,
           );
        } else {
           whatsappGroup!.items.addAll(newWhatsapp);
        }
      }'''
content = content.replace(target4, new4)


with open(r'lib/providers/gallery_provider.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("WhatsApp logic fixed")
