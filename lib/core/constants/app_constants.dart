/// Central place for collection names, config keys, and magic values.
/// Keeping these here means every service refers to the same source of
/// truth instead of hardcoding strings around the codebase.
class AppConstants {
  AppConstants._();

  // Firestore collections
  static const String usersCollection = 'users';
  static const String callsCollection = 'calls';
  static const String callHistoryCollection = 'call_history';

  // Agora
  // TODO: replace with your Agora App ID from console.agora.io
  static const String agoraAppId = 'YOUR_AGORA_APP_ID';

  // How long the caller waits for a response before marking the call missed.
  static const Duration ringingTimeout = Duration(seconds: 30);
}

enum CallType { audio, video }

enum CallStatus { ringing, accepted, rejected, ended, missed, failed }

enum CallDirection { incoming, outgoing }
