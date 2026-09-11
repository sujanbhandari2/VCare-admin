package com.vcare.admin

import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.math.BigInteger
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.Signature
import java.security.interfaces.ECPublicKey
import java.security.spec.ECGenParameterSpec

/**
 * MethodChannel bridge for non-exportable EC P-256 keys in Android Keystore,
 * with biometric-gated ECDSA SHA-256 signing (IEEE P1363 / raw r||s).
 */
class BiometricCryptoChannel(
    private val activity: FragmentActivity,
) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "com.vcare.admin/biometric_crypto"
        private const val ANDROID_KEYSTORE = "AndroidKeyStore"
        private const val SIGNATURE_ALGORITHM = "SHA256withECDSA"

        fun register(activity: FragmentActivity, messenger: BinaryMessenger) {
            MethodChannel(messenger, CHANNEL).setMethodCallHandler(
                BiometricCryptoChannel(activity),
            )
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "generateKeyPair" -> {
                val keyAlias = call.argument<String>("keyAlias")
                if (keyAlias.isNullOrBlank()) {
                    result.error("invalid_args", "keyAlias is required", null)
                    return
                }
                try {
                    result.success(generateKeyPair(keyAlias))
                } catch (error: Exception) {
                    result.error("generate_failed", error.message, null)
                }
            }

            "sign" -> {
                val keyAlias = call.argument<String>("keyAlias")
                val nonce = call.argument<String>("nonce")
                val reason = call.argument<String>("reason")
                    ?: "Authenticate to sign in"
                if (keyAlias.isNullOrBlank() || nonce.isNullOrBlank()) {
                    result.error("invalid_args", "keyAlias and nonce are required", null)
                    return
                }
                signWithBiometric(keyAlias, nonce, reason, result)
            }

            "deleteKey" -> {
                val keyAlias = call.argument<String>("keyAlias")
                if (keyAlias.isNullOrBlank()) {
                    result.error("invalid_args", "keyAlias is required", null)
                    return
                }
                try {
                    deleteKey(keyAlias)
                    result.success(null)
                } catch (error: Exception) {
                    result.error("delete_failed", error.message, null)
                }
            }

            else -> result.notImplemented()
        }
    }

    private fun generateKeyPair(keyAlias: String): Map<String, String> {
        deleteKey(keyAlias)

        val keyPairGenerator = KeyPairGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_EC,
            ANDROID_KEYSTORE,
        )

        val builder = KeyGenParameterSpec.Builder(
            keyAlias,
            KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY,
        )
            .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
            .setDigests(KeyProperties.DIGEST_SHA256)
            .setUserAuthenticationRequired(true)
            .setInvalidatedByBiometricEnrollment(true)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            builder.setUserAuthenticationParameters(
                0,
                KeyProperties.AUTH_BIOMETRIC_STRONG,
            )
        } else {
            @Suppress("DEPRECATION")
            builder.setUserAuthenticationValidityDurationSeconds(-1)
        }

        keyPairGenerator.initialize(builder.build())
        val keyPair = keyPairGenerator.generateKeyPair()
        val publicKey = keyPair.public as ECPublicKey
        val publicKeyBase64 = Base64.encodeToString(publicKey.encoded, Base64.NO_WRAP)

        return mapOf(
            "keyAlias" to keyAlias,
            "publicKeyBase64" to publicKeyBase64,
        )
    }

    private fun signWithBiometric(
        keyAlias: String,
        nonce: String,
        reason: String,
        result: MethodChannel.Result,
    ) {
        val authenticators = BiometricManager.Authenticators.BIOMETRIC_STRONG
        val biometricManager = BiometricManager.from(activity)
        val canAuthenticate = biometricManager.canAuthenticate(authenticators)
        if (canAuthenticate != BiometricManager.BIOMETRIC_SUCCESS) {
            result.error("biometric_unavailable", "Biometric authentication is unavailable", null)
            return
        }

        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        val entry = keyStore.getEntry(keyAlias, null) as? KeyStore.PrivateKeyEntry
        if (entry == null) {
            result.error("key_missing", "Biometric key was not found", null)
            return
        }

        val signature = Signature.getInstance(SIGNATURE_ALGORITHM)
        try {
            signature.initSign(entry.privateKey)
        } catch (error: Exception) {
            result.error("sign_init_failed", error.message, null)
            return
        }

        val executor = ContextCompat.getMainExecutor(activity)
        val prompt = BiometricPrompt(
            activity,
            executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(
                    authResult: BiometricPrompt.AuthenticationResult,
                ) {
                    try {
                        val cryptoSignature = authResult.cryptoObject?.signature
                            ?: signature
                        cryptoSignature.update(nonce.toByteArray(Charsets.UTF_8))
                        val der = cryptoSignature.sign()
                        val raw = derToP1363(der)
                        val encoded = Base64.encodeToString(raw, Base64.NO_WRAP)
                        result.success(mapOf("signatureBase64" to encoded))
                    } catch (error: Exception) {
                        result.error("sign_failed", error.message, null)
                    }
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    result.error("auth_failed", errString.toString(), errorCode)
                }

                override fun onAuthenticationFailed() {
                    // Keep the prompt open; terminal failures go through onAuthenticationError.
                }
            },
        )

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle(reason)
            .setSubtitle("Confirm with biometrics")
            .setNegativeButtonText("Cancel")
            .setAllowedAuthenticators(authenticators)
            .build()

        activity.runOnUiThread {
            prompt.authenticate(promptInfo, BiometricPrompt.CryptoObject(signature))
        }
    }

    private fun deleteKey(keyAlias: String) {
        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        if (keyStore.containsAlias(keyAlias)) {
            keyStore.deleteEntry(keyAlias)
        }
    }

    /** Converts ASN.1 DER ECDSA signature to IEEE P1363 (r||s, 64 bytes). */
    private fun derToP1363(der: ByteArray): ByteArray {
        var offset = 0
        if (der[offset++] != 0x30.toByte()) {
            throw IllegalArgumentException("Invalid DER signature")
        }
        val seqLen = der[offset++].toInt() and 0xFF
        if (seqLen and 0x80 != 0) {
            val lenBytes = seqLen and 0x7F
            offset += lenBytes
        }
        if (der[offset++] != 0x02.toByte()) {
            throw IllegalArgumentException("Invalid DER signature (r)")
        }
        val rLen = der[offset++].toInt() and 0xFF
        val rBytes = der.copyOfRange(offset, offset + rLen)
        offset += rLen
        if (der[offset++] != 0x02.toByte()) {
            throw IllegalArgumentException("Invalid DER signature (s)")
        }
        val sLen = der[offset++].toInt() and 0xFF
        val sBytes = der.copyOfRange(offset, offset + sLen)

        return fixed32(rBytes) + fixed32(sBytes)
    }

    private fun fixed32(value: ByteArray): ByteArray {
        val normalized = BigInteger(1, value).toByteArray()
        val out = ByteArray(32)
        if (normalized.size >= 32) {
            System.arraycopy(normalized, normalized.size - 32, out, 0, 32)
        } else {
            System.arraycopy(normalized, 0, out, 32 - normalized.size, normalized.size)
        }
        return out
    }
}
