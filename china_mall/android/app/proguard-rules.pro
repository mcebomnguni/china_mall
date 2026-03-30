# ─── Flutter ─────────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable

# ─── Keep crash line numbers ──────────────────────────────────────────────────
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# ─── OkHttp (used by http package) ───────────────────────────────────────────
-dontwarn okhttp3.**
-dontwarn okio.**

# ─── Glide / Image loading ────────────────────────────────────────────────────
-keep public class * implements com.bumptech.glide.module.GlideModule
-keep class com.bumptech.glide.** { *; }

# ─── Kotlin ───────────────────────────────────────────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings { <fields>; }

# ─── Gson / JSON serialization ────────────────────────────────────────────────
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }

# ─── Remove debug logging in release ────────────────────────────────────────
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
