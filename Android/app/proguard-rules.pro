# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

-keep class com.khandoba.securedocs.** { *; }
-dontwarn com.khandoba.securedocs.**

# Keep Room entities
-keep class * extends androidx.room.RoomDatabase
-keep @androidx.room.Entity class *
-keepclassmembers class * {
    @androidx.room.* <methods>;
}

# Keep data classes
-keep class com.khandoba.securedocs.data.entity.** { *; }
-keep class com.khandoba.securedocs.domain.model.** { *; }
