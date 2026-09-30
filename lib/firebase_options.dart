// Cấu hình Firebase của project chat-11c93, sinh từ GoogleService-Info.plist và
// google-services.json. Các giá trị này không phải bí mật: chúng nằm sẵn trong app đã build.
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => Platform.isIOS ? ios : android;

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBIFCuHs7uPoRViNVlOKPxSpjGCZCG3u_Q',
    appId: '1:925711755412:android:33e8c132fe9eb0d4feec81',
    messagingSenderId: '925711755412',
    projectId: 'chat-11c93',
    storageBucket: 'chat-11c93.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB3myZ-SpMA0_6N5CvhdolQpGtm5bRi_z4',
    appId: '1:925711755412:ios:c0e4aa68fb91d77ffeec81',
    messagingSenderId: '925711755412',
    projectId: 'chat-11c93',
    storageBucket: 'chat-11c93.firebasestorage.app',
    iosBundleId: 'com.hungtv.chatapp',
  );
}
