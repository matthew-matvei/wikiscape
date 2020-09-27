import 'package:either_option/either_option.dart';
import 'package:location/location.dart';

extension LocationGetting on Location {
  Future<Either<String, LocationData>> getCurrent() async {
    if (!await this.serviceEnabled() && !await this.requestService()) {
      Left("Location service is not enabled");
    }

    final locationPermission = await this.hasPermission();

    if (locationPermission == PermissionStatus.deniedForever) {
      Left("User has forever denied location permissions");
    }

    if (locationPermission != PermissionStatus.granted &&
        await this.requestPermission() != PermissionStatus.granted) {
      Left("User denied location permissions");
    }

    return Right(await this.getLocation());
  }
}
