# Keep Flutter core classes in main dex
-keep class io.flutter.embedding.android.FlutterActivity
-keep class io.flutter.embedding.android.FlutterApplication
-keep class io.flutter.plugin.platform.PlatformPlugin
-keep class io.flutter.view.FlutterMain

# Keep essential app components in main dex
-keep class com.example.afterlife.MainActivity
-keep class com.example.afterlife.MainApplication

# Keep critical plugins in main dex for faster startup
-keep class io.flutter.plugins.sharedpreferences.**
-keep class io.flutter.plugins.pathprovider.**

# Keep multidex support classes
-keep class androidx.multidex.** 