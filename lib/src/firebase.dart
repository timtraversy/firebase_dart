import 'package:meta/meta.dart';

import 'firestore.dart';

class Firebase {
  final String projectId, authDomain, apiKey;

  Firebase.initialize(
      {@required this.projectId,
      @required this.authDomain,
      @required this.apiKey});

  @override
  String toString() {
    return 'Firebase{projectId: $projectId, authDomain: $authDomain, apiKey: $apiKey}';
  }

  Firestore firestore() {
    return Firestore(firebase: this);
  }
}
