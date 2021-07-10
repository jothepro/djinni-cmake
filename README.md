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
- 🎳 Supports targets Java (Android), Objective-C (macOS, iOS, ...) and C# (Windows .NET 5 & .NET Framework)

## Prerequisites

- [CMake](https://cmake.org/) >= 3.19
- [Djinni Generator](https://github.com/cross-language-cpp/djinni-generator) >= 1.1.0

## Installation

Copy the file `Djinni.cmake` from the latest release to your CMake modules folder and include it in the root `CMakeLists.txt`:

```cmake
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules ${CMAKE_MODULE_PATH})
include(Djinni)
```

Watch this repository so you don't miss updates! 🔔

## Synopsis

```cmake
add_djinni_library(<target> [SHARED|STATIC|INTERFACE]
        IDL <filename>
        LANGUAGES <CPP|JAVA|CPPCLI|OBJC> [CPP|JAVA|CPPCLI|OBJC ...]
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

If generating for Java, additionally a target `<target>-java` is created, that builds a jar named `<target>.jar` with
the Java gluecode to `<jar-output-dir>` when the target `<target>` is built.

This generator is intentionally favoring convention over configuration to keep things as simple as possible.
If you miss a configuration option anyways, please consider opening an issue.

## Options

The options are:

- `IDL <filename>`<br>
  filename/path of the Djinni-IDL file that should be processed
- `SHARED|STATIC|INTERFACE`<br>
  Optional;<br>
  Type of library. If no type is given explicitly the type is `STATIC` or `SHARED` based on whether the current value
  of the variable `BUILD_SHARED_LIBS` is `ON`
- `LANGUAGES`<br>
  list of languages that bindings should be generated for. Possible values: `CPP`, `JAVA`, `CPPCLI`, `OBJC`
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
  Other (Djinni) targets that the library links to. Their `include` directories are appended to `--idl-include-path` and
  any `.jar` in the `include` directories will be appended to `CMAKE_JAVA_INCLUDE_PATH`. That way other Djinni libraries
  can be linked.
- `JAR_OUTPUT_DIR <jar-output-dir>`<br>
  Optional; Default: `${CMAKE_CURRENT_BINARY_DIR}`<br>
  The directory to which the jar should be written if gluecode for Android is created.
  
## Example

*For a full usage example please have a look at [jothepro/djinni-library-template](https://github.com/jothepro/djinni-library-template)!*

Given a Djinni-IDL file named `example.djinni`, this is all you need in your `CMakeLists.txt`:

```cmake
add_djinni_library(Example
    IDL example.djinni
    LANGUAGES CPP JAVA CPPCLI OBJC
    NAMESPACE Demo
    SOURCES
      src/example.cpp
)
```

This will generate a target `Example` that contains all the required gluecode from the interface defined in `example.djinni` and
it's implementation source `src/example.cpp`.

All C++ classes will be in the namespace `Demo`, all Java classes in the package `demo` and all ObjC structures will have the prefix `D`.

All generated header files can be found on the include path under `Demo/`

If the target language is Java, a jar named `Example.jar` will be built to `${CMAKE_CURRENT_BINARY_DIR}` once the target `Example` is built.

If the target language is Objective-C, a Swift Bridging Header can be found on the include path: `Demo/Example.h`

## Troubleshooting

- **The Djinni executable can not be found!** 😠<br>Solution: Explicitly define the full path of the `djinni` binary in `DJINNI_EXECUTABLE`.

## Credits

Thanks to the work of @freitass ([Djinni.cmake](https://github.com/cross-language-cpp/djinni-support-lib/blob/main/test-suite/Djinni.cmake)) and @a4z ([djinni_process_idl.cmake](https://github.com/cross-language-cpp/djinni-example-cc/blob/main/cmake/djinni_process_idl.cmake))
for inspiring me to write this wrapper.
