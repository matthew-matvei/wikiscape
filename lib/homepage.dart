import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'fetcher.dart' as fetcher;

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  LatLng _centrePoint;
  List<Marker> _mapMarkers = List.empty();

  void _handlePositionChanged(MapPosition position, bool _) {
    _centrePoint = position.center;
  }

  void _search() async {
    String formatPoint(LatLng point) =>
        [point.latitude, point.longitude].join("|");

    final endpoint = Uri.https(
        'en.wikipedia.org',
        'w/api.php',
        {
          'action': 'query',
          'list': 'geosearch',
          'gscoord': formatPoint(_centrePoint),
          'gsradius': '1000',
          'gslimit': '20',
          'format': 'json',
        }
    );

    final fetchedArticles = (await fetcher.get(endpoint))
      .fold(
            (error) {
              print("${error.errorCode}: ${error.errorMessage}");
              return null;
            },
            (result) => _FetchArticlesResult.fromJson(result));

    if (fetchedArticles != null) {
      setState(() {
        _mapMarkers = fetchedArticles
            .articleResults
            .map(_ArticleResult.asMarker)
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: FlutterMap(
          options: MapOptions(
            center: LatLng(50.9097, 1.4044),
            zoom: 8.0,
            onPositionChanged: _handlePositionChanged,
          ),
          layers: [
            TileLayerOptions(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
                tileProvider: CachedNetworkTileProvider()
            ),
            MarkerLayerOptions(markers: _mapMarkers)
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Search',
        child: Icon(Icons.search),
        onPressed: _search,
      ),
    );
  }
}

class _FetchArticlesResult {

  final List<_ArticleResult> articleResults;

  const _FetchArticlesResult({this.articleResults});

  factory _FetchArticlesResult.fromJson(Map<String, dynamic> json) =>
      _FetchArticlesResult(articleResults: (json['query']['geosearch'] as List<dynamic>).map((result) => _ArticleResult.fromJson(result)).toList());
}

class _ArticleResult {
  final int pageId;
  final String title;
  final LatLng coordinates;

  const _ArticleResult(
      {
        this.pageId,
        this.title,
        this.coordinates,
      });

  factory _ArticleResult.fromJson(Map<String, dynamic> json) =>
      _ArticleResult(
        pageId: json['pageid'],
        title: json['title'],
        coordinates: LatLng(json['lat'], json['lon']),
      );

  static Marker asMarker(_ArticleResult article) {
    void _handleButtonPressed() async {
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

      final url = (await fetcher.get(endpoint))
        .fold(
              (error) {
                print("${error.errorCode}: ${error.errorMessage}");
                return null;
              },
              (result) => _FetchPageInfoResult
                  .fromJson(result['query']['pages'][article.pageId.toString()])
                  .uri);

      if (url != null && await canLaunch(url)) {
        await launch(url);
      } else {
        print("Couldn't launch url");
      }
    }

    return Marker(
        width: 40,
        height: 40,
        point: LatLng(article.coordinates.latitude, article.coordinates.longitude),
        builder: (_) => Container(
            child: IconButton(
              icon: Icon(Icons.pin_drop),
              color: Colors.redAccent,
              onPressed: _handleButtonPressed,
            )
        )
    );
  }
}

class _FetchPageInfoResult {

  final String uri;

  const _FetchPageInfoResult({this.uri});

  factory _FetchPageInfoResult.fromJson(Map<String, dynamic> json) =>
      _FetchPageInfoResult(uri: json['canonicalurl']);
}