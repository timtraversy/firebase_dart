@TestOn("dart-vm")

import 'package:firebase_dart/firebase.dart';
import "package:test/test.dart";
import 'dart:math';

void main() {
  final fb = Firebase(projectId: 'fire-dart-test');
  final fs = Firestore(firebase: fb);

  /// Create random collection name so two tests don't commit to the same collection
  final String path = Random().nextDouble().toString()+'/';
  const String docId = 'testDoc';
  String generatedName;
  String updateTime;

  group("Create Document", () {
    final complexDoc = {
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
    test("- without ID", () async {
      final response =
          await fs.createDocument(path: path, document: complexDoc);
      expect(response, isNot(null));
      generatedName = response.name;
      updateTime = response.updateTime;
    });
    test("- with ID", () async {
      final response = await fs.createDocument(
          path: path, document: complexDoc, docId: docId);
      expect(response, isNot(null));
      expect(response.name, equals('$path$docId'));
    });
  });

  group("- normally", () {
    test("", () async {
      final response = await fs.deleteDocument(name: '$generatedName');
      expect(response, isNull);
    });
    test("- with precondition: !exists", () async {
      var response = await fs.deleteDocument(
        name: '$path$docId',
        precondition: Precondition(exists: false),
      );
      expect(response, isNotNull);
    });
    test("- with precondition: exists", () async {
      var response = await fs.deleteDocument(
        name: '$path$docId',
        precondition: Precondition(exists: true),
      );
      expect(response, isNull);
    });
  });
}
