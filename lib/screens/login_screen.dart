import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../styles/app_styles.dart'; // Импортируем стили

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;

  Future<void> _login() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/projects');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.code == 'user-not-found'
            ? 'Пользователь не найден.'
            : e.code == 'wrong-password'
                ? 'Неверный пароль.'
                : 'Ошибка: ${e.message}';
      });
    }
  }

  Future<String?> _fetchAvatarUrl(String uid) async {
    final snapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return snapshot.data()?['avatarUrl'];
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Авторизация')),
        body: Center(
          child: FutureBuilder<String?>(
            future: _fetchAvatarUrl(user.uid),
            builder: (context, snapshot) {
              final avatarUrl = snapshot.data ??
                  'https://ui-avatars.com/api/?name=${user.displayName ?? "User"}';

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(avatarUrl),
                    radius: 50,
                  ),
                  AppStyles.verticalSpacingLarge,
                  Text(
                    'Вы вошли как ${user.displayName ?? user.email}',
                    style: AppStyles.loggedInTextStyle,
                  ),
                  AppStyles.verticalSpacingLarge,
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/projects');
                    },
                    child: const Text('Перейти к проектам'),
                  ),
                  AppStyles.verticalSpacingSmall,
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    style: AppStyles.signOutButtonStyle, // Стиль кнопки выхода
                    child: const Text('Выйти'),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            width: 300,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  ' Вход в Agile-доска 📝',
                  style: AppStyles.projectTitleStyle,
                  textAlign: TextAlign.center,
                ),
                AppStyles.verticalSpacingLarge,
                TextField(
                  controller: _emailController,
                  decoration: AppStyles.inputDecoration.copyWith(
                    labelText: 'Почта',
                  ),
                ),
                AppStyles.verticalSpacingSmall,
                TextField(
                  controller: _passwordController,
                  decoration: AppStyles.inputDecoration.copyWith(
                    labelText: 'Пароль',
                  ),
                  obscureText: true,
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      _errorMessage!,
                      style: AppStyles.errorTextStyle,
                    ),
                  ),
                AppStyles.verticalSpacingLarge,
                ElevatedButton(
                  onPressed: _login,
                  style: AppStyles.buttonSignStyle,
                  child: const Text('Войти'),
                ),
                AppStyles.verticalSpacingSmall,
                OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  style: AppStyles.outlinedButtonStyle,
                  child: const Text('Регистрация'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
