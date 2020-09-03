import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

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

  LatLng _northWestPoint;
  LatLng _southEastPoint;

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
    _northWestPoint = position.bounds.northWest;
    _southEastPoint = position.bounds.southEast;
  }

  void _search() {
    print("Searching activated");
    print("North West point: latitude = ${_northWestPoint?.latitude ?? 0}, longitude = ${_northWestPoint?.longitude ?? 0}");
    print("South East point: latitude = ${_southEastPoint?.latitude ?? 0}, longitude = ${_southEastPoint?.longitude ?? 0}");
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
