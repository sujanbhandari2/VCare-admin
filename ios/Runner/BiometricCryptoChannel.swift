import Foundation
import LocalAuthentication
import Security
import Flutter

/// MethodChannel bridge for non-exportable EC P-256 keys in the Secure Enclave,
/// with biometric-gated ECDSA SHA-256 signing (IEEE P1363 / raw r||s).
enum BiometricCryptoChannel {
  static let name = "com.vcare.admin/biometric_crypto"

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "generateKeyPair":
        guard
          let args = call.arguments as? [String: Any],
          let keyAlias = args["keyAlias"] as? String,
          !keyAlias.isEmpty
        else {
          result(
            FlutterError(
              code: "invalid_args",
              message: "keyAlias is required",
              details: nil
            )
          )
          return
        }
        do {
          result(try generateKeyPair(keyAlias: keyAlias))
        } catch {
          result(
            FlutterError(
              code: "generate_failed",
              message: error.localizedDescription,
              details: nil
            )
          )
        }

      case "sign":
        guard
          let args = call.arguments as? [String: Any],
          let keyAlias = args["keyAlias"] as? String,
          let nonce = args["nonce"] as? String,
          !keyAlias.isEmpty,
          !nonce.isEmpty
        else {
          result(
            FlutterError(
              code: "invalid_args",
              message: "keyAlias and nonce are required",
              details: nil
            )
          )
          return
        }
        let reason = (args["reason"] as? String)?
          .trimmingCharacters(in: .whitespacesAndNewlines)
        let prompt = (reason?.isEmpty == false)
          ? reason!
          : "Authenticate to sign in"
        do {
          let signature = try sign(
            keyAlias: keyAlias,
            nonce: nonce,
            reason: prompt
          )
          result(["signatureBase64": signature])
        } catch {
          result(
            FlutterError(
              code: "sign_failed",
              message: error.localizedDescription,
              details: nil
            )
          )
        }

      case "deleteKey":
        guard
          let args = call.arguments as? [String: Any],
          let keyAlias = args["keyAlias"] as? String,
          !keyAlias.isEmpty
        else {
          result(
            FlutterError(
              code: "invalid_args",
              message: "keyAlias is required",
              details: nil
            )
          )
          return
        }
        deleteKey(keyAlias: keyAlias)
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func tagData(for keyAlias: String) -> Data {
    Data("com.vcare.admin.biometric.\(keyAlias)".utf8)
  }

  private static func generateKeyPair(keyAlias: String) throws -> [String: String] {
    deleteKey(keyAlias: keyAlias)

    var error: Unmanaged<CFError>?
    guard let access = SecAccessControlCreateWithFlags(
      nil,
      kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
      [.privateKeyUsage, .biometryCurrentSet],
      &error
    ) else {
      throw error!.takeRetainedValue() as Error
    }

    let tag = tagData(for: keyAlias)
    let attributes: [String: Any] = [
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecAttrKeySizeInBits as String: 256,
      kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
      kSecPrivateKeyAttrs as String: [
        kSecAttrIsPermanent as String: true,
        kSecAttrApplicationTag as String: tag,
        kSecAttrAccessControl as String: access,
      ],
    ]

    guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
      throw error!.takeRetainedValue() as Error
    }

    guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
      throw NSError(
        domain: "BiometricCrypto",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Unable to export public key"]
      )
    }

    guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
      throw error!.takeRetainedValue() as Error
    }

    let spki = encodeSpki(uncompressedPoint: publicKeyData)
    return [
      "keyAlias": keyAlias,
      "publicKeyBase64": spki.base64EncodedString(),
    ]
  }

  private static func sign(keyAlias: String, nonce: String, reason: String) throws -> String {
    guard let privateKey = loadPrivateKey(keyAlias: keyAlias) else {
      throw NSError(
        domain: "BiometricCrypto",
        code: 2,
        userInfo: [NSLocalizedDescriptionKey: "Biometric key was not found"]
      )
    }

    let context = LAContext()
    context.localizedReason = reason

    var authError: NSError?
    guard context.canEvaluatePolicy(
      .deviceOwnerAuthenticationWithBiometrics,
      error: &authError
    ) else {
      throw authError
        ?? NSError(
          domain: "BiometricCrypto",
          code: 3,
          userInfo: [NSLocalizedDescriptionKey: "Biometric authentication is unavailable"]
        )
    }

    let algorithm = SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256
    guard SecKeyIsAlgorithmSupported(privateKey, .sign, algorithm) else {
      throw NSError(
        domain: "BiometricCrypto",
        code: 4,
        userInfo: [NSLocalizedDescriptionKey: "Signing algorithm is unsupported"]
      )
    }

    let nonceData = Data(nonce.utf8)
    var signError: Unmanaged<CFError>?
    guard let derSignature = SecKeyCreateSignature(
      privateKey,
      algorithm,
      nonceData as CFData,
      &signError
    ) as Data? else {
      throw signError!.takeRetainedValue() as Error
    }

    let raw = try derToP1363(derSignature)
    return raw.base64EncodedString()
  }

  private static func loadPrivateKey(keyAlias: String) -> SecKey? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassKey,
      kSecAttrApplicationTag as String: tagData(for: keyAlias),
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecReturnRef as String: true,
    ]

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard status == errSecSuccess else {
      return nil
    }
    return (item as! SecKey)
  }

  private static func deleteKey(keyAlias: String) {
    let query: [String: Any] = [
      kSecClass as String: kSecClassKey,
      kSecAttrApplicationTag as String: tagData(for: keyAlias),
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
    ]
    SecItemDelete(query as CFDictionary)
  }

  /// Wraps an uncompressed EC point (0x04||X||Y) in SubjectPublicKeyInfo for P-256.
  private static func encodeSpki(uncompressedPoint: Data) -> Data {
    let algorithmIdentifier: [UInt8] = [
      0x30, 0x13,
      0x06, 0x07, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02, 0x01,
      0x06, 0x08, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x03, 0x01, 0x07,
    ]
    var bitString = Data([0x03, 0x42, 0x00])
    bitString.append(uncompressedPoint)

    var sequence = Data([0x30, 0x59])
    sequence.append(contentsOf: algorithmIdentifier)
    sequence.append(bitString)
    return sequence
  }

  private static func derToP1363(_ der: Data) throws -> Data {
    var offset = 0
    func readByte() throws -> UInt8 {
      guard offset < der.count else {
        throw NSError(
          domain: "BiometricCrypto",
          code: 5,
          userInfo: [NSLocalizedDescriptionKey: "Invalid DER signature"]
        )
      }
      let value = der[offset]
      offset += 1
      return value
    }

    guard try readByte() == 0x30 else {
      throw NSError(
        domain: "BiometricCrypto",
        code: 5,
        userInfo: [NSLocalizedDescriptionKey: "Invalid DER signature"]
      )
    }

    let seqLen = try readByte()
    if seqLen & 0x80 != 0 {
      let lenBytes = Int(seqLen & 0x7F)
      offset += lenBytes
    }

    func readInteger() throws -> Data {
      guard try readByte() == 0x02 else {
        throw NSError(
          domain: "BiometricCrypto",
          code: 5,
          userInfo: [NSLocalizedDescriptionKey: "Invalid DER signature"]
        )
      }
      let length = Int(try readByte())
      guard offset + length <= der.count else {
        throw NSError(
          domain: "BiometricCrypto",
          code: 5,
          userInfo: [NSLocalizedDescriptionKey: "Invalid DER signature"]
        )
      }
      let value = der.subdata(in: offset..<(offset + length))
      offset += length
      return fixed32(value)
    }

    var raw = Data()
    raw.append(try readInteger())
    raw.append(try readInteger())
    return raw
  }

  private static func fixed32(_ value: Data) -> Data {
    var bytes = [UInt8](value)
    while bytes.count > 32 {
      bytes.removeFirst()
    }
    if bytes.count < 32 {
      bytes = Array(repeating: 0, count: 32 - bytes.count) + bytes
    }
    return Data(bytes)
  }
}
