// lib/models/review_model.dart

class ReviewModel {
  final String id;
  final String spotId;
  final String userId;
  final String userName;
  final String text;
  final double rating;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.spotId,
    required this.userId,
    required this.userName,
    required this.text,
    required this.rating,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'spotId': spotId,
      'userId': userId,
      'userName': userName,
      'text': text,
      'rating': rating,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map['id'] ?? '',
      spotId: map['spotId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      text: map['text'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
