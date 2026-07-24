/// Login flow steps — parity: vcare-agent-app-2.0/src/features/auth/types.ts
enum LoginFlowStep {
  identify,
  verify,
  disambiguate,
  password,
  twoFactor,
  activate,
  onboard,
  biometric,
  forgotIdentify,
  forgotSelect,
  forgotVerify,
  forgotReset,
}

enum LoginFlowMethod { phone, email }
