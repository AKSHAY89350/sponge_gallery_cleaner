import os
import shutil

# 1. Move video_card_player
old_vcp = 'lib/widgets/video_card_player.dart'
new_vcp = 'lib/core/widgets/video_card_player.dart'
if os.path.exists(old_vcp):
    shutil.move(old_vcp, new_vcp)

# 2. Fix import in swipe_screen.dart
ss_path = 'lib/features/media_cleaners/swipe_screen.dart'
with open(ss_path, 'r', encoding='utf-8') as f:
    ss_content = f.read()

ss_content = ss_content.replace(
    "import '../widgets/video_card_player.dart';", 
    "import 'package:sponge_gallery_cleaner/core/widgets/video_card_player.dart';"
)

with open(ss_path, 'w', encoding='utf-8') as f:
    f.write(ss_content)

# 3. Fix import in widget_test.dart
test_path = 'test/widget_test.dart'
if os.path.exists(test_path):
    with open(test_path, 'r', encoding='utf-8') as f:
        test_content = f.read()
    
    test_content = test_content.replace(
        "import 'package:sponge_gallery_cleaner/providers/gallery_provider.dart';",
        "import 'package:sponge_gallery_cleaner/features/gallery_core/providers/gallery_provider.dart';"
    )
    with open(test_path, 'w', encoding='utf-8') as f:
        f.write(test_content)

# Remove old empty directories again
for old_dir in ['lib/models', 'lib/providers', 'lib/utils', 'lib/widgets', 'lib/screens']:
    if os.path.exists(old_dir):
        try:
            os.rmdir(old_dir)
        except OSError:
            pass
