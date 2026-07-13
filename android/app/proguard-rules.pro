# ProGuard rules for AutoUBC
# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Keep Isar
-keep class io.isar.** { *; }
-keep class * extends io.isar.IsarCollection { *; }
-dontwarn io.isar.**

# Keep Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep Google Sign In
-keep class com.google.** { *; }
-dontwarn com.google.**

# Keep PDF library
-keep class com.itextpdf.** { *; }
-dontwarn com.itextpdf.**
