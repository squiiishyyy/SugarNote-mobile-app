import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddRecipeScreen extends StatefulWidget {
  final Recipe? recipe; // null = new recipe, not null = editing
  const AddRecipeScreen({super.key, this.recipe});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;
  late TextEditingController _imageUrlController;
  late TextEditingController _prepTimeController;
  late TextEditingController _cookTimeController;
  late TextEditingController _servingsController;

  late String _selectedCategory;
  bool _loading = false;
  String? _error;

  late List<TextEditingController> _ingredientControllers;
  late List<TextEditingController> _stepControllers;

  final List<String> _categories = [
    'Breakfast',
    'Main Dish',
    'Appetizer',
    'Dessert',
    'Snack',
    'Drinks',
    'Other',
  ];

  bool get _isEditing => widget.recipe != null;

  File? _selectedImage;
  bool _uploadingImage = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    _titleController = TextEditingController(text: r?.title ?? '');
    _descriptionController = TextEditingController(text: r?.description ?? '');
    _notesController = TextEditingController(text: r?.notes ?? '');
    _imageUrlController = TextEditingController(text: r?.imageUrl ?? '');
    _prepTimeController = TextEditingController(
      text: r?.prepTime?.toString() ?? '',
    );
    _cookTimeController = TextEditingController(
      text: r?.cookTime?.toString() ?? '',
    );
    _servingsController = TextEditingController(
      text: r?.servings?.toString() ?? '',
    );
    _selectedCategory = r?.category ?? 'Other';

    _ingredientControllers = (r != null && r.ingredientsList.isNotEmpty)
        ? r.ingredientsList.map((i) => TextEditingController(text: i)).toList()
        : [TextEditingController()];

    _stepControllers = (r != null && r.instructionsList.isNotEmpty)
        ? r.instructionsList.map((s) => TextEditingController(text: s)).toList()
        : [TextEditingController()];
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() {
        _error = 'Title is required';
      });
      return;
    }

    final ingredients = _ingredientControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .join('\n');
    final instructions = _stepControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .join('\n');

    if (ingredients.isEmpty) {
      setState(() {
        _error = 'At least one ingredient is required';
      });
      return;
    }
    if (instructions.isEmpty) {
      setState(() {
        _error = 'At least one step is required';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final payload = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'ingredients': ingredients,
        'instructions': instructions,
        'category': _selectedCategory,
        'prep_time': int.tryParse(_prepTimeController.text) ?? 0,
        'cook_time': int.tryParse(_cookTimeController.text) ?? 0,
        'servings': int.tryParse(_servingsController.text) ?? 1,
        'image_url': _imageUrlController.text.trim(),
        'notes': _notesController.text.trim(),
      };

      Map<String, dynamic> data;
      if (_isEditing) {
        data = await ApiService.updateRecipe(widget.recipe!.id, payload);
      } else {
        data = await ApiService.createRecipe(payload);
      }

      if (data.containsKey('id') || data.containsKey('message')) {
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        setState(() {
          _error = data['error'] ?? 'Failed to save recipe';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error';
      });
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _uploadingImage = true;
      });
      final url = await ApiService.uploadImage(picked.path);
      setState(() {
        _uploadingImage = false;
        if (url != null) {
          _imageUrlController.text = url;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1410),
        title: Text(
          _isEditing ? 'Edit Recipe' : 'New Recipe',
          style: const TextStyle(
            color: Color(0xFFFAF6F0),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _loading ? null : _submit,
            child: const Text(
              'Save',
              style: TextStyle(color: Color(0xFFE67E22), fontSize: 16),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDEDEC),
                  borderRadius: BorderRadius.circular(4),
                  border: const Border(
                    left: BorderSide(color: Color(0xFFC0392B), width: 3),
                  ),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFC0392B)),
                ),
              ),
              const SizedBox(height: 16),
            ],

            _buildField(
              'Recipe Title *',
              _titleController,
              hint: 'e.g. Classic Carbonara',
            ),
            const SizedBox(height: 16),

            _buildField(
              'Description',
              _descriptionController,
              hint: 'A brief note about this dish...',
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            _buildLabel('Category'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _categories.contains(_selectedCategory)
                  ? _selectedCategory
                  : 'Other',
              decoration: _inputDecoration(''),
              items: _categories
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (val) => setState(() {
                _selectedCategory = val ?? 'Other';
              }),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildField(
                    'Prep (min)',
                    _prepTimeController,
                    hint: '15',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildField(
                    'Cook (min)',
                    _cookTimeController,
                    hint: '30',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildField(
                    'Servings',
                    _servingsController,
                    hint: '4',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildLabel('Recipe Image'),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _uploadingImage ? null : _pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFDDD5C8)),
                ),
                child: _uploadingImage
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF8B5E3C),
                        ),
                      )
                    : _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 180,
                        ),
                      )
                    : _imageUrlController.text.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          _imageUrlController.text,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 180,
                        ),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 40,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap to upload image',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            const Divider(color: Color(0xFFDDD5C8)),
            const SizedBox(height: 16),

            _buildLabel('Ingredients *'),
            const SizedBox(height: 4),
            const Text(
              'One ingredient per line',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ..._ingredientControllers.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: entry.value,
                        decoration: _inputDecoration('e.g. 2 cups flour'),
                      ),
                    ),
                    if (_ingredientControllers.length > 1)
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(() {
                          _ingredientControllers.removeAt(entry.key);
                        }),
                      ),
                  ],
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() {
                _ingredientControllers.add(TextEditingController());
              }),
              icon: const Icon(Icons.add, color: Color(0xFF8B5E3C)),
              label: const Text(
                'Add Ingredient',
                style: TextStyle(color: Color(0xFF8B5E3C)),
              ),
            ),
            const SizedBox(height: 16),

            _buildLabel('Instructions *'),
            const SizedBox(height: 4),
            const Text(
              'One step per line',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ..._stepControllers.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: entry.value,
                        decoration: _inputDecoration('Describe this step...'),
                        maxLines: 2,
                      ),
                    ),
                    if (_stepControllers.length > 1)
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(() {
                          _stepControllers.removeAt(entry.key);
                        }),
                      ),
                  ],
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() {
                _stepControllers.add(TextEditingController());
              }),
              icon: const Icon(Icons.add, color: Color(0xFF8B5E3C)),
              label: const Text(
                'Add Step',
                style: TextStyle(color: Color(0xFF8B5E3C)),
              ),
            ),
            const SizedBox(height: 16),

            _buildField(
              'Notes',
              _notesController,
              hint: 'Tips, substitutions, storage...',
              maxLines: 3,
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5E3C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _isEditing ? 'Save Changes' : 'Create Recipe',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 1,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    String hint = '',
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: _inputDecoration(hint),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
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
