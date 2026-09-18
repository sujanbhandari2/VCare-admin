package com.vcare.admin

import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import android.util.Log
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
 * MethodChannel bridge for non-exportable EC P-256 keys in Android Keystore.
 *
 * Signing always goes through [BiometricPrompt.CryptoObject]. A plain biometric
 * prompt does not unlock Keystore keys that require user authentication, which
 * is why silent [Signature.sign] after `authenticate()` fails with
 * KEY_USER_NOT_AUTHENTICATED (-26).
 *
 * Flow:
 * 1. authenticateForSigning — BiometricPrompt + CryptoObject(Signature)
 * 2. completeSign — update/sign on the *same* authenticated Signature
 */
class BiometricCryptoChannel(
    private val activity: FragmentActivity,
) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "com.vcare.admin/biometric_crypto"
        const val REENROLLMENT_REQUIRED = "reenrollment_required"
        private const val TAG = "BiometricCrypto"
        private const val ANDROID_KEYSTORE = "AndroidKeyStore"
        private const val SIGNATURE_ALGORITHM = "SHA256withECDSA"

        fun register(activity: FragmentActivity, messenger: BinaryMessenger) {
            MethodChannel(messenger, CHANNEL).setMethodCallHandler(
                BiometricCryptoChannel(activity),
            )
        }
    }

    @Volatile
    private var pendingKeyAlias: String? = null

    /** Authenticated Signature from CryptoObject; must be used for completeSign. */
    @Volatile
    private var pendingSignature: Signature? = null

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

            "authenticateForSigning" -> {
                val keyAlias = call.argument<String>("keyAlias")
                val reason = call.argument<String>("reason")
                    ?: "Authenticate to sign in"
                val preferredBiometric = call.argument<String>("preferredBiometric")
                if (keyAlias.isNullOrBlank()) {
                    result.error("invalid_args", "keyAlias is required", null)
                    return
                }
                authenticateForSigning(keyAlias, reason, preferredBiometric, result)
            }

            "completeSign" -> {
                val nonce = call.argument<String>("nonce")
                if (nonce.isNullOrBlank()) {
                    result.error("invalid_args", "nonce is required", null)
                    return
                }
                completeSign(nonce, result)
            }

            "cancelSigning" -> {
                clearPending()
                result.success(null)
            }

            "sign" -> {
                val keyAlias = call.argument<String>("keyAlias")
                val nonce = call.argument<String>("nonce")
                val reason = call.argument<String>("reason")
                    ?: "Authenticate to sign in"
                val preferredBiometric = call.argument<String>("preferredBiometric")
                if (keyAlias.isNullOrBlank() || nonce.isNullOrBlank()) {
                    result.error("invalid_args", "keyAlias and nonce are required", null)
                    return
                }
                authenticateForSigning(
                    keyAlias,
                    reason,
                    preferredBiometric,
                    object : MethodChannel.Result {
                        override fun success(resultData: Any?) {
                            completeSign(nonce, result)
                        }

                        override fun error(
                            errorCode: String,
                            errorMessage: String?,
                            errorDetails: Any?,
                        ) {
                            result.error(errorCode, errorMessage, errorDetails)
                        }

                        override fun notImplemented() {
                            result.notImplemented()
                        }
                    },
                )
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

        // Bind signing to biometric auth so CryptoObject can unlock the key.
        // BIOMETRIC_STRONG is required for CryptoObject on modern Android.
        val builder = KeyGenParameterSpec.Builder(
            keyAlias,
            KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY,
        )
            .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
            .setDigests(KeyProperties.DIGEST_SHA256)
            .setUserAuthenticationRequired(true)

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

    private fun authenticateForSigning(
        keyAlias: String,
        reason: String,
        preferredBiometric: String?,
        result: MethodChannel.Result,
    ) {
        clearPending()

        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        val entry = keyStore.getEntry(keyAlias, null) as? KeyStore.PrivateKeyEntry
        if (entry == null) {
            result.error("key_missing", "Biometric key was not found", null)
            return
        }

        val authenticators = BiometricManager.Authenticators.BIOMETRIC_STRONG
        val biometricManager = BiometricManager.from(activity)
        if (biometricManager.canAuthenticate(authenticators) != BiometricManager.BIOMETRIC_SUCCESS) {
            result.error(
                "biometric_unavailable",
                "Strong biometric authentication is unavailable",
                null,
            )
            return
        }

        val signature = try {
            Signature.getInstance(SIGNATURE_ALGORITHM).apply {
                initSign(entry.privateKey)
            }
        } catch (error: Exception) {
            Log.e(TAG, "initSign failed for $keyAlias", error)
            // Legacy / broken key — force a clean re-enroll.
            deleteKey(keyAlias)
            result.error(
                REENROLLMENT_REQUIRED,
                "Biometric login needs to be set up again on this device.",
                null,
            )
            return
        }

        val subtitle = when (preferredBiometric?.lowercase()) {
            "face" -> "Use Face unlock"
            "fingerprint" -> "Use fingerprint"
            else -> "Confirm with biometrics"
        }

        val executor = ContextCompat.getMainExecutor(activity)
        val prompt = BiometricPrompt(
            activity,
            executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(
                    authResult: BiometricPrompt.AuthenticationResult,
                ) {
                    val cryptoSignature = authResult.cryptoObject?.signature
                    if (cryptoSignature == null) {
                        clearPending()
                        result.error(
                            "auth_failed",
                            "Biometric crypto session was not established",
                            null,
                        )
                        return
                    }
                    pendingKeyAlias = keyAlias
                    pendingSignature = cryptoSignature
                    result.success(null)
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    clearPending()
                    result.error("auth_failed", errString.toString(), errorCode)
                }

                override fun onAuthenticationFailed() {
                    // Keep the prompt open for another attempt.
                }
            },
        )

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle(reason)
            .setSubtitle(subtitle)
            .setNegativeButtonText("Cancel")
            .setAllowedAuthenticators(authenticators)
            .build()

        activity.runOnUiThread {
            prompt.authenticate(promptInfo, BiometricPrompt.CryptoObject(signature))
        }
    }

    private fun completeSign(nonce: String, result: MethodChannel.Result) {
        val signature = pendingSignature
        val keyAlias = pendingKeyAlias
        if (signature == null || keyAlias.isNullOrBlank()) {
            clearPending()
            result.error(
                "auth_required",
                "Biometric authentication is required before signing",
                null,
            )
            return
        }

        try {
            signature.update(nonce.toByteArray(Charsets.UTF_8))
            val der = signature.sign()
            clearPending()
            result.success(
                mapOf(
                    "signatureBase64" to Base64.encodeToString(derToP1363(der), Base64.NO_WRAP),
                ),
            )
        } catch (error: Exception) {
            Log.e(TAG, "completeSign failed for $keyAlias", error)
            clearPending()
            val message = error.message.orEmpty()
            if (message.contains("Key user not authenticated", ignoreCase = true) ||
                message.contains("KEY_USER_NOT_AUTHENTICATED", ignoreCase = true) ||
                message.contains("-26")
            ) {
                deleteKey(keyAlias)
                result.error(
                    REENROLLMENT_REQUIRED,
                    "Biometric login needs to be set up again on this device.",
                    null,
                )
                return
            }
            result.error("sign_failed", error.message, null)
        }
    }

    private fun clearPending() {
        pendingKeyAlias = null
        pendingSignature = null
    }

    private fun deleteKey(keyAlias: String) {
        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        if (keyStore.containsAlias(keyAlias)) {
            keyStore.deleteEntry(keyAlias)
        }
    }

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
