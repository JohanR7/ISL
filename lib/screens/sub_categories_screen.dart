
import 'package:flutter/material.dart';
import '/models/category_model.dart';
import '/services/local_api.dart';
import '/screens/main_tabs_screen.dart';
import '/widgets/app_helpers.dart'; // Import helpers

class SubCategoriesScreen extends StatefulWidget {
  final String mainCategoryName;
  final Object? mainCategoryJson;

  const SubCategoriesScreen({
    super.key,
    required this.mainCategoryName,
    this.mainCategoryJson,
  });

  @override
  State<SubCategoriesScreen> createState() => _SubCategoriesScreenState();
}

class _SubCategoriesScreenState extends State<SubCategoriesScreen> {
  List<SubCategory> _subCategories = [];
  String _errorMessage = '';
  bool _isLoading = true;
  Object? _lastSelectedSubCategoryJson;

  @override
  void initState() {
    super.initState();
    _fetchSubCategories();
  }

  Future<void> _fetchSubCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      _subCategories = await LocalAPI.getAllSubCategoriesForMainCategory(widget.mainCategoryName);
      debugPrint('API Call: getAllSubCategoriesForMainCategory("${widget.mainCategoryName}") successful.');
    } catch (e) {
      _errorMessage = 'Error loading subcategories: ${e.toString()}';
      debugPrint('API Call Error: $_errorMessage');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleSubCategoryTap(SubCategory subCategory) {
    setState(() {
      _lastSelectedSubCategoryJson = subCategory;
    });

    final String subCategoryName = subCategory.name ?? 'Untitled Subcategory';
    final String? youtubeId = subCategory.youtubeVideoId;

    showVideoOverlay( // Use the global helper
      context: context,
      youtubeId: youtubeId,
      title: subCategoryName,
      jsonResponse: subCategory,
      onEnter: () {
        if (subCategory.name != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MainTabsScreen(
                mainCategoryName: widget.mainCategoryName,
                subCategoryName: subCategory.name!,
                subCategoryJson: subCategory,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot navigate: Subcategory name is missing.')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.mainCategoryName)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
              : Column(
                  children: [
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                          childAspectRatio: 1.2,
                        ),
                        itemCount: _subCategories.length,
                        itemBuilder: (context, index) {
                          final subCategory = _subCategories[index];
                          return CategoryGridTile( // Use the global helper
                            title: subCategory.name ?? 'Untitled',
                            youtubeId: subCategory.youtubeVideoId,
                            onTap: () => _handleSubCategoryTap(subCategory),
                          );
                        },
                      ),
                    ),
                    if (_lastSelectedSubCategoryJson != null)
                      buildJsonResponsePanel( // Use the global helper
                        context,
                        'API: LocalAPI.getSubCategoryByName(...) called for:',
                        _lastSelectedSubCategoryJson!,
                      ),
                  ],
                ),
    );
  }
}