import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/recipe.dart';
import '../services/api_service.dart';
import 'recipe_detail_screen.dart';
import 'login_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';
import 'add_recipe_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Recipe> _recipes = [];
  bool _loading = true;
  String? _username;
  final _searchController = TextEditingController();
  final _ingredientController = TextEditingController();
  String _selectedCategory = '';

  final List<String> _categories = [
    '', 'Breakfast', 'Main Dish', 'Appetizer',
    'Dessert', 'Snack', 'Drinks', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadRecipes();
  }

  Future<void> _loadUser() async {
    final username = await ApiService.getUsername();
    setState(() { _username = username; });
  }

  Future<void> _loadRecipes() async {
    setState(() { _loading = true; });
    try {
      final recipes = await ApiService.getRecipes(
        query:      _searchController.text,
        category:   _selectedCategory,
        ingredient: _ingredientController.text,
      );
      setState(() { _recipes = recipes; });
    } catch (e) {
      print('Error loading recipes: $e');
      setState(() { _recipes = []; });
    }
    setState(() { _loading = false; });
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1410),
        title: Row(
          children: [
            const Text(
              'SugarNote',
              style: TextStyle(
                color: Color(0xFFFAF6F0),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Image.asset('assets/icon/icon.png', height: 30, width: 30),
          ],
        ),
        actions: [
          if (_username != null) ...[
            IconButton(
              icon: const Icon(Icons.favorite, color: Colors.white),
              onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen())),
            ),
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => ProfileScreen(username: _username!))),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _logout,
            ),
          ] else ...[
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text('Login', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: const Text('Sign up', style: TextStyle(color: Color(0xFF8B5E3C))),
            ),
          ],
        ],
      ),

      floatingActionButton: _username != null
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF8B5E3C),
              foregroundColor: Colors.white,
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddRecipeScreen()),
                );
                if (result == true) _loadRecipes();
              },
              child: const Icon(Icons.add),
            )
          : null,

      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: _inputDecoration('Search by title...'),
                  onSubmitted: (_) => _loadRecipes(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _ingredientController,
                  decoration: _inputDecoration('Ingredients: chicken, garlic...'),
                  onSubmitted: (_) => _loadRecipes(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: _inputDecoration('Category'),
                        items: _categories.map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat.isEmpty ? 'All categories' : cat),
                        )).toList(),
                        onChanged: (val) {
                          setState(() { _selectedCategory = val ?? ''; });
                          _loadRecipes();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus(); // dismiss keyboard
                        _loadRecipes();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5E3C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: const Text('Search'),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Recipe grid
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5E3C)))
              : _recipes.isEmpty
                ? const Center(child: Text('No recipes found'))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _recipes.length,
                    itemBuilder: (context, index) => _RecipeCard(
                      recipe: _recipes[index],
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(
                          builder: (_) => RecipeDetailScreen(recipeId: _recipes[index].id),
                        ));
                        _loadRecipes();
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFFAF6F0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFDDD5C8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFDDD5C8)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const _RecipeCard({required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 120,
                      color: const Color(0xFFF2EBE0),
                      child: const Icon(Icons.restaurant, color: Colors.grey),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 120,
                      color: const Color(0xFFF2EBE0),
                      child: const Icon(Icons.restaurant, color: Colors.grey),
                    ),
                  )
                : Container(
                    height: 120,
                    color: const Color(0xFFF2EBE0),
                    child: const Center(child: Icon(Icons.restaurant, size: 40, color: Colors.grey)),
                  ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.category,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF8B5E3C),
                      fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(recipe.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  if (recipe.totalTime > 0)
                    Text('⏱ ${recipe.totalTime} min',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}