class Product {
  final int id;
  final String name;
  final String desc;
  final String mrp;
  final String sp;
  final String image1;
  final List<dynamic> units;

  Product({
    required this.id,
    required this.name,
    required this.desc,
    required this.mrp,
    required this.sp,
    required this.image1,
    required this.units,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['PROD_ID'] ?? 0,
      name: json['PROD_NAME'] ?? '',
      desc: json['PROD_DESC'] ?? '',
      mrp: json['PROD_MRP'] ?? '',
      sp: json['PROD_SP'] ?? '',
      image1: json['PROD_IMAGE_1'] ?? '',
      units: json['units'] ?? [],
    );
  }
} 