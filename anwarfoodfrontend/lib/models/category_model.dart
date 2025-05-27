class Category {
  final int id;
  final String name;
  final String imageUrl;

  Category({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['CATEGORY_ID'] ?? 0,
      name: json['CATEGORY_NAME'] ?? '',
      imageUrl: json['CAT_IMAGE'] ?? '',
    );
  }
} 