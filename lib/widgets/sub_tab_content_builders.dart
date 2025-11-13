import 'dart:convert';
import 'package:flutter/material.dart';
import '/models/category_model.dart';
import '/widgets/app_helpers.dart'; // For showVideoOverlay, toPrettyJson, CategoryGridTile

// Helper to get the runtime type name of a SubTabBase for display
String getActualSubTabTypeName(SubTabBase? subTab) {
  if (subTab is WordsOnlySubTab) return 'WordsOnly';
  if (subTab is SentenceMakingSubTab) return 'SentenceMaking';
  if (subTab is SentenceOnlySubTab) return 'SentenceOnly';
  if (subTab is AssessmentSubTab) return 'Assessment';
  if (subTab is GenericSubTab) return 'Generic';
  return 'Unknown/No Sub-Tab Selected';
}


Widget buildWordsOnlyContent(BuildContext context, WordsOnlySubTab subTab) {
  if (subTab.words.isEmpty) {
    return const Text('No words available in this section.');
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Words in "${subTab.name ?? 'Words Only'}":',
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
        itemCount: subTab.words.length,
        itemBuilder: (context, index) {
          final word = subTab.words[index];
          return CategoryGridTile(
            title: word.name ?? 'N/A',
            youtubeId: word.youtubeVideoId,
            imagePath: word.image, // Use local image if available
            onTap: () {
              showVideoOverlay(
                context: context,
                youtubeId: word.youtubeVideoId,
                title: 'Word: ${word.name ?? 'N/A'}',
                jsonResponse: word,
                onEnter: null,
              );
            },
          );
        },
      ),
    ],
  );
}

Widget buildSentenceOnlyContent(BuildContext context, SentenceOnlySubTab subTab) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (subTab.words.isNotEmpty) ...[
        Text('Words in "${subTab.name ?? 'Sentence Only'}":',
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
          itemCount: subTab.words.length,
          itemBuilder: (context, index) {
            final word = subTab.words[index];
            return CategoryGridTile(
              title: word.name ?? 'N/A',
              youtubeId: word.youtubeVideoId,
              imagePath: word.image, // Use local image if available
              onTap: () {
                showVideoOverlay(
                  context: context,
                  youtubeId: word.youtubeVideoId,
                  title: 'Word: ${word.name ?? 'N/A'}',
                  jsonResponse: word,
                  onEnter: null,
                );
              },
            );
          },
        ),
        const SizedBox(height: 20),
      ],
      if (subTab.sentences.isNotEmpty) ...[
        Text('Sentences in "${subTab.name ?? 'Sentence Only'}":',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: subTab.sentences.length,
          itemBuilder: (context, index) {
            final sentence = subTab.sentences[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                title: Text(sentence.sentence ?? 'No sentence text'),
                trailing: IconButton(
                  icon: const Icon(Icons.play_circle_fill),
                  onPressed: () {
                    showVideoOverlay(
                      context: context,
                      youtubeId: sentence.youtubeVideoId,
                      title: 'Sentence: ${sentence.sentence ?? 'N/A'}',
                      jsonResponse: sentence,
                      onEnter: null,
                    );
                  },
                ),
              ));
            },
          ),
        ] else if (subTab.words.isEmpty)
          const Text('No content (words or sentences) available in this section.'),
    ],
  );
}

Widget buildAssessmentContent(BuildContext context, AssessmentSubTab subTab) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Assessment for "${subTab.name ?? 'Assessment'}":',
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      const Text(
          'This is an assessment section. Specific assessment logic would go here. '
          'The data structure for assessments is typically more complex, involving questions, answer options, and scoring.'),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: () {
          // Placeholder for starting assessment
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Starting assessment... (Not implemented yet)')),
          );
        },
        child: const Text('Start Assessment'),
      ),
    ],
  );
}

Widget buildGenericContent(BuildContext context, GenericSubTab subTab) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Generic Content for "${subTab.name ?? 'Generic Tab'}":',
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      const Text(
          'This tab type is not specifically handled. Displaying raw JSON data for debugging.'),
      const SizedBox(height: 10),
      ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 300),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(8),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              const JsonEncoder.withIndent('  ').convert(toPrettyJson(subTab.rawData)),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ),
      ),
    ],
  );
}