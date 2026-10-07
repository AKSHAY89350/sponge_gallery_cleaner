import re

with open(r'lib/providers/gallery_provider.dart', 'r', encoding='utf-8') as f:
    content = f.read()

target = r'''      notifyListeners\(\);
    \}

    isBackgroundLoading = false;
    _findSimilarPhotos\(\);
    notifyListeners\(\);
  \}'''

# wait, I don't know the exact indentation. I will just use string replace.
target_str = """      notifyListeners();
    }

    isBackgroundLoading = false;
    _findSimilarPhotos();
    notifyListeners();
  }"""

replacement_str = """      notifyListeners();
    }
    
    _findSimilarPhotos();
    } finally {
      isBackgroundLoading = false;
      notifyListeners();
    }
  }"""

if target_str in content:
    content = content.replace(target_str, replacement_str)
else:
    # Try another pattern
    target_str2 = """        notifyListeners();
      }

    isBackgroundLoading = false;
    _findSimilarPhotos();
    notifyListeners();
  }"""
    
    replacement_str2 = """        notifyListeners();
      }

    _findSimilarPhotos();
    } finally {
      isBackgroundLoading = false;
      notifyListeners();
    }
  }"""
    content = content.replace(target_str2, replacement_str2)

with open(r'lib/providers/gallery_provider.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed")
