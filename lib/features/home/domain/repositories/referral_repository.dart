abstract class ReferralRepository {
  Future<String?> readSlug();
  Future<void> saveSlug(String slug);
}
