import 'admin_auth_user.dart';
import 'app_urls.dart';

class AdminAuthSession {
  const AdminAuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.menu,
    this.urls,
  });

  final String accessToken;
  final String refreshToken;
  final AdminAuthUser user;
  final List<String> menu;
  final AppUrls? urls;
}
