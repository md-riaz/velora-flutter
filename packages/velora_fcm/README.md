# velora_fcm

Firebase Cloud Messaging `PushAdapter` for Velora apps.

Wired by hand as `Velora.boot(pushAdapter: VeloraFcmAdapter())`, after `Firebase.initializeApp()`. `velora install velora_fcm` adds the dependency and prints the steps.

Requires Flutter >=3.47.0 / Dart >=3.13.0. Not published to pub.dev yet; use a git or path dependency.

Full guide: [`docs/packages/fcm.md`](../../docs/packages/fcm.md).
