class CategoryModel {
  final int? id; // ID kategori
  final String name; // Nama kategori
  final DateTime createdAt; // Waktu pembuatan
  final DateTime updatedAt; // Waktu pembaruan

  CategoryModel({
    this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  // Constructor untuk data dari API
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int?,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CategoryModel && other.id == id && other.name == name;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode;
  }
}
