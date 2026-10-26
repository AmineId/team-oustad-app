import 'package:flutter_test/flutter_test.dart';
import 'package:team_oustad_app/widgets/common/profile_avatar.dart';

void main() {
  test('userIdOf lit l\'id à la racine ou sous user', () {
    expect(ProfilePhotos.userIdOf({'id': 7}), 7);
    expect(ProfilePhotos.userIdOf({'id': '8'}), 8);
    expect(
      ProfilePhotos.userIdOf({
        'user': {'id': 9},
      }),
      9,
    );
    expect(ProfilePhotos.userIdOf(null), isNull);
    expect(ProfilePhotos.userIdOf({}), isNull);
  });
}
