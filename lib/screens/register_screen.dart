import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../styles/app_styles.dart'; // Импортируем стили

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  Future<void> _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Генерация URL для аватара
      final avatarUrl =
          'https://ui-avatars.com/api/?name=${_nameController.text}+${_surnameController.text}';

      // Сохранение данных пользователя в Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'name': _nameController.text.trim(),
        'surname': _surnameController.text.trim(),
        'email': _emailController.text.trim(),
        'avatarUrl': avatarUrl,
        'createdAt': Timestamp.now(),
      });

      Navigator.pushReplacementNamed(context, '/projects');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            width: 300, // Ограничение ширины формы
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: AppStyles.inputDecoration.copyWith(
                    labelText: 'Имя',
                  ), // Стили для поля
                ),
                AppStyles.verticalSpacingLarge,
                TextField(
                  controller: _surnameController,
                  decoration: AppStyles.inputDecoration.copyWith(
                    labelText: 'Фамилия',
                  ), // Стили для поля
                ),
                AppStyles.verticalSpacingLarge,
                TextField(
                  controller: _emailController,
                  decoration: AppStyles.inputDecoration.copyWith(
                    labelText: 'Почта',
                  ), // Стили для поля
                ),
                AppStyles.verticalSpacingLarge,
                TextField(
                  controller: _passwordController,
                  decoration: AppStyles.inputDecoration.copyWith(
                    labelText: 'Пароль',
                  ), // Стили для поля
                  obscureText: true,
                ),
                AppStyles.verticalSpacingLarge,
                TextField(
                  controller: _confirmPasswordController,
                  decoration: AppStyles.inputDecoration.copyWith(
                    labelText: 'Подтвердите пароль',
                  ), // Стили для поля
                  obscureText: true,
                ),
                AppStyles.verticalSpacingLarge,
                ElevatedButton(
                  onPressed: _register,
                  style: AppStyles.buttonSignStyle, // Стили кнопки
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
