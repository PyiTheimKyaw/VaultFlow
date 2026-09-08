import 'package:meta/meta.dart';

@immutable
class UserRecord {
  const UserRecord({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String passwordHash;
  final DateTime createdAt;
}

@immutable
class DeviceRecord {
  const DeviceRecord({
    required this.id,
    required this.userId,
    required this.name,
    required this.platform,
    required this.lastSeenAt,
  });

  final String id;
  final String userId;
  final String name;
  final String platform;
  final DateTime lastSeenAt;
}

@immutable
class RefreshTokenRecord {
  const RefreshTokenRecord({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.familyId,
    required this.tokenHash,
    required this.expiresAt,
    required this.createdAt,
    this.revokedAt,
    this.replacedBy,
  });

  final String id;
  final String userId;
  final String deviceId;

  /// Shared by every token descending from one login.
  final String familyId;
  final String tokenHash;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime? revokedAt;

  /// Id of the token that superseded this one after a refresh.
  final String? replacedBy;

  bool get isActive => revokedAt == null && replacedBy == null;

  RefreshTokenRecord copyWith({DateTime? revokedAt, String? replacedBy}) =>
      RefreshTokenRecord(
        id: id,
        userId: userId,
        deviceId: deviceId,
        familyId: familyId,
        tokenHash: tokenHash,
        expiresAt: expiresAt,
        createdAt: createdAt,
        revokedAt: revokedAt ?? this.revokedAt,
        replacedBy: replacedBy ?? this.replacedBy,
      );
}
