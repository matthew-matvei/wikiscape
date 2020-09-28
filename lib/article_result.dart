import 'package:latlong/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

import 'article_marker.dart';

class ArticleResult {
  final int pageId;
  final String title;
  final LatLng coordinates;

  const ArticleResult({this.pageId, this.title, this.coordinates});

  static ArticleResult fromJson(dynamic json) =>
      ArticleResult(
        pageId: json['pageid'],
        title: json['title'],
        coordinates: LatLng(json['lat'], json['lon']),
      );

  static Marker asMarker(ArticleResult article) => ArticleMarker(article);
}
