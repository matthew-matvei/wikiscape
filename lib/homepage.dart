import 'dart:math';

import 'package:either_option/either_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

import 'article_result.dart';
import 'fetcher.dart' as fetcher;
import 'locator.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

bool Function(LocationData) locationDiffers(LatLng location) =>
    (otherLocation) =>
        location.latitude != otherLocation.latitude ||
        location.longitude != otherLocation.longitude;

class _HomePageState extends State<HomePage> {
  LatLng? _centrePoint;
  late LatLng _userLocation;
  bool _isFetching = false;
  List<Marker> _mapMarkers = List.empty();

  final _spinner = const CircularProgressIndicator(
    valueColor: AlwaysStoppedAnimation(Colors.white),
  );
  final _location = Location();
  final MapController _mapController = MapController();

  void _handlePositionChanged(MapPosition position, bool _) {
    _centrePoint = position.center;
  }

  void _search() async {
    if (_isFetching) {
      return;
    }

    if (_centrePoint == null) {
      return;
    }

    setState(() {
      _isFetching = true;
    });

    String formatPoint(LatLng point) =>
        [point.latitude, point.longitude].join("|");

    final endpoint = Uri.https('en.wikipedia.org', 'w/api.php', {
      'action': 'query',
      'list': 'geosearch',
      'gscoord': formatPoint(_centrePoint!),
      'gsradius': '1000',
      'gslimit': '20',
      'format': 'json',
    });

    (await fetcher.get(endpoint)).fold((error) {
      print("${error.errorCode}: ${error.errorMessage}");
      return None<_FetchArticlesResult>();
    }, (result) => Some(_FetchArticlesResult.fromJson(result))).map(
        (a) => setState(() {
              _mapMarkers =
                  a.articleResults.map(ArticleResult.asMarker).toList();

              // if there are no map markers, fitting bounds later will fail
              if (_mapMarkers.isEmpty) {
                return;
              }

              _mapController.fitBounds(
                  LatLngBounds.fromPoints(
                      _mapMarkers.map((marker) => marker.point).toList()),
                  options: const FitBoundsOptions(padding: EdgeInsets.all(40)));
            }));

    setState(() {
      _isFetching = false;
    });
  }

  void _centre() {
    _mapController.move(_userLocation, max(_mapController.zoom, 10));
  }

  @override
  void initState() {
    super.initState();

    _userLocation = LatLng(50.9097, 1.4044);

    _location.getCurrentLocation().then((locationResult) =>
        locationResult.fold((error) => print(error), (location) {
          if (location.latitude == null || location.longitude == null) {
            return;
          }

          setState(() {
            _userLocation = LatLng(location.latitude!, location.longitude!);
          });
        }));

    _location.onLocationChanged
        .where(locationDiffers(_userLocation))
        .listen((location) {
      if (location.latitude == null || location.longitude == null) {
        return;
      }

      setState(() {
        _userLocation = LatLng(location.latitude!, location.longitude!);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final markers = List<Marker>.from(_mapMarkers);
    markers.insert(
        0,
        Marker(
            point: _userLocation,
            builder: (_) => const Icon(Icons.person_pin_circle,
                color: Colors.blueAccent, size: 40)));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: FlutterMap(
            options: MapOptions(
                center: _userLocation,
                zoom: 8.0,
                onPositionChanged: _handlePositionChanged),
            mapController: _mapController,
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: markers,
              )
            ]),
      ),
      floatingActionButton: Stack(
        children: <Widget>[
          Positioned(
            bottom: 10,
            right: 10,
            child: FloatingActionButton(
                tooltip: 'Search',
                onPressed: _search,
                heroTag: 'search',
                child: _isFetching ? _spinner : const Icon(Icons.search)),
          ),
          Positioned(
            bottom: 90,
            right: 10,
            child: FloatingActionButton(
                tooltip: 'Centre',
                onPressed: _centre,
                heroTag: 'centre',
                backgroundColor: Colors.white,
                foregroundColor: Colors.blueAccent,
                child: const Icon(Icons.my_location)),
          )
        ],
      ),
    );
  }
}

class _FetchArticlesResult {
  final List<ArticleResult> articleResults;

  const _FetchArticlesResult({required this.articleResults});

  factory _FetchArticlesResult.fromJson(dynamic json) => _FetchArticlesResult(
      articleResults: (json['query']['geosearch'] as List<dynamic>)
          .map(ArticleResult.fromJson)
          .toList());
}
