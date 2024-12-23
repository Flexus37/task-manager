import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/project_list_screen.dart';
import 'screens/register_screen.dart';
import 'screens/task_board_screen.dart';
import 'screens/user_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Устанавливаем стратегию URL для Flutter Web
  setUrlStrategy(PathUrlStrategy()); // Это убирает # из URL

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agile-доска',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/', // Главная страница
      onGenerateRoute: (settings) {
        final user = FirebaseAuth.instance.currentUser;

        // Публичные маршруты
        const publicRoutes = ['/', '/login', '/register'];

        // Если пользователь не авторизован и пытается перейти на защищенный маршрут
        if (user == null && !publicRoutes.contains(settings.name)) {
          return MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          );
        }

        // Если пользователь авторизован, роутинг работает как обычно
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) => const HomeScreen());
          case '/login':
            return MaterialPageRoute(builder: (context) => const LoginScreen());
          case '/register':
            return MaterialPageRoute(
                builder: (context) => const RegisterScreen());
          case '/profile':
            return MaterialPageRoute(
                builder: (context) => const UserProfileScreen());
          case '/projects':
            return MaterialPageRoute(
                builder: (context) => const ProjectListScreen());
          case '/tasks':
            final projectId = settings.arguments as String?;
            if (projectId != null) {
              return MaterialPageRoute(
                builder: (context) => TaskBoardScreen(projectId: projectId),
              );
            }
            break;
        }

        // Если маршрут не найден, показываем ошибку
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text('404: Страница ${settings.name} не найдена'),
            ),
          ),
        );
      },
    );
  }
}
