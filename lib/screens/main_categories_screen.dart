import 'package:flutter/material.dart';
import '/models/category_model.dart';
import '/services/local_api.dart';
import '/screens/sub_categories_screen.dart';
import '/widgets/app_helpers.dart'; // Import helpers

class MainCategoriesScreen extends StatefulWidget {
  const MainCategoriesScreen({super.key});    //stateful widget to manage its own internal state

  @override
  State<MainCategoriesScreen> createState() => _MainCategoriesScreenState();
}

class _MainCategoriesScreenState extends State<MainCategoriesScreen> {
  List<MainCategory> _mainCategories = [];
  String _errorMessage = '';
  bool _isLoading = true;
  Object? _lastSelectedCategoryJson; // To display JSON of last clicked item

  // Map of category names to their corresponding image paths
  final Map<String, String> _categoryImages = {
    'Alphabets and Words': 'assets/images/Alphabets and Words.png',
    'Bharat': 'assets/images/Bharat.png',
    'Dictionary': 'assets/images/Dictionary.jpg',
    'Education, Work & Money': 'assets/images/Education, Work & Money.png',
    'Home, Family & Health': 'assets/images/Home, Family & Health.png',
    'Numbers': 'assets/images/Numbers.png',
    'Parts of speech': 'assets/images/Parts of speech.jpg',
    'Polite expressions-Situations': 'assets/images/Polite expressions-Situations.jpg',
    'Question words and Conversation': 'assets/images/Question words and Conversation.png',
    'Time, Calender, Nature & Weather': 'assets/images/Time, Calender, Nature & Weather.png',
    'Transportation & Travel': 'assets/images/Transportation & Travel.png',
  };

  @override
  void initState() {   //called once at the beginning for data loading
    super.initState();
    _fetchMainCategories();
  }

  Future<void> _fetchMainCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      _mainCategories = await LocalAPI.getAllMainCategories();
      debugPrint('API Call: getAllMainCategories() successful.');
      
      // Debug: Print all category names
      debugPrint('=== CATEGORY NAMES FROM API ===');
      for (var category in _mainCategories) {
        debugPrint('Category: "${category.name}"');
        final imagePath = _getImageForCategory(category.name);
        debugPrint('  -> Image path: ${imagePath ?? "NOT FOUND"}');
      }
      debugPrint('=== END CATEGORY NAMES ===');
      
    } catch (e) {
      _errorMessage = 'Error loading main categories: ${e.toString()}';
      debugPrint('API Call Error: $_errorMessage');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Get the image path for a category, returns null if not found
  String? _getImageForCategory(String? categoryName) {
    if (categoryName == null) return null;
    
    // Try exact match first
    if (_categoryImages.containsKey(categoryName)) {
      debugPrint('Exact match found for: "$categoryName"');
      return _categoryImages[categoryName];
    }
    
    // Try case-insensitive match
    final lowerCaseName = categoryName.toLowerCase();
    for (var entry in _categoryImages.entries) {
      if (entry.key.toLowerCase() == lowerCaseName) {
        debugPrint('Case-insensitive match found for: "$categoryName" -> "${entry.key}"');
        return entry.value;
      }
    }
    
    debugPrint('No match found for: "$categoryName"');
    return null;
  }

  void _handleMainCategoryTap(MainCategory category) {  //user interaction on grid
    setState(() {
      _lastSelectedCategoryJson = category; // Set JSON for display
    });

    final String categoryName = category.name ?? 'Untitled Category';
    final String? youtubeId = category.youtubeVideoId;

    showVideoOverlay( // Use the global helper
      context: context,
      youtubeId: youtubeId,
      title: categoryName,
      jsonResponse: category,
      onEnter: () {   //route to subcategory
        if (category.name != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubCategoriesScreen(
                mainCategoryName: category.name!,
                mainCategoryJson: category,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot navigate: Category name is missing.')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learning Categories')),
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
                        itemCount: _mainCategories.length,
                        itemBuilder: (context, index) {
                          final category = _mainCategories[index];
                          final imagePath = _getImageForCategory(category.name);
                          
                          return CategoryGridTile( // Use the global helper
                            title: category.name ?? 'Untitled',
                            youtubeId: category.youtubeVideoId,
                            imagePath: imagePath, // Pass the image path
                            onTap: () => _handleMainCategoryTap(category),
                          );
                        },
                      ),
                    ),
                    if (_lastSelectedCategoryJson != null)
                      buildJsonResponsePanel( // Use the global helper
                        context,
                        'API: LocalAPI.getMainCategoryByName(...) called for:',
                        _lastSelectedCategoryJson!,
                      ),
                  ],
                ),
    );
  }
}