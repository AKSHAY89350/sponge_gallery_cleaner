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
    // Update feature vector centroid
    if (featureVector.length == newFeatures.length) {
      for (int i = 0; i < featureVector.length; i++) {
        featureVector[i] = (featureVector[i] * 0.75) + (newFeatures[i] * 0.25);
      }
    }
  }

  /// Calculates cosine similarity between this person's centroid and a target vector
  double calculateSimilarity(List<double> other) {
    if (featureVector.isEmpty || other.isEmpty || featureVector.length != other.length) {
      return 0.0;
    }
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    for (int i = 0; i < featureVector.length; i++) {
      dotProduct += featureVector[i] * other[i];
      normA += featureVector[i] * featureVector[i];
      normB += other[i] * other[i];
    }

    if (normA <= 0 || normB <= 0) return 0.0;
    return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
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
