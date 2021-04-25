# Djinni CMake 🧞‍♂️

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/jothepro/djinni-cmake)](https://github.com/jothepro/djinni-cmake/releases/latest)
[![GitHub](https://img.shields.io/github/license/jothepro/djinni-cmake)](https://github.com/jothepro/djinni-cmake/blob/main/LICENSE)

Simple CMake wrapper for [Djinni](https://djinni.xlcpp.dev/).

## Motivation

While I like to have a good portion of configuration options in the [Djinni Generator](https://github.com/cross-language-cpp/djinni-generator), 
I think it is easier to get started with Djinni if a few presumptions are made for the developer.

This wrapper attemts to be a tool that allows a quick and simple start into a new project with C++ using Djinni.

It may evolve over time to a more powerful tool with more configuration options. This depends on your feedback and my future requirements.

## Features

- 🎯 Easy to use
- 🧶 Little configuration required
- 🧩 Convention over configuration
- 🎳 Supports targets Java (Android), Objective-C (macOS, iOS, ...) and C# (Windows)

## Prerequisites

- [CMake](https://cmake.org/) >= 3.20
- [Djinni Generator](https://github.com/cross-language-cpp/djinni-generator) >= 0.3.2
- [Djinni Support Lib](https://github.com/cross-language-cpp/djinni-support-lib) >= 0.0.1 (must be available as CMake target `djinni-support-lib::djinni-support-lib`)

## Installation

Copy the file `Djinni.cmake` from the latest release to your CMake modules folder and include it in the root `CMakeLists.txt`:

```cmake
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules ${CMAKE_MODULE_PATH})
include(Djinni)
```

Watch this repository so you don't miss updates! 🔔

## Synopsis

```cmake
add_djinni_library(<target> 
        IDL <filename>
        [SHARED | STATIC]
        [NAMESPACE <namespace>]
        [DIRECTORY <output-dir>]
        [SOURCES <sources>]
        [JAR_OUTPUT_DIR <jar-output-dir>]
)
```

Calls Djinni Generator and creates a target with name `<target>` from the generated sources.

Automatically detects for which platform to configure the generator, depending on `CMAKE_SYSTEM_NAME`.
If building for Android, additionally a target `<target>-android` is created, that builds a jar named `<target>.jar` with the Java gluecode to `<jar-output-dir>` 
when the target `<target>` is built.

If a non supported target platform (everything except Android, iOS, macOS, tvOS, watchOS) is detected, only the C++ interface is generated.

This generator is intentionally favouring convention over configuration to keep things as simple as possible.
If you miss a configuration option anyways, please consider opening an issue.

## Options

The options are:

- `IDL <filename>`<br>
  filename/path of the Djinni-IDL file that should be processed.
- `SHARED | STATIC`<br>
  Optional;<br>
  Whether to make the target a `SHARED` or `STATIC` library. If none is given, the preset of `BUILD_SHARED_LIBS` will be followed.
- `NAMESPACE <namespace>`<br>
  Optional; Default: `Djinni`<br>
  The namespace for the generated code. Each namespace part should start with an uppercase letter.
  The namespace is used for the generated C++ code, but also automatically transformed to a Java package & ObjC prefix.<br>
  Examples:
  
  | `NAMESPACE` value | C++ namespace          | Java package           | ObjC prefix |
  | ----------------- | ---------------------- | ---------------------- | ------------|
  | `Djinni::Lib`     | `Djinni::Lib`          | `djinni.lib`           | `DL`        |
  | `My::LibExample`  | `My::LibExample`         | `my.libexample`        | `MLE`       |
  
- `DIRECTORY <output-dir>`<br>
  Optional; Default: `djinni-generated`<br>
  The output directory where the generated code should be written to.
- `SOURCES <sources>` <br>
  Optional; <br>
  Additional sources. This could for example be the sources that implement the Djinni interface in C++.
- `JAR_OUTPUT_DIR <jar-output-dir>`<br>
  Optional; Default: `${CMAKE_CURRENT_BINARY_DIR}`<br>
  The directory to which the jar should be written if gluecode for Android is created.

## Example

*(A full project example is coming soon, stay tuned)*

Given a Djinni-IDL file named `example.djinni`, this is all you need in your `CMakeLists.txt`:

```cmake
add_djinni_library(Example
    IDL example.djinni
    NAMESPACE Demo
)
```

This will generate a target `Example` that contains all the required gluecode from the interface defined in `example.djinni`.

All C++ classes will be in the namespace `Demo`, all Java classes in the package `demo` and all ObjC structures will have the prefix `D`.

All generated header files can be found on the include path under `Demo/`

If the target platform is Android, a jar named `Example.jar` will be built to `${CMAKE_CURRENT_BINARY_DIR}` once the target `Example` is built.

If the target platform is Darwin (iOS/macOS/watchOS/tvOS), a Swift Bridging Header can be found on the include path: `Demo/Example.h`

## Troubleshooting

- **😠 The Djinni executable can not be found!** Solution: Explicitly define the full path of the `djinni` binary in `DJINNI_EXECUTABLE`.

## Credits

Thanks to the work of @freitass ([Djinni.cmake](https://github.com/cross-language-cpp/djinni-support-lib/blob/main/test-suite/Djinni.cmake)) and @a4z ([djinni_process_idl.cmake](https://github.com/cross-language-cpp/djinni-example-cc/blob/main/cmake/djinni_process_idl.cmake))
for inspiring me to write this wrapper.
