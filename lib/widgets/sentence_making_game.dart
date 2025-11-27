import 'package:flutter/material.dart';
import '/models/category_model.dart';
import '/widgets/app_helpers.dart'; // For showVideoOverlay

Widget buildSentenceMakingGame({
  required BuildContext context,
  required SentenceMakingSubTab subTab,
  required Activity? selectedActivity,
  required List<Word> availableGameWords,
  required List<Word> chosenSentenceWords,
  required String gameMessage,
  required ValueChanged<Activity?> onActivitySelected,
  required ValueChanged<Word> onAddWord,
  required ValueChanged<Word> onRemoveWord,
  required VoidCallback onCheckSentence,
}) {
  if (subTab.activities.isEmpty) {
    return const Text('No activities available for sentence making in this section.');
  }

  return Column(
    children: [
      // TOP SECTION - Fixed header with title and dropdown
      Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sentence Making Game',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            DropdownButtonFormField<Activity>(
        value: selectedActivity,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Select Activity',
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Add this
          isDense: true, // Add this to make it more compact
        ),
              items: subTab.activities.map((activity) {
                return DropdownMenuItem<Activity>(
                  value: activity,
                  child: Text(activity.name ?? 'Untitled Activity'),
                );
              }).toList(),
              onChanged: onActivitySelected,
            ),
          ],
        ),
      ),

      // MIDDLE SECTION - Scrollable word grid (takes remaining space)
      Expanded(
        child: selectedActivity != null
            ? SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: availableGameWords.length,
                  itemBuilder: (context, index) {
                    final word = availableGameWords[index];
                    final isSelected = chosenSentenceWords.contains(word);
                    return GameWordTile(
                      word: word,
                      isSelected: isSelected,
                      onTap: (selectedWord) {
                        onAddWord(selectedWord);
                        showVideoOverlay(
                          context: context,
                          youtubeId: selectedWord.youtubeVideoId,
                          title: 'Word: ${selectedWord.name ?? 'N/A'}',
                          jsonResponse: selectedWord,
                          onEnter: null,
                        );
                      },
                    );
                  },
                ),
              )
            : const Center(
                child: Text('Please select an activity to start the game.'),
              ),
      ),

      // BOTTOM SECTION - Fixed drop zone (always visible, non-scrollable)
      if (selectedActivity != null)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 140,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 3),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.blue.withOpacity(0.1),
                ),
                child: chosenSentenceWords.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              color: Colors.blue.withOpacity(0.5),
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap words above to build your sentence',
                              style: TextStyle(
                                color: Colors.blue.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: chosenSentenceWords.map((word) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildSentenceWordCard(word, onRemoveWord),
                            );
                          }).toList(),
                        ),
                      ),
              ),
              if (gameMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    gameMessage,
                    style: TextStyle(
                      color: gameMessage.startsWith('Correct') ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onCheckSentence,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Check Sentence'),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

Widget _buildSentenceWordCard(Word word, ValueChanged<Word> onRemove) {
  Color bgColor = _parseColorStatic(word.color);
  
  final String? thumbnailUrl = word.youtubeVideoId != null && word.youtubeVideoId!.isNotEmpty
      ? 'https://img.youtube.com/vi/${word.youtubeVideoId}/mqdefault.jpg'
      : null;
  
  final bool hasLocalImage = word.image != null && word.image!.isNotEmpty;
  
  return GestureDetector(
    onTap: () => onRemove(word),
    child: Container(
      width: 100,
      height: 115,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            color: bgColor,
            padding: const EdgeInsets.all(4),
            child: Text(
              word.name ?? 'N/A',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: Center(
                child: _buildSentenceImageWidget(hasLocalImage, thumbnailUrl, word),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            color: bgColor,
            child: const Icon(Icons.close, color: Colors.white, size: 18),
          ),
        ],
      ),
    ),
  );
}

Widget _buildSentenceImageWidget(bool hasLocalImage, String? thumbnailUrl, Word word) {
  if (hasLocalImage) {
    return Image.asset(
      word.image!,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        if (thumbnailUrl != null) {
          return Image.network(
            thumbnailUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.image, size: 30, color: Colors.grey[400]);
            },
          );
        }
        return Icon(Icons.image, size: 30, color: Colors.grey[400]);
      },
    );
  } else if (thumbnailUrl != null) {
    return Image.network(
      thumbnailUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.image, size: 30, color: Colors.grey[400]);
      },
    );
  } else {
    return Icon(Icons.image, size: 30, color: Colors.grey[400]);
  }
}

Color _parseColorStatic(String? colorString) {
  switch (colorString?.toLowerCase()) {
    case 'yellow':
      return Colors.yellow[700]!;
    case 'orange':
      return Colors.orange;
    case 'blue':
      return Colors.blue;
    case 'red':
      return Colors.red;
    case 'green':
      return Colors.green;
    case 'dark':
      return Colors.grey.shade800;
    default:
      return Colors.grey.shade400;
  }
}

class GameWordTile extends StatelessWidget {
  final Word word;
  final bool isSelected;
  final ValueChanged<Word> onTap;

  const GameWordTile({
    super.key,
    required this.word,
    required this.isSelected,
    required this.onTap,
  });

  Color _parseColor(String? colorString) {
    switch (colorString?.toLowerCase()) {
      case 'yellow':
        return Colors.yellow[700]!;
      case 'orange':
        return Colors.orange;
      case 'blue':
        return Colors.blue;
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'dark':
        return Colors.grey.shade800;
      default:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(word.color);
    
    final String? thumbnailUrl = word.youtubeVideoId != null && word.youtubeVideoId!.isNotEmpty
        ? 'https://img.youtube.com/vi/${word.youtubeVideoId}/mqdefault.jpg'
        : null;
    
    final bool hasLocalImage = word.image != null && word.image!.isNotEmpty;

    return GestureDetector(
      onTap: () => onTap(word),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: isSelected 
              ? Border.all(color: Colors.deepPurple, width: 3)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.2 : 0.1),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              Container(
                color: bgColor,
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        word.name ?? 'N/A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.deepPurple,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: Center(
                    child: _buildImageWidget(hasLocalImage, thumbnailUrl, bgColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(bool hasLocalImage, String? thumbnailUrl, Color bgColor) {
    if (hasLocalImage) {
      return Image.asset(
        word.image!,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          if (thumbnailUrl != null) {
            return Image.network(
              thumbnailUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholder();
              },
            );
          }
          return _buildPlaceholder();
        },
      );
    } else if (thumbnailUrl != null) {
      return Image.network(
        thumbnailUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Icon(
      Icons.text_fields,
      size: 50,
      color: Colors.grey[400],
    );
  }
}