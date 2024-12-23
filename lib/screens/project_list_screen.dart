import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'user_profile_screen.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  List<String> _favoriteProjects = []; // Локальный список избранных проектов
  int _unreadNotifications = 0; // Количество непрочитанных уведомлений
  int _projectsToShow = 5; // Количество отображаемых проектов

  /// Метод для получения количества непрочитанных уведомлений
  Future<void> _fetchUnreadNotifications() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .doc(userId)
        .collection('userNotifications')
        .where('read', isEqualTo: false)
        .get();

    setState(() {
      _unreadNotifications = snapshot.docs.length;
    });
  }

  /// Метод для отправки уведомлений пользователю
  Future<void> _sendNotification(
      String userId, String title, String body) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(userId)
        .collection('userNotifications')
        .add({
      'title': title,
      'body': body,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });

    _fetchUnreadNotifications(); // Обновляем счётчик уведомлений
  }

  @override
  void initState() {
    super.initState();
    _fetchFavoriteProjects(); // Загружаем избранные проекты при инициализации
    _fetchUnreadNotifications(); // Загружаем количество уведомлений
  }

  /// Метод для отображения уведомлений в диалоговом окне
  void _showNotifications(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Уведомления'),
          content: SizedBox(
            width: 400, // Ограничиваем ширину окна
            height: 300, // Ограничиваем высоту окна
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .doc(userId)
                  .collection('userNotifications')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final notifications = snapshot.data?.docs ?? [];

                if (notifications.isEmpty) {
                  return const Center(child: Text('Уведомлений нет.'));
                }

                return ListView.builder(
                  shrinkWrap:
                      true, // Позволяет списку занимать минимальный размер
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification =
                        notifications[index].data() as Map<String, dynamic>;

                    return ListTile(
                      title: Text(notification['title'] ?? 'Без заголовка'),
                      subtitle: Text(notification['body'] ?? 'Нет описания'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          // Удаление уведомления
                          notifications[index].reference.delete();
                          _fetchUnreadNotifications(); // Обновляем счётчик
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }

  /// Метод для загрузки списка избранных проектов текущего пользователя
  Future<void> _fetchFavoriteProjects() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    setState(() {
      _favoriteProjects =
          List<String>.from(userSnapshot.data()?['favoriteProjects'] ?? []);
    });
  }

  Future<void> _toggleFavorite(String projectId, bool isFavorite) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    setState(() {
      // Обновляем локальный список перед отправкой запроса
      if (isFavorite) {
        _favoriteProjects.remove(projectId);
      } else {
        _favoriteProjects.add(projectId);
      }
    });

    if (isFavorite) {
      // Удаляем проект из избранного
      await userRef.update({
        'favoriteProjects': FieldValue.arrayRemove([projectId]),
      });
    } else {
      // Добавляем проект в избранное
      await userRef.update({
        'favoriteProjects': FieldValue.arrayUnion([projectId]),
      });
    }
  }

  Future<Map<String, dynamic>?> _fetchUserData(String userId) async {
    final userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userSnapshot.data();
  }

  Future<void> _createProject(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController searchController = TextEditingController();

    List<Map<String, dynamic>> foundUsers = [];
    List<Map<String, dynamic>> selectedUsers = [];

    Future<void> _searchUsers(String query) async {
      if (query.isEmpty) {
        foundUsers = [];
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final nameSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      final surnameSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('surname', isGreaterThanOrEqualTo: query)
          .where('surname', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      final emailSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      foundUsers = [
        ...nameSnapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}),
        ...surnameSnapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}),
        ...emailSnapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}),
      ];

      // Исключить текущего пользователя
      foundUsers =
          foundUsers.where((userData) => userData['id'] != user.uid).toList();
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Создать проект'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width *
                      0.4, // Устанавливаем ширину 80% от экрана
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                            labelText: 'Название проекта'),
                      ),
                      TextField(
                        controller: descriptionController,
                        decoration:
                            const InputDecoration(labelText: 'Описание'),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                            labelText: 'Поиск участников'),
                        onChanged: (query) async {
                          await _searchUsers(query);
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 10),
                      if (foundUsers.isNotEmpty)
                        ...foundUsers.map((user) {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(user['avatarUrl'] ??
                                  'https://ui-avatars.com/'),
                            ),
                            title: Text('${user['name']} ${user['surname']}'),
                            subtitle: Text(user['email']),
                            trailing: IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                if (!selectedUsers
                                    .any((u) => u['id'] == user['id'])) {
                                  setState(() {
                                    selectedUsers
                                        .add({...user, 'role': 'participant'});
                                  });
                                }
                              },
                            ),
                          );
                        }),
                      const SizedBox(height: 10),
                      if (selectedUsers.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Выбранные пользователи:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ...selectedUsers.map((user) {
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                      user['avatarUrl'] ??
                                          'https://ui-avatars.com/'),
                                ),
                                title:
                                    Text('${user['name']} ${user['surname']}'),
                                subtitle: Text('Роль: ${user['role']}'),
                                trailing: DropdownButton<String>(
                                  value: user['role'],
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'participant',
                                      child: Text('Участник'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'manager',
                                      child: Text('Менеджер'),
                                    ),
                                  ],
                                  onChanged: (newRole) {
                                    setState(() {
                                      user['role'] = newRole;
                                    });
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Название проекта обязательно')),
                      );
                      return;
                    }

                    final projectRef =
                        FirebaseFirestore.instance.collection('projects').doc();

                    final members = {
                      for (var user in selectedUsers)
                        user['id']: user['role'] ?? 'participant',
                    };

                    await projectRef.set({
                      'name': nameController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'ownerId': user.uid,
                      'members': members..addAll({user.uid: 'manager'}),
                    });

                    // Отправка уведомлений выбранным пользователям
                    for (var selectedUser in selectedUsers) {
                      await _sendNotification(
                        selectedUser['id'],
                        'Добавлен в проект',
                        'Вы были добавлены в проект "${nameController.text.trim()}".',
                      );
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Проект успешно создан')),
                    );

                    Navigator.of(context).pop();
                  },
                  child: const Text('Создать'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Метод для удаления проекта
  Future<void> _deleteProject(String projectId) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Подтвердите удаление'),
          content: const Text(
              'Вы уверены, что хотите удалить этот проект? Это действие нельзя отменить.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Отмена
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Подтверждение
              child: const Text('Удалить', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmation ?? false) {
      // Если пользователь подтвердил удаление
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Проект успешно удален')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<Map<String, dynamic>?>(
      future: user != null ? _fetchUserData(user.uid) : null,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final userData = userSnapshot.data;
        // final favoriteProjects =
        //     userData?['favoriteProjects'] as List<dynamic>? ?? [];

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Text('Проекты'),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => _createProject(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepPurple,
                  ),
                  child: const Text('Создать проект'),
                ),
              ],
            ),
            actions: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, size: 28),
                    tooltip: 'Уведомления',
                    onPressed: () => _showNotifications(
                        context), // Показать список уведомлений
                  ),
                  // Показ количества непрочитанных уведомлений
                  if (_unreadNotifications > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.red,
                        child: Text(
                          _unreadNotifications.toString(),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: CircleAvatar(
                  backgroundImage: NetworkImage(
                    userData?['avatarUrl'] ??
                        'https://ui-avatars.com/api/?name=${user?.displayName ?? ''}',
                  ),
                ),
                onPressed: () {
                  showMenu(
                    context: context,
                    position: const RelativeRect.fromLTRB(1000, 50, 0, 0),
                    items: [
                      PopupMenuItem(
                        enabled: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${userData?['name'] ?? ''} ${userData?['surname'] ?? ''}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Divider(),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'profile',
                        child: ListTile(
                          title: const Text('Профиль'),
                          leading: const Icon(Icons.account_circle),
                          onTap: () {
                            Navigator.of(context).pop(); // Закрываем меню
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UserProfileScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: ListTile(
                          title: Text('Выход'),
                          leading: Icon(Icons.logout),
                        ),
                      ),
                    ],
                  ).then((value) {
                    if (value == 'logout') {
                      FirebaseAuth.instance.signOut();
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  });
                },
              ),
            ],
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('projects').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Нет доступных проектов.'));
              }

              final projects = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final members = data['members'] as Map<String, dynamic>? ?? {};
                final ownerId = data['ownerId'] as String? ?? '';
                return members.containsKey(user?.uid) || ownerId == user?.uid;
              }).toList();

              // Разделяем избранные и обычные проекты
              final favoriteProjectsList = projects
                  .where((project) => _favoriteProjects.contains(project.id))
                  .toList();
              final otherProjectsList = projects
                  .where((project) => !_favoriteProjects.contains(project.id))
                  .toList();

              final sortedProjects = [
                ...favoriteProjectsList,
                ...otherProjectsList
              ];

              // Показываем только `_projectsToShow` проектов
              final visibleProjects =
                  sortedProjects.take(_projectsToShow).toList();

              return SingleChildScrollView(
                child: Column(
                  children: [
                    ListView.builder(
                      shrinkWrap:
                          true, // Позволяет списку занимать минимально возможное пространство
                      physics:
                          const NeverScrollableScrollPhysics(), // Отключаем прокрутку для списка, чтобы прокрутка шла у родительского виджета
                      itemCount: visibleProjects.length,
                      itemBuilder: (context, index) {
                        final project = visibleProjects[index];
                        final data = project.data() as Map<String, dynamic>;
                        final isFavorite =
                            _favoriteProjects.contains(project.id);

                        return ListTile(
                          title: Text(data['name'] ?? 'Без названия'),
                          subtitle: Text(data['description'] ?? 'Нет описания'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isFavorite ? Icons.star : Icons.star_border,
                                  color:
                                      isFavorite ? Colors.amber : Colors.grey,
                                ),
                                onPressed: () =>
                                    _toggleFavorite(project.id, isFavorite),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _deleteProject(project.id);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: ListTile(
                                      leading:
                                          Icon(Icons.delete, color: Colors.red),
                                      title: Text('Удалить проект'),
                                    ),
                                  ),
                                ],
                                icon: const Icon(Icons.more_vert),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/tasks',
                              arguments: project.id,
                            );
                          },
                        );
                      },
                    ),
                    // Кнопка для загрузки дополнительных проектов
                    if (_projectsToShow < sortedProjects.length)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _projectsToShow += 5;
                            });
                          },
                          child: Text(
                              'Загрузить ещё (${sortedProjects.length - _projectsToShow})'),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
