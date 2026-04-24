import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/recipe.dart';
import '../services/api_service.dart';
import 'profile_screen.dart';
import 'add_recipe_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final int recipeId;
  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  Recipe? _recipe;
  bool _loading = true;
  bool _favorited = false;
  String? _currentUsername;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final recipe = await ApiService.getRecipe(widget.recipeId);
      final username = await ApiService.getUsername();
      setState(() {
        _recipe = recipe;
        _currentUsername = username;
        _loading = false;
      });
    } catch (e) {
      print('Error loading recipe: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final token = await ApiService.getToken();
    if (token == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }
    final favorited = await ApiService.toggleFavorite(widget.recipeId);
    setState(() { _favorited = favorited; });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(favorited ? 'Added to favorites' : 'Removed from favorites')),
    );
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Recipe'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService.deleteRecipe(widget.recipeId);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }
  

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_recipe == null) return const Scaffold(body: Center(child: Text('Recipe not found')));

    final recipe = _recipe!;
    final isOwner = _currentUsername == recipe.author;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF1A1410),
            flexibleSpace: FlexibleSpaceBar(
              background: recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: recipe.imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(color: const Color(0xFFF2EBE0),
                      child: const Icon(Icons.restaurant, size: 60, color: Colors.grey)),
                  )
                : Container(color: const Color(0xFFF2EBE0),
                    child: const Icon(Icons.restaurant, size: 60, color: Colors.grey)),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _favorited ? Icons.favorite : Icons.favorite_border,
                  color: Colors.white,
                ),
                onPressed: _toggleFavorite,
              ),
              if (isOwner) ...[
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddRecipeScreen(recipe: _recipe!),
                      ),
                    );
                    if (result == true) _load();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: _delete,
                ),
              ],
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5E3C),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(recipe.category,
                      style: const TextStyle(color: Colors.white, fontSize: 11,
                        fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(recipe.title,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  // Author
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(username: recipe.author),
                      ),
                    ),
                    child: Text(
                      'by ${recipe.author}',
                      style: const TextStyle(
                        color: Color(0xFF8B5E3C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Posted ${recipe.createdAt}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  
                  const SizedBox(height: 16),

                  // Meta row
                  Row(
                    children: [
                      if (recipe.prepTime != null && recipe.prepTime! > 0)
                        _metaChip('Prep', '${recipe.prepTime}m'),
                      if (recipe.cookTime != null && recipe.cookTime! > 0)
                        _metaChip('Cook', '${recipe.cookTime}m'),
                      if (recipe.servings != null)
                        _metaChip('Serves', '${recipe.servings}'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description
                  if (recipe.description.isNotEmpty) ...[
                    Text(recipe.description,
                      style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic,
                        fontSize: 15, height: 1.6)),
                    const SizedBox(height: 20),
                  ],

                  // Ingredients
                  _sectionTitle('Ingredients'),
                  const SizedBox(height: 8),
                  ...recipe.ingredientsList.map((ing) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('— ', style: TextStyle(color: Color(0xFF8B5E3C))),
                        Expanded(child: Text(ing)),
                      ],
                    ),
                  )),
                  const SizedBox(height: 24),

                  // Instructions
                  _sectionTitle('Instructions'),
                  const SizedBox(height: 8),
                  ...recipe.instructionsList.asMap().entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28, height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1A1410), shape: BoxShape.circle),
                          child: Center(child: Text('${entry.key + 1}',
                            style: const TextStyle(color: Colors.white, fontSize: 12))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(entry.value, style: const TextStyle(height: 1.6)),
                        )),
                      ],
                    ),
                  )),

                  // Notes
                  if (recipe.notes != null && recipe.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2EBE0),
                        borderRadius: BorderRadius.circular(4),
                        border: const Border(left: BorderSide(color: Color(0xFF8B5E3C), width: 3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text(recipe.notes!, style: const TextStyle(color: Colors.grey, height: 1.6)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaChip(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFDDD5C8)),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold));
  }
}