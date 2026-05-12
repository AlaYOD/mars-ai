# Vosk Model Directory

Vosk model `.zip` files are downloaded at runtime by `VoskModelService`
and stored in the app's private document directory (not here).

Only bundle a zip here if you want it pre-packaged inside the APK
(increases APK size). The app falls back to runtime download automatically.
