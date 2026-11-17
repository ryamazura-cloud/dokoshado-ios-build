import 'package:flutter/material.dart';

class InterestCategory {
  const InterestCategory(this.id, this.label, this.icon);
  final String id, label;
  final IconData icon;
}

const interestCategories = [
  InterestCategory('beauty', '美容/コスメ', Icons.brush_outlined),
  InterestCategory('health', '健康/医療', Icons.medical_services_outlined),
  InterestCategory('food', 'グルメ/料理', Icons.restaurant),
  InterestCategory('fashion', 'ファッション', Icons.checkroom),
  InterestCategory('entertainment', 'エンタメ/芸能', Icons.movie_outlined),
  InterestCategory('lifestyle', 'ライフスタイル', Icons.home_outlined),
  InterestCategory('parenting', '出産/育児', Icons.child_friendly),
  InterestCategory('learning', '学び/資格', Icons.school_outlined),
  InterestCategory('relationships', '恋愛/結婚', Icons.favorite_border),
  InterestCategory('pets', 'ペット', Icons.pets),
  InterestCategory('games', 'ゲーム/アニメ', Icons.sports_esports_outlined),
  InterestCategory('business', 'ビジネス/経済', Icons.work_outline),
  InterestCategory('travel', '旅行/観光', Icons.flight_takeoff),
  InterestCategory('cars', '自動車', Icons.directions_car_outlined),
  InterestCategory('gadgets', '家電/ガジェット', Icons.devices_other),
  InterestCategory('sports', 'スポーツ', Icons.sports_soccer),
  InterestCategory('money', '金融/マネー', Icons.account_balance_wallet_outlined),
];

bool isInterest(String id) => interestCategories.any((c) => c.id == id);
InterestCategory interestCategory(String id) =>
    interestCategories.singleWhere((c) => c.id == id);
String interestLabel(String id) => interestCategory(id).label;

List<String> validateInterests(dynamic raw) {
  if (raw == null) return const [];
  if (raw is! List ||
      raw.any((value) => value is! String || !isInterest(value))) {
    throw const FormatException('Invalid interests');
  }
  if (raw.toSet().length != raw.length) {
    throw const FormatException('Repeated interest');
  }
  return List<String>.from(raw);
}
