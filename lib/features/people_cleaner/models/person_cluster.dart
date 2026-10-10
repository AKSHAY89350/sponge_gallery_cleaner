import 'dart:convert';
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
    // Update centroid very conservatively to prevent snowball cluster drift
    if (featureVector.length == newFeatures.length) {
      for (int i = 0; i < featureVector.length; i++) {
        featureVector[i] = (featureVector[i] * 0.93) + (newFeatures[i] * 0.07);
      }
    }
  }

  /// Calculates biometric similarity (0.0 to 1.0) using normalized geometric proportion difference
  double calculateSimilarity(List<double> other) {
    if (featureVector.isEmpty || other.isEmpty || featureVector.length != other.length) {
      return 0.0;
    }
    double totalError = 0.0;
    for (int i = 0; i < featureVector.length; i++) {
      final a = featureVector[i];
      final b = other[i];
      if (a <= 0 || b <= 0) continue;
      totalError += (a - b).abs() / a;
    }
    final avgError = totalError / featureVector.length;
    // 0 error = 1.0 match. If average landmark difference is 7%, similarity is 0.93.
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
