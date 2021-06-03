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
- 🎳 Supports targets Java (Android), Objective-C (macOS, iOS, ...) and C# (Windows .NET 5)

## Prerequisites

- [CMake](https://cmake.org/) >= 3.18
- [Djinni Generator](https://github.com/cross-language-cpp/djinni-generator) >= 1.0.0

## Installation

Copy the file `Djinni.cmake` from the latest release to your CMake modules folder and include it in the root `CMakeLists.txt`:

```cmake
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules ${CMAKE_MODULE_PATH})
include(Djinni)
```

Watch this repository so you don't miss updates! 🔔

## Functions/Macros provided by this module

### Initializing a Djinni CMake project

```cmake
djinni_project(<PROJECT-NAME>)
```

Initializes a normal CMake project with some Djinni-specific extras:

- Automatically selects the languages that need to be enabled depending on the platform.
- Additionally sets the variables `DARWIN` or `WINDOWS` to `1` depending on the platform.
  This complements the variable `ANDROID` set by default if building for Android.
  You can use these 3 variables for your own platform specific configuration logic.

### Adding a Djinni target

```cmake
add_djinni_library(<target> 
        IDL <filename>
        [SHARED | STATIC]
        [NO_JNI_MAIN]
        [NAMESPACE <namespace>]
        [DIRECTORY <output-dir>]
        [SOURCES <sources>]
        [DEPENDENCIES <dependencies>]
        [JAR_OUTPUT_DIR <jar-output-dir>]
)
```

Calls Djinni Generator and creates a target with name `<target>` from the generated sources.
The YAML definition of the generated interface is available on the targets include directory.

Automatically detects for which platform to configure the generator, depending on `CMAKE_SYSTEM_NAME`.
If building for Android, additionally a target `<target>-android` is created, that builds a jar named `<target>.jar` with the Java gluecode to `<jar-output-dir>` 
when the target `<target>` is built.

If an  unsupported target platform (everything except Android, iOS, macOS, tvOS, watchOS, Windows) is detected, only the C++ interface is generated.

This generator is intentionally favoring convention over configuration to keep things as simple as possible.
If you miss a configuration option anyways, please consider opening an issue.

#### Options

The options are:

- `IDL <filename>`<br>
  filename/path of the Djinni-IDL file that should be processed.
- `SHARED | STATIC`<br>
  Optional;<br>
  Whether to make the target a `SHARED` or `STATIC` library. If none is given, the preset of `BUILD_SHARED_LIBS` will be followed.
- `NO_JNI_MAIN`<br>
  Optional;<br>
  By default `JNI_OnLoad` & `JNI_OnUnload` entrypoints for JNI are included. Set this argument to not include entrypoints.
- `NAMESPACE <namespace>`<br>
  Optional; Default: `Djinni`<br>
  The namespace for the generated code. Each namespace part should start with an uppercase letter.
  The namespace is used for the generated C++ code, but also automatically transformed to a Java package & ObjC prefix.<br>
  Examples:
  
  | `NAMESPACE` value | C++ namespace          | Java package           | ObjC prefix |
  | ----------------- | ---------------------- | ---------------------- | ------------|
  | `Djinni::Lib`     | `Djinni::Lib`          | `djinni.lib`           | `DL`        |
  | `My::LibExample`  | `My::LibExample`       | `my.libexample`        | `MLE`       |
  
- `DIRECTORY <output-dir>`<br>
  Optional; Default: `djinni-generated`<br>
  The output directory where the generated code should be written to.
- `SOURCES <sources>` <br>
  Optional; <br>
  Additional sources. This could for example be the sources that implement the Djinni interface in C++.
- `DEPENDENCIES <dependencies>` <br>
  Optional; <br>
  Other targets that the library links to. Their include directories are appended to `--idl-include-path`. That way
  other Djinni libraries can be linked because their YAML interface can be imported in the IDL file.
- `JAR_OUTPUT_DIR <jar-output-dir>`<br>
  Optional; Default: `${CMAKE_CURRENT_BINARY_DIR}`<br>
  The directory to which the jar should be written if gluecode for Android is created.
  

### Linking the djinni-support-lib

```cmake
djinni_target_link_support_lib(<target> <support-lib-version>)
```

Automatically fetches the djinni-support-lib with `FetchContent` and links it to the given target.

This wrapper is needed because when building for Windows .NET 5 a workaround is required to link the support-lib.
This macro may become obsolete once [this problem](https://github.com/cross-language-cpp/djinni-support-lib/pull/33) is fixed.

## Example

*(A full project example is coming soon, stay tuned)*

Given a Djinni-IDL file named `example.djinni`, this is all you need in your `CMakeLists.txt`:

```cmake
djinni_project(ExampleProject)

add_djinni_library(Example
    IDL example.djinni
    NAMESPACE Demo
    SOURCES
      src/example.cpp
)

djinni_target_link_support_lib(Example v1.0.0)
```

This will generate a target `Example` that contains all the required gluecode from the interface defined in `example.djinni` and
it's implementation source `src/example.cpp`.

All C++ classes will be in the namespace `Demo`, all Java classes in the package `demo` and all ObjC structures will have the prefix `D`.

All generated header files can be found on the include path under `Demo/`

If the target platform is Android, a jar named `Example.jar` will be built to `${CMAKE_CURRENT_BINARY_DIR}` once the target `Example` is built.

If the target platform is Darwin (iOS/macOS/watchOS/tvOS), a Swift Bridging Header can be found on the include path: `Demo/Example.h`

## Troubleshooting

- **The Djinni executable can not be found!** 😠<br>Solution: Explicitly define the full path of the `djinni` binary in `DJINNI_EXECUTABLE`.

## Credits

Thanks to the work of @freitass ([Djinni.cmake](https://github.com/cross-language-cpp/djinni-support-lib/blob/main/test-suite/Djinni.cmake)) and @a4z ([djinni_process_idl.cmake](https://github.com/cross-language-cpp/djinni-example-cc/blob/main/cmake/djinni_process_idl.cmake))
for inspiring me to write this wrapper.
