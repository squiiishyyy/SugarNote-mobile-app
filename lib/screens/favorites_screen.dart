import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/recipe.dart';
import '../services/api_service.dart';
import 'recipe_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Recipe> _recipes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final recipes = await ApiService.getFavorites();
      setState(() { _recipes = recipes; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1410),
        title: const Text('My Favorites',
          style: TextStyle(color: Color(0xFFFAF6F0), fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5E3C)))
        : _recipes.isEmpty
          ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text('No favorites yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                SizedBox(height: 8),
                Text('Browse recipes and tap ♥ to save them here',
                  style: TextStyle(color: Colors.grey)),
              ],
            ))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: _recipes.length,
              itemBuilder: (context, index) {
                final recipe = _recipes[index];
                return GestureDetector(
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(
                      builder: (_) => RecipeDetailScreen(recipeId: recipe.id),
                    ));
                    _load();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFDDD5C8)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          child: recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: recipe.imageUrl!,
                                height: 120, width: double.infinity, fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(height: 120,
                                  color: const Color(0xFFF2EBE0),
                                  child: const Icon(Icons.restaurant, color: Colors.grey)),
                              )
                            : Container(height: 120, color: const Color(0xFFF2EBE0),
                                child: const Center(child: Icon(Icons.restaurant, size: 40, color: Colors.grey))),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(recipe.category,
                                style: const TextStyle(fontSize: 10, color: Color(0xFF8B5E3C),
                                  fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(recipe.title,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                              if (recipe.totalTime > 0) ...[
                                const SizedBox(height: 4),
                                Text('⏱ ${recipe.totalTime} min',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}