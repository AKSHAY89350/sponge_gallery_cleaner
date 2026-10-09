import re

path = 'lib/features/media_cleaners/blurry_photos_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target = """              if (provider.isBlurryScanning)
                _buildScanningIndicator(
                    provider.blurryScannedCount, provider.blurryTotalCount),"""

replacement = """              _buildScanningIndicator(
                  provider.blurryAnalyzedCount, provider.blurryTotalTarget, provider.isBlurryScanning),"""

content = content.replace(target, replacement)

# Now update the method signature of _buildScanningIndicator
target2 = """  Widget _buildScanningIndicator(int scanned, int total) {"""
replacement2 = """  Widget _buildScanningIndicator(int scanned, int total, bool isScanning) {"""
content = content.replace(target2, replacement2)

# Update the text "AI Scanning..."
target3 = """          Text('AI Scanning... $scanned / $total photos analyzed',"""
replacement3 = """          Text(isScanning ? 'AI Scanning... $scanned / $total photos analyzed' : 'Scan Complete. $scanned / $total photos analyzed',"""
content = content.replace(target3, replacement3)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated blurry photos screen")
