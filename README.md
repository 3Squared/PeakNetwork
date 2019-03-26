
![Peak Network](PeakNetwork.png "Peak Network")

PeakNetwork is a Swift networking microframework, built on top of [`Session`](https://developer.apple.com/documentation/foundation/urlsession) and leveraging the power of [`Codable`](https://developer.apple.com/documentation/swift/codable).

## Requestable

Implement this protocol to signify that the object can be converted into a `URLRequest`. This allows you to package URL request information as a custom type, and perform a request using it.

A common pattern is to implement this as an extension to an enum which describes your API endpoints:

```swift
enum ApiEndpoint {
    case search(query: String)
}

extension ApiEndpoints: Requestable {
    var request: URLRequest {
        switch self {
        case .search(let query):
            var urlRequest = URLRequest()
            ...
            return urlRequest
        }
    }
 }
 
 let requestable: Requestable = ApiEndpoint.search(
    query: "Hello World"
 )
 
 let request: URLRequest = requestable.request
```

The library also provides 2 implementations:

### BlockRequestable

Creates a `Requestable` using a given block.

```swift
let requestable = BlockRequestable {
    ...
    return urlRequest
}
```

### BodyRequest

Creates a `Requestable` with a `httpBody` set to the provded `Encodable` object.

```swift
let requestable = BodyRequest("http://example.com", body: encodable)
```

Extensions that implement `Requestable` are also provided for `URLRequest`, `URL` and `String`. 

```swift
"http://example.com".request
```

## NetworkOperation

The core of PeakNetwork is made up of an Operation subclasses which wrap a `URLSessionTask`. It is built on top of `RetryingOperation` from [PeakOperation](https://github.com/3squared/PeakOperation).

`NetworkOperation` accepts a `Requestable`, converts it to a `URLRequest`, and then performs it on the shared or provided `URLSession`. This operation conforms both `ConsumesResult` and `ProducesResult` from PeakOperation:
    - Consumes `Result<Requestable, Error>`, so it can be chained with a `Requestable`-producing operation instead of being initialised with one.
    - Produces `Result<NetworkResponse, Error>` where `NetworkResponse` wraps the data and URL response from performing  the request. 

If the request receives a response outside of the 200..300 range, the result of the operation will be a `.failure` containing a `ServerError`.

```swift
let networkOperation = NetworkOperation(requestable: ApiEndpoint.search("hello"))
networkOperation.addResultBlock { result in
    // The result of the operation will be 
    // .success(NetworkResponse) or .failure(error)
    let response = try? result.get()
}
```

### DecodeOperation

Once you have your `NetworkResponse` from your `NetworkOperation`, you most likely want to decode it into some other format. This is commonly done using a `JSONDecoder`, for which `JSONDecodeOperation` is provided. Given:

```swift
struct Item: Decodable {
    let name: String
}
```
and a JSON body of the form:

```json
{
    "name": "PeakNetwork"
}
```

you can request a item from your server like so:

```swift
let networkOperation = NetworkOperation(requestable: ApiEndpoint.search("hello"))
let decodeOperation = JSONDecodeOperation<Item>()

decodeOperation.addResultBlock { result in
    // The result of the operation will be 
    // .success(Item) or .failure(error)
    let item = try? result.get()
}

networkOperation.passesResult(to: decodeOperation).enqueue()
```

A list of `Item`s can be decoded with `JSONDecodeOperation<[Item]>` - the generic behaviour matches that of `Decoder` and `Encoder`, as they are used internally.

Other included `DecodeOperations` are:

- `JSONDecodeResponseOperation`, also passes along the `HTTPURLResponse` along with the `Decodable`.
- `ImageDecodeOperation`, decodes the response data as a `UIImage`/`NSImage`.

To create your own for a custom format or behaviour, subclass `DecodeOperation` and override `decode(:)`.

## ImageController

`ImageController` manages starting, cancelling, and mapping  of `ImageResponseOperations`. This allows remote images to be easily set on UI elements. 

```swift
let controller = ImageController()
controller.getImage(requestable), object: context) { image, context, source in
    // use image
}
```
You can use any `NSObject` as the context parameter - it will be used as a unique key for the request. 

It is recommended to use the UI element (such as a `UIImageView`) as the context - that way, you are passed the element in the block, and any repeated requests for the same UI element are cancelled (for example, when reusing a `UITableViewCell`).

It has several optimisations to reduce memory usage. If you share an instance of the controller, then repeated requests for the same image will be combined into one, even if the first request has not completed yet.

```swift
let imageView1 = ...
let imageView2 = ...

ImageController.sharedInstance.getImage(
    requestable, 
    object: imageView1
) { image, view, source in
    // this imageview requests it first
}
        
ImageController.sharedInstance.getImage(
    requestable, 
    object: imageView2
) { image, view, source in
    // but both get the same UIImage delivered at the same time
}

```

Extensions are provided for `UIImageView` and `UIButton` to simplify usage further. These use `ImageController.sharedInstance`, which can be configured.

```swift
ImageController.sharedInstance = ImageController() // optional
imageView.setImage(requestable)
```

## Certificate Pinning

[Certificate/SSL pinning](https://en.wikipedia.org/wiki/HTTP_Public_Key_Pinning) can be used to ensure that an app communicates only with a designated server, avoiding MITM attacks using mis-issued or otherwise fraudulent certificates. 

PeakNetwork provides `CertificatePinningSessionDelegate` which you can use with any `URLSession`.

All that you need to do is add the valid certificates to your bundle with a file name corresponding to the domain you want to pin; for example, `google.com.cer` for connections to google.com. After that, just create the delegate and set it on your `URLSession`:

```swift
let delegate = CertificatePinningSessionDelegate()

let urlSession = URLSession(
    configuration: URLSessionConfiguration.default, 
    delegate: certificatePinningSessionDelegate, 
    delegateQueue: nil
)
```


If a certificate is missing, the terminal command to fetch it will be printed to the console:

```bash
openssl s_client -showcerts -connect DOMAIN:PORT < /dev/null | openssl x509 -outform DER > DOMAIN.cer\n\n
```

## Mocking

You may notice that PeakNetwork does not use `URLSession` in its method signatures. Instead, the framework adds a protocol `Session` which is implemented by both Apple's `URLSession` and our `MockSession`. It is therefore recommended to always pass a `Session` to your web service calls, so you can swap in a mock implementation.

By implementing this shared interface, we can easily swap out a real session, that hits the web, with a mocked one which returns responses from strings or loaded from files.

This is very useful in unit tests, for testing behaviour without hitting a real web server. You could also use it in the app target to test your UI before you have a real server, or for demo purposes.

Creating a `MockSession` is simple:

```swift
let session = MockSession { session in
    session.queue(response: MockResponse(statusCode: .ok))
}

let networkOperation = NetworkOperation(requestable, session: session)
```

Here, we mock a response with a 200 status, and nothing else. This is the minimum `MockResponse` we can make. The next time a request is made using this session, the mock response will be returned. Once all the responses have been used, a fatal error will occur.

In this next example, we queue up 2 responses: a dictionary, which will be delivered to the next request as JSON data, and an error. They will be returned in the order they are queued:

```swift
session.queue(response: MockResponse(json: ["name" : "Peak"], statusCode: .ok))
session.queue(response: MockResponse(statusCode: .internalServerError, sticky: true))

```

In the previous examples we return the response regardless of the request made. If you provide a block, you can inspect the request and decide if you should respond. This example is only returned if the URL is for a resource at 3squared.com:

```swift
session.queue(response: MockResponse(statusCode: .badGateway) { request in 
    return request.url?.host == "3squared.com" 
})
```

We can also load JSON from files in the bundle:

```
session.queue(response: MockResponse(fileName: "searchResults", statusCode: .ok, sticky: true) { request in 
    return request.url?.absoluteString.contains("search") 
}))
```
Here we also set `sticky: true`. This means that the response is nt consumed, and multiple requests will receive this same response.

There are many other options and combinations of arguments for `MockResponse.`

## Examples

Please see the included sample project (`Examples/PeakNetworkExamples.xcworkspace`) for examples and a suggested structure for your networking code. 

Please see the tests for further examples. 

## Getting Started

### Installing

- Using Cocoapods, add `pod 'PeakNetwork'` to your Podfile.
- `import PeakNetwork` where necessary.

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

- [rhodgkins/SwiftHTTPStatusCodes](https://github.com/rhodgkins/SwiftHTTPStatusCodes)
- [Mocking Classes You Don't Own](http://masilotti.com/testing-nsurlsession-input/) by Joe Masilotti

# Peak Framework

The Peak Framework is a collection of open-source microframeworks created by the team at [3Squared](https://github.com/3squared), named for the [Peak District](https://en.wikipedia.org/wiki/Peak_District). It is made up of:

|Name|Description|
|:--|:--|
|[PeakCoreData](https://github.com/3squared/PeakCoreData)|Provides enhances and conveniences to `Core Data`.|
|[PeakOperation](https://github.com/3squared/PeakOperation)|Provides enhancement and conveniences to `Operation`, making use of the `Result` type.|
