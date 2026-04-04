
// ─── Banner Model ─────────────────────────────────────────────────────────────
import 'package:cloud_firestore/cloud_firestore.dart';

class BannerModel {
  final String id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String colorHex;
  final String? actionUrl;
  final int sortOrder;

  BannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.colorHex,
    this.actionUrl,
    this.sortOrder = 0,
  });

  factory BannerModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BannerModel(
      id: doc.id,
      title: d['title'] ?? '',
      subtitle: d['subtitle'] ?? '',
      imageUrl: d['imageUrl'],
      colorHex: d['colorHex'] ?? '#0D2B1F',
      actionUrl: d['actionUrl'],
      sortOrder: d['sortOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title, 'subtitle': subtitle, 'imageUrl': imageUrl,
    'colorHex': colorHex, 'actionUrl': actionUrl, 'sortOrder': sortOrder,
  };
}