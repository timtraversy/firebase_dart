import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;

import 'firebase.dart';

class Firestore {
  final Firebase firebase;
  final baseUrl;
  Firestore({@required Firebase firebase})
      : firebase = firebase,
        baseUrl =
            'https://firestore.googleapis.com/v1beta1/projects/${firebase.projectId}/databases/(default)/documents/';

  Future deleteDocument(
      {@required String name, Precondition precondition}) async {
    var url = '$baseUrl$name';
    if (precondition.exists != null) {
      url += '?currentDocument.exists=${precondition.exists}';
    }
    if (precondition.updateTime != null) {
      url +=
          '?currentDocument.updateTime=${_dateTimeToTimestamp(precondition.updateTime)}';
    }
    final response = await http.delete(url);
    if (response.statusCode != 200) {
      print('Error: Deletion unsuccesful');
      print(response.body);
      return;
    }
    return;
  }

  Future<String> createDocument(
      {@required String path,
      @required Map<String, dynamic> document,
      String docId = ''}) async {
    final url = '$baseUrl$path?documentId=$docId';

    final fields = _parseMap(document);
    if (fields == null) {
      return null;
    }

    final json = jsonEncode(fields);
    final response = await http.post(url, body: json);
    if (response.statusCode != 200) {
      print('Error: Document creation unsuccesful');
      print(response.body);
      return null;
    }
    return response.body;
  }

  String _dateTimeToTimestamp(DateTime dt) {
    return dt.toUtc().toIso8601String();
  }

  Map<String, dynamic> _parseMap(Map<String, dynamic> document) {
    var fields = {};
    var entries = document.entries;
    for (final entry in entries) {
      final json = _valueToJson(entry.value);
      if (json == null) {
        print('Error: Unsupported data type: ${entry.value}');
        return null;
      }
      fields[entry.key] = _valueToJson(entry.value);
    }
    return {'fields': fields};
  }

  Map<String, dynamic> _valueToJson(dynamic value) {
    if (value == null) {
      return {'nullValue': value};
    }
    if (value is bool) {
      return {'booleanValue': value};
    }
    if (value is int) {
      return {'integerValue': value};
    }
    if (value is double) {
      return {'doubleValue': value};
    }
    if (value is DateTime) {
      return {'timestampValue': value.toUtc().toIso8601String()};
    }
    if (value is String) {
      return {'stringValue': value};
    }
    // TODO: bytes parsing, gh link
    if (value is Uint8List) {
      print('This package can\'t handle byte values yet.');
      return null;
//      return {'bytesValue': value.toString()};
    }
    if (value is Reference) {
      return {'referenceValue': value.path};
    }
    if (value is LatLng) {
      return {
        'geoPointValue': {
          "latitude": value.lat,
          "longitude": value.lng,
        }
      };
    }
    if (value is List) {
      final arrayValue = {
        'arrayValue': {'values': []}
      };
      for (final subVal in value) {
        if (subVal is List) {
          print('Error: an array cannot directly contain another array value');
          return null;
        }
        arrayValue['arrayValue']['values'].add(_valueToJson(subVal));
      }
      return arrayValue;
    }
    if (value is Map) {
      return {'mapValue': _parseMap(value)};
    }
    return null;
  }
}

class Reference {
  final String path;
  Reference({@required this.path});
}

class LatLng {
  final double lat, lng;
  LatLng({@required this.lat, @required this.lng});
}

class Precondition {
  final bool exists;
  final DateTime updateTime;
  Precondition({this.exists, this.updateTime});
}
