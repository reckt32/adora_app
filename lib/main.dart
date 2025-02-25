import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/location_service.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  

  await LocationService.initialize();
 
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,  
      ),
      home: const HomeScreen(),
    );
  }
}