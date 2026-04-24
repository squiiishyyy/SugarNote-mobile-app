import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../models/recipe.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String baseUrl = Config.baseUrl;
  static const _timeout = Duration(seconds: 30);

  // ── Auth ──────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    ).timeout(_timeout);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> register(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'email': email, 'password': password}),
    ).timeout(_timeout);
    return jsonDecode(response.body);
  }

  static Future<void> saveToken(String token, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('username', username);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('username');
  }

  // ── Recipes ───────────────────────────────────────────────────

  static Future<List<Recipe>> getRecipes({String query = '', String category = '', String ingredient = ''}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/recipes').replace(queryParameters: {
        if (query.isNotEmpty) 'q': query,
        if (category.isNotEmpty) 'category': category,
        if (ingredient.isNotEmpty) 'ingredient': ingredient,
      });
      final response = await http.get(uri).timeout(_timeout);
      final List data = jsonDecode(response.body);
      return data.map((r) => Recipe.fromJson(r)).toList();
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  static Future<Recipe> getRecipe(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/recipes/$id')).timeout(_timeout);
      return Recipe.fromJson(jsonDecode(response.body));
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  static Future<bool> deleteRecipe(int id) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/api/recipes/$id'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(_timeout);
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> createRecipe(Map<String, dynamic> data) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/api/recipes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    ).timeout(_timeout);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateRecipe(int id, Map<String, dynamic> data) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/api/recipes/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    ).timeout(_timeout);
    return jsonDecode(response.body);
  }

  // ── Image Upload ──────────────────────────────────────────────

  static Future<String?> uploadImage(String filePath) async {
    try {
      final cloudName = 'dp4nvbmlg';
      final uploadPreset = 'sugarnote_unsigned';

      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri);

      request.fields['upload_preset'] = uploadPreset;
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final response = await request.send().timeout(const Duration(seconds: 60));
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body);
      return data['secure_url'];
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  // ── Favorites ─────────────────────────────────────────────────

  static Future<List<Recipe>> getFavorites() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/favorites'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(_timeout);
    final List data = jsonDecode(response.body);
    return data.map((r) => Recipe.fromJson(r)).toList();
  }

  static Future<bool> toggleFavorite(int recipeId) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/api/favorites/$recipeId'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(_timeout);
    final data = jsonDecode(response.body);
    return data['favorited'];
  }

  // ── Profile ───────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getUserProfile(String username) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/user/$username'))
        .timeout(_timeout);
    return jsonDecode(response.body);
  }
}
