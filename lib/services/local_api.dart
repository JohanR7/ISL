

import 'dart:convert';
import 'package:http/http.dart' as http; // Added http import
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle; // Retained but not used for network calls
import '../models/category_model.dart'; // Make sure this path is correct

/// A class to interact with the remote ISL API to fetch category-wise data,
/// keeping the original class name 'LocalAPI' for compatibility.
class LocalAPI {
  // Base URL for all API endpoints
  static const String _baseUrl = 'https://www.olabs.edu.in/isl/api/';

  // Cache for the top-level categories
  static List<MainCategory>? _cache;

  /// Private helper method to make a GET request and handle basic errors.
  static Future<dynamic> _fetchData(String endpoint) async {
    final url = Uri.parse(_baseUrl + endpoint);
    debugPrint('Attempting to fetch data from: $url');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('Received an empty response from $url.');
        }
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        final errorJson = jsonDecode(response.body);
        final errorMessage = errorJson['error'] ?? 'Resource not found.';
        throw Exception(
            'API Error (404 Not Found) at $endpoint: $errorMessage');
      } else {
        throw Exception(
            'Failed to load data from $endpoint. Status code: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: Could not connect to the server at $url. $e');
    } catch (e, stack) {
      debugPrint('--- ERROR FETCHING API DATA ---');
      debugPrint('Endpoint: $endpoint');
      debugPrint('Error: $e');
      debugPrint('Stack Trace: $stack');
      debugPrint('-----------------------------');
      rethrow;
    }
  }

  /// Loads and caches all main categories from the API.
  /// Throws an [Exception] if the data cannot be loaded or parsed.
  static Future<void> _loadData() async {
    if (_cache != null) return; // Load only once

    try {
      debugPrint('Attempting to load all main categories from API...');
      
      final jsonList = await _fetchData(''); // Endpoint for all main categories is /

      if (jsonList is List) {
        _cache = jsonList
            .map((e) => MainCategory.fromJson(e as Map<String, dynamic>))
            .toList();
        debugPrint('Successfully loaded and parsed all main categories.');
      } else {
        throw Exception('Failed to parse main categories list. Expected a JSON array.');
      }

    } catch (e, stack) {
      debugPrint('--- ERROR LOADING DATA FROM API ---');
      debugPrint('Error: $e');
      debugPrint('Stack Trace: $stack');
      debugPrint('-----------------------------');
      throw Exception('Failed to load or parse API data: $e. This usually means a network error or malformed JSON.');
    }
  }

  /// Helper to get the ID of a main category from its name.
  /// Relies on the cached list from _loadData.
  static Future<String> _getMainCategoryIdByName(String mainCategoryName) async {
    await _loadData();
    final category = _cache!.firstWhere(
      (c) => c.name == mainCategoryName,
      orElse: () => throw Exception('Main category "$mainCategoryName" not found in cached list.'),
    );
    if (category.id == null) {
      throw Exception('Main category "$mainCategoryName" has no ID.');
    }
    return category.id!;
  }
  
  // =========================================================================
  //                       MAIN CATEGORY LEVEL API CALLS
  // =========================================================================

  /// Retrieves a list of all main categories.
  /// Returns an empty list if no categories are found.
  static Future<List<MainCategory>> getAllMainCategories() async {
    await _loadData();
    return _cache ?? [];
  }

  /// Retrieves a specific [MainCategory] object by its exact name.
  /// Throws an [Exception] if the main category is not found.
  static Future<MainCategory> getMainCategoryByName(String mainCategoryName) async {
    // We fetch the full details by ID to get the subCategories summary
    final mainCategoryId = await _getMainCategoryIdByName(mainCategoryName);
    
    final jsonObject = await _fetchData(mainCategoryId); // Endpoint: /{mainCategoryId}

    if (jsonObject is Map<String, dynamic>) {
       return MainCategory.fromJson(jsonObject);
    }

    throw Exception('Failed to load full main category data for "$mainCategoryName".');
  }

  /// Retrieves the video URL for a specific main category.
  /// Throws an [Exception] if the main category is not found, returns null if video is not present.
  static Future<String?> getMainCategoryVideoUrl(String mainCategoryName) async {
    final category = await getMainCategoryByName(mainCategoryName);
    return category.video;
  }

  /// Retrieves the YouTube video ID for a specific main category.
  /// Throws an [Exception] if the main category is not found, returns null if YouTube ID is not present.
  static Future<String?> getMainCategoryYoutubeId(String mainCategoryName) async {
    final category = await getMainCategoryByName(mainCategoryName);
    return category.youtubeVideoId;
  }

  /// Retrieves the image asset path for a specific main category.
  /// Throws an [Exception] if the main category is not found, returns null if image is not present.
  static Future<String?> getMainCategoryImage(String mainCategoryName) async {
    final category = await getMainCategoryByName(mainCategoryName);
    return category.image;
  }

  // =========================================================================
  //                       SUB CATEGORY LEVEL API CALLS
  // =========================================================================

  /// Retrieves a list of all [SubCategory] objects for a given main category name.
  /// Returns an empty list if no subcategories are found or main category does not exist.
  static Future<List<SubCategory>> getAllSubCategoriesForMainCategory(String mainCategoryName) async {
    try {
      final mainCategoryId = await _getMainCategoryIdByName(mainCategoryName);
      final jsonObject = await _fetchData(mainCategoryId); // Endpoint: /{mainCategoryId}

      if (jsonObject is Map<String, dynamic> && jsonObject.containsKey('subCategories')) {
        final List subCategoriesJson = jsonObject['subCategories'];
        // Note: The main category endpoint only returns a summary, but the model
        // expects the full structure, so we use the summary data to create the object.
        return subCategoriesJson
            .map((e) => SubCategory.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on Exception {
      return []; // Return empty list if main category not found or fetch fails
    }
  }

  /// Retrieves a specific [SubCategory] object by its exact name within a main category.
  /// Throws an [Exception] if either the main category or sub category is not found.
  static Future<SubCategory> getSubCategoryByName(String mainCategoryName, String subCategoryName) async {
    final mainCategoryId = await _getMainCategoryIdByName(mainCategoryName);
    final subCategoriesSummary = await getAllSubCategoriesForMainCategory(mainCategoryName);

    // 1. Find the sub-category ID from the summary list
    final subCategorySummary = subCategoriesSummary.firstWhere(
      (s) => s.name == subCategoryName,
      orElse: () => throw Exception('Subcategory "$subCategoryName" not found in "$mainCategoryName".'),
    );

    if (subCategorySummary.id == null) {
      throw Exception('Subcategory "$subCategoryName" has no ID.');
    }
    final subCategoryId = subCategorySummary.id!;

    // 2. Fetch the full sub-category data from the dedicated endpoint
    final endpoint = '$mainCategoryId/$subCategoryId'; // Endpoint: /{mainCategoryId}/{subCategoryId}
    final jsonObject = await _fetchData(endpoint);

    if (jsonObject is Map<String, dynamic>) {
      // The model must parse the full nested subcategory data (mainTabs, subTabs, etc.)
      return SubCategory.fromJson(jsonObject);
    }

    throw Exception('Failed to load full subcategory data for "$subCategoryName".');
  }

  /// Retrieves the video URL for a specific subcategory.
  /// Throws an [Exception] if the subcategory is not found, returns null if video is not present.
  static Future<String?> getSubCategoryVideoUrl(String mainCategoryName, String subCategoryName) async {
    final subCategory = await getSubCategoryByName(mainCategoryName, subCategoryName);
    return subCategory.video;
  }

  /// Retrieves the YouTube video ID for a specific subcategory.
  /// Throws an [Exception] if the subcategory is not found, returns null if YouTube ID is not present.
  static Future<String?> getSubCategoryYoutubeId(String mainCategoryName, String subCategoryName) async {
    final subCategory = await getSubCategoryByName(mainCategoryName, subCategoryName);
    return subCategory.youtubeVideoId;
  }

  /// Retrieves the image asset path for a specific subcategory.
  /// Throws an [Exception] if the subcategory is not found, returns null if image is not present.
  static Future<String?> getSubCategoryImage(String mainCategoryName, String subCategoryName) async {
    final subCategory = await getSubCategoryByName(mainCategoryName, subCategoryName);
    return subCategory.image;
  }

  // =========================================================================
  //                         MAIN TAB LEVEL API CALLS
  //
  // NOTE: All subsequent methods rely on the full data being present within
  // the SubCategory object, as there are no deeper API endpoints.
  // =========================================================================

  /// Retrieves a list of all [MainTab] objects for a given subcategory name.
  /// Returns an empty list if no main tabs are found or subcategory does not exist.
  static Future<List<MainTab>> getAllMainTabsForSubCategory(String mainCategoryName, String subCategoryName) async {
    try {
      final sub = await getSubCategoryByName(mainCategoryName, subCategoryName);
      return sub.mainTabs;
    } catch (_) {
      return []; // Return empty list if subcategory not found
    }
  }

  /// Retrieves a specific [MainTab] object by its exact ID within a subcategory.
  /// Throws an [Exception] if the subcategory or main tab is not found.
  static Future<MainTab> getMainTabById(String mainCategoryName, String subCategoryName, String mainTabId) async {
    final sub = await getSubCategoryByName(mainCategoryName, subCategoryName);
    return sub.mainTabs.firstWhere(
      (tab) => tab.id == mainTabId,
      orElse: () => throw Exception('Main tab with ID "$mainTabId" not found in subcategory "$subCategoryName".'),
    );
  }

  /// Retrieves the name of a specific main tab.
  /// Throws an [Exception] if the main tab is not found, returns null if name is not present.
  static Future<String?> getMainTabName(String mainCategoryName, String subCategoryName, String mainTabId) async {
    final mainTab = await getMainTabById(mainCategoryName, subCategoryName, mainTabId);
    return mainTab.name;
  }

  /// Retrieves the video URL for a specific main tab.
  /// Throws an [Exception] if the main tab is not found, returns null if video is not present.
  static Future<String?> getMainTabVideoUrl(String mainCategoryName, String subCategoryName, String mainTabId) async {
    final mainTab = await getMainTabById(mainCategoryName, subCategoryName, mainTabId);
    return mainTab.video;
  }

  /// Retrieves the YouTube video ID for a specific main tab.
  /// Throws an [Exception] if the main tab is not found, returns null if YouTube ID is not present.
  static Future<String?> getMainTabYoutubeId(String mainCategoryName, String subCategoryName, String mainTabId) async {
    final mainTab = await getMainTabById(mainCategoryName, subCategoryName, mainTabId);
    return mainTab.youtubeVideoId;
  }

  // =========================================================================
  //                         SUB-TAB LEVEL API CALLS
  // =========================================================================

  /// Retrieves a list of all [SubTabBase] objects (polymorphic list) for a specific main tab.
  /// Returns an empty list if no sub-tabs are found or main tab does not exist.
  static Future<List<SubTabBase>> getAllSubTabsForMainTab(String mainCategoryName, String subCategoryName, String mainTabId) async {
    try {
      final mainTab = await getMainTabById(mainCategoryName, subCategoryName, mainTabId);
      return mainTab.subTabs;
    } catch (_) {
      return []; // Return empty list if main tab not found
    }
  }

  /// Retrieves a specific [SubTabBase] object by its exact ID within a main tab.
  /// Throws an [Exception] if the main tab or sub-tab is not found.
  static Future<SubTabBase> getSubTabById(String mainCategoryName, String subCategoryName, String mainTabId, String subTabId) async {
    final mainTab = await getMainTabById(mainCategoryName, subCategoryName, mainTabId);
    return mainTab.subTabs.firstWhere(
      (st) => st.id == subTabId,
      orElse: () => throw Exception('Sub-tab with ID "$subTabId" not found in main tab "$mainTabId".'),
    );
  }

  /// Retrieves the name of a specific sub-tab.
  /// Throws an [Exception] if the sub-tab is not found, returns null if name is not present.
  static Future<String?> getSubTabName(String mainCategoryName, String subCategoryName, String mainTabId, String subTabId) async {
    final subTab = await getSubTabById(mainCategoryName, subCategoryName, mainTabId, subTabId);
    return subTab.name;
  }

  /// Retrieves the video URL for a specific sub-tab.
  /// Throws an [Exception] if the sub-tab is not found, returns null if video is not present.
  static Future<String?> getSubTabVideoUrl(String mainCategoryName, String subCategoryName, String mainTabId, String subTabId) async {
    final subTab = await getSubTabById(mainCategoryName, subCategoryName, mainTabId, subTabId);
    return subTab.video;
  }

  /// Retrieves the YouTube video ID for a specific sub-tab.
  /// Throws an [Exception] if the sub-tab is not found, returns null if YouTube ID is not present.
  static Future<String?> getSubTabYoutubeId(String mainCategoryName, String subCategoryName, String mainTabId, String subTabId) async {
    final subTab = await getSubTabById(mainCategoryName, subCategoryName, mainTabId, subTabId);
    return subTab.youtubeVideoId;
  }

  // =========================================================================
  //                     SPECIFIC SUB-TAB TYPE API CALLS
  // =========================================================================
  // --- WordsOnlySubTab Specific Calls ---
  /// Retrieves content specifically for a 'Words Only' sub-tab as a [WordsOnlySubTab] object.
  /// Throws an [Exception] if the sub-tab is not of this type or not found.
  static Future<WordsOnlySubTab> getWordsOnlySubTabContent(String mainCategoryName, String subCategoryName, String mainTabId, String subTabId) async {
    final subTab = await getSubTabById(mainCategoryName, subCategoryName, mainTabId, subTabId);
    if (subTab is WordsOnlySubTab) {
      return subTab;
    }
    throw Exception('Sub-tab "$subTabId" is not a Words Only type.');
  }

  /// Retrieves the list of [Word] objects directly from a 'Words Only' sub-tab.
  static Future<List<Word>> getWordsListFromWordsOnlySubTab(String mainCategoryName, String subCategoryName, String mainTabId, String subTabId) async {
    final wordsOnlyTab = await getWordsOnlySubTabContent(mainCategoryName, subCategoryName, mainTabId, subTabId);
    return wordsOnlyTab.words;
  }

  // --- SentenceMakingSubTab Specific Calls ---
  /// Retrieves content specifically for a 'Sentence Making' sub-tab as a [SentenceMakingSubTab] object.
  /// Throws an [Exception] if the sub-tab is not of this type or not found.
  static Future<SentenceMakingSubTab> getSentenceMakingSubTabContent(String mainCategoryName, String subCategoryName, String mainTabId, String subTabId) async {
    final subTab = await getSubTabById(mainCategoryName, subCategoryName, mainTabId, subTabId);
    if (subTab is SentenceMakingSubTab) {
      return subTab;
    }
    throw Exception('Sub-tab "$subTabId" is not a Sentence Making type.');
  }

  /// Retrieves the list of [Activity] objects from a 'Sentence Making' sub-tab.
  static Future<List<Activity>> getActivitiesFromSentenceMakingSubTab(String mainCategoryName, String subCategoryName, String mainTabId, String subTabId) async {
    final sentenceMakingTab = await getSentenceMakingSubTabContent(mainCategoryName, subCategoryName, mainTabId, subTabId);
    return sentenceMakingTab.activities;
  }

  /// Retrieves a specific [Activity] by its ID from a 'Sentence Making' sub-tab.
  /// Throws an [Exception] if the activity is not found.
  static Future<Activity> getActivityById(String mainCategoryName, String subCategoryName, String mainTabId, String subTabId, String activityId) async {
    final activities = await getActivitiesFromSentenceMakingSubTab(mainCategoryName, subCategoryName, mainTabId, subTabId);
    return activities.firstWhere(
      (a) => a.id == activityId,
      orElse: () => throw Exception('Activity with ID "$activityId" not found in sub-tab "$subTabId".'),
    );
  }

  /// Retrieves the name of a specific activity.
  /// Throws an [Exception] if the activity is not found, returns null if name is not present.
  static Future<String?> getActivityName(String mainCategoryName, String subCategoryName, String mainTabId, String subTabId, String activityId) async {
    final activity = await getActivityById(mainCategoryName, subCategoryName, mainTabId, subTabId, activityId);
    return activity.name;
  }

  /// Retrieves the list of [Word] objects for a specific activity within a 'Sentence Making' sub-tab.
  static Future<List<Word>> getWordsForActivity(String mainCategoryName, String subCategoryName, String mainTabId, String subTabId, String activityId) async {
    final activity = await getActivityById(mainCategoryName, subCategoryName, mainTabId, subTabId, activityId);
    return activity.words;
  }

  /// Retrieves the list of [Sentence] objects for a specific activity within a 'Sentence Making' sub-tab.
  static Future<List<Sentence>> getSentencesForActivity(String mainCategoryName, String subCategoryName, String mainTabId, String subTabId, String activityId) async {
    final activity = await getActivityById(mainCategoryName, subCategoryName, mainTabId, subTabId, activityId);
    return activity.sentences;
  }

  // --- SentenceOnlySubTab Specific Calls ---
  /// Retrieves content specifically for a 'Sentence Only' sub-tab as a [SentenceOnlySubTab] object.
  /// Throws an [Exception] if the sub-tab is not of this type or not found.
  static Future<SentenceOnlySubTab> getSentenceOnlySubTabContent(String mainCategoryName, String subCategoryName, String mainTabId, String subTabId) async {
    final subTab = await getSubTabById(mainCategoryName, subCategoryName, mainTabId, subTabId);
    if (subTab is SentenceOnlySubTab) {
      return subTab;
    }
    throw Exception('Sub-tab "$subTabId" is not a Sentence Only type.');
  }

  /// Retrieves the list of [Word] objects from a 'Sentence Only' sub-tab.
  static Future<List<Word>> getWordsListFromSentenceOnlySubTab(String mainCategoryName, String subCategoryName, String mainTabId, String subTabId) async {
    final sentenceOnlyTab = await getSentenceOnlySubTabContent(mainCategoryName, subCategoryName, mainTabId, subTabId);
    return sentenceOnlyTab.words;
  }

  /// Retrieves the list of [Sentence] objects from a 'Sentence Only' sub-tab.
  static Future<List<Sentence>> getSentencesListFromSentenceOnlySubTab(String mainCategoryName, String subCategoryName, String mainTabId, String subTabId) async {
    final sentenceOnlyTab = await getSentenceOnlySubTabContent(mainCategoryName, subCategoryName, mainTabId, subTabId);
    return sentenceOnlyTab.sentences;
  }

  /// Checks if the 'sentenceAndWords' flag is true for a 'Sentence Only' sub-tab.
  /// Returns null if the flag is not present.
  static Future<bool?> getSentenceOnlyAndWordsFlag(String mainCategoryName, String subCategoryName, String mainTabId, String subTabId) async {
    final sentenceOnlyTab = await getSentenceOnlySubTabContent(mainCategoryName, subCategoryName, mainTabId, subTabId);
    return sentenceOnlyTab.sentenceAndWords;
  }

  // --- AssessmentSubTab Specific Calls ---
  /// Retrieves content specifically for an 'Assessment' sub-tab as an [AssessmentSubTab] object.
  /// Throws an [Exception] if the sub-tab is not of this type or not found.
  static Future<AssessmentSubTab> getAssessmentSubTabContent(String mainCategoryName, String subCategoryName, String mainTabId, String subTabId) async {
    final subTab = await getSubTabById(mainCategoryName, subCategoryName, mainTabId, subTabId);
    if (subTab is AssessmentSubTab) {
      return subTab;
    }
    throw Exception('Sub-tab "$subTabId" is not an Assessment type.');
  }

  /// Checks if a specific sub-tab is an 'Assessment' tab.
  static Future<bool> isAssessmentSubTab(String mainCategoryName, String subCategoryName, String mainTabId, String subTabId) async {
    try {
      await getAssessmentSubTabContent(mainCategoryName, subCategoryName, mainTabId, subTabId);
      return true;
    } catch (_) {
      return false;
    }
  }

  // --- Generic SubTab Calls (for unhandled types) ---
  /// Retrieves a [GenericSubTab] object for unhandled sub-tab types.
  static Future<GenericSubTab> getGenericSubTabContent(String mainCategoryName, String subCategoryName, String mainTabId, String subTabId) async {
    final subTab = await getSubTabById(mainCategoryName, subCategoryName, mainTabId, subTabId);
    if (subTab is GenericSubTab) {
      return subTab;
    }
    throw Exception('Sub-tab "$subTabId" is not a Generic SubTab type.');
  }

  /// Retrieves the raw data map for a generic sub-tab.
  static Future<Map<String, dynamic>> getGenericSubTabRawData(String mainCategoryName, String subCategoryName, String mainTabId, String subTabId) async {
    final genericSubTab = await getGenericSubTabContent(mainCategoryName, subCategoryName, mainTabId, subTabId);
    return genericSubTab.rawData;
  }
}