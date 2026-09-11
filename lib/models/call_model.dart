import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../core/constants/app_constants.dart';

/// Represents a live signaling document at calls/{callId}, and — once the
/// call ends — the record that gets copied into call_history.
class CallModel extends Equatable {
  final String callId;
  final String callerId;
  final String callerName;
  final String? callerPhotoUrl;
  final String calleeId;
  final String calleeName;
  final String? calleePhotoUrl;
  final String channelName;
  final CallType type;
  final CallStatus status;
  final DateTime createdAt;
  final DateTime? endedAt;
  final int durationSeconds;

  const CallModel({
    required this.callId,
    required this.callerId,
    required this.callerName,
    this.callerPhotoUrl,
    required this.calleeId,
    required this.calleeName,
    this.calleePhotoUrl,
    required this.channelName,
    required this.type,
    required this.status,
    required this.createdAt,
    this.endedAt,
    this.durationSeconds = 0,
  });

  factory CallModel.fromMap(String callId, Map<String, dynamic> map) {
    return CallModel(
      callId: callId,
      callerId: map['callerId'] as String,
      callerName: map['callerName'] as String? ?? '',
      callerPhotoUrl: map['callerPhotoUrl'] as String?,
      calleeId: map['calleeId'] as String,
      calleeName: map['calleeName'] as String? ?? '',
      calleePhotoUrl: map['calleePhotoUrl'] as String?,
      channelName: map['channelName'] as String,
      type: CallType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CallType.audio,
      ),
      status: CallStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CallStatus.ringing,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endedAt: (map['endedAt'] as Timestamp?)?.toDate(),
      durationSeconds: map['durationSeconds'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'callerId': callerId,
      'callerName': callerName,
      'callerPhotoUrl': callerPhotoUrl,
      'calleeId': calleeId,
      'calleeName': calleeName,
      'calleePhotoUrl': calleePhotoUrl,
      'channelName': channelName,
      'type': type.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'durationSeconds': durationSeconds,
    };
  }

  CallModel copyWith({
    CallStatus? status,
    DateTime? endedAt,
    int? durationSeconds,
  }) {
    return CallModel(
      callId: callId,
      callerId: callerId,
      callerName: callerName,
      callerPhotoUrl: callerPhotoUrl,
      calleeId: calleeId,
      calleeName: calleeName,
      calleePhotoUrl: calleePhotoUrl,
      channelName: channelName,
      type: type,
      status: status ?? this.status,
      createdAt: createdAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  /// Convenience: which side is "me" determines incoming vs outgoing,
  /// and who the "other party" is — used heavily by the UI layer.
  bool isCaller(String myUid) => callerId == myUid;

  @override
  List<Object?> get props => [
        callId,
        callerId,
        calleeId,
        channelName,
        type,
        status,
        createdAt,
        endedAt,
        durationSeconds,
      ];
}
