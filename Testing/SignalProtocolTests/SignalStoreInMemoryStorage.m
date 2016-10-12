//
//  SignalStoreInMemoryStorage.m
//  SignalProtocolTests
//
//  Created by Chris Ballinger on 6/30/16.
//
//

#import "SignalStoreInMemoryStorage.h"

@interface SignalStoreInMemoryStorage ()
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString*,NSMutableDictionary*> *sessionStore;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSNumber*,NSData*> *preKeyStore;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSNumber*,NSData*> *signedPreKeyStore;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString*,NSData*> *identityKeyStore;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString*,NSData*> *senderKeyStore;
@end

@implementation SignalStoreInMemoryStorage

- (instancetype) init {
    if (self = [super init]) {
        _sessionStore = [[NSMutableDictionary alloc] init];
        _preKeyStore = [[NSMutableDictionary alloc] init];
        _signedPreKeyStore = [[NSMutableDictionary alloc] init];
        _identityKeyStore = [[NSMutableDictionary alloc] init];
        _senderKeyStore = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark SignalSessionStore

- (NSMutableDictionary<NSNumber*,NSData*>*)deviceSessionRecordsForAddressName:(NSString*)addressName {
    return [self.sessionStore objectForKey:addressName];
}

/**
 * Returns a copy of the serialized session record corresponding to the
 * provided recipient ID + device ID tuple.
 * or nil if not found.
 */
- (nullable NSData*) sessionRecordForAddress:(SignalAddress*)address {
    return [[self deviceSessionRecordsForAddressName:address.name] objectForKey:@(address.deviceId)];
}

/**
 * Commit to storage the session record for a given
 * recipient ID + device ID tuple.
 *
 * Return YES on success, NO on failure.
 */
- (BOOL) storeSessionRecord:(NSData*)recordData forAddress:(SignalAddress*)address {
    NSMutableDictionary *dict = @{@(address.deviceId):recordData}.mutableCopy;
    [self.sessionStore setObject:dict forKey:address.name];
    return YES;
}

/**
 * Determine whether there is a committed session record for a
 * recipient ID + device ID tuple.
 */
- (BOOL) sessionRecordExistsForAddress:(SignalAddress*)address {
    if ([self sessionRecordExistsForAddress:address]) {
        return YES;
    }
    return NO;
}

/**
 * Remove a session record for a recipient ID + device ID tuple.
 */
- (BOOL) deleteSessionRecordForAddress:(SignalAddress*)address {
    [[self deviceSessionRecordsForAddressName:address.name] removeObjectForKey:@(address.deviceId)];
    return YES;
}

/**
 * Returns all known devices with active sessions for a recipient
 */
- (NSArray<NSNumber*>*) allDeviceIdsForAddressName:(NSString*)addressName {
    return [[self deviceSessionRecordsForAddressName:addressName] allKeys];
}

/**
 * Remove the session records corresponding to all devices of a recipient ID.
 *
 * @return the number of deleted sessions on success, negative on failure
 */
- (int) deleteAllSessionsForAddressName:(NSString*)addressName {
    NSMutableDictionary *deviceSessionRecords = [self deviceSessionRecordsForAddressName:addressName];
    int count = (int)deviceSessionRecords.count;
    [deviceSessionRecords removeAllObjects];
    return count;
}

#pragma mark SignalPreKeyStore

/**
 * Load a local serialized PreKey record.
 * return nil if not found
 */
- (nullable NSData*) loadPreKeyWithId:(uint32_t)preKeyId {
    return [self.preKeyStore objectForKey:@(preKeyId)];
}

/**
 * Store a local serialized PreKey record.
 * return YES if storage successful, else NO
 */
- (BOOL) storePreKey:(NSData*)preKey preKeyId:(uint32_t)preKeyId {
    [self.preKeyStore setObject:preKey forKey:@(preKeyId)];
    return YES;
}

/**
 * Determine whether there is a committed PreKey record matching the
 * provided ID.
 */
- (BOOL) containsPreKeyWithId:(uint32_t)preKeyId {
    if ([self.preKeyStore objectForKey:@(preKeyId)]) {
        return YES;
    }
    return NO;
}

/**
 * Delete a PreKey record from local storage.
 */
- (BOOL) deletePreKeyWithId:(uint32_t)preKeyId {
    [self.preKeyStore removeObjectForKey:@(preKeyId)];
    return YES;
}

#pragma mark SignalSignedPreKeyStore

/**
 * Load a local serialized signed PreKey record.
 */
- (nullable NSData*) loadSignedPreKeyWithId:(uint32_t)signedPreKeyId {
    return [self.signedPreKeyStore objectForKey:@(signedPreKeyId)];
}

/**
 * Store a local serialized signed PreKey record.
 */
- (BOOL) storeSignedPreKey:(NSData*)signedPreKey signedPreKeyId:(uint32_t)signedPreKeyId {
    [self.signedPreKeyStore setObject:signedPreKey forKey:@(signedPreKeyId)];
    return YES;
}

/**
 * Determine whether there is a committed signed PreKey record matching
 * the provided ID.
 */
- (BOOL) containsSignedPreKeyWithId:(uint32_t)signedPreKeyId {
    if ([self.signedPreKeyStore objectForKey:@(signedPreKeyId)]) {
        return YES;
    }
    return NO;
}

/**
 * Delete a SignedPreKeyRecord from local storage.
 */
- (BOOL) removeSignedPreKeyWithId:(uint32_t)signedPreKeyId {
    [self.signedPreKeyStore removeObjectForKey:@(signedPreKeyId)];
    return YES;
}

#pragma mark SignalIdentityKeyStore


/**
 * Get the local client's identity key pair.
 */
- (SignalIdentityKeyPair*) getIdentityKeyPair {
    NSParameterAssert(self.identityKeyPair);
    return self.identityKeyPair;
}

/**
 * Return the local client's registration ID.
 *
 * Clients should maintain a registration ID, a random number
 * between 1 and 16380 that's generated once at install time.
 *
 * return negative on failure
 */
- (uint32_t) getLocalRegistrationId {
    return self.localRegistrationId;
}

/**
 * Save a remote client's identity key
 * <p>
 * Store a remote client's identity key as trusted.
 * The value of key_data may be null. In this case remove the key data
 * from the identity store, but retain any metadata that may be kept
 * alongside it.
 */
- (BOOL) saveIdentity:(SignalAddress*)address identityKey:(nullable NSData*)identityKey {
    [self.identityKeyStore setObject:identityKey forKey:address.name];
    return YES;
}

/**
 * Verify a remote client's identity key.
 *
 * Determine whether a remote client's identity is trusted.  Convention is
 * that the TextSecure protocol is 'trust on first use.'  This means that
 * an identity key is considered 'trusted' if there is no entry for the recipient
 * in the local store, or if it matches the saved key for a recipient in the local
 * store.  Only if it mismatches an entry in the local store is it considered
 * 'untrusted.'
 */
- (BOOL) isTrustedIdentity:(SignalAddress*)address identityKey:(NSData*)identityKey {
    NSData *existingKey = [self.identityKeyStore objectForKey:address.name];
    if (!existingKey) { return YES; }
    if ([existingKey isEqualToData:identityKey]) {
        return YES;
    }
    return NO;
}

#pragma mark SignalSenderKeyStore

- (NSString*)keyForAddress:(SignalAddress*)address groupId:(NSString*)groupId {
    return [NSString stringWithFormat:@"%@%d%@", address.name, address.deviceId, groupId];
}

/**
 * Store a serialized sender key record for a given
 * (groupId + senderId + deviceId) tuple.
 */
- (BOOL) storeSenderKey:(NSData*)senderKey address:(SignalAddress*)address groupId:(NSString*)groupId {
    NSString *key = [self keyForAddress:address groupId:groupId];
    [self.senderKeyStore setObject:senderKey forKey:key];
    return YES;
}

/**
 * Returns a copy of the sender key record corresponding to the
 * (groupId + senderId + deviceId) tuple.
 */
- (nullable NSData*) loadSenderKeyForAddress:(SignalAddress*)address groupId:(NSString*)groupId {
    NSString *key = [self keyForAddress:address groupId:groupId];
    return [self.senderKeyStore objectForKey:key];
}


@end
