import os
import shutil
import re

# File mapping: old_relative_path -> new_relative_path
file_moves = {
    'lib/models/gallery_media_item.dart': 'lib/features/gallery_core/models/gallery_media_item.dart',
    'lib/providers/gallery_provider.dart': 'lib/features/gallery_core/providers/gallery_provider.dart',
    'lib/utils/blur_detector.dart': 'lib/core/utils/blur_detector.dart',
    'lib/widgets/universal_preview_dialog.dart': 'lib/core/widgets/universal_preview_dialog.dart',
    'lib/screens/home_screen.dart': 'lib/features/dashboard/home_screen.dart',
    'lib/screens/permission_screen.dart': 'lib/features/dashboard/permission_screen.dart',
    'lib/screens/staging_bin_screen.dart': 'lib/features/staging_bin/staging_bin_screen.dart',
    'lib/screens/swipe_screen.dart': 'lib/features/media_cleaners/swipe_screen.dart',
    'lib/screens/blurry_photos_screen.dart': 'lib/features/media_cleaners/blurry_photos_screen.dart',
    'lib/screens/similar_photos_screen.dart': 'lib/features/media_cleaners/similar_photos_screen.dart',
    'lib/screens/large_files_menu_screen.dart': 'lib/features/media_cleaners/large_files_menu_screen.dart'
}

# Create new directories
for new_path in file_moves.values():
    os.makedirs(os.path.dirname(new_path), exist_ok=True)

# Move files
for old_path, new_path in file_moves.items():
    if os.path.exists(old_path):
        shutil.move(old_path, new_path)
    else:
        print(f"Warning: {old_path} not found.")

# We will replace any import that ends with these filenames with the package import
filename_to_package = {
    'gallery_media_item.dart': 'package:sponge_gallery_cleaner/features/gallery_core/models/gallery_media_item.dart',
    'gallery_provider.dart': 'package:sponge_gallery_cleaner/features/gallery_core/providers/gallery_provider.dart',
    'blur_detector.dart': 'package:sponge_gallery_cleaner/core/utils/blur_detector.dart',
    'universal_preview_dialog.dart': 'package:sponge_gallery_cleaner/core/widgets/universal_preview_dialog.dart',
    'home_screen.dart': 'package:sponge_gallery_cleaner/features/dashboard/home_screen.dart',
    'permission_screen.dart': 'package:sponge_gallery_cleaner/features/dashboard/permission_screen.dart',
    'staging_bin_screen.dart': 'package:sponge_gallery_cleaner/features/staging_bin/staging_bin_screen.dart',
    'swipe_screen.dart': 'package:sponge_gallery_cleaner/features/media_cleaners/swipe_screen.dart',
    'blurry_photos_screen.dart': 'package:sponge_gallery_cleaner/features/media_cleaners/blurry_photos_screen.dart',
    'similar_photos_screen.dart': 'package:sponge_gallery_cleaner/features/media_cleaners/similar_photos_screen.dart',
    'large_files_menu_screen.dart': 'package:sponge_gallery_cleaner/features/media_cleaners/large_files_menu_screen.dart'
}

def update_imports_in_file(filepath):
    if not os.path.exists(filepath): return
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Replace relative imports with absolute package imports
    for filename, package_path in filename_to_package.items():
        # Match import '.../filename.dart'; or import 'filename.dart';
        # Regex explanation: import\s+['"]([^'"]*/)filename\.dart['"]\s*;
        pattern = r"import\s+['\"](?:[^'\"]*/)?" + re.escape(filename) + r"['\"]\s*;"
        replacement = f"import '{package_path}';"
        content = re.sub(pattern, replacement, content)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

# Update imports in all dart files in lib
for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            update_imports_in_file(os.path.join(root, file))

# Remove old empty directories if they exist
for old_dir in ['lib/models', 'lib/providers', 'lib/utils', 'lib/widgets', 'lib/screens']:
    if os.path.exists(old_dir):
        try:
            os.rmdir(old_dir)
        except OSError:
            print(f"Directory {old_dir} is not empty.")

print("Migration completed.")
