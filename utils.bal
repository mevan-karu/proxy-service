import proxy_service.com.cossacklabs.themis;
import ballerina/lang.array;

public function encryptData(byte[] dataToBeEncrypted, string encodedPublicKey) returns byte[]|error {
    themis:PrivateKey privateKey = check themis:newPrivateKey1(check array:fromBase64(encodedServerPrivateKey));
    themis:PublicKey publicKey = check themis:newPublicKey1(check array:fromBase64(encodedPublicKey));
    themis:SecureMessage secureMessage = themis:newSecureMessage2(privateKey, publicKey);
    return secureMessage.wrap(dataToBeEncrypted);
}

public function decryptData(byte[] dataToBeDecrypted, string encodedPublicKey) returns byte[]|error {
    themis:PrivateKey privateKey = check themis:newPrivateKey1(check array:fromBase64(encodedServerPrivateKey));
    themis:PublicKey publicKey = check themis:newPublicKey1(check array:fromBase64(encodedPublicKey));
    themis:SecureMessage secureMessage = themis:newSecureMessage2(privateKey, publicKey);
    return secureMessage.unwrap(dataToBeDecrypted);
}

public function maskData(MaskingConfig[] maskingConfig, json responsePayload) returns json|error? {
    map<json> payload = check responsePayload.fromJsonWithType();
    foreach MaskingConfig config in maskingConfig {
        if payload[config.fieldName] is string {
            string filedValue = <string>payload[config.fieldName];
            payload[config.fieldName] = re `${config.maskingRegex}`.replace(filedValue, config.maskingString);
        }
    }
    return payload.toJson();
}
