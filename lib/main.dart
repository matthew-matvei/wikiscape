import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:either_option/either_option.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wikiscape',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(title: 'Wikiscape'),
    );
  }
}

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
    Future<Either<_FetchError, _FetchArticlesResult>> fetchArticles(Uri endpoint) async {
      final response = await http.get(endpoint);

      if (response.statusCode != 200) {
        return Left(_FetchError(
            errorCode: response.statusCode, 
            errorMessage: response.reasonPhrase));
      } else {
        final decodedBody = json.decode(response.body);

        if (decodedBody['error'] != null) {
          return Left(_FetchError(
            errorCode: 0,
            errorMessage: json.encode(decodedBody['error']),
          ));
        }

        return Right(_FetchArticlesResult.fromJson(decodedBody));
      }
    }

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

    final fetchedArticles = await fetchArticles(endpoint);

    setState(() {
      _mapMarkers = fetchedArticles.fold(
              (error) {
                print("Fetch error: ${error.errorCode}: ${error.errorMessage}");
                return List.empty();
              },
              (result) => result.articleResults.map(_ArticleResult.asMarker).toList());
    });
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

class _FetchError {
  final int errorCode;
  final String errorMessage;

  const _FetchError({this.errorCode, this.errorMessage});
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
      Future<Either<_FetchError, _FetchPageInfoResult>> fetchPageInformation(Uri endpoint) async {
        final response = await http.get(endpoint);

        if (response.statusCode != 200) {
          return Left(_FetchError(
              errorCode: response.statusCode,
              errorMessage: response.reasonPhrase));
        } else {
          final decodedBody = json.decode(response.body);

          if (decodedBody['error'] != null) {
            return Left(_FetchError(
              errorCode: 0,
              errorMessage: json.encode(decodedBody['error']),
            ));
          }

          return Right(_FetchPageInfoResult.fromJson(decodedBody['query']['pages'][article.pageId.toString()]));
        }
      }

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

      final pageInformation = await fetchPageInformation(endpoint);
      final url = pageInformation.fold(
              (error) {
                print(error.errorMessage);
                return null;
              },
              (result) => result.uri);

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