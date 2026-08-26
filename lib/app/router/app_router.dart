import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/supabase_provider.dart';
import '../../core/utils/responsive_layout.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/game/presentation/screens/game_screen.dart';
import '../../features/game/presentation/screens/result_screen.dart';
import '../../features/matchmaking/presentation/screens/matchmaking_screen.dart';
import '../../features/room/presentation/screens/create_room_screen.dart';
import '../../features/room/presentation/screens/join_room_screen.dart';
import '../../features/room/presentation/screens/lobby_screen.dart';
import '../../features/shared/presentation/screens/home_screen.dart';
import '../constants/app_routes.dart';

/// Converts a Stream into a Listenable for GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final supabase = ref.watch(supabaseClientProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: GoRouterRefreshStream(supabase.auth.onAuthStateChange),
    redirect: (BuildContext context, GoRouterState state) {
      final session = supabase.auth.currentSession;
      final isLoggingIn = state.matchedLocation == AppRoutes.login;
      final isSplash = state.matchedLocation == AppRoutes.splash;

      if (session == null && !isLoggingIn && !isSplash) {
        return AppRoutes.login;
      }

      if (session != null && (isLoggingIn || isSplash)) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) =>
            const ResponsiveLayout(child: SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) =>
            const ResponsiveLayout(child: LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) =>
            const ResponsiveLayout(child: HomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.createRoom,
        builder: (context, state) =>
            const ResponsiveLayout(child: CreateRoomScreen()),
      ),
      GoRoute(
        path: AppRoutes.joinRoom,
        builder: (context, state) =>
            const ResponsiveLayout(child: JoinRoomScreen()),
      ),
      GoRoute(
        path: AppRoutes.lobby,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          return ResponsiveLayout(child: LobbyScreen(roomId: roomId));
        },
      ),
      GoRoute(
        path: AppRoutes.matchmaking,
        builder: (context, state) =>
            const ResponsiveLayout(child: MatchmakingScreen()),
      ),
      GoRoute(
        path: AppRoutes.game,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          return ResponsiveLayout(child: GameScreen(roomId: roomId));
        }, // i changed game id to room id
      ),
      GoRoute(
        path: AppRoutes.result,
        builder: (context, state) {
          final gameId = state.pathParameters['gameId'] ?? '';
          return ResponsiveLayout(child: ResultScreen(gameId: gameId));
        },
      ),
    ],
  );
});
