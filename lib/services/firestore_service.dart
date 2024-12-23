import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final String projectId;

  FirestoreService(this.projectId);

  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .doc(taskId)
        .update({'status': newStatus});
  }

  Future<void> deleteTask(String taskId) async {
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    return userSnapshot.docs
        .map((doc) => {...doc.data(), 'id': doc.id})
        .toList();
  }
}
