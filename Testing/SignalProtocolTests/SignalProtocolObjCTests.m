//
//  SignalProtocolObjCTests.m
//  SignalProtocolTests
//
//  Created by Chris Ballinger on 6/30/16.
//
//

#import <XCTest/XCTest.h>
@import SignalProtocolObjC;
#import "SignalStoreInMemoryStorage.h"

@interface SignalProtocolObjCTests : XCTestCase

@end

@implementation SignalProtocolObjCTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExchange {
    SignalAddress *aliceAddress = [[SignalAddress alloc] initWithName:@"alice" deviceId:12355];
    SignalAddress *bobAddress = [[SignalAddress alloc] initWithName:@"bob" deviceId:12351];

    SignalStoreInMemoryStorage *inMemoryStore = [[SignalStoreInMemoryStorage alloc] init];
    SignalStorage *storage = [[SignalStorage alloc] initWithSignalStore:inMemoryStore];
    XCTAssertNotNil(storage);
    SignalContext *context = [[SignalContext alloc] initWithStorage:storage];
    XCTAssertNotNil(context);
    SignalKeyHelper *keyHelper = [[SignalKeyHelper alloc] initWithContext:context];
    XCTAssertNotNil(keyHelper);
    SignalIdentityKeyPair *identityKeyPair = [keyHelper generateIdentityKeyPair];
    XCTAssertNotNil(identityKeyPair);
    uint32_t localRegistrationId = [keyHelper generateRegistrationId];
    inMemoryStore.identityKeyPair = identityKeyPair;
    inMemoryStore.localRegistrationId = localRegistrationId;
    NSArray<SignalPreKey*>*preKeys = [keyHelper generatePreKeysWithStartingPreKeyId:0 count:100];
    XCTAssert(preKeys.count == 100);
    SignalSignedPreKey *signedPreKey = [keyHelper generateSignedPreKeyWithIdentity:identityKeyPair signedPreKeyId:0];
    XCTAssertNotNil(signedPreKey);
    
    SignalPreKey *preKey1 = [preKeys firstObject];
    [inMemoryStore storePreKey:preKey1.serializedData preKeyId:preKey1.preKeyId];
    [inMemoryStore storeSignedPreKey:signedPreKey.serializedData signedPreKeyId:signedPreKey.preKeyId];
    
    NSError *error = nil;
    SignalPreKeyBundle *alicePreKeyBundle = [[SignalPreKeyBundle alloc] initWithRegistrationId:localRegistrationId deviceId:aliceAddress.deviceId preKeyId:preKey1.preKeyId preKeyPublic:preKey1.keyPair.publicKey signedPreKeyId:signedPreKey.preKeyId signedPreKeyPublic:signedPreKey.keyPair.publicKey signature:signedPreKey.signature identityKey:identityKeyPair.publicKey error:&error];
    
    XCTAssertNil(error);
    XCTAssertNotNil(alicePreKeyBundle);
    
    SignalStoreInMemoryStorage *bobInMemoryStore = [[SignalStoreInMemoryStorage alloc] init];
    SignalStorage *bobStorage = [[SignalStorage alloc] initWithSignalStore:bobInMemoryStore];
    SignalContext *bobContext = [[SignalContext alloc] initWithStorage:bobStorage];
    SignalKeyHelper *bobKeyHelper = [[SignalKeyHelper alloc] initWithContext:bobContext];
    SignalIdentityKeyPair *bobIdentityKeyPair = [bobKeyHelper generateIdentityKeyPair];
    uint32_t bobLocalRegistrationId = [bobKeyHelper generateRegistrationId];
    bobInMemoryStore.identityKeyPair = bobIdentityKeyPair;
    bobInMemoryStore.localRegistrationId = bobLocalRegistrationId;
    NSArray<SignalPreKey*>*bobPreKeys = [bobKeyHelper generatePreKeysWithStartingPreKeyId:0 count:100];
    SignalSignedPreKey *bobSignedPreKey = [bobKeyHelper generateSignedPreKeyWithIdentity:bobIdentityKeyPair signedPreKeyId:0];
    
    SignalPreKey *bobPreKey1 = [bobPreKeys firstObject];
    SignalPreKeyBundle *bobPreKeyBundle = [[SignalPreKeyBundle alloc] initWithRegistrationId:bobLocalRegistrationId deviceId:bobAddress.deviceId preKeyId:bobPreKey1.preKeyId preKeyPublic:bobPreKey1.keyPair.publicKey signedPreKeyId:bobSignedPreKey.preKeyId signedPreKeyPublic:bobSignedPreKey.keyPair.publicKey signature:bobSignedPreKey.signature identityKey:bobIdentityKeyPair.publicKey error:&error];
    XCTAssertNotNil(bobPreKeyBundle);
    XCTAssertNil(error);
    
    SignalSessionBuilder *bobSessionBuilder = [[SignalSessionBuilder alloc] initWithAddress:aliceAddress context:bobContext];
    BOOL result = [bobSessionBuilder processPreKeyBundle:alicePreKeyBundle error:&error];
    XCTAssertTrue(result);
    XCTAssertNil(error);
    SignalSessionCipher *bobSessionCipher = [[SignalSessionCipher alloc] initWithAddress:aliceAddress context:bobContext];
    
    error = nil;
    NSString *bobMessage = @"Hey it's Bob";
    NSData *bobMessageData = [bobMessage dataUsingEncoding:NSUTF8StringEncoding];
    SignalCiphertext *bobOut = [bobSessionCipher encryptData:bobMessageData error:&error];
    XCTAssertNil(error, @"error encrypting data: %@", error);
    
    
    //SignalSessionBuilder *aliceSessionBuilder = [[SignalSessionBuilder alloc] initWithAddress:bobAddress context:context];
    //SignalPreKeyMessage *bobPreKeyMessage = [[SignalPreKeyMessage alloc] initWithData:bobOut.data context:context error:&error];
    //XCTAssertNil(error, @"error parsing prekeymessage: %@", error);
    //[aliceSessionBuilder processPreKeyMessage:bobPreKeyMessage];
    SignalSessionCipher *aliceSessionCipher = [[SignalSessionCipher alloc] initWithAddress:bobAddress context:context];
    NSData *decryptedBobMessage = [aliceSessionCipher decryptCiphertext:bobOut error:&error];
    NSString *decryptedBobString = [[NSString alloc] initWithData:decryptedBobMessage encoding:NSUTF8StringEncoding];
    
    XCTAssertNil(error, @"error decrypting data: %@", error);
    XCTAssertEqualObjects(decryptedBobMessage, bobMessageData);
    
    NSLog(@"bob encrypted: %@", bobMessage);
    NSLog(@"alice decrypted: %@", decryptedBobString);
}


@end
