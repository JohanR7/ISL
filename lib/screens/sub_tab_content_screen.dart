

import 'package:flutter/foundation.dart'; // For listEquals
import 'package:flutter/material.dart';
import '/models/category_model.dart';
import '/services/local_api.dart';
import '/widgets/app_helpers.dart'; // Global helpers
import '/widgets/sub_tab_content_builders.dart'; // Sub-tab specific builders
import '/widgets/sentence_making_game.dart'; // Game specific widgets

class SubTabContentScreen extends StatefulWidget {
  final String mainCategoryName;
  final String subCategoryName;
  final String mainTabId;
  final Object? mainTabJson;

  const SubTabContentScreen({
    super.key,
    required this.mainCategoryName,
    required this.subCategoryName,
    required this.mainTabId,
    this.mainTabJson,
  });

  @override
  State<SubTabContentScreen> createState() => _SubTabContentScreenState();
}

class _SubTabContentScreenState extends State<SubTabContentScreen> {
  List<SubTabBase> _allSubTabs = [];
  SubTabBase? _selectedSubTabContent; // The currently selected sub-tab to display its content

  String _errorMessage = '';
  bool _isLoading = true;
  Object? _lastApiCallJson; // JSON response for the *content* of the selected sub-tab

  // State for Sentence Making Game (managed here to be passed down)
  Activity? _selectedActivity;
  List<Word> _availableGameWords = [];
  final List<Word> _chosenSentenceWords = [];
  String _gameMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAllSubTabsAndSetDefault();
  }

  Future<void> _fetchAllSubTabsAndSetDefault() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _allSubTabs = [];
      _selectedSubTabContent = null;
      _lastApiCallJson = null;
      _selectedActivity = null;
      _availableGameWords = [];
      _chosenSentenceWords.clear();
      _gameMessage = '';
    });

    try {
      _allSubTabs = await LocalAPI.getAllSubTabsForMainTab(
          widget.mainCategoryName, widget.subCategoryName, widget.mainTabId);

      if (_allSubTabs.isNotEmpty) {
        // Automatically select the first sub-tab to display its content
        await _selectSubTab(_allSubTabs.first.id!);
      } else {
        _errorMessage = 'No sub-tabs found for this main tab.';
      }
    } catch (e) {
      _errorMessage = 'Error loading sub-tabs: ${e.toString()}';
      debugPrint('API Call Error: $_errorMessage');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectSubTab(String subTabId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _lastApiCallJson = null;
      _selectedActivity = null;
      _availableGameWords = [];
      _chosenSentenceWords.clear();
      _gameMessage = '';
    });

    try {
      final subTabBase = await LocalAPI.getSubTabById(
          widget.mainCategoryName, widget.subCategoryName, widget.mainTabId, subTabId);
      _selectedSubTabContent = subTabBase;
      _lastApiCallJson = subTabBase; // Store the content object itself

      // Handle specific sub-tab types for game logic or display setup
      if (subTabBase is SentenceMakingSubTab) {
        if (subTabBase.activities.isNotEmpty) {
          _selectedActivity = subTabBase.activities.first;
          _availableGameWords = _selectedActivity!.words;
        } else {
          _errorMessage = 'No activities found for this Sentence Making tab.';
        }
      } else if (subTabBase is WordsOnlySubTab) {
        _availableGameWords = subTabBase.words;
      } else if (subTabBase is SentenceOnlySubTab) {
        _availableGameWords = subTabBase.words;
      }

    } catch (e) {
      _errorMessage = 'Error loading content for sub-tab "$subTabId": ${e.toString()}';
      debugPrint('API Call Error: $_errorMessage');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Sentence Making Game Logic (moved from main.dart, now within _SubTabContentScreenState)
  void _addWordToSentence(Word word) {
    setState(() {
      if (!_chosenSentenceWords.contains(word)) {
        _chosenSentenceWords.add(word);
      }
      _gameMessage = ''; // Clear previous message
    });
  }

  void _removeWordFromSentence(Word word) {
    setState(() {
      _chosenSentenceWords.remove(word);
      _gameMessage = '';
    });
  }

  void _checkSentence() {
    if (_selectedActivity == null || _chosenSentenceWords.isEmpty) {
      setState(() {
        _gameMessage = 'Please choose words to form a sentence.';
      });
      return;
    }

    // Convert chosen words to a sorted list of names for order-independent comparison
    final List<String> chosenWordNames =
        _chosenSentenceWords.map((w) => w.name?.toLowerCase() ?? '').toList()..sort();

    bool correct = false;
    Sentence? matchedSentence;

    for (var sentence in _selectedActivity!.sentences) {
      final List<String> sentenceWordNames =
          sentence.wordArray.map((w) => w.toLowerCase()).toList()..sort();

      // Check if word counts match and if all chosen words are in the sentence (order-independent)
      if (chosenWordNames.length == sentenceWordNames.length &&
          listEquals(chosenWordNames, sentenceWordNames)) {
        correct = true;
        matchedSentence = sentence;
        break;
      }
    }

    setState(() {
      if (correct) {
        _gameMessage = 'Correct! Good job!';
        if (matchedSentence?.youtubeVideoId != null &&
            matchedSentence!.youtubeVideoId!.isNotEmpty) {
          showVideoOverlay( // Use global helper
            context: context,
            youtubeId: matchedSentence.youtubeVideoId,
            title: 'Correct Sentence: "${matchedSentence.sentence}"',
            jsonResponse: matchedSentence,
            onEnter: null, // No further navigation after correct answer video
            allowDismiss: false, // User must interact with buttons
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Correct! "${matchedSentence?.sentence ?? 'Sentence'}" formed.')));
        }
      } else {
        _gameMessage = 'Try again! This sentence does not match any known sentences.';
      }
      _chosenSentenceWords.clear(); // Clear for next attempt
    });
  }


  // Helper to get the runtime type name of a SubTabBase for display
  String _getActualSubTabTypeName(SubTabBase? subTab) {
    if (subTab is WordsOnlySubTab) return 'WordsOnly';
    if (subTab is SentenceMakingSubTab) return 'SentenceMaking';
    if (subTab is SentenceOnlySubTab) return 'SentenceOnly';
    if (subTab is AssessmentSubTab) return 'Assessment';
    if (subTab is GenericSubTab) return 'Generic';
    return 'Unknown/No Sub-Tab Selected';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.mainTabId)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
              : Column(
                  children: [
                    // Horizontal list of sub-tabs
                    _buildSubTabSelector(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Content for Main Tab: ${widget.mainTabId}',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Currently showing: ${_getActualSubTabTypeName(_selectedSubTabContent)}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.deepPurple),
                            ),
                            const SizedBox(height: 20),
                            // Render content based on the type of _selectedSubTabContent
                            _buildSubTabContent(),
                          ],
                        ),
                      ),
                    ),
                    if (_lastApiCallJson != null)
                      buildJsonResponsePanel( // Use global helper
                        context,
                        'API response for selected sub-tab content:',
                        _lastApiCallJson!,
                      ),
                  ],
                ),
    );
  }

  Widget _buildSubTabSelector() {
    return Container(
      height: 60, // Fixed height for the horizontal list
      color: Colors.grey[200],
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _allSubTabs.length,
        itemBuilder: (context, index) {
          final subTab = _allSubTabs[index];
          final bool isSelected = _selectedSubTabContent?.id == subTab.id;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: ChoiceChip(
              label: Text(subTab.name ?? 'N/A'),
              selected: isSelected,
              selectedColor: Theme.of(context).primaryColor,
              onSelected: (selected) {
                if (selected) {
                  _selectSubTab(subTab.id!);
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubTabContent() {
    if (_selectedSubTabContent is WordsOnlySubTab) {
      return buildWordsOnlyContent(context, _selectedSubTabContent as WordsOnlySubTab);
    } else if (_selectedSubTabContent is SentenceMakingSubTab) {
      // Pass down the necessary state and callbacks for the game
      return buildSentenceMakingGame(
        context: context, // Explicitly pass context
        subTab: _selectedSubTabContent as SentenceMakingSubTab,
        selectedActivity: _selectedActivity,
        availableGameWords: _availableGameWords,
        chosenSentenceWords: _chosenSentenceWords,
        gameMessage: _gameMessage,
        onActivitySelected: (activity) {
          setState(() {
            _selectedActivity = activity;
            _availableGameWords = activity?.words ?? [];
            _chosenSentenceWords.clear();
            _gameMessage = '';
          });
        },
        onAddWord: _addWordToSentence,
        onRemoveWord: _removeWordFromSentence,
        onCheckSentence: _checkSentence,
      );
    } else if (_selectedSubTabContent is SentenceOnlySubTab) {
      return buildSentenceOnlyContent(context, _selectedSubTabContent as SentenceOnlySubTab);
    } else if (_selectedSubTabContent is AssessmentSubTab) {
      return buildAssessmentContent(context, _selectedSubTabContent as AssessmentSubTab);
    } else if (_selectedSubTabContent is GenericSubTab) {
      return buildGenericContent(context, _selectedSubTabContent as GenericSubTab);
    }
    return const Text('Select a sub-tab to view its content.', style: TextStyle(fontStyle: FontStyle.italic));
  }
}