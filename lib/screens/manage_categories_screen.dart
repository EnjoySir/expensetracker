import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/expense_provider.dart';
import '../utils/color_helper.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final _nameController = TextEditingController();
  String _selectedIcon = '📌';
  String _selectedColor = '9E9E9E';
  Color _previewColor = Colors.grey;
  
  final List<String> _availableIcons = [
    '🍔', '🚗', '🛍️', '🎬', '💡', '💊', '📚', '💰', '🎁', '🏠', 
    '✈️', '🎮', '☕', '🍕', '💪', '📱', '🎵', '⚽', '🐶', '🌸',
  ];
  
  final List<String> _availableColors = [
    'FF6B6B', '4ECDC4', 'FFE66D', 'A8E6CF', 'FF8B94', 
    'C7CEEA', 'B5EAD7', '4CAF50', 'FF9800', '9C27B0',
  ];

  @override
  void initState() {
    super.initState();
    _updatePreviewColor();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExpenseProvider>(context, listen: false).loadCategories();
    });
  }

  void _updatePreviewColor() {
    _previewColor = ColorHelper.fromHex(_selectedColor);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add New Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Select Icon', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _availableIcons.length,
                    itemBuilder: (context, index) {
                      final icon = _availableIcons[index];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIcon = icon),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _selectedIcon == icon ? Colors.deepPurple.shade100 : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _selectedIcon == icon ? Colors.deepPurple : Colors.grey.shade300),
                          ),
                          child: Text(icon, style: const TextStyle(fontSize: 24)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Select Color', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _availableColors.length,
                    itemBuilder: (context, index) {
                      final colorHex = _availableColors[index];
                      final color = ColorHelper.fromHex(colorHex);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColor = colorHex;
                            _updatePreviewColor();
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedColor == colorHex ? Colors.black : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: _selectedColor == colorHex ? const Icon(Icons.check, size: 20, color: Colors.white) : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _previewColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(backgroundColor: _previewColor, child: Text(_selectedIcon)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nameController.text.isEmpty ? 'Preview' : _nameController.text,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('New category', style: TextStyle(fontSize: 12, color: _previewColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a category name')),
                        );
                        return;
                      }
                      final category = Category(
                        name: _nameController.text.trim(),
                        icon: _selectedIcon,
                        color: _selectedColor,
                        isDefault: 0,
                      );
                      await provider.addCategory(category);
                      _nameController.clear();
                      setState(() {
                        _selectedIcon = '📌';
                        _selectedColor = '9E9E9E';
                        _updatePreviewColor();
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${category.name} added'), backgroundColor: Colors.green),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Add Category', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: provider.categories.isEmpty
                ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.category, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No categories yet'),
                  ]))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: provider.categories.length,
                    itemBuilder: (context, index) {
                      final category = provider.categories[index];
                      final color = ColorHelper.fromHex(category.color);
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withOpacity(0.2),
                            child: Text(category.icon),
                          ),
                          title: Text(category.name),
                          subtitle: category.isDefault == 1 ? const Text('Default', style: TextStyle(fontSize: 11)) : null,
                          trailing: category.isDefault == 1
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteCategory(context, category.id!, category.name),
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
  
  void _deleteCategory(BuildContext context, int id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Provider.of<ExpenseProvider>(context, listen: false).deleteCategory(id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$name deleted'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}