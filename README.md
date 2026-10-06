# Sponge Gallery Cleaner

A fast, intuitive, swipe-based gallery cleaner app inspired by Sponge. 
Quickly clean up your device's photos and videos with a Tinder-like swipe interface!

## 🔒 100% Offline & Privacy-Focused
**Your data never leaves your device.** 
Sponge Gallery Cleaner is built with absolute privacy in mind:
- **No Internet Permission**: The release version of this app does not even request internet access (`android.permission.INTERNET` is not in the main manifest).
- **No Analytics or Telemetry**: We do not track your usage, crashes, or any other metrics.
- **Local Processing**: All photo loading, video playback, and file deletion happens entirely on your device's local storage.

## Features
- **Swipe Interface:** Swipe right to Keep, swipe left to Trash.
- **Video Support:** Inline video player to preview video files before deciding.
- **Timeline Preview:** A top bar showing your recent decisions and upcoming media.
- **Safe Staging Bin:** Trashed items are held in a Staging Bin until you permanently delete them.
- **Month-by-Month Grouping:** Easily clean up old photos month by month.

## Permissions Requested
- `READ_EXTERNAL_STORAGE` / `READ_MEDIA_IMAGES` / `READ_MEDIA_VIDEO`: To display your gallery items.
- `WRITE_EXTERNAL_STORAGE`: To permanently delete items from your device.
- `VIBRATE`: For haptic feedback when swiping.

## Getting Started

1. Clone the repository.
2. Ensure you have the Flutter SDK installed.
3. Run `flutter pub get` to fetch dependencies.
4. Run `flutter run` on an emulator or physical device.

*(Note: Requires Android SDK 36)*
