# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(usb_esc_printer_c-win64_library VERSION 0.0.1 LANGUAGES C)

add_library(usb_esc_printer_c-win64 SHARED
  "usb_esc_printer_c.c"
)

set_target_properties(usb_esc_printer_c-win64 PROPERTIES
  PUBLIC_HEADER usb_esc_printer_c.h
  OUTPUT_NAME "usb_esc_printer_c"
)
target_compile_definitions(usb_esc_printer_c-win64 PUBLIC DART_SHARED_LIB)
