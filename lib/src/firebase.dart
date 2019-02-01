import 'package:meta/meta.dart';
import 'firestore.dart';

class Firebase {
  final String projectId;
  final String authDomain;
  final String apiKey;
  Firebase.initialize({@required this.projectId, @required this.authDomain, @required this.apiKey});
  firestore() {
    return Firestore(firebase: this);
  }
}