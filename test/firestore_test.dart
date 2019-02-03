@TestOn("dart-vm")

import 'package:firebase_dart/firebase.dart';
import "package:test/test.dart";
import 'dart:math';

void main() {
  final fb = Firebase.initialize(
      apiKey: 'AIzaSyCYvIWnxswqzCEFChwZEQkzBEIE1xB0Eaw',
      projectId: 'fire-dart-test',
      authDomain: 'fire-dart-test.firebaseapp.com');
  final Firestore fs = fb.firestore();

  /// Create random collection name so two tests don't commit to the same collection
  final collection = fs.collection(Random().nextDouble().toString());
  final doc = {
    'null': null,
    'bool': true,
    'int': 100,
    'double': 3.14159,
    'timestamp': DateTime(1996),
    'string': 'Hello Firestore!',
    'reference': 'myDocs/anotherDoc',
    'geoPoint': LatLng(lat: 37, lng: -122),
    'array': ['a', 2, true, null],
    'map': {
      'nestedMap': {
        'x': 1.5,
        'y': 'foo',
      },
      'z': false,
    }
  };

  group('Path generation', () {
    CollectionReference cr1;
    test('from firestore', () {
      cr1 = fs.collection('cities');
      expect(cr1.id, equals('cities'));
      expect(cr1.path, equals(''));
      final cr2 = fs.collection('cities/Boston/stores');
      expect(cr2.id, equals('stores'));
      expect(cr2.path, equals('cities/Boston/'));
      final dr1 = fs.doc('cities/Boston');
      expect(dr1.id, equals('Boston'));
      expect(dr1.path, equals('cities/'));
    });
    test('from  doc or collection references', () {
      final dr2 = cr1.doc('Boston');
      expect(dr2.id, equals('Boston'));
      expect(dr2.path, equals('cities/'));
      final cr3 = dr2.collection('stores');
      expect(cr3.id, equals('stores'));
      expect(cr3.path, equals('cities/Boston/'));
    });
    test('with errors', () {
      final cr4 = fs.collection('cities/Boston');
      expect(cr4, isNull);
      final dr5 = fs.doc('cities');
      expect(dr5, isNull);
    });
  });

  group('Add data', () {
    final dr = collection.doc('Boston');
//    test('with set', () async {
//      final dr2 = await dr.set(doc);
//      expect(dr2, isNotNull);
//      expect(dr2.id, equals('Boston'));
//    });
    test('with add', () async {
      final dr2 = collection.add(doc);
      expect(collection, completes);
    });
  });

  group('Update data', () {
    test('with fields', () {});
    test('with nested fields', () {});
    test('with array fields', () {});
  });

  group('Query data', () {
    test('with get', () {});
    test('with query', () {});
    test('with limit and order', () {});
  });

  group('Delete', () {
    test('document', () {});
    test('fields', () {});
  });

  //  final fb = Firebase.initialize(
//      apiKey: '2', projectId: 'fire-dart-test', authDomain: '2');
//  final fs = fb.firestore();
//  final collection = fs.collection('hello');
//  final doc = {
//    'null': null,
//    'bool': true,
//    'int': 100,
//    'double': 3.14159,
//    'timestamp': DateTime(1996),
//    'string': 'Hello Firestore!',
//    'reference': 'myDocs/anotherDoc',
//    'geoPoint': LatLng(lat: 37, lng: -122),
////    'array': ['a', 2, true, null],
////    'map': {
////      'nestedMap': {
////        'x': 1.5,
////        'y': 'foo',
////      },
////      'z': false,
////    }
//  };
//  DocumentReference docRef;
//  try {
//    docRef = await collection.add(document: doc);
//    print('Document written with ID: ${docRef.id}');
//  } catch (e) {
//    print(e);
//  }
////  final QuerySnapshot qs = await collection.where().limit().get();
////  qs.forEach((DocumentSnapshot doc) => print('${doc.id} => ${doc.data()}'));
//  final ds = await docRef.get();
//  print(ds);
//  test('Query Data', () {});
//  test('Delete Data', () {});
//  test('Add Data', () {});
//  final Frfs = fb.firestore();
//  fs.
//  final fb = Firebase(projectId: 'fire-dart-test');
//  final fs = Firestore(firebase: fb);
//
//  /// Create random collection name so two tests don't commit to the same collection
//  final String path = Random().nextDouble().toString()+'/';
//  const String docId = 'testDoc';
//  String generatedName;
//  String updateTime;
//
//  group("Create Document", () {
//    final complexDoc = {
//      'null': null,
//      'bool': true,
//      'int': 100,
//      'double': 3.14159,
//      'timestamp': DateTime(1996),
//      'string': 'Hello Firestore!',
//      'reference': 'myDocs/anotherDoc',
//      'geoPoint': LatLng(lat: 37, lng: -122),
//      'array': ['a', 2, true, null],
//      'map': {
//        'nestedMap': {
//          'x': 1.5,
//          'y': 'foo',
//        },
//        'z': false,
//      }
//    };
//    test("- without ID", () async {
//      final response =
//          await fs.createDocument(path: path, document: complexDoc);
//      expect(response, isNot(null));
//      generatedName = response.name;
//      updateTime = response.updateTime;
//    });
//    test("- with ID", () async {
//      final response = await fs.createDocument(
//          path: path, document: complexDoc, docId: docId);
//      expect(response, isNot(null));
//      expect(response.name, equals('$path$docId'));
//    });
//  });
//
//  group("- normally", () {
//    test("", () async {
//      final response = await fs.deleteDocument(name: '$generatedName');
//      expect(response, isNull);
//    });
//    test("- with precondition: !exists", () async {
//      var response = await fs.deleteDocument(
//        name: '$path$docId',
//        precondition: Precondition(exists: false),
//      );
//      expect(response, isNotNull);
//    });
//    test("- with precondition: exists", () async {
//      var response = await fs.deleteDocument(
//        name: '$path$docId',
//        precondition: Precondition(exists: true),
//      );
//      expect(response, isNull);
//    });
//  });
}
