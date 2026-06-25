# Isar
-keep class isar.** { *; }
-keepclassmembers class * {
    @isar.* *;
}

# Google Generative AI
-keep class com.google.ai.** { *; }

# Gson / JSON (dipakai banyak SDK)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
