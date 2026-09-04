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

# Keep Google Sign-In classes
-keep class com.google.** { *; }
-dontwarn com.google.**
