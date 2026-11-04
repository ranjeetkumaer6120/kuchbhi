# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# Google Play Core
-dontwarn com.google.android.play.core.**

# Just Audio & Audio Service Background
-keep class com.ryanheise.** { *; }
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.just_audio.** { *; }
-keepattributes *Annotation*
-dontwarn com.ryanheise.**
