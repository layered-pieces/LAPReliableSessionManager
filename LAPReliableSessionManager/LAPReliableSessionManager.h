//
//  LAPReliableSessionManager.h
//  LAPReliableSessionManager
//
//  Created by Oliver Letterer on 08.11.18.
//

#import <Foundation/Foundation.h>

#import <AFNetworking/AFNetworking.h>
#import <LAPWebServiceReachabilityManager/LAPWebServiceReachabilityManager.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_subclassing_restricted))
@interface LAPReliableSessionManager : NSObject

@property (nonatomic, readonly) NSString *service;
@property (nonatomic, readonly) AFHTTPSessionManager *sessionManager;
@property (nonatomic, readonly) LAPWebServiceReachabilityManager *reachabilityManager;

@property (nonatomic, nullable) NSString *authorizationHeader;

@property (nonatomic, strong) NSIndexSet *acceptableStatusCodes;

- (instancetype)init NS_DESIGNATED_INITIALIZER NS_UNAVAILABLE;
- (instancetype)initWithService:(NSString *)service sessionManager:(AFHTTPSessionManager *)sessionManager reachabilityManager:(LAPWebServiceReachabilityManager *)reachabilityManager NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly) NSInteger pendingPackageCount;

- (void)savePackage:(NSURLRequest *)urlRequest completion:(void(^ _Nullable)(NSURLRequest *request, NSURLResponse * _Nullable response, NSError * _Nullable error))completion;
- (void)enumeratePackages:(void(^)(NSURLRequest *request, BOOL *stop))enumerator;

- (NSMutableURLRequest *)GET:(NSString *)URLString parameters:(nullable id)parameters;
- (NSMutableURLRequest *)HEAD:(NSString *)URLString parameters:(nullable id)parameters;
- (NSMutableURLRequest *)POST:(NSString *)URLString parameters:(nullable id)parameters;
- (NSMutableURLRequest *)POST:(NSString *)URLString parameters:(nullable id)parameters constructingBodyWithBlock:(void (^)(id<AFMultipartFormData> formData))block;
- (NSMutableURLRequest *)PUT:(NSString *)URLString parameters:(nullable id)parameters;
- (NSMutableURLRequest *)PATCH:(NSString *)URLString parameters:(nullable id)parameters;
- (NSMutableURLRequest *)DELETE:(NSString *)URLString parameters:(nullable id)parameters;

@end

NS_ASSUME_NONNULL_END
