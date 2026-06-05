import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/providers.dart';
import '../../features/auth/presentation/pages/pages.dart';
import '../../features/tasks/presentation/pages/pages.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      if (authState case AsyncData(:final value)) {
        final isLoggedIn = value != null;
        final location = state.matchedLocation;

        if (location == '/') {
          return isLoggedIn ? '/home' : '/login';
        }

        final isAuthRoute = location == '/login' || location == '/register';
        final isProtectedRoute = location == '/home';

        if (!isLoggedIn && isProtectedRoute) return '/login';
        if (isLoggedIn && isAuthRoute) return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (_, _) => const HomeScreen(),
      ),
    ],
  );
});
