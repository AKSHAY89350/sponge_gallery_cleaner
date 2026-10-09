import re

path = 'lib/features/gallery_core/providers/gallery_provider.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target = """    randomGroup?.items.removeWhere((i) => deletedIds.contains(i.id));

    notifyListeners();
    return deletedIds.length;
  }"""

replacement = """    randomGroup?.items.removeWhere((i) => deletedIds.contains(i.id));

    // Refetch disk space so the home screen storage widget updates!
    await fetchDiskSpace();

    notifyListeners();
    return deletedIds.length;
  }"""

if target in content:
    content = content.replace(target, replacement)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Fixed storage update issue.")
else:
    print("Target not found.")
