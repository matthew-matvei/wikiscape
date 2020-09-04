import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:either_option/either_option.dart';
import 'package:http/http.dart' as http;

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

  var staticMarkers = <Marker>[
    Marker(
      width: 40,
      height: 40,
      point: LatLng(50.9097, 1.4044),
      builder: (_) => Container(
        child: FlutterLogo(
          colors: Colors.blue,
          key: ObjectKey(Colors.blue),
        ),
      )
    )
  ];

  void _handlePositionChanged(MapPosition position, bool _) {
    _centrePoint = position.center;
  }

  void _search() async {
    Future<Either<_FetchError, _FetchResult>> fetchArticles(Uri endpoint) async {
      final response = await http.get(endpoint);

      if (response.statusCode != 200) {
        return Left(_FetchError(
            errorCode: response.statusCode, 
            errorMessage: response.reasonPhrase));
      } else {
        final decodedBody = json.decode(response.body);
        print(decodedBody);

        if (decodedBody['error'] != null) {
          return Left(_FetchError(
            errorCode: 0,
            errorMessage: json.encode(decodedBody['error']),
          ));
        }

        print(response.statusCode);
        return Right(_FetchResult.fromJson(decodedBody));
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

    print("Searching activated");
    final fetchedArticles = await fetchArticles(endpoint);
    fetchedArticles.fold(
            (error) => print("${error.errorCode}: ${error.errorMessage}"),
            (result) => {
              for (var i in result.queryResults) {
                print("Title = ${i.title}, Id = ${i.pageId}")
              }
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
            MarkerLayerOptions(markers: staticMarkers)
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

class _FetchResult {

  final List<_QueryResult> queryResults;

  const _FetchResult({this.queryResults});

  factory _FetchResult.fromJson(Map<String, dynamic> json) =>
      _FetchResult(queryResults: (json['query']['geosearch'] as List<dynamic>).map((result) => _QueryResult(pageId: result['pageid'], title: result['title'])).toList());
}

class _QueryResult {
  final int pageId;
  final String title;

  const _QueryResult({this.pageId, this.title});
}