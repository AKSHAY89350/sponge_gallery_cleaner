import re

with open(r'lib/providers/gallery_provider.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Pattern for the direct screenshot album fetch inside loadGallery
ss_fetch_pattern = r'''      // ────────────────────────────────────────────────────────────────────────
      // DIRECT SCREENSHOTS ALBUM FETCH
      // Bypass the 2000 recent items limit to get ALL screenshots perfectly
      // ────────────────────────────────────────────────────────────────────────
      AssetPathEntity\? screenshotAlbum;
      for \(final album in albums\) \{
        if \(album\.name\.toLowerCase\(\)\.contains\('screenshot'\)\) \{
          screenshotAlbum = album;
          break;
        \}
      \}

      if \(screenshotAlbum != null\) \{
        final ssTotal = await screenshotAlbum\.assetCountAsync;
        final ssAssets = await screenshotAlbum\.getAssetListRange\(
          start: 0, 
          end: ssTotal\.clamp\(0, 3000\) // load up to 3000 screenshots
        \);
        
        for \(final asset in ssAssets\) \{
          // Skip if already found in the main "Recent" pass
          if \(screenshots\.any\(\(i\) => i\.id == asset\.id\)\) continue;

          int fileSizeBytes = 0;
          String filePath = '';
          try \{
            final originFile = await asset\.file; // \.file is faster than \.originFile
            filePath = originFile\?\.path \?\? '';
            fileSizeBytes = originFile\?\.lengthSync\(\) \?\? 0;
          \} catch \(_\) \{\}

          final item = GalleryMediaItem\(
            id: asset\.id,
            path: filePath,
            dateTaken: asset\.createDateTime\.millisecondsSinceEpoch,
            fileSize: fileSizeBytes,
            isVideo: asset\.type == AssetType\.video,
            videoDuration: asset\.type == AssetType\.video \? asset\.videoDuration : null,
            width: asset\.width,
            height: asset\.height,
            mimeType: asset\.mimeType,
          \);

          // Load decision
          final savedDecision = prefs\.getString\('decision_\$\{item\.id\}'\);
          if \(savedDecision != null\) \{
            item\.decision = SwipeAction\.values\.firstWhere\(
              \(e\) => e\.name == savedDecision,
              orElse: \(\) => SwipeAction\.keep,
            \);
            if \(item\.decision == SwipeAction\.trash\) \{
              _stagingBin\.add\(item\);
            \}
          \}

          screenshots\.add\(item\);
        \}
      \}

      // Sort screenshots by date newest first
      screenshots\.sort\(\(a, b\) => b\.dateTaken\.compareTo\(a\.dateTaken\)\);'''

content = re.sub(ss_fetch_pattern, '', content)


# Find the background load trigger and add screenshot background loader
bg_trigger_pattern = r'''      // Start background load if there's more data
      if \(albums\.isNotEmpty\) \{
         final total = await albums\.first\.assetCountAsync;
         if \(total > 3000\) \{
            _loadRemainingBackground\(albums\.first, 3000, total\.clamp\(0, 50000\)\);
         \}
      \}'''

bg_trigger_replacement = r'''      // Start background load if there's more data
      if (albums.isNotEmpty) {
         AssetPathEntity? screenshotAlbum;
         for (final album in albums) {
           if (album.name.toLowerCase().contains('screenshot')) {
             screenshotAlbum = album;
             break;
           }
         }
         if (screenshotAlbum != null) {
            _loadScreenshotsInBackground(screenshotAlbum);
         }
         
         final total = await albums.first.assetCountAsync;
         if (total > 3000) {
            _loadRemainingBackground(albums.first, 3000, total.clamp(0, 50000));
         }
      }'''

content = re.sub(bg_trigger_pattern, bg_trigger_replacement, content)

# Add _loadScreenshotsInBackground
loader_method = r'''  Future<void> _loadScreenshotsInBackground(AssetPathEntity screenshotAlbum) async {
    final ssTotal = await screenshotAlbum.assetCountAsync;
    final ssAssets = await screenshotAlbum.getAssetListRange(
      start: 0, 
      end: ssTotal.clamp(0, 5000) 
    );
    
    final prefs = await SharedPreferences.getInstance();
    final newScreenshots = <GalleryMediaItem>[];
    
    for (final asset in ssAssets) {
      if (screenshotsGroup?.items.any((i) => i.id == asset.id) ?? false) continue;

      int fileSizeBytes = 0;
      String filePath = '';
      try {
        final originFile = await asset.file; 
        filePath = originFile?.path ?? '';
        fileSizeBytes = originFile?.lengthSync() ?? 0;
      } catch (_) {}

      final item = GalleryMediaItem(
        id: asset.id,
        path: filePath,
        dateTaken: asset.createDateTime.millisecondsSinceEpoch,
        fileSize: fileSizeBytes,
        isVideo: asset.type == AssetType.video,
        videoDuration: asset.type == AssetType.video ? asset.videoDuration : null,
        width: asset.width,
        height: asset.height,
        mimeType: asset.mimeType,
      );

      final savedDecision = prefs.getString('decision_${item.id}');
      if (savedDecision != null) {
        item.decision = SwipeAction.values.firstWhere(
          (e) => e.name == savedDecision,
          orElse: () => SwipeAction.keep,
        );
        if (item.decision == SwipeAction.trash) {
          if (!_stagingBin.any((existing) => existing.id == item.id)) {
            _stagingBin.add(item);
          }
        }
      }

      newScreenshots.add(item);
    }
    
    if (newScreenshots.isNotEmpty) {
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
      screenshotsGroup!.items.sort((a, b) => b.dateTaken.compareTo(a.dateTaken));
      totalTrashedBytes = _stagingBin.fold(0, (s, item) => s + item.fileSize);
      notifyListeners();
    }
  }

  Future<void> _loadRemainingBackground(AssetPathEntity album, int start, int end) async {'''

content = content.replace('  Future<void> _loadRemainingBackground(AssetPathEntity album, int start, int end) async {', loader_method)

with open(r'lib/providers/gallery_provider.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Screenshots extraction complete")
