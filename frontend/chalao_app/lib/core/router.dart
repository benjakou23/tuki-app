import 'package:go_router/go_router.dart';
import 'auth_provider.dart';
import '../features/splash/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/registro_screen.dart';
import '../features/auth/screens/onboarding_cliente_screen.dart';
import '../features/auth/screens/en_revision_screen.dart';
import '../features/home/screens/buscar_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/pedidos/screens/crear_pedido_screen.dart';
import '../features/pedidos/screens/pedidos_disponibles_screen.dart';
import '../features/pedidos/screens/detalle_pedido_screen.dart';
import '../features/tecnico/screens/completar_perfil_screen.dart';
import '../features/perfil/screens/perfil_screen.dart';
import '../features/mapa/screens/mapa_cliente_screen.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/pedidos/screens/mis_pedidos_screen.dart';
import '../features/tecnico/screens/ganancias_screen.dart';
import '../features/tecnico/screens/trabajos_screen.dart';

class AppRouter {
  static GoRouter router(AuthProvider auth) {
    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final autenticado = auth.autenticado;
        final ruta = state.matchedLocation;
        final estado = auth.estadoVerificacion;

        // Splash — se maneja a sí mismo, nunca redirigir desde aquí
        if (ruta == '/') return null;

        // No autenticado — solo puede ver login y registro
        if (!autenticado) {
          if (ruta == '/login' || ruta == '/registro') return null;
          return '/login';
        }

        // Autenticado — lógica por estado
        if (ruta == '/login' || ruta == '/registro') {
          if (estado == 'verificado') return '/home';
          if (estado == 'docs_enviados' ||
              estado == 'en_revision') return '/en-revision';
          return '/onboarding';
        }

        // Permitir estas rutas siempre si está autenticado
        if (ruta == '/onboarding' ||
            ruta == '/en-revision' ||
            ruta == '/home') return null;

        return null;
      },
      routes: [
        GoRoute(path: '/',
          builder: (c, s) => const SplashScreen()),
        GoRoute(path: '/login',
          builder: (c, s) => const LoginScreen()),
        GoRoute(path: '/registro',
          builder: (c, s) => const RegistroScreen()),
        GoRoute(path: '/onboarding',
          builder: (c, s) => const OnboardingClienteScreen()),
        GoRoute(path: '/en-revision',
          builder: (c, s) => const EnRevisionScreen()),
        GoRoute(path: '/home',
          builder: (c, s) => const HomeScreen()),
        GoRoute(path: '/crear-pedido',
          builder: (c, s) => const CrearPedidoScreen()),
GoRoute(
  path: '/pedidos-disponibles',
  builder: (c, s) => const PedidosDisponiblesScreen(),
),
GoRoute(
  path: '/buscar',
  builder: (c, s) => const BuscarScreen(),
),
GoRoute(
  path: '/pedido/:id',
  builder: (c, s) => DetallePedidoScreen(
    pedidoId: s.pathParameters['id']!),
),
GoRoute(
  path: '/chat/:pedidoId/:nombre',
  builder: (c, s) => ChatScreen(
    pedidoId: s.pathParameters['pedidoId']!,
    otroNombre: s.pathParameters['nombre']!,
  ),
),
GoRoute(
  path: '/mis-pedidos',
  builder: (c, s) => const MisPedidosScreen(),
),
GoRoute(
  path: '/mapa',
  builder: (c, s) => const MapaClienteScreen(),
),
GoRoute(
  path: '/perfil',
  builder: (c, s) => const PerfilScreen(),
),

GoRoute(
  path: '/trabajos',
  builder: (c, s) => const TrabajosScreen(),
),

GoRoute(
  path: '/ganancias',
  builder: (c, s) => const GananciasScreen(),
),
GoRoute(
  path: '/completar-perfil',
  builder: (c, s) => const CompletarPerfilScreen(),
),
      ],
    );
  }
}