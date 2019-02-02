import 'dart:convert';
import 'dart:collection';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;

import 'firebase.dart';

main() async {
  final fb = Firebase.initialize(
      apiKey: '2', projectId: 'fire-dart-test', authDomain: '2');
  final fs = fb.firestore();
  final collection = fs.collection('hello');
  final doc = {
    'null': null,
    'bool': true,
    'int': 100,
    'double': 3.14159,
    'timestamp': DateTime(1996),
    'string': 'Hello Firestore!',
    'reference': 'myDocs/anotherDoc',
    'geoPoint': LatLng(lat: 37, lng: -122),
//    'array': ['a', 2, true, null],
//    'map': {
//      'nestedMap': {
//        'x': 1.5,
//        'y': 'foo',
//      },
//      'z': false,
//    }
  };
  DocumentReference docRef;
  try {
    docRef = await collection.add(document: doc);
    print('Document written with ID: ${docRef.id}');
  } catch (e) {
    print(e);
  }
//  final QuerySnapshot qs = await collection.where().limit().get();
//  qs.forEach((DocumentSnapshot doc) => print('${doc.id} => ${doc.data()}'));
  final ds = await docRef.get();
  print(ds);
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

  DocumentReference doc(String documentPath) {
    final parts = documentPath.split('/');
    if (parts.length % 2 != 0) {
      // Formatting error
      return null;
    }
    final id = parts.last;
    final path = parts.length == 1
        ? ''
        : parts.sublist(0, parts.length - 1).join('/') + '/';
    var dr = DocumentReference(firestore: this, path: path, id: id);
    return DocumentReference(firestore: this, path: path, id: id);
  }

  CollectionReference collection(String collectionPath) {
    final parts = collectionPath.split('/');
    if (parts.length % 2 == 0) {
      // Formatting error
      return null;
    }
    final id = parts.last;
    final path = parts.length == 1
        ? ''
        : parts.sublist(0, parts.length - 1).join('/') + '/';
    return CollectionReference(firestore: this, path: path, id: id);
  }

  // API calls

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

  Future<DocumentReference> _createDocument(
      {@required String path,
      @required Map<String, dynamic> document,
      String docId = ''}) async {
    final url = '$baseUrl$path?documentId=$docId';

    final fields = _parseMap(document);
    if (fields == null) {
      return null;
    }

    final response = await http.post(url, body: jsonEncode(fields));
    if (response.statusCode != 200) {
      print('Error: Document creation unsuccesful');
      print(response.body);
      return null;
    }

    final jsonResp = jsonDecode(response.body);
    return doc(jsonResp['name'].toString().substring(baseName.length));
  }

  Future<DocumentSnapshot> getDocument(
      {@required DocumentReference ref}) async {
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

  Future<QuerySnapshot> _runQuery({String path, Query query}) {}

  String _dateTimeToTimestamp(DateTime dt) {
    return dt.toUtc().toIso8601String();
  }

  Map<String, dynamic> _parseFields(Map<String, dynamic> fields) {
    var map = Map<String, dynamic>();
    var entries = fields.entries;
    for (final entry in entries) {
      // TODO handle datetime, ints, LtLng etc.
      Map<String, dynamic> entryMap = entry.value;
      print(entryMap.entries.first.value);
      print(entryMap.entries.first.value.runtimeType);
      map[entry.key] = entryMap.entries.first.value;
    }
    return map;
  }

//  _valueToNative(Map<String, dynamic> value) {
//    if (value.entries.first.key == 'booleanValue') {
//      print(value.entries.first.value.runtimeType);
//    }
//  }

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

class DocumentReference {
  final Firestore firestore;
  final String id;
  final String path;
  DocumentReference(
      {@required this.firestore, @required this.id, @required this.path});

  @override
  String toString() {
    return 'DocumentReference{firestore: $firestore, id: $id, path: $path}';
  }

  Future<DocumentSnapshot> get() async {
    return await firestore.getDocument(ref: this);
  }

  CollectionReference collection(String collectionPath) {}
}

class Query {
  final Firestore firestore;
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
  Query({@required this.firestore});

  // query builders
  Query endAt(dynamic value) {}
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
  CollectionReference(
      {@required firestore, @required this.id, @required this.path})
      : super(firestore: firestore);

  @override
  String toString() {
    return 'CollectionReference{firestore: $firestore, id: $id, path: $path}';
  }

  DocumentReference doc(String docId) {
    return DocumentReference(
        firestore: firestore, id: docId, path: '$path/$id');
  }

  Future<DocumentReference> add({Map<String, dynamic> document}) async {
    return await firestore._createDocument(path: path + id, document: document);
  }

  Future<List<DocumentReference>> listDocuments() {}
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
  QueryDocumentSnapshot(data,
      {createTime, readTime, updateTime, id, ref})
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
