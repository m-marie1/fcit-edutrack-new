# Keep all model classes
-keep class com.example.fci_edutrack.models.** { *; }
-keep class com.example.fci_edutrack.auth.** { *; }
-keep class com.example.fci_edutrack.providers.** { *; }

# Keep API service and related classes
-keep class com.example.fci_edutrack.services.** { *; }
-keep class com.example.fci_edutrack.config.** { *; }

# Keep all Parcelable implementations
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Keep JSON-related classes
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep Flutter plugin implementations
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.view.**  { *; }

# Keep classes with @Keep annotation
-keep class androidx.annotation.Keep

-keep @androidx.annotation.Keep class * {*;}

-keepclasseswithmembers class * {
    @androidx.annotation.Keep <methods>;
}

-keepclasseswithmembers class * {
    @androidx.annotation.Keep <fields>;
}

-keepclasseswithmembers class * {
    @androidx.annotation.Keep <init>(...);
}

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep model classes used in API responses
-keep class * extends com.example.fci_edutrack.models.Course { *; }
-keep class * extends com.example.fci_edutrack.models.Assignment { *; }
-keep class * extends com.example.fci_edutrack.models.Quiz { *; }
-keep class * extends com.example.fci_edutrack.models.User { *; }
-keep class * extends com.example.fci_edutrack.models.Attendance { *; }

# Keep API response classes
-keepclassmembers class * {
    @retrofit2.http.* <methods>;
}

# Keep serializable classes
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}