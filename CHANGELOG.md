# CHANGELOG

The changelog for `THRNetwork`.

--------------------------------------

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
