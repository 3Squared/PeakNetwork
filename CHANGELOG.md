# CHANGELOG

The changelog for `PeakNetwork`.

--------------------------------------

6.0.0
-----
- Adds a new, more structured way to construct your API and requests.
- `WebAPI`, `Resource` and `Endpoint` replacing existing `Requestable`.

5.2.0
-----
- Add more detailed progress for network operations.
- Update `PeakOperation` dependancy.

5.1.0
-----
- Remove dependency on `PeakResult`.
- Update project to Swift 5.

5.0.0
-----
- Added support for `macOS` and `tvOS`.
- Add `RequestInterceptorSession`, allowing actions to be performed on a request before it is executed. 
- Add `ErrorInterceptorSession`, allowing actions to be performed if a request encounters an error.
- Split Network and Decode steps into separate operations.
    - Instead of `DecodableOpeation` doing everything, you now perform a `NetworkOperation` then pass its result onto a `DecodeOperation`, which could decode it into any format.

4.0.0
-----
- Rename from `THRNetwork` to `PeakNetwork`.
- 
3.1.2
-----
- Remove retain cycles.

3.1.1
-----
- Set minimum deployment target to 10
- Update THROperations

3.1.0
-----
- Add a variant of DecodableResponseOperation that does not have a URLRequest in the result
- Remove Header parsing support

3.0.0
-----
- Provide more explicit information for successful network requests
- Add ability to mock requests at the session level using Session/MockSession
- Removed MockRequestOperation
- Add DecodableFileOperation
- Improve consistency of operation names

2.0.0
-----
- Update Operations library to 0.2.0

1.0.0
-----
- Remove JSONConvertible and replace with Decodable

0.2.1
-----
- Update Operations library to 0.2.0

0.2.0
-----
- Set device detail headers on request
- Add extra parameter indicating source of the image (cached or not)
- Improve behaviour of image controller when used with recycled views
- Correctly mark an operation as cancelled
- When the same image is requested for different views, only perform one operation
- Update Operations library to 0.1.0

0.1.0
-----
* Rename JSON type alias to prevent clashing.
* Remove RequestManyOperation, RequestOperation now handles both cases.

0.0.9
-----
* Fix visibility of AnimationOption fields.

0.0.8
-----
* Remove unnecessary parens from enum definition.
* Make the shared instance of ImageController publically accessible.

0.0.7
-----
* Fix issue where setting images for different states would cancel each other.
