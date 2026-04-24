class Recipe {
  final int id;
  final String title;
  final String description;
  final String category;
  final String ingredients;
  final String instructions;
  final int? prepTime;
  final int? cookTime;
  final int? servings;
  final String? imageUrl;
  final String? notes;
  final String author;
  final int userId;
  final String createdAt;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.ingredients,
    required this.instructions,
    this.prepTime,
    this.cookTime,
    this.servings,
    this.imageUrl,
    this.notes,
    required this.author,
    required this.userId,
    required this.createdAt,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id:           json['id'],
      title:        json['title'] ?? '',
      description:  json['description'] ?? '',
      category:     json['category'] ?? '',
      ingredients:  json['ingredients'] ?? '',
      instructions: json['instructions'] ?? '',
      prepTime:     json['prep_time'],
      cookTime:     json['cook_time'],
      servings:     json['servings'],
      imageUrl:     json['image_url'],
      notes:        json['notes'],
      author:       json['author'] ?? '',
      userId:       json['user_id'] ?? 0,
      createdAt:    json['created_at'] ?? '',
    );
  }

  List<String> get ingredientsList =>
      ingredients.split('\n').where((i) => i.trim().isNotEmpty).toList();

  List<String> get instructionsList =>
      instructions.split('\n').where((i) => i.trim().isNotEmpty).toList();

  int get totalTime => (prepTime ?? 0) + (cookTime ?? 0);
}