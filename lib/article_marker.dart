import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'article_preview.dart';
import 'article_result.dart';

void _handlePressed(ArticleResult article, BuildContext context) async {
  showModalBottomSheet<void>(
      context: context,
      builder: (_) => ArticlePreview(article: article, context: context),
      isScrollControlled: true);
}

class ArticleMarker extends Marker {
  ArticleMarker(ArticleResult article)
      : super(
            point: article.coordinates,
            builder: (context) => IconButton(
                  icon: const Icon(Icons.pin_drop, size: 35),
                  color: Colors.redAccent,
                  onPressed: () => _handlePressed(article, context),
                  iconSize: 35,
                ));
}
