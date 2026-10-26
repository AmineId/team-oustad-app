import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';

/// Photos de profil chargées depuis `GET /users/{id}/profile-image`.
///
/// Le profil (`/auth/me`) renvoie l'image en octets sérialisés en JSON,
/// illisibles côté client : on passe par la route dédiée, avec un cache
/// mémoire par utilisateur.
class ProfilePhotos {
  ProfilePhotos._();

  static final Map<int, Future<Uint8List?>> _cache = {};

  /// Incrémenté quand une photo change : les [ProfileAvatar] se rechargent.
  static final ValueNotifier<int> version = ValueNotifier<int>(0);

  /// Id de l'utilisateur d'un profil (racine ou `user`).
  static int? userIdOf(Map<String, dynamic>? profile) {
    final id = profile?['id'] ?? (profile?['user'] as Map?)?['id'];
    return id is int ? id : int.tryParse('${id ?? ''}');
  }

  static Future<Uint8List?> load(int userId) =>
      _cache.putIfAbsent(userId, () async {
        final api = ApiService.fromEnv();
        final token = await AuthService(api).loadToken();
        if (token == null) return null;
        return api.getBytes('/users/$userId/profile-image', token);
      });

  /// À appeler après un envoi ou une suppression de photo.
  static void invalidate(int userId) {
    _cache.remove(userId);
    version.value++;
  }
}

/// Avatar rond affichant la photo de profil de [userId], ou [placeholder].
class ProfileAvatar extends StatefulWidget {
  final int? userId;
  final double size;
  final Widget placeholder;

  const ProfileAvatar({
    super.key,
    required this.userId,
    required this.size,
    required this.placeholder,
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    ProfilePhotos.version.addListener(_load);
    _load();
  }

  @override
  void didUpdateWidget(ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) _load();
  }

  @override
  void dispose() {
    ProfilePhotos.version.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final id = widget.userId;
    final bytes = id == null ? null : await ProfilePhotos.load(id);
    if (mounted && id == widget.userId) setState(() => _bytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ClipOval(
        child: bytes == null
            ? widget.placeholder
            : Image.memory(
                bytes,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => widget.placeholder,
              ),
      ),
    );
  }
}
