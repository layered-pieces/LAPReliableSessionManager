//
//  LAPReliableSessionManager.m
//  LAPReliableSessionManager
//
//  Created by Oliver Letterer on 08.11.18.
//

#import "LAPReliableSessionManager.h"

@interface LAPReliableSessionManager ()

@property (nonatomic, readonly) NSURL *dataPackagesURL;
@property (nonatomic, readonly) NSArray<NSURL *> *sortedPackageURLs;

@property (nonatomic, readonly) id<LAPWebServiceReachabilityManagerToken> token;
@property (nonatomic, readonly) dispatch_source_t timer;

@property (nonatomic, nullable) NSURLRequest *transmittingRequest;
@property (nonatomic, readonly) NSMutableDictionary<NSURLRequest *, void(^)(NSURLRequest *request, NSURLResponse *response, NSError *error)> *completionLookup;

@end

@implementation LAPReliableSessionManager

#pragma mark - setters and getters

- (NSInteger)pendingPackageCount
{
    return [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.dataPackagesURL.path error:NULL].count;
}

- (NSArray<NSURL *> *)sortedPackageURLs
{
    NSArray<NSURL *> *sortedPackageURLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:self.dataPackagesURL includingPropertiesForKeys:nil options:kNilOptions error:NULL];
    return [sortedPackageURLs sortedArrayUsingComparator:^NSComparisonResult(NSURL *_Nonnull file1, NSURL *_Nonnull file2) {
        double name1 = file1.lastPathComponent.doubleValue;
        double name2 = file2.lastPathComponent.doubleValue;

        if (name1 < name2) {
            return NSOrderedAscending;
        } else if (name1 > name2) {
            return NSOrderedDescending;
        }

        return NSOrderedSame;
    }];
}

#pragma mark - initialisation

- (instancetype)initWithService:(NSString *)service sessionManager:(AFHTTPSessionManager *)sessionManager reachabilityManager:(LAPWebServiceReachabilityManager *)reachabilityManager
{
    if (self = [super init]) {
        _service = service;
        _sessionManager = sessionManager;
        _reachabilityManager = reachabilityManager;

        _acceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 200)];

        _completionLookup = [NSMutableDictionary dictionary];

        NSURL *dataPackagesURL = [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask].firstObject URLByAppendingPathComponent:service];
        if (![[NSFileManager defaultManager] fileExistsAtPath:dataPackagesURL.path isDirectory:NULL]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:dataPackagesURL.path withIntermediateDirectories:YES attributes:nil error:NULL];
        }

        _dataPackagesURL = dataPackagesURL;

        __weak typeof(self) welf = self;
        _token = [_reachabilityManager addStatusObserver:^(LAPWebServiceReachabilityManager * _Nonnull manager, LAPWebServiceReachabilityStatus status) {
            [welf _tryToSendNextDataPackage];
        }];

        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(_timer, dispatch_time(DISPATCH_TIME_NOW, 60.0 * NSEC_PER_SEC), 60.0 * NSEC_PER_SEC, (1ull * NSEC_PER_SEC) / 10);
        dispatch_source_set_event_handler(_timer, ^{
            [welf _tryToSendNextDataPackage];
        });
        dispatch_resume(_timer);
    }
    return self;
}

- (void)dealloc
{
    dispatch_source_cancel(self.timer);
    [self.reachabilityManager removeStatusObserver:self.token];
}

#pragma mark - instance methods

- (void)savePackage:(NSURLRequest *)urlRequest completion:(void (^)(NSURLRequest * _Nonnull, NSURLResponse * _Nullable, NSError * _Nullable))completion
{
    [self willChangeValueForKey:@"pendingPackageCount"];

    NSString *name = [NSString stringWithFormat:@"%lf", [NSDate date].timeIntervalSince1970];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:urlRequest];
    [data writeToURL:[self.dataPackagesURL URLByAppendingPathComponent:name] atomically:YES];

    [self didChangeValueForKey:@"pendingPackageCount"];

    if (completion != nil) {
        self.completionLookup[urlRequest] = completion;
    }

    [self _tryToSendNextDataPackage];
}

- (void)enumeratePackages:(void (^)(NSURLRequest * _Nonnull, BOOL * _Nonnull))enumerator
{
    [self.sortedPackageURLs enumerateObjectsUsingBlock:^(NSURL * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSURLRequest *request = [NSKeyedUnarchiver unarchiveObjectWithFile:obj.path];

        if (request != nil) {
            enumerator(request, stop);
        }
    }];
}

#pragma mark - convenient methods

- (NSMutableURLRequest *)GET:(NSString *)URLString parameters:(id)parameters
{
    NSString *url = [[NSURL URLWithString:URLString relativeToURL:self.sessionManager.baseURL] absoluteString];

    NSError *serializationError = nil;
    NSMutableURLRequest *request = [self.sessionManager.requestSerializer requestWithMethod:@"GET" URLString:url parameters:parameters error:&serializationError];

    assert(serializationError == nil);
    return request;
}

- (NSMutableURLRequest *)HEAD:(NSString *)URLString parameters:(id)parameters
{
    NSString *url = [[NSURL URLWithString:URLString relativeToURL:self.sessionManager.baseURL] absoluteString];

    NSError *serializationError = nil;
    NSMutableURLRequest *request = [self.sessionManager.requestSerializer requestWithMethod:@"HEAD" URLString:url parameters:parameters error:&serializationError];

    assert(serializationError == nil);
    return request;
}

- (NSMutableURLRequest *)POST:(NSString *)URLString parameters:(id)parameters
{
    NSString *url = [[NSURL URLWithString:URLString relativeToURL:self.sessionManager.baseURL] absoluteString];

    NSError *serializationError = nil;
    NSMutableURLRequest *request = [self.sessionManager.requestSerializer requestWithMethod:@"POST" URLString:url parameters:parameters error:&serializationError];

    assert(serializationError == nil);
    return request;
}

- (NSMutableURLRequest *)POST:(NSString *)URLString parameters:(id)parameters constructingBodyWithBlock:(void (^)(id<AFMultipartFormData> formData))block
{
    NSString *url = [[NSURL URLWithString:URLString relativeToURL:self.sessionManager.baseURL] absoluteString];

    NSError *serializationError = nil;
    NSMutableURLRequest *request = [self.sessionManager.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:url parameters:parameters constructingBodyWithBlock:block error:&serializationError];

    assert(serializationError == nil);
    return request;
}

- (NSMutableURLRequest *)PUT:(NSString *)URLString parameters:(id)parameters
{
    NSString *url = [[NSURL URLWithString:URLString relativeToURL:self.sessionManager.baseURL] absoluteString];

    NSError *serializationError = nil;
    NSMutableURLRequest *request = [self.sessionManager.requestSerializer requestWithMethod:@"PUT" URLString:url parameters:parameters error:&serializationError];

    assert(serializationError == nil);
    return request;
}

- (NSMutableURLRequest *)PATCH:(NSString *)URLString parameters:(id)parameters
{
    NSString *url = [[NSURL URLWithString:URLString relativeToURL:self.sessionManager.baseURL] absoluteString];

    NSError *serializationError = nil;
    NSMutableURLRequest *request = [self.sessionManager.requestSerializer requestWithMethod:@"PATCH" URLString:url parameters:parameters error:&serializationError];

    assert(serializationError == nil);
    return request;
}

- (NSMutableURLRequest *)DELETE:(NSString *)URLString parameters:(id)parameters
{
    NSString *url = [[NSURL URLWithString:URLString relativeToURL:self.sessionManager.baseURL] absoluteString];

    NSError *serializationError = nil;
    NSMutableURLRequest *request = [self.sessionManager.requestSerializer requestWithMethod:@"DELETE" URLString:url parameters:parameters error:&serializationError];

    assert(serializationError == nil);
    return request;
}

#pragma mark - private category implementation ()

- (void)_tryToSendNextDataPackage
{
    if (self.reachabilityManager.status != LAPWebServiceReachabilityStatusReachable) {
        return;
    }

    if (self.transmittingRequest != nil) {
        return;
    }

    NSURL *nextURL = self.sortedPackageURLs.firstObject;
    if (nextURL == nil) {
        return;
    }

    NSURLRequest *nextRequest = [NSKeyedUnarchiver unarchiveObjectWithFile:nextURL.path];
    self.transmittingRequest = nextRequest;

    NSMutableURLRequest *request = nextRequest.mutableCopy;

    if (self.authorizationHeader != nil) {
        [request setValue:self.authorizationHeader forHTTPHeaderField:@"Authorization"];
    }

    NSURLSessionDataTask *dataTask = [self.sessionManager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

        if (self.completionLookup[nextRequest] != nil) {
            void(^completion)(NSURLRequest *request, NSURLResponse *response, NSError *error) = self.completionLookup[nextRequest];
            completion(request, httpResponse, error);

            [self.completionLookup removeObjectForKey:nextRequest];
        }

        self.transmittingRequest = nil;

        if (error == nil || [self.acceptableStatusCodes containsIndex:httpResponse.statusCode]) {
            [self willChangeValueForKey:@"pendingPackageCount"];
            [[NSFileManager defaultManager] removeItemAtURL:nextURL error:NULL];
            [self didChangeValueForKey:@"pendingPackageCount"];

            [self _tryToSendNextDataPackage];
        }
    }];

    [dataTask resume];
}

@end
