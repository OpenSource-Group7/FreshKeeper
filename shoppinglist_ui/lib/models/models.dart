class ShoppingItem {
  String name;
  String quantity;
  String unit;
  bool isChecked;

  ShoppingItem({
    required this.name,
    required this.quantity,
    required this.unit,
    this.isChecked = false,
  });
}

class RecipeModel {
  String title;
  String duration;
  List<String> ingredients;

  RecipeModel({
    required this.title,
    required this.duration,
    required this.ingredients,
  });
}

class Ingredient {
  final int? id;
  final String name;
  final String unit;
  final String category;
  final String status;
  final DateTime expiryDate;
  final DateTime useByDate;
  final double quantity;
  final double progress;

  Ingredient({
    this.id,
    required this.name,
    required this.expiryDate,
    required this.useByDate,
    required this.quantity,
    required this.unit,
    required this.category,
    required this.status,
    required this.progress,
  });
}