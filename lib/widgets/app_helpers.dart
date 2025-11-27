import 'dart:convert';
import 'package:flutter/material.dart';
import '/models/category_model.dart'; // Adjust path
// ignore: depend_on_referenced_packages
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// Helper to convert model objects to a JSON-serializable map for debugging
Map<String, dynamic> toPrettyJson(Object? obj) {
  if (obj == null) return {};
  if (obj is MainCategory) {
    return {
      'name': obj.name,
      'video': obj.video,
      'youtubeVideoId': obj.youtubeVideoId,
      'image': obj.image,
      'subCategoriesCount': obj.subCategories.length,
    };
  } else if (obj is SubCategory) {
    return {
      'name': obj.name,
      'video': obj.video,
      'youtubeVideoId': obj.youtubeVideoId,
      'image': obj.image,
      'mainTabsCount': obj.mainTabs.length,
    };
  } else if (obj is MainTab) {
    return {
      'name': obj.name,
      'id': obj.id,
      'video': obj.video,
      'youtubeVideoId': obj.youtubeVideoId,
      'subTabsCount': obj.subTabs.length,
    };
  } else if (obj is WordsOnlySubTab) {
    return {
      'name': obj.name,
      'id': obj.id,
      'video': obj.video,
      'youtubeVideoId': obj.youtubeVideoId,
      'wordsOnly': obj.wordsOnly,
      'wordsCount': obj.words.length,
    };
  } else if (obj is SentenceMakingSubTab) {
    return {
      'name': obj.name,
      'id': obj.id,
      'video': obj.video,
      'youtubeVideoId': obj.youtubeVideoId,
      'activitiesCount': obj.activities.length,
    };
  } else if (obj is SentenceOnlySubTab) {
    return {
      'name': obj.name,
      'id': obj.id,
      'video': obj.video,
      'youtubeVideoId': obj.youtubeVideoId,
      'sentenceAndWords': obj.sentenceAndWords,
      'wordsCount': obj.words.length,
      'sentencesCount': obj.sentences.length,
    };
  } else if (obj is AssessmentSubTab) {
    return {
      'name': obj.name,
      'id': obj.id,
      'video': obj.video,
      'youtubeVideoId': obj.youtubeVideoId,
      'assessment': obj.assessment,
    };
  } else if (obj is GenericSubTab) {
    return obj.rawData;
  } else if (obj is Activity) {
    return {
      'name': obj.name,
      'id': obj.id,
      'wordsCount': obj.words.length,
      'sentencesCount': obj.sentences.length,
    };
  } else if (obj is Word) {
    return {
      'name': obj.name,
      'video': obj.video,
      'youtubeVideoId': obj.youtubeVideoId,
      'image': obj.image,
      'color': obj.color,
      'sentenceMakingActivities': obj.sentenceMaking,
    };
  } else if (obj is Sentence) {
    return {
      'sentence': obj.sentence,
      'wordArray': obj.wordArray,
      'video': obj.video,
      'youtubeVideoId': obj.youtubeVideoId,
    };
  }
  return {
    '_objectType': obj.runtimeType.toString(),
    '_details': obj.toString(),
  };
}

Future<void> showVideoOverlay({
  required BuildContext context,
  required String? youtubeId,
  required String title,
  required VoidCallback? onEnter,
  Object? jsonResponse,
  bool allowDismiss = true,
}) async {
  YoutubePlayerController? controller;
  bool hasValidYoutubeId = youtubeId != null && youtubeId.isNotEmpty;

  if (hasValidYoutubeId) {
    controller = YoutubePlayerController(
      initialVideoId: youtubeId!,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        controlsVisibleAtStart: true,
        disableDragSeek: false,
        loop: false,
      ),
    );
  }

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: allowDismiss,
    enableDrag: allowDismiss,
    builder: (context) {
      return WillPopScope(
        // Use WillPopScope instead of PopScope
        onWillPop: () async {
          if (controller != null) {
            controller.pause();
            // Don't dispose here, let whenComplete handle it
          }
          return allowDismiss;
        },
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    height: 20,
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: Container(
                      height: 5,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  if (hasValidYoutubeId)
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: YoutubePlayer(
                        controller: controller!,
                        showVideoProgressIndicator: true,
                        onReady: () {
                          debugPrint('YouTube Player is ready for $title');
                        },
                      ),
                    )
                  else
                    Container(
                      height: MediaQuery.of(context).size.width * 9 / 16,
                      color: Colors.black,
                      child: const Center(
                        child: Text(
                          'No video available',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: onEnter != null
                                      ? () {
                                          Navigator.pop(context);
                                          onEnter();
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Enter',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    if (controller != null) {
                                      controller.pause();
                                    }
                                    Navigator.pop(context);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red, 
                                    side: const BorderSide(color: Colors.red, width: 2),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Close',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  ).whenComplete(() {
    // Add a small delay before disposing to ensure widget tree is updated
    if (controller != null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        try {
          controller?.dispose();
        } catch (e) {
          debugPrint('Error disposing controller: $e');
        }
      });
    }
  });
}

// Generic tile builder for categories, subcategories, and main tabs
class CategoryGridTile extends StatelessWidget {
  final String title;
  final String? youtubeId; // Use this for thumbnail and video playback
  final String? imagePath; // Local image path from assets
  final VoidCallback onTap;

  const CategoryGridTile({
    super.key,
    required this.title,
    this.youtubeId,
    this.imagePath, // Add this parameter
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Priority: Local image > YouTube thumbnail > Fallback icon
    final bool hasLocalImage = imagePath != null && imagePath!.isNotEmpty;
    final String? thumbnailUrl = youtubeId != null && youtubeId!.isNotEmpty
        ? 'https://img.youtube.com/vi/$youtubeId/mqdefault.jpg'
        : null;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasLocalImage)
              // Display local image first (highest priority)
              Image.asset(
                imagePath!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // If local image fails, try YouTube thumbnail
                  if (thumbnailUrl != null) {
                    return Image.network(
                      thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildFallbackContainer();
                      },
                    );
                  }
                  return _buildFallbackContainer();
                },
              )
            else if (thumbnailUrl != null)
              // Display YouTube thumbnail if no local image
              Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.deepPurple.shade50,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallbackContainer();
                },
              )
            else
              // Fallback to a generic icon if no image or YouTube ID
              _buildFallbackContainer(),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black.withOpacity(0.6),
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackContainer() {
    return Container(
      color: Colors.deepPurple.shade100,
      alignment: Alignment.center,
      child: Icon(Icons.category, size: 48, color: Colors.deepPurple.shade400),
    );
  }
}
