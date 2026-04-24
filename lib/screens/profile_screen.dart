import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import 'recipe_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String username;
  const ProfileScreen({super.key, required this.username});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await ApiService.getUserProfile(widget.username);
      setState(() { _profile = profile; _loading = false; });
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
        title: Text(widget.username,
          style: const TextStyle(color: Color(0xFFFAF6F0), fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5E3C)))
        : _profile == null
          ? const Center(child: Text('Profile not found'))
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_profile!['username'],
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Member since ${_profile!['member_since']}',
                        style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('${_profile!['recipe_count']} recipe${_profile!['recipe_count'] != 1 ? 's' : ''}',
                        style: const TextStyle(color: Color(0xFF8B5E3C), fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Expanded(
                  child: (_profile!['recipes'] as List).isEmpty
                    ? const Center(child: Text('No recipes yet', style: TextStyle(color: Colors.grey)))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: (_profile!['recipes'] as List).length,
                        itemBuilder: (context, index) {
                          final r = _profile!['recipes'][index];
                          return GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => RecipeDetailScreen(recipeId: r['id']),
                            )),
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
                                    child: r['image_url'] != null && r['image_url'].isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: r['image_url'],
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
                                        Text(r['category'] ?? '',
                                          style: const TextStyle(fontSize: 10, color: Color(0xFF8B5E3C),
                                            fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 4),
                                        Text(r['title'] ?? '',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                          maxLines: 2, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
    );
  }
}