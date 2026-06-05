import '../../domain/entities/entities.dart';

class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }
}
