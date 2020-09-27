import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:either_option/either_option.dart';
import 'package:location/location.dart';

import 'article_result.dart';
import 'fetcher.dart' as fetcher;
import 'locator.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  LatLng _centrePoint;
  LatLng _userLocation;
  bool _isFetching = false;
  List<Marker> _mapMarkers = List.empty();

  final _spinner = CircularProgressIndicator(
    valueColor: AlwaysStoppedAnimation(Colors.white),
  );
  final _location = Location();

  void _handlePositionChanged(MapPosition position, bool _) {
    _centrePoint = position.center;
  }

  void _search() async {
    setState(() {
      _isFetching = true;
    });

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

    (await fetcher.get(endpoint))
      .fold(
            (error) {
              print("${error.errorCode}: ${error.errorMessage}");
              return None<_FetchArticlesResult>();
            },
            (result) => Some(_FetchArticlesResult.fromJson(result)))
      .map((a) => setState(() {
        _mapMarkers = a.articleResults.map(ArticleResult.asMarker).toList();
    }));

    setState(() {
      _isFetching = false;
    });
  }

  @override
  void initState() {
    super.initState();

    _userLocation = LatLng(50.9097, 1.4044);

    _location.getCurrentLocation()
      .then((locationResult) => locationResult
        .fold(
            (error) => print(error),
            (location) => setState(() {
              _userLocation = LatLng(location.latitude, location.longitude);
            })));

    _location.onLocationChanged.listen((event) {
      setState(() {
        _userLocation = LatLng(event.latitude, event.longitude);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final markers = List<Marker>.from(_mapMarkers);
    markers.add(Marker(
        point: _userLocation,
        builder: (_) => Container(
          child: Icon(Icons.person_pin, color: Colors.blueAccent, size: 40),
    )));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: FlutterMap(
          options: MapOptions(
            center: _userLocation,
            zoom: 8.0,
            onPositionChanged: _handlePositionChanged
          ),
          layers: [
            TileLayerOptions(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
                tileProvider: CachedNetworkTileProvider()
            ),
            MarkerLayerOptions(markers: markers)
          ],
        ),
      ),
      floatingActionButton: Stack(
        children: <Widget>[
          Positioned(
            bottom: 10,
            right: 10,
            child: FloatingActionButton(
              tooltip: 'Search',
              child: _isFetching ? _spinner : Icon(Icons.search),
              onPressed: _search,
              heroTag: 'search',
            ),
          ),
          Positioned(
            bottom: 80,
            right: 10,
            child: FloatingActionButton(
              tooltip: 'Centre',
              child: Icon(Icons.my_location),
              heroTag: 'centre',
              backgroundColor: Colors.white,
              foregroundColor: Colors.blueAccent
            ),
          )
        ],
      ),
    );
  }
}

class _FetchArticlesResult {

  final List<ArticleResult> articleResults;

  const _FetchArticlesResult({this.articleResults});

  factory _FetchArticlesResult.fromJson(dynamic json) =>
      _FetchArticlesResult(
          articleResults: (json['query']['geosearch'] as List<dynamic>)
              ?.map(ArticleResult.fromJson)
              ?.toList()
              ?? List.empty()
      );
}



