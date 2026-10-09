import re

path = 'lib/features/gallery_core/providers/gallery_provider.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target = """    } finally {
      isBlurryScanning = false;
      notifyListeners();
    }
  }"""

replacement = """    } finally {
      isBlurryScanning = false;
      notifyListeners();
      
      if (hasUnscannedBlurry) {
        Future.microtask(() => scanMoreBlurry());
      }
    }
  }"""

content = content.replace(target, replacement)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated gallery provider auto loop")
