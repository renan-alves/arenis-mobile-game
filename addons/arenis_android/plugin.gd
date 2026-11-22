@tool
extends EditorPlugin

class AndroidExport extends EditorExportPlugin:
	func _get_name() -> String:
		return "ArenisAndroid"
	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid
	func _get_android_libraries(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray(["res://addons/arenis_android/bin/arenis-android.aar"])
	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray(["com.google.android.gms:play-services-ads:25.5.0", "com.google.android.ump:user-messaging-platform:4.0.0", "com.google.android.gms:play-services-games-v2:22.1.0"])

var exporter: AndroidExport
func _enter_tree() -> void:
	exporter = AndroidExport.new()
	add_export_plugin(exporter)
func _exit_tree() -> void:
	remove_export_plugin(exporter)
