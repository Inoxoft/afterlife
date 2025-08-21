# Flutter and Dart specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Dart and Flutter reflection
-keep class * extends io.flutter.app.FlutterApplication
-keep class * extends io.flutter.embedding.android.FlutterActivity
-keep class * extends io.flutter.embedding.android.FlutterFragmentActivity

# Keep Flutter Gemma plugin classes
-keep class ai.flutter.flutter_gemma.** { *; }
-keep class com.google.mediapipe.** { *; }
-keep class org.tensorflow.** { *; }

# Keep Google Play Core classes
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Keep Protocol Buffers classes
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# Keep Protobuf annotations
-keep class * extends com.google.protobuf.GeneratedMessageLite { *; }
-keepclassmembers class * extends com.google.protobuf.GeneratedMessageLite {
  <fields>;
}

# HTTP and networking
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }
-dontwarn okhttp3.**
-dontwarn retrofit2.**

# JSON serialization (for API responses)
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Keep model classes used for JSON serialization
-keep class * implements java.io.Serializable { *; }
-keepclassmembers class * implements java.io.Serializable {
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# File access and providers
-keep class androidx.core.content.FileProvider { *; }
-keep class * extends androidx.core.content.FileProvider

# PDF processing (Syncfusion)
-keep class com.syncfusion.** { *; }
-dontwarn com.syncfusion.**

# Shared preferences
-keep class android.content.SharedPreferences { *; }
-keep class * implements android.content.SharedPreferences { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep custom classes that might be used via reflection
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# Image picker and camera functionality
-keep class * implements android.hardware.Camera$** { *; }

# URL launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# Wakelock
-keep class dev.fluttercommunity.plus.wakelock.** { *; }

# Path provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Remove debug and logging information in release builds
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# Optimization settings
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify

# Keep line numbers for crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile 