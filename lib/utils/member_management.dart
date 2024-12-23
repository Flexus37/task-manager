import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future<bool> isManager(String projectId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  final project = await FirebaseFirestore.instance
      .collection('projects')
      .doc(projectId)
      .get();

  final members = project.data()?['members'] ?? {};
  return members[user.uid] == 'manager';
}

Future<void> manageMembers(BuildContext context, String projectId,
    Future<bool> Function() isManager) async {
  if (!await isManager()) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Только менеджеры могут управлять участниками')),
    );
    return;
  }

  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> filteredUsers = [];
  Map<String, String> currentMembers = {};

  // Загрузка участников и всех пользователей
  final projectSnapshot = await FirebaseFirestore.instance
      .collection('projects')
      .doc(projectId)
      .get();
  final members = projectSnapshot.data()?['members'] ?? {};
  currentMembers = Map<String, String>.from(members);

  final usersSnapshot =
      await FirebaseFirestore.instance.collection('users').get();
  allUsers =
      usersSnapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();

  // Функция фильтрации пользователей
  void filterUsers(String query) {
    if (query.isEmpty) {
      filteredUsers = [];
    } else {
      filteredUsers = allUsers
          .where((user) =>
              user['name']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              user['surname']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()))
          .toList();
    }
  }

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Управление участниками'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: 'Поиск пользователей',
                    ),
                    onChanged: (query) {
                      setState(() {
                        filterUsers(query);
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Текущие участники',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: currentMembers.entries.map((entry) {
                      final userId = entry.key;
                      final role = entry.value;

                      final userData = allUsers.firstWhere(
                          (user) => user['id'] == userId,
                          orElse: () => {});

                      if (userData.isEmpty) return const SizedBox();

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(userData['avatarUrl'] ??
                              'https://ui-avatars.com/'),
                        ),
                        title:
                            Text('${userData['name']} ${userData['surname']}'),
                        subtitle: Text('Роль: $role'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.swap_horiz),
                              tooltip: 'Сменить роль',
                              onPressed: () async {
                                final newRole =
                                    role == 'manager' ? 'member' : 'manager';
                                await FirebaseFirestore.instance
                                    .collection('projects')
                                    .doc(projectId)
                                    .update({
                                  'members.$userId': newRole,
                                });
                                setState(() {
                                  currentMembers[userId] = newRole;
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              tooltip: 'Удалить участника',
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('projects')
                                    .doc(projectId)
                                    .update({
                                  'members.$userId': FieldValue.delete(),
                                });
                                setState(() {
                                  currentMembers.remove(userId);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Найти и добавить участников',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (filteredUsers.isNotEmpty)
                    Column(
                      children: filteredUsers.map((user) {
                        final isAlreadyMember =
                            currentMembers.containsKey(user['id']);
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(
                                user['avatarUrl'] ?? 'https://ui-avatars.com/'),
                          ),
                          title: Text('${user['name']} ${user['surname']}'),
                          trailing: IconButton(
                            icon: Icon(
                              isAlreadyMember ? Icons.check : Icons.add,
                              color:
                                  isAlreadyMember ? Colors.green : Colors.blue,
                            ),
                            onPressed: isAlreadyMember
                                ? null
                                : () async {
                                    await FirebaseFirestore.instance
                                        .collection('projects')
                                        .doc(projectId)
                                        .update({
                                      'members.${user['id']}': 'member',
                                    });
                                    setState(() {
                                      currentMembers[user['id']] = 'member';
                                    });
                                  },
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Закрыть'),
              ),
            ],
          );
        },
      );
    },
  );
}
