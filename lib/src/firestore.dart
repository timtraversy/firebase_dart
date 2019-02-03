import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;

import 'firebase.dart';

class FirestoreError extends Error {

}

class Firestore {
  final Firebase firebase;
  final String baseUrl;
  final String baseName;

  Firestore({@required Firebase firebase})
      : firebase = firebase,
        baseUrl =
            'https://firestore.googleapis.com/v1beta1/projects/${firebase.projectId}/databases/(default)/documents/',
        baseName =
            'projects/${firebase.projectId}/databases/(default)/documents/';

  @override
  String toString() {
    return 'Firestore{firebase: $firebase}';
  }

  DocumentReference doc(String name) =>
      DocumentReference(firestore: this, name: name);

  CollectionReference collection(String name) =>
      CollectionReference(firestore: this, name: name);

  // API methods

  Future<DocumentReference> _createDocument(
      {@required String path, @required Map<String, dynamic> document}) async {
    final url = '$baseUrl$path?documentId=';

    final fields = _parseDocumentMap(document);

    final response = await http.post(url, body: jsonEncode(fields));
    if (response.statusCode != 200) {
      throw FormatException('Failed to create document: ${response.body}');
    }

    final jsonResp = jsonDecode(response.body);
    return doc(jsonResp['name'].toString().substring(baseName.length));
  }

  Future<String> _delete(
      {@required String name, Precondition precondition}) async {
    var url = '$baseUrl$name';

    if (precondition != null) {
      if (precondition.exists != null) {
        url += '?currentDocument.exists=${precondition.exists}';
      }
    }
    final response = await http.delete(url);
    if (response.statusCode != 200) {
      return response.body;
    }
    return null;
  }

  Future<DocumentSnapshot> _get({@required DocumentReference ref}) async {
    final url = '$baseUrl${ref.path + ref.id}';
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Error;
    }
    final fields = jsonDecode(response.body)['fields'];
    final id = jsonDecode(response.body)['name'].split('/').last;
    final data = _parseFields(fields);
    return DocumentSnapshot(data, exists: true, id: id, ref: ref);
  }

  Future _patch() {}

  Future<QuerySnapshot> _runQuery({String path, Query query}) {}

  // Helper methods

  String _dateTimeToTimestamp(DateTime dt) {
    return dt.toUtc().toIso8601String();
  }

  Map<String, dynamic> _parseFields(Map<String, dynamic> fields) {
    var map = Map<String, dynamic>();
    var entries = fields.entries;
    for (final entry in entries) {
      // TODO handle datetime, ints, LtLng etc.
      Map<String, dynamic> entryMap = entry.value;
      map[entry.key] = entryMap.entries.first.value;
    }
    return map;
  }

//  _valueToNative(Map<String, dynamic> value) {
//    if (value.entries.first.key == 'booleanValue') {
//      print(value.entries.first.value.runtimeType);
//    }
//  }

  Map<String, dynamic> _parseDocumentMap(Map<String, dynamic> document) {
    var fields = {};
    document.entries.forEach((entry) {
      fields[entry.key] = _valueToFBFormat(entry.value);
    });
    return {'fields': fields};
  }

  Map<String, dynamic> _valueToFBFormat(dynamic value) {
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
    // TODO: bytes parsing, GH link
    if (value is Uint8List) {
      throw UnimplementedError(
          'This package can\'t handle byte values yet. https://github.com/timtraversy/firebase_dart');
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
          throw FormatException(
              'Error: an array cannot directly contain another array value');
        }
        arrayValue['arrayValue']['values'].add(_valueToFBFormat(subVal));
      }
      return arrayValue;
    }
    if (value is Map) {
      return {'mapValue': _parseDocumentMap(value)};
    }
    throw ArgumentError('The argument $value is not supported by Firebase');
  }
}

class DocumentReference {
  final Firestore firestore;
  final String id;
  final String path;
  DocumentReference._internal(
      {@required this.firestore, @required this.id, @required this.path});

  factory DocumentReference({Firestore firestore, String name}) {
    final parts = name.split('/');
    if (parts.length % 2 != 0) {
      return null;
    }
    final id = parts.last;
    final path = parts.sublist(0, parts.length - 1).join('/') + '/';
    return DocumentReference._internal(
        firestore: firestore, id: id, path: path);
  }

  @override
  String toString() {
    return 'DocumentReference{firestore: $firestore, id: $id, path: $path}';
  }

  CollectionReference collection(String name) =>
      CollectionReference(firestore: firestore, name: '$path$id/$name');

  Future<DocumentSnapshot> get() async {
    return await firestore._get(ref: this);
  }

  Future<DocumentReference> set(Map<String, dynamic> document) async {
//    return await firestore._patch(path: null, document: null);
  }

  Future<DocumentReference> update() async {}
}

class Query {
  final Firestore firestore;
  final Map query;
  // TODO store this model
//  {
//  "select": {
//  object(Projection)
//  },
//  "from": [
//  {
//  object(CollectionSelector)
//  }
//  ],
//  "where": {
//  object(Filter)
//  },
//  "orderBy": [
//  {
//  object(Order)
//  }
//  ],
//  "startAt": {
//  object(Cursor)
//  },
//  "endAt": {
//  object(Cursor)
//  },
//  "offset": number,
//  "limit": number
//  }
  Query(this.firestore, this.query);

  // query builders
  Query endAt(dynamic value) {
    final newQuery = query;
    return Query(firestore, newQuery);
  }

  Query endBefore(dynamic value) {}
  Query limit(int limit) {}
  Query offset(int offset) {}
  Query orderBy(int limit) {}
  Query select() {}
  Query startAfter(dynamic value) {}
  Query startAt(dynamic value) {}
//  "<", "<=", "==", ">", and ">=" array-contains"
  Query where(String fieldPath, String operator, dynamic value) {}

  Future<QuerySnapshot> get() async {
    // handle generating query
//    return await firestore._runQuery(path: path + id, query: null);
  }
}

class CollectionReference extends Query {
  final String id, path;
  CollectionReference._internal(firestore, query,
      {@required this.id, @required this.path})
      : super(firestore, query);

  factory CollectionReference({Firestore firestore, String name}) {
    final parts = name.split('/');
    if (parts.length % 2 == 0) {
      return null;
    }
    final id = parts.last;
    print(id);
    final path = parts.length == 1
        ? ''
        : parts.sublist(0, parts.length - 1).join('/') + '/';
    return CollectionReference._internal(firestore, {}, id: id, path: path);
  }

  @override
  String toString() {
    return 'CollectionReference{firestore: $firestore, id: $id, path: $path}';
  }

  DocumentReference doc(String name) =>
      DocumentReference(firestore: firestore, name: '$path$id/$name');

//  String _generateId() {
//    var id = '';
//    var rand = Random.secure();
//    while (id.length < 20) {
//      final num = rand.nextInt(68);
//      if (num < 10) {
//        id += num.toString();
//        continue;
//      }
//      if (num < 36) {
//        id += String.fromCharCode(num + 55);
//        continue;
//      }
//      if (num < 42) {
//        continue;
//      }
//      id += String.fromCharCode(num + 55);
//    }
//    return id;
//  }

  Future<DocumentReference> add(Map<String, dynamic> document) async {
    return await firestore._createDocument(path: path + id, document: document);
  }

//  Future<List<DocumentReference>> listDocuments() {}
}

class DocumentSnapshot {
  final DateTime createTime, readTime, updateTime;
  final Map<String, dynamic> _data;
  final bool exists;
  final String id;
  final DocumentReference ref;

  DocumentSnapshot(this._data,
      {this.createTime,
      this.readTime,
      this.updateTime,
      this.exists,
      this.id,
      this.ref});

  @override
  String toString() {
    return 'DocumentSnapshot{_data: $_data, exists: $exists, id: $id, ref: $ref}';
  }

  Map<String, dynamic> data() {
    return _data;
  }

  dynamic get(String fieldPath) {
    return _data[fieldPath];
  }
}

class QueryDocumentSnapshot extends DocumentSnapshot {
  QueryDocumentSnapshot(data, {createTime, readTime, updateTime, id, ref})
      : super(data,
            createTime: createTime,
            readTime: readTime,
            updateTime: updateTime,
            exists: true,
            id: id,
            ref: ref);
}

class QuerySnapshot {
  final List<QueryDocumentSnapshot> docs;
  final bool empty;
  final Query query;
  final int size;

  QuerySnapshot({this.docs, this.empty, this.query, this.size});

  forEach(Function callback) {
    docs.forEach((doc) => callback(doc));
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
  // TODO: make updateTime work, Firestore is rejecting
//  final String updateTime;
//  Precondition({this.exists, this.updateTime});
  Precondition({this.exists});
}
