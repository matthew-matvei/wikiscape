import 'dart:convert';

import 'package:either_option/either_option.dart';
import 'package:http/http.dart' as http;

Future<Either<FetchError, Map<String, dynamic>>> get(Uri endpoint) async {
  final response = await http.get(endpoint);

  if (response.statusCode != 200) {
    return Left(FetchError._(
        errorCode: response.statusCode,
        errorMessage: response.reasonPhrase));
  } else {
    final decodedBody = json.decode(response.body);

    return decodedBody['error'] != null
        ? Left(FetchError._(
            errorCode: 0,
            errorMessage: json.encode(decodedBody['error']),
          ))
        : Right(decodedBody);
  }
}

class FetchError {
  final int errorCode;
  final String errorMessage;

  const FetchError._({this.errorCode, this.errorMessage});
}
