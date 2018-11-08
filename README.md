# LAPReliableSessionManager

If you want to send data packages to a web service in a reliable way, with guaranteed delivery. LAPReliableSessionManager builds on top of [AFNetworking](https://github.com/AFNetworking/AFNetworking) and [LAPWebServiceReachabilityManager](https://github.com/layered-pieces/LAPWebServiceReachabilityManager). It first saves data packages to disk and then synchronizes them in a FIFO manner, one at a time.

## Installation

LAPReliableSessionManager is available through [CocoaPods](https://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod "LAPReliableSessionManager"
```

## Usage

```objc
LAPWebServiceReachabilityManager *reachabilityManager = ...;
AFHTTPSessionManager *sessionManager = ...;

LAPReliableSessionManager *offlineStorage = [[LAPReliableSessionManager alloc] initWithService:@"de.layered-pieces.offline-storage" sessionManager:sessionManager reachabilityManager:reachabilityManager];

NSMutableURLRequest *request = [offlineStorage POST:@"/v1/endpoint" parameters:@{ @"json": @"dictionary" }];
[offlineStorage savePackage:request completion:^(NSURLRequest * _Nonnull request, NSURLResponse * _Nullable response, NSError * _Nullable error) {
    // delivery complete
}];
```
