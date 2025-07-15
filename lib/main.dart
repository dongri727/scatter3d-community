import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scatter3d_community/firebase_options.dart';
import 'package:scatter3d_community/pages/second_page.dart';
import 'package:scatter3d_community/pages/top_page.dart';
import 'package:scatter3d_community/projects/project_provider.dart';
import 'package:scatter3d_community/utils/snackbars.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ProjectProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {

  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scatter3D Community',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/topPage',
      routes: {
        '/topPage': (context) => const TopPage(),
        '/secondPage': (context) => const SecondPage(
          parsedData: [],
          scatterData: [],
          csvFilePath: '',
        ),
      },
      scaffoldMessengerKey: SuccessSnackBar.messengerKey,
    );
  }
}
