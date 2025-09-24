# 🛠 Steps to Build DLL on Windows 10

The goal: compile them into a Windows DLL.

###  1. Install prerequisites

CMake
 (≥3.10, required by your CMakeLists).

[Visual Studio with Desktop Development for C++] or MinGW-w64
.

###  2. Create folder structure

Example:

```
usb_esc_printer/
 ├── CMakeLists.txt
 ├── usb_esc_printer_c.c
 └── usb_esc_printer_c.h
```

### 3. Open a Developer Command Prompt

(for MSVC) or use MinGW terminal.

### 4. Configure build with CMake

Inside your project folder:

```
mkdir build
cd build
cmake .. -G "MinGW Makefiles"
```

Or if using Visual Studio:
```
cmake .. -G "Visual Studio 16 2019"
```
### 5. Compile

With MinGW:
```
mingw32-make
```

With MSVC:
```
cmake --build . --config Release
```
### 6. Result

You should get:
```
build/
 ├── usb_esc_printer_windows.dll   ✅
 ├── usb_esc_printer_windows.lib   (import library, MSVC only)
 └── usb_esc_printer_windows.exp   (export info)
 ```

 # Hint

 For Epson thermo printer such as TM-T20, additional software is needed.
 See [Epson AdvancedPrinterDriver TM-T20III](https://ftp.epson.com/drivers/pos/APD_607R1_T20III_WM.exe)