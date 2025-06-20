#
# Generated file, do not edit.
#

list(APPEND FLUTTER_PLUGIN_LIST
  emoji_picker_flutter
  file_saver
  file_selector_windows
  flutter_inappwebview_windows
  flutter_libserialport
  flutter_nesigner_sdk
  isar_flutter_libs
  local_auth_windows
  local_notifier
  media_kit_libs_windows_video
  media_kit_video
  nesigner_adapter
  permission_handler_windows
  screen_retriever_windows
  share_plus
  tray_manager
  url_launcher_windows
  volume_controller
  window_manager
)

list(APPEND FLUTTER_FFI_PLUGIN_LIST
  blurhash_ffi
)

set(PLUGIN_BUNDLED_LIBRARIES)

foreach(plugin ${FLUTTER_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${plugin}/windows plugins/${plugin})
  target_link_libraries(${BINARY_NAME} PRIVATE ${plugin}_plugin)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES $<TARGET_FILE:${plugin}_plugin>)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${plugin}_bundled_libraries})
endforeach(plugin)

foreach(ffi_plugin ${FLUTTER_FFI_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${ffi_plugin}/windows plugins/${ffi_plugin})
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${ffi_plugin}_bundled_libraries})
endforeach(ffi_plugin)
