import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:sponge_gallery_cleaner/features/gallery_core/models/gallery_media_item.dart';

class PersonCluster {
  final String id;
  String name;
  Uint8List? avatarBytes;
  final List<GalleryMediaItem> items;
  List<double> featureVector;

  PersonCluster({
    required this.id,
    required this.name,
    this.avatarBytes,
    required this.items,
    required this.featureVector,
  });

  int get photoCount => items.length;

  int get pendingPhotoCount =>
      items.where((i) => i.decision == null).length;

  void addPhoto(GalleryMediaItem item, List<double> newFeatures, {Uint8List? newAvatar}) {
    if (!items.any((i) => i.id == item.id)) {
      items.add(item);
    }
    if (avatarBytes == null && newAvatar != null) {
      avatarBytes = newAvatar;
    }
    // Conservative anchor-based blending:
    // Caps weight between 1% and 3% to preserve original high-confidence anchor profile
    // and completely eliminate snowball cluster drift.
    if (featureVector.length == newFeatures.length) {
      final weight = (1.0 / (items.length + 12)).clamp(0.01, 0.03);
      for (int i = 0; i < featureVector.length; i++) {
        featureVector[i] = (featureVector[i] * (1.0 - weight)) + (newFeatures[i] * weight);
      }
    } else if (newFeatures.length > featureVector.length) {
      // Smoothly upgrade legacy vectors to full 8-dimensional profile
      featureVector = List<double>.from(newFeatures);
    }
  }

  /// Calculates biometric similarity (0.0 to 1.0) using weighted normalized landmark error
  double calculateSimilarity(List<double> other) {
    if (featureVector.isEmpty || other.isEmpty) {
      return 0.0;
    }
    final compareLen = math.min(featureVector.length, other.length);
    if (compareLen == 0) return 0.0;

    // Feature importance weights:
    // Bone structure & invariant geometry (eyeToNose, cheekWidth, eyeToCheek, faceAspect)
    // carry higher weight than expression-sensitive features (mouthWidth, noseToMouth).
    const weights = [1.5, 1.0, 0.8, 1.0, 1.5, 1.2, 1.2, 1.0];
    double totalWeightedError = 0.0;
    double totalWeight = 0.0;

    for (int i = 0; i < compareLen; i++) {
      final a = featureVector[i];
      final b = other[i];
      if (a <= 0 || b <= 0) continue;
      final w = i < weights.length ? weights[i] : 1.0;
      totalWeightedError += ((a - b).abs() / a) * w;
      totalWeight += w;
    }

    if (totalWeight <= 0) return 0.0;
    final avgError = totalWeightedError / totalWeight;
    return (1.0 - avgError).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarBase64': avatarBytes != null ? base64Encode(avatarBytes!) : null,
      'itemIds': items.map((i) => i.id).toList(),
      'featureVector': featureVector,
    };
  }

  factory PersonCluster.fromJson(
    Map<String, dynamic> json,
    Map<String, GalleryMediaItem> itemMap,
  ) {
    final itemIds = (json['itemIds'] as List<dynamic>?)?.cast<String>() ?? [];
    final items = <GalleryMediaItem>[];
    for (final id in itemIds) {
      final it = itemMap[id];
      if (it != null) items.add(it);
    }

    Uint8List? avatar;
    if (json['avatarBase64'] != null) {
      try {
        avatar = base64Decode(json['avatarBase64'] as String);
      } catch (_) {}
    }

    final fVector = (json['featureVector'] as List<dynamic>?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        [];

    return PersonCluster(
      id: json['id'] as String? ?? 'person_1',
      name: json['name'] as String? ?? 'Person',
      avatarBytes: avatar,
      items: items,
      featureVector: fVector,
    );
  }
}
