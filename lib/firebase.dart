export 'src/firebase.dart';
export 'src/firestore.dart';
export 'src/auth.dart';
//main() async {
//  final fb = Firebase(projectId: 'course-gnome');
//  final fs = Firestore(firebase: fb);
//
//  final doc = {
//    'bits': Uint8List(10),
//  };
//
//  final response = await fs.deleteDocument(
//      name: 'cities/hi', precondition: Precondition(exists: true));
//  print(response);
//  if (response != null) {
//    print('Document deleted succesfully!');
//  }
//}
