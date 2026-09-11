class BiometricChallenge {
  const BiometricChallenge({
    required this.challengeToken,
    required this.nonce,
  });

  final String challengeToken;
  final String nonce;
}
