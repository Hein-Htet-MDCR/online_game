abstract class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String createRoom = '/create-room';
  static const String joinRoom = '/join-room';
  static const String lobby = '/lobby/:roomId';
  static const String matchmaking = '/matchmaking';
  static const String game = '/game/:roomId';
  static const String result = '/result/:gameId';
}
