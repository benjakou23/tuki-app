import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth_provider.dart';
import 'home_cliente_screen.dart';
import 'home_tecnico_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final rol = auth.rol;

    if (rol == 'tecnico') return const HomeTecnicoScreen();
    return const HomeClienteScreen();
  }
}