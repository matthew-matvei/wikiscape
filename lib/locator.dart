import 'package:either_option/either_option.dart';
import 'package:location/location.dart';

extension LocationGetting on Location {
  Future<Either<String, LocationData>> getCurrentLocation() async {
    if (!await serviceEnabled() && !await requestService()) {
      Left("Location service is not enabled");
    }

    final locationPermission = await hasPermission();

    if (locationPermission == PermissionStatus.deniedForever) {
      Left("User has forever denied location permissions");
    }

    if (locationPermission != PermissionStatus.granted &&
        await requestPermission() != PermissionStatus.granted) {
      Left("User denied location permissions");
    }

    return Right(await getLocation());
  }
}
