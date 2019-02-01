@TestOn("dart-vm")

import 'package:firebase_dart/firebase.dart';
import "package:test/test.dart";

void main() {
  final fb = Firebase(projectId: 'fire-dart-test');
  final fs = Firestore(firebase: fb);
  test("createDocument", () async {
    final complexDoc = {
      'null': null,
      'bool': true,
      'int': 100,
      'double': 3.14159,
      'timestamp': DateTime(1996),
      'string': 'Hello Firestore!',
      'reference': 'myDocs/doc100',
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
    final response = await fs.createDocument(path: 'myDocs', document: complexDoc);
    print(response);
    expect(response, !null);
  });
}
