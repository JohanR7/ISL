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
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Sentence Making Game - "${subTab.name ?? 'Sentence Making'}"',
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      DropdownButtonFormField<Activity>(
        value: selectedActivity,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Select Activity',
        ),
        items: subTab.activities.map((activity) {
          return DropdownMenuItem<Activity>(
            value: activity,
            child: Text(activity.name ?? 'Untitled Activity'),
          );
        }).toList(),
        onChanged: onActivitySelected,
      ),
      const SizedBox(height: 20),
      if (selectedActivity != null) ...[
        Text('Available Words for "${selectedActivity.name ?? 'Activity'}":',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 columns for better thumbnail display
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2, // Adjust for thumbnail proportions
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
        const SizedBox(height: 20),
        Text('Your Sentence:', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: chosenSentenceWords.map((word) {
            return Chip(
              label: Text(word.name ?? ''),
              onDeleted: () => onRemoveWord(word),
              deleteIcon: const Icon(Icons.close, size: 18),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        if (gameMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Text(
              gameMessage,
              style: TextStyle(
                color: gameMessage.startsWith('Correct') ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onCheckSentence,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Check Sentence'),
          ),
        ),
      ] else
        const Text('Please select an activity to start the game.'),
    ],
  );
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
        return Colors.yellow;
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
        return Colors.grey.shade400; // Default color
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(word.color);
    final textColor = (bgColor == Colors.yellow || bgColor == Colors.white) ? Colors.black : Colors.white;
    
    // Get thumbnail URL if YouTube ID exists
    final String? thumbnailUrl = word.youtubeVideoId != null && word.youtubeVideoId!.isNotEmpty
        ? 'https://img.youtube.com/vi/${word.youtubeVideoId}/mqdefault.jpg'
        : null;
    
    final bool hasLocalImage = word.image != null && word.image!.isNotEmpty;

    return InkWell(
      onTap: () => onTap(word),
      child: Card(
        elevation: isSelected ? 8 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: isSelected ? const BorderSide(color: Colors.deepPurple, width: 3) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image/thumbnail layer
            if (hasLocalImage)
              Image.asset(
                word.image!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  if (thumbnailUrl != null) {
                    return Image.network(
                      thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildColoredBackground(bgColor);
                      },
                    );
                  }
                  return _buildColoredBackground(bgColor);
                },
              )
            else if (thumbnailUrl != null)
              Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildColoredBackground(bgColor);
                },
                errorBuilder: (context, error, stackTrace) {
                  return _buildColoredBackground(bgColor);
                },
              )
            else
              _buildColoredBackground(bgColor),
            
            // Overlay gradient for better text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
            
            // Text overlay at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  word.name ?? 'N/A',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 3,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Selected indicator
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildColoredBackground(Color bgColor) {
    return Container(
      color: bgColor,
      alignment: Alignment.center,
      child: Icon(
        Icons.text_fields,
        size: 48,
        color: (bgColor == Colors.yellow || bgColor == Colors.white) 
            ? Colors.black26 
            : Colors.white24,
      ),
    );
  }
}