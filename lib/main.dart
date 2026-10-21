import 'package:flutter/material.dart';
import 'package:jrrplayerapp/constants/app_strings.dart';
import 'package:jrrplayerapp/constants/app_theme.dart';
import 'package:provider/provider.dart';
import 'services/audio_player_service.dart';
import 'repositories/podcast_repository.dart';
import 'ui/screens/main_screen.dart';
import 'ui/screens/podcast_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AudioPlayerService>(
          create: (context) => AudioPlayerService()..initialize(),
        ),
        ChangeNotifierProvider<PodcastRepository>(
          // Загружаем сохранённые позиции эпизодов сразу при старте
          create: (context) => PodcastRepository()..loadPositionsFromStorage(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.radioName,
      theme: AppTheme.dark,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/podcasts': (context) => const PodcastListScreen(),
      },
    );
  }
}
