import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:either_option/either_option.dart';

import 'article_result.dart';
import 'fetcher.dart' as fetcher;

void _handlePressed(ArticleResult article) async {
  final endpoint = Uri.https(
      'en.wikipedia.org',
      'w/api.php',
      {
        'action': 'query',
        'prop': 'info',
        'inprop': 'url',
        'titles': article.title,
        'format': 'json',
      }
  );

  (await fetcher.get(endpoint))
      .fold(
          (error) {
        print("${error.errorCode}: ${error.errorMessage}");
        return None<String>();
      },
          (result) =>
          Some(_FetchPageInfoResult
              .fromJson(result['query']['pages'][article.pageId.toString()])
              .uri))
      .fold(
          () => print("Couldn't acquire url"),
          (urlString) async =>
      {
        if (await canLaunch(urlString)) {
          await launch(urlString)
        } else {
            print("Couldn't launch url")
          }
      });
}

class ArticleMarker extends Marker {

  ArticleMarker(ArticleResult article) : super(
      point: article.coordinates,
      builder: (_) =>
          Container(
              child: IconButton(
                icon: Icon(Icons.pin_drop, size: 35),
                color: Colors.redAccent,
                onPressed: () => _handlePressed(article),
                iconSize: 35,
              )
          )
  );
}

class _FetchPageInfoResult {

  final String uri;

  const _FetchPageInfoResult({this.uri});

  factory _FetchPageInfoResult.fromJson(Map<String, dynamic> json) =>
      _FetchPageInfoResult(uri: json['canonicalurl']);
}
