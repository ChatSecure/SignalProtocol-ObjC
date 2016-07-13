//
//  SignalCommonCryptoProvider.m
//  Pods
//
//  Created by Chris Ballinger on 6/27/16.
//
//

#import "SignalCommonCryptoProvider.h"
#import <CommonCrypto/CommonCrypto.h>
#import <CommonCrypto/CommonRandom.h>

static int random_func(uint8_t *data, size_t len, void *user_data) {
    CCRNGStatus result = CCRandomGenerateBytes(data, len);
    if (result != kCCSuccess) {
        return -1;
    }
    return 0;
}

static int hmac_sha256_init_func(void **hmac_context, const uint8_t *key, size_t key_len, void *user_data) {
    CCHmacContext *context = malloc(sizeof(CCHmacContext));
    CCHmacInit(context, kCCHmacAlgSHA256, key, key_len);
    *hmac_context = context;
    return 0;
}

static int hmac_sha256_update_func(void *hmac_context, const uint8_t *data, size_t data_len, void *user_data) {
    CCHmacUpdate(hmac_context, data, data_len);
    return 0;
}

static int hmac_sha256_final_func(void *hmac_context, signal_buffer **output, void *user_data) {
    NSMutableData *mutableData = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CCHmacFinal(hmac_context, mutableData.mutableBytes);
    signal_buffer *macOut = signal_buffer_create(mutableData.bytes, mutableData.length);
    *output = macOut;
    return 0;
}

static void hmac_sha256_cleanup_func(void *hmac_context, void *user_data) {
    if (hmac_context) {
        free(hmac_context);
    }
}

static int sha512_digest_func(signal_buffer **output, const uint8_t *data, size_t data_len, void *user_data) {
    NSMutableData *mutableData = [NSMutableData dataWithLength:CC_SHA512_DIGEST_LENGTH];
    CC_SHA512(data, (CC_LONG)data_len, mutableData.mutableBytes);
    signal_buffer *digestOut = signal_buffer_create(mutableData.bytes, mutableData.length);
    *output = digestOut;
    return 0;
}

/**
 * Callback for an AES encryption implementation.
 *
 * @param output buffer to be allocated and populated with the ciphertext
 * @param cipher specific cipher variant to use, either SG_CIPHER_AES_CTR_NOPADDING or SG_CIPHER_AES_CBC_PKCS5
 * @param key the encryption key
 * @param key_len length of the encryption key
 * @param iv the initialization vector
 * @param iv_len length of the initialization vector
 * @param plaintext the plaintext to encrypt
 * @param plaintext_len length of the plaintext
 * @return 0 on success, negative on failure
 */
static int encrypt_func(signal_buffer **output,
                           int cipher,
                           const uint8_t *key, size_t key_len,
                           const uint8_t *iv, size_t iv_len,
                           const uint8_t *plaintext, size_t plaintext_len,
                           void *user_data) {
    // We only support Version 3
    if (cipher != SG_CIPHER_AES_CBC_PKCS5) {
        return -1;
    }
    
    size_t outLength;
    NSMutableData *
    cipherData = [NSMutableData dataWithLength:plaintext_len +
                  kCCBlockSizeAES128];
    
    CCCryptorStatus
    result = CCCrypt(kCCEncrypt, // operation
                     kCCAlgorithmAES, // Algorithm
                     kCCOptionPKCS7Padding, // options
                     key, // key
                     key_len, // keylength
                     iv,// iv
                     plaintext, // dataIn
                     plaintext_len, // dataInLength,
                     cipherData.mutableBytes, // dataOut
                     cipherData.length, // dataOutAvailable
                     &outLength); // dataOutMoved
    
    if (result == kCCSuccess) {
        cipherData.length = outLength;
    }
    else {
        return -1;
    }
    signal_buffer *outputBuffer = signal_buffer_create(cipherData.bytes, cipherData.length);
    *output = outputBuffer;
    return 0;
}

/**
 * Callback for an AES decryption implementation.
 *
 * @param output buffer to be allocated and populated with the plaintext
 * @param cipher specific cipher variant to use, either SG_CIPHER_AES_CTR_NOPADDING or SG_CIPHER_AES_CBC_PKCS5
 * @param key the encryption key
 * @param key_len length of the encryption key
 * @param iv the initialization vector
 * @param iv_len length of the initialization vector
 * @param ciphertext the ciphertext to decrypt
 * @param ciphertext_len length of the ciphertext
 * @return 0 on success, negative on failure
 */
static int decrypt_func(signal_buffer **output,
                    int cipher,
                    const uint8_t *key, size_t key_len,
                    const uint8_t *iv, size_t iv_len,
                    const uint8_t *ciphertext, size_t ciphertext_len,
                    void *user_data) {
    // We only support Version 3
    if (cipher != SG_CIPHER_AES_CBC_PKCS5) {
        return -1;
    }
    
    size_t outLength;
    NSMutableData *
    outData = [NSMutableData dataWithLength:ciphertext_len +
                  kCCBlockSizeAES128];
    
    CCCryptorStatus
    result = CCCrypt(kCCDecrypt, // operation
                     kCCAlgorithmAES, // Algorithm
                     kCCOptionPKCS7Padding, // options
                     key, // key
                     key_len, // keylength
                     iv,// iv
                     ciphertext, // dataIn
                     ciphertext_len, // dataInLength,
                     outData.mutableBytes, // dataOut
                     outData.length, // dataOutAvailable
                     &outLength); // dataOutMoved
    
    if (result == kCCSuccess) {
        outData.length = outLength;
    }
    else {
        return -1;
    }
    signal_buffer *outputBuffer = signal_buffer_create(outData.bytes, outData.length);
    *output = outputBuffer;
    return 0;
}

@implementation SignalCommonCryptoProvider

- (signal_crypto_provider) cryptoProvider {
    signal_crypto_provider cryptoProvider;
    cryptoProvider.random_func = random_func;
    cryptoProvider.hmac_sha256_init_func = hmac_sha256_init_func;
    cryptoProvider.hmac_sha256_update_func = hmac_sha256_update_func;
    cryptoProvider.hmac_sha256_final_func = hmac_sha256_final_func;
    cryptoProvider.hmac_sha256_cleanup_func = hmac_sha256_cleanup_func;
    cryptoProvider.sha512_digest_func = sha512_digest_func;
    cryptoProvider.encrypt_func = encrypt_func;
    cryptoProvider.decrypt_func = decrypt_func;
    cryptoProvider.user_data = (__bridge void *)(self);
    return cryptoProvider;
}
@end