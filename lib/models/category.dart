class Category {
  int? id;
  String name;
  String icon;
  String color;
  int isDefault;

  Category({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isDefault = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'is_default': isDefault,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      icon: map['icon'],
      color: map['color'],
      isDefault: map['is_default'] ?? 1,
    );
  }
}