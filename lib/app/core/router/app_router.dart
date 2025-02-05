import 'package:go_router/go_router.dart';
import 'package:prontuario_social/app/core/pages/auth/home_page.dart';
import 'package:prontuario_social/app/core/pages/auth/login_page.dart';
import 'package:prontuario_social/app/core/router/auth_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient supabase = Supabase.instance.client;
final managerAuth = ManagerAuth(supabase: supabase);

final appRouter = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/',
    redirect: (context, state) async {
      final isGoingTo = state.fullPath;
      final isAuth = await managerAuth.isAuthenticated();

      if (isAuth && (isGoingTo == '/login-page' || isGoingTo == '/')) {
        return '/home-page';
      }

      if (!isAuth && (isGoingTo != '/login-page' && isGoingTo != '/')) {
        return '/login-page';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: LoginPage.name,
        builder: (context, state) => LoginPage(),
      ),
      GoRoute(
        path: '/login-page',
        name: "LoginPage",
        builder: (context, state) => LoginPage(),
      ),
      GoRoute(
        path: '/home-page',
        name: HomePage.name,
        builder: (context, state) => HomePage(),
      )
    ]);
