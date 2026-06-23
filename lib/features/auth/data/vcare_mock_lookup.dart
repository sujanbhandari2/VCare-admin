/// Mock identifier lookup — parity with vcareapp `mock-lookup.ts`.
class LoginClientRecord {
  const LoginClientRecord({
    required this.clientId,
    required this.fullName,
    required this.dobMasked,
    required this.zipMasked,
    required this.memberId,
    required this.hasLogin,
  });

  final String clientId;
  final String fullName;
  final String dobMasked;
  final String zipMasked;
  final String memberId;
  final bool hasLogin;
}

sealed class LoginLookupBranch {
  const LoginLookupBranch();
}

class LoginLookupNew extends LoginLookupBranch {
  const LoginLookupNew();
}

class LoginLookupActivate extends LoginLookupBranch {
  const LoginLookupActivate(this.client);

  final LoginClientRecord client;
}

class LoginLookupPassword extends LoginLookupBranch {
  const LoginLookupPassword({
    required this.client,
    required this.biometricEnrolled,
  });

  final LoginClientRecord client;
  final bool biometricEnrolled;
}

class LoginLookupDisambiguate extends LoginLookupBranch {
  const LoginLookupDisambiguate(this.clients);

  final List<LoginClientRecord> clients;
}

class VcareMockLookup {
  VcareMockLookup._();

  static const demoOtp = '123456';

  static const _demo = <String, LoginLookupBranch>{
    'new@example.com': LoginLookupNew(),
    'activate@example.com': LoginLookupActivate(
      LoginClientRecord(
        clientId: 'c-1001',
        fullName: 'Jordan Patel',
        dobMasked: '•• / •• / 198•',
        zipMasked: '941••',
        memberId: 'VC-1001-2025',
        hasLogin: false,
      ),
    ),
    'alex.rivera@example.com': LoginLookupPassword(
      biometricEnrolled: true,
      client: LoginClientRecord(
        clientId: 'c-1002',
        fullName: 'Alex Rivera',
        dobMasked: '•• / •• / 199•',
        zipMasked: '941••',
        memberId: 'VC-8472-1903',
        hasLogin: true,
      ),
    ),
    'duplicate@example.com': LoginLookupDisambiguate([
      LoginClientRecord(
        clientId: 'c-2001',
        fullName: 'Sam Chen',
        dobMasked: '•• / •• / 197•',
        zipMasked: '100••',
        memberId: 'VC-2001-2025',
        hasLogin: true,
      ),
      LoginClientRecord(
        clientId: 'c-2002',
        fullName: 'Sam Chen',
        dobMasked: '•• / •• / 199•',
        zipMasked: '941••',
        memberId: 'VC-2002-2025',
        hasLogin: false,
      ),
    ]),
  };

  static Future<LoginLookupBranch> lookup(String identifier) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final key = identifier.trim().toLowerCase();
    final match = _demo[key];
    if (match != null) return match;

    return const LoginLookupPassword(
      biometricEnrolled: false,
      client: LoginClientRecord(
        clientId: 'c-default',
        fullName: 'Demo User',
        dobMasked: '•• / •• / 19••',
        zipMasked: '•••••',
        memberId: 'VC-DEMO-0000',
        hasLogin: true,
      ),
    );
  }

  /// Mock accounts for forgot-password — parity with mock-lookup.ts
  static Future<List<LoginClientRecord>> accountsByEmail(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final key = email.trim().toLowerCase();
    if (key.isEmpty) return [];
    return const [
      LoginClientRecord(
        clientId: 'c-3001',
        fullName: 'Alex Rivera',
        dobMasked: '•• /•• / 199•',
        zipMasked: '941••',
        memberId: 'VC-8472-1903',
        hasLogin: true,
      ),
      LoginClientRecord(
        clientId: 'c-3002',
        fullName: 'Jamie Rivera',
        dobMasked: '•• /•• / 201•',
        zipMasked: '941••',
        memberId: 'VC-8472-2210',
        hasLogin: true,
      ),
    ];
  }
}
