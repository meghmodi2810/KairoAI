# TensorFlow Lite
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

# MediaPipe
-keep class com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**

# javapoet (shaded in AutoValue/others)
-dontwarn autovalue.shaded.com.squareup.javapoet.**
-dontwarn com.squareup.javapoet.**

# javax.lang.model (referenced by javapoet)
-dontwarn javax.lang.model.**

# Google Sign-In
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.common.api.ApiException { *; }
-dontwarn com.google.android.gms.auth.api.signin.**

# Firebase Auth/Core
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# General keep rules
-keepattributes Signature, Exceptions, *Annotation*
