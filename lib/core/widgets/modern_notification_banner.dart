import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ModernBannerType {
  success,
  trash,
  restore,
  info,
  warning,
  error,
}

class ModernNotificationBanner {
  static void show(
    BuildContext? context, {
    ScaffoldMessengerState? messenger,
    required String message,
    String? subtitle,
    ModernBannerType type = ModernBannerType.success,
    Duration duration = const Duration(seconds: 2),
  }) {
    HapticFeedback.lightImpact();

    final Color accentColor;
    final IconData iconData;

    switch (type) {
      case ModernBannerType.success:
        accentColor = const Color(0xFF10B981); // Emerald Green
        iconData = Icons.check_circle_rounded;
        break;
      case ModernBannerType.trash:
        accentColor = const Color(0xFFEF4444); // Coral Red
        iconData = Icons.delete_sweep_rounded;
        break;
      case ModernBannerType.restore:
        accentColor = const Color(0xFF38BDF8); // Sky Blue
        iconData = Icons.restore_rounded;
        break;
      case ModernBannerType.info:
        accentColor = const Color(0xFF818CF8); // Indigo
        iconData = Icons.info_outline_rounded;
        break;
      case ModernBannerType.warning:
        accentColor = const Color(0xFFFBBF24); // Amber
        iconData = Icons.warning_amber_rounded;
        break;
      case ModernBannerType.error:
        accentColor = const Color(0xFFF43F5E); // Rose
        iconData = Icons.error_outline_rounded;
        break;
    }

    final targetMessenger = messenger ?? (context != null ? ScaffoldMessenger.of(context) : null);
    if (targetMessenger == null) return;
    targetMessenger.hideCurrentSnackBar();

    targetMessenger.showSnackBar(
      SnackBar(
        duration: duration,
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        padding: EdgeInsets.zero,
        content: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.18),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Glowing Icon Badge
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor.withValues(alpha: 0.15),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      iconData,
                      color: accentColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Message Text
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null && subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
