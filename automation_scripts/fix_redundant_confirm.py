path = 'lib/features/staging_bin/staging_bin_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

start_sig = "  Future<void> _confirmAndDelete("
end_sig = "    }\n  }\n}\n"

start_idx = content.find(start_sig)
end_idx = content.find(end_sig, start_idx) + len(end_sig)

if start_idx != -1 and end_idx != -1:
    old_func = content[start_idx:end_idx]
    
    new_func = """  Future<void> _confirmAndDelete(
      BuildContext context, GalleryProvider provider) async {
    // Capture context-dependent objects BEFORE any await
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (mounted) {
      setState(() => _isDeleting = true);
      try {
        final deletedCount = await provider.permanentlyDeleteStaged();
        if (mounted) {
          setState(() => _isDeleting = false);
          if (deletedCount > 0) {
            navigator.pop();
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                    '✅ $deletedCount item${deletedCount > 1 ? "s" : ""} deleted permanently!'),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('⚠️ Deletion cancelled or denied by system.'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);
          messenger.showSnackBar(
            const SnackBar(
              content: Text('❌ Error deleting items. System rejected request.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}
"""
    new_content = content[:start_idx] + new_func + content[end_idx:]
    with open(path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("Fixed!")
else:
    print("Could not find boundaries")
