import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/auth_provider.dart';
import 'core/router.dart';
import 'core/notificaciones_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await Supabase.initialize(
    url: 'https://yklmkkialphvwpxdazvc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlrbG1ra2lhbHBodndweGRhenZjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk2MDMwOTgsImV4cCI6MjA5NTE3OTA5OH0.gra_DUeh0J7slVRLvdlWKH2sXNwP9dPPD7R_Z41ZsVo',
  );

  await NotificacionesService.inicializar();

  runApp(const TukiApp());
}

class TukiApp extends StatelessWidget {
  const TukiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final auth = AuthProvider();
        auth.cargarSesion();
        return auth;
      },
      child: Builder(
        builder: (context) {
          final auth = context.watch<AuthProvider>();
          return MaterialApp.router(
            title: 'Tuki.pe',
            debugShowCheckedModeBanner: false,
            routerConfig: AppRouter.router(auth),
          );
        },
      ),
    );
  }
}