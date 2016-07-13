//
//  SignalStoreInMemoryStorage.h
//  SignalProtocolTests
//
//  Created by Chris Ballinger on 6/30/16.
//
//

#import <Foundation/Foundation.h>
@import SignalProtocolObjC;

@interface SignalStoreInMemoryStorage : NSObject <SignalStore>

@property (nonatomic, strong) SignalIdentityKeyPair *identityKeyPair;
@property (nonatomic) uint32_t localRegistrationId;

@end
