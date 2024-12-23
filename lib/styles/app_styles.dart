import 'package:flutter/material.dart';

class AppStyles {
  /// Градиенты
  static const List<Color> gradientColors1 = [
    Color(0xFF6A11CB), // Фиолетовый
    Color(0xFF2575FC), // Голубой
  ];

  static const List<Color> gradientColors2 = [
    Color(0xFFFF9A8B), // Розовый
    Color(0xFFFA709A), // Светло-розовый
  ];

  // Стиль заголовка
  static const TextStyle homeTitleStyle = TextStyle(
    fontSize: 80, // Увеличенный размер текста
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  // Стиль кнопки "Начать"
  static final ButtonStyle startButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: Colors.deepPurple,
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
  );

  // Стиль текста внутри кнопки
  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 20,
  );

  // --- Стили для LoginScreen и RegisterScreen ---
  // Поля ввода
  static const InputDecoration inputDecoration = InputDecoration(
    labelText: '',
    border: OutlineInputBorder(),
  );

  // Ошибки
  static const TextStyle errorTextStyle = TextStyle(
    color: Colors.red,
    fontSize: 14,
  );

  // Кнопки входа
  static final ButtonStyle buttonSignStyle = ElevatedButton.styleFrom(
    minimumSize: const Size(double.infinity, 50),
  );

  // Кнопки регистрации
  static final ButtonStyle outlinedButtonStyle = OutlinedButton.styleFrom(
    minimumSize: const Size(double.infinity, 50),
  );

  // Заголовки
  static const TextStyle loggedInTextStyle = TextStyle(
    fontSize: 18,
  );

  // Отступы
  static const SizedBox verticalSpacingLarge = SizedBox(height: 20);
  static const SizedBox verticalSpacingSmall = SizedBox(height: 10);

  // Кнопка выхода
  static final ButtonStyle signOutButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.red,
    foregroundColor: Colors.white,
  );

  // --- Стили для ProjectListScreen ---

  // Основной стиль заголовка
  static const TextStyle projectTitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  // Стиль для кнопок
  static final ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: Colors.deepPurple,
  );

  // Стиль текста списка проектов
  static const TextStyle listTileTitleStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  // Стиль описания в списке
  static const TextStyle listTileSubtitleStyle = TextStyle(
    fontSize: 14,
    color: Colors.grey,
  );

  // Стиль для аватара в меню
  static const TextStyle popupMenuHeaderStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  // Отступы и размеры
  static const EdgeInsets contentPadding = EdgeInsets.all(16);
  static const SizedBox verticalSpacing = SizedBox(height: 10);

  // --- Стили для TaskBoardScreen ---
  static const TextStyle taskTitleStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  static const TextStyle taskDescriptionStyle = TextStyle(
    fontSize: 14,
  );

  static const TextStyle taskDueDateStyle = TextStyle(
    fontSize: 12,
    color: Colors.grey,
  );

  static final BoxDecoration taskCardDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 4,
        offset: Offset(0, 2),
      ),
    ],
  );

  static const TextStyle columnTitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const EdgeInsets columnPadding = EdgeInsets.all(8);
}
