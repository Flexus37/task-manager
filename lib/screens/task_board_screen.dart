import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_manager/styles/app_styles.dart';

import '../services/firestore_service.dart';
import '../utils/member_management.dart';

class TaskBoardScreen extends StatelessWidget {
  final String projectId;

  const TaskBoardScreen({Key? key, required this.projectId}) : super(key: key);

  Future<void> _addTask(BuildContext context) async {
    if (!await isManager(projectId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Только менеджеры проекта могут добавлять новые задачи!')),
      );
      return;
    }

    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController searchController = TextEditingController();
    DateTime? dueDate;
    String priority = 'medium';
    List<Map<String, dynamic>> foundUsers = [];
    List<Map<String, dynamic>> selectedUsers = [];

    await showDialog(
      context: context,
      builder: (context) {
        final firestoreService = FirestoreService(projectId);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Добавить задачу'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration:
                            const InputDecoration(labelText: 'Название задачи'),
                      ),
                      TextField(
                        controller: descriptionController,
                        decoration:
                            const InputDecoration(labelText: 'Описание'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: priority,
                        decoration:
                            const InputDecoration(labelText: 'Приоритет'),
                        items: const [
                          DropdownMenuItem(
                            value: 'low',
                            child: Text('Низкий'),
                          ),
                          DropdownMenuItem(
                            value: 'medium',
                            child: Text('Средний'),
                          ),
                          DropdownMenuItem(
                            value: 'high',
                            child: Text('Высокий'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              priority = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        title: Text(dueDate == null
                            ? 'Выбрать срок сдачи'
                            : DateFormat.yMMMd().format(dueDate!)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (selectedDate != null) {
                            setState(() {
                              dueDate = selectedDate;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                            labelText: 'Поиск исполнителей'),
                        onChanged: (query) async {
                          final users =
                              await firestoreService.searchUsers(query);
                          setState(() {
                            foundUsers = users;
                          });
                        },
                      ),
                      if (foundUsers.isNotEmpty)
                        ...foundUsers.map((user) {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                user['avatarUrl'] ?? 'https://ui-avatars.com/',
                              ),
                            ),
                            title: Text('${user['name']} ${user['surname']}'),
                            onTap: () {
                              if (!selectedUsers
                                  .any((u) => u['id'] == user['id'])) {
                                setState(() {
                                  selectedUsers.add(user);
                                });
                              }
                            },
                          );
                        }),
                      const SizedBox(height: 10),
                      if (selectedUsers.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Исполнители:'),
                            ...selectedUsers.map((user) {
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    user['avatarUrl'] ??
                                        'https://ui-avatars.com/',
                                  ),
                                ),
                                title:
                                    Text('${user['name']} ${user['surname']}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove_circle),
                                  onPressed: () {
                                    setState(() {
                                      selectedUsers.remove(user);
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
                    final title = titleController.text.trim();
                    final description = descriptionController.text.trim();

                    if (title.isEmpty ||
                        dueDate == null ||
                        selectedUsers.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Заполните все поля!'),
                        ),
                      );
                      return;
                    }

                    await FirebaseFirestore.instance
                        .collection('projects')
                        .doc(projectId)
                        .collection('tasks')
                        .add({
                      'title': title,
                      'description': description,
                      'priority': priority,
                      'status': 'to-do',
                      'dueDate': Timestamp.fromDate(dueDate!),
                      'assignees':
                          selectedUsers.map((user) => user['id']).toList(),
                      'createdAt': Timestamp.now(),
                    });

                    Navigator.of(context).pop();
                  },
                  child: const Text('Добавить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _editTask(BuildContext context, Map<String, dynamic> taskData,
      String taskId) async {
    if (!await isManager(projectId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only managers can edit tasks')),
      );
      return;
    }

    final TextEditingController titleController =
        TextEditingController(text: taskData['title']);
    final TextEditingController descriptionController =
        TextEditingController(text: taskData['description']);
    final TextEditingController searchController = TextEditingController();
    DateTime? dueDate = taskData['dueDate']?.toDate();
    String priority = taskData['priority'] ?? 'medium';
    List<Map<String, dynamic>> foundUsers = [];
    List<String> selectedUserIds =
        List<String>.from(taskData['assignees'] ?? []);

    Future<void> _searchUsers(String query) async {
      if (query.isEmpty) {
        foundUsers = [];
        return;
      }

      final project = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .get();
      final members = project.data()?['members'] ?? {};

      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      foundUsers = userSnapshot.docs
          .where((doc) => members.keys.contains(doc.id))
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Редактировать задачу'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width *
                      0.4, // Адаптивная ширина
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Поле для названия задачи
                      TextField(
                        controller: titleController,
                        decoration:
                            const InputDecoration(labelText: 'Название задачи'),
                      ),
                      // Поле для описания задачи
                      TextField(
                        controller: descriptionController,
                        decoration:
                            const InputDecoration(labelText: 'Описание'),
                      ),
                      const SizedBox(height: 10),
                      // Выпадающий список для приоритета
                      DropdownButtonFormField<String>(
                        value: priority,
                        decoration:
                            const InputDecoration(labelText: 'Приоритет'),
                        items: const [
                          DropdownMenuItem(
                            value: 'low',
                            child: Text('Низкий'),
                          ),
                          DropdownMenuItem(
                            value: 'medium',
                            child: Text('Средний'),
                          ),
                          DropdownMenuItem(
                            value: 'high',
                            child: Text('Высокий'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              priority = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      // Поле для выбора срока сдачи
                      ListTile(
                        title: Text(dueDate == null
                            ? 'Выбрать срок сдачи'
                            : DateFormat.yMMMd().format(dueDate!)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: dueDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (selectedDate != null) {
                            setState(() {
                              dueDate = selectedDate;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      // Поле для поиска исполнителей
                      TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                            labelText: 'Поиск исполнителей'),
                        onChanged: (query) async {
                          await _searchUsers(query);
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 10),
                      // Список найденных пользователей
                      if (foundUsers.isNotEmpty)
                        ...foundUsers.map((user) {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(user['avatarUrl'] ??
                                  'https://ui-avatars.com/'),
                            ),
                            title: Text('${user['name']} ${user['surname']}'),
                            onTap: () {
                              if (!selectedUserIds.contains(user['id'])) {
                                setState(() {
                                  selectedUserIds.add(user['id']);
                                });
                              }
                            },
                          );
                        }),
                      const SizedBox(height: 10),
                      // Список выбранных исполнителей
                      if (selectedUserIds.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Исполнители:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            ...selectedUserIds.map((userId) {
                              return FutureBuilder(
                                future: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(userId)
                                    .get(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const CircularProgressIndicator();
                                  }
                                  final userData = snapshot.data?.data();
                                  if (userData == null) return const SizedBox();
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage: NetworkImage(
                                          userData['avatarUrl'] ??
                                              'https://ui-avatars.com/'),
                                    ),
                                    title: Text(
                                        '${userData['name']} ${userData['surname']}'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.remove_circle),
                                      onPressed: () {
                                        setState(() {
                                          selectedUserIds.remove(userId);
                                        });
                                      },
                                    ),
                                  );
                                },
                              );
                            }).toList(),
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
                    final title = titleController.text.trim();
                    final description = descriptionController.text.trim();

                    if (title.isEmpty || dueDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Заполните все поля!'),
                        ),
                      );
                      return;
                    }

                    // Обновляем задачу в Firestore
                    await FirebaseFirestore.instance
                        .collection('projects')
                        .doc(projectId)
                        .collection('tasks')
                        .doc(taskId)
                        .update({
                      'title': title,
                      'description': description,
                      'priority': priority,
                      'dueDate': Timestamp.fromDate(dueDate!),
                      'assignees': selectedUserIds,
                    });

                    Navigator.of(context).pop();
                  },
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Доска задач',
                  style: AppStyles.projectTitleStyle,
                ),
                const SizedBox(
                  width: 16,
                ),
                ElevatedButton(
                  onPressed: () => _addTask(context),
                  style: AppStyles.elevatedButtonStyle,
                  child: const Text('Добавить задачу'),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.group_add),
              tooltip: 'Управление участниками',
              onPressed: () =>
                  manageMembers(context, projectId, () => isManager(projectId)),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('projects')
            .doc(projectId)
            .collection('tasks')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Нет задач.'));
          }

          final tasks = snapshot.data!.docs;
          final toDo =
              tasks.where((task) => task['status'] == 'to-do').toList();
          final inProgress =
              tasks.where((task) => task['status'] == 'in-progress').toList();
          final done = tasks.where((task) => task['status'] == 'done').toList();

          return Row(
            children: [
              _buildTaskColumn('К выполнению', toDo, 'to-do', context),
              _buildTaskColumn(
                  'В процессе', inProgress, 'in-progress', context),
              _buildTaskColumn('Выполнено', done, 'done', context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTaskColumn(String title, List<QueryDocumentSnapshot> tasks,
      String status, BuildContext context) {
    final firestoreService = FirestoreService(projectId);

    return Expanded(
      child: DragTarget<Map<String, dynamic>>(
        onAcceptWithDetails: (DragTargetDetails<Map<String, dynamic>> details) {
          final taskId = details.data['taskId']; // Извлекаем taskId из data

          firestoreService.updateTaskStatus(taskId, status).catchError((e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating task: $e')),
            );
          });
        },
        builder: (context, candidateData, rejectedData) {
          return Container(
            padding: AppStyles.columnPadding,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade300,
              ),
            ),
            child: Column(
              children: [
                Text(title, style: AppStyles.columnTitleStyle),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      final priorityColor = task['priority'] == 'high'
                          ? Colors.red.shade200
                          : task['priority'] == 'medium'
                              ? Colors.yellow.shade200
                              : Colors.green.shade200;
                      return Draggable<Map<String, dynamic>>(
                        data: {
                          'taskId': task.id,
                          'currentStatus': task['status']
                        },
                        feedback: Material(
                          child: Card(
                            color: priorityColor,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                task['title'],
                                style: AppStyles.taskTitleStyle,
                              ),
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.5,
                          child: Card(
                            child: ListTile(
                              title: Text(task['title']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Описание: ${task['description']}'),
                                  Text(
                                    'Срок: ${DateFormat.yMMMd().format(task['dueDate'].toDate())}',
                                  ),
                                  if (task['assignees'] != null)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: (task['assignees']
                                              as List<dynamic>)
                                          .map((assigneeId) => FutureBuilder(
                                                future: FirebaseFirestore
                                                    .instance
                                                    .collection('users')
                                                    .doc(assigneeId)
                                                    .get(),
                                                builder: (context, snapshot) {
                                                  if (snapshot
                                                          .connectionState ==
                                                      ConnectionState.waiting) {
                                                    return const SizedBox(
                                                        width: 24,
                                                        height: 24,
                                                        child:
                                                            CircularProgressIndicator());
                                                  }
                                                  final userData =
                                                      snapshot.data?.data();
                                                  if (userData == null) {
                                                    return const SizedBox();
                                                  }
                                                  return ListTile(
                                                    leading: CircleAvatar(
                                                      backgroundImage:
                                                          NetworkImage(userData[
                                                                  'avatarUrl'] ??
                                                              'https://ui-avatars.com/'),
                                                    ),
                                                    title: Text(
                                                        '${userData['name']} ${userData['surname']}'),
                                                  );
                                                },
                                              ))
                                          .toList(),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        child: Card(
                          color: priorityColor,
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task['title'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Описание: ${task['description']}',
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Срок: ${DateFormat.yMMMd().format(task['dueDate'].toDate())}',
                                    ),
                                    const SizedBox(height: 8),
                                    if (task['assignees'] != null)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: (task['assignees']
                                                as List<dynamic>)
                                            .map((assigneeId) => FutureBuilder(
                                                  future: FirebaseFirestore
                                                      .instance
                                                      .collection('users')
                                                      .doc(assigneeId)
                                                      .get(),
                                                  builder: (context, snapshot) {
                                                    if (snapshot
                                                            .connectionState ==
                                                        ConnectionState
                                                            .waiting) {
                                                      return const SizedBox(
                                                        width: 24,
                                                        height: 24,
                                                        child:
                                                            CircularProgressIndicator(),
                                                      );
                                                    }
                                                    final userData =
                                                        snapshot.data?.data();
                                                    if (userData == null) {
                                                      return const SizedBox();
                                                    }
                                                    return Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical:
                                                              4.0), // Уменьшенный отступ между исполнителями
                                                      child: Row(
                                                        children: [
                                                          CircleAvatar(
                                                            radius:
                                                                16, // Уменьшенный размер аватарки
                                                            backgroundImage:
                                                                NetworkImage(userData[
                                                                        'avatarUrl'] ??
                                                                    'https://ui-avatars.com/'),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Text(
                                                            '${userData['name']} ${userData['surname']}',
                                                            style: const TextStyle(
                                                                fontSize:
                                                                    12), // Уменьшенный шрифт
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ))
                                            .toList(),
                                      ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () => _editTask(
                                          context,
                                          task.data() as Map<String, dynamic>,
                                          task.id),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      onPressed: () =>
                                          firestoreService.deleteTask(task.id),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
