# ─── Flutter & Dart ────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ─── BetterPlayer / ExoPlayer ─────────────────────────────────
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**
-keep class com.jhomlala.better_player.** { *; }
-dontwarn com.jhomlala.better_player.**

# ─── OkHttp (used by ExoPlayer for HLS) ──────────────────────
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }

# ─── Google Fonts ─────────────────────────────────────────────
-keep class com.google.android.gms.fonts.** { *; }

# ─── Cached Network Image / Glide ────────────────────────────
-keep public class * implements com.bumptech.glide.module.GlideModule
-keep class * extends com.bumptech.glide.module.AppGlideModule { <init>(...); }
-keep public enum com.bumptech.glide.load.ImageHeaderParser$** {
    **[] $VALUES;
    public *;
}

# ─── Connectivity Plus ───────────────────────────────────────
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# ─── SharedPreferences ───────────────────────────────────────
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# ─── General Android ─────────────────────────────────────────
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# ─── Prevent stripping of native methods ─────────────────────
-keepclasseswithmembernames class * {
    native <methods>;
}

# ─── Obfuscation: obfuscate everything not explicitly kept ───
-repackageclasses ''
-allowaccessmodification
-optimizations !code/simplification/arithmetic,!field/*,!class/merging/*
