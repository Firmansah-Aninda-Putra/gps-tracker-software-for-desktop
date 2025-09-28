import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens.dart';
import 'services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MadiunSiaga112App());
}

class MadiunSiaga112App extends StatelessWidget {
  const MadiunSiaga112App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppStateProvider(),
      child: MaterialApp(
        title: 'Madiun Siaga 112',
        theme: ThemeData(
          primarySwatch: Colors.red,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}