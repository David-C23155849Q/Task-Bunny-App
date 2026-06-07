import 'package:errand_app/authentication/login_screen.dart';
import 'package:errand_app/infoHandler/app_info.dart';
import 'package:errand_app/pages/errand_design_page.dart';
import 'package:errand_app/pages/home_page.dart';
import 'package:errand_app/pages/main_screen.dart';
import 'package:errand_app/pages/profile_page.dart';
import 'package:errand_app/pages/search_places_screen.dart';
import 'package:errand_app/pages/trial/screens/home_screen.dart';
import 'package:errand_app/pages/trial/screens/welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

Future<void> main() async
{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await Permission.locationWhenInUse.isDenied.then((valueOfPermission)
  {
    if(valueOfPermission)
      {
        Permission.locationWhenInUse.request();
      }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context)=> AppInfo(),
        child: MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.white,
      ),
      home: ClientHomeScreen(),
      //home: FirebaseAuth.instance.currentUser == null ? LoginScreen() : HomePage(),
    ),
    );
  }
}
