# MIT License
#
# Djinni CMake
# https://github.com/jothepro/djinni-cmake
#
# Copyright (c) 2021 jothepro
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

cmake_minimum_required(VERSION 3.18)

function(add_djinni_library LIBRARY_TARGET)
    cmake_parse_arguments(DJINNI
        # options
            "NO_JNI_MAIN;STATIC;SHARED;NO_OBJC_PREFIX"
        # one-value keywords
            "IDL;NAMESPACE;DIRECTORY;JAR_OUTPUT_DIR"
        # multi-value keywords
            "LANGUAGES;SOURCES;"
        # args
            ${ARGN}
    )

    set(MESSAGE_PREFIX "[djinni]")

    if(NOT DEFINED DJINNI_DIRECTORY)
        set(DJINNI_DIRECTORY djinni-generated)
    endif()

    if(NOT DEFINED DJINNI_NAMESPACE)
        set(DJINNI_NAMESPACE Djinni)
    endif()

    if(NOT DEFINED DJINNI_JAR_OUTPUT_DIR)
        set(DJINNI_JAR_OUTPUT_DIR ${CMAKE_CURRENT_BINARY_DIR})
    endif()

    # derive namespaces, prefixes, paths from NAMESPACE
    string(REPLACE "::" "/" DJINNI_NAMESPACE_PATH ${DJINNI_NAMESPACE})
    set(DJINNI_JNI_NAMESPACE "${DJINNI_NAMESPACE}::jni")
    set(DJINNI_OBJCPP_NAMESPACE "objcpp::${DJINNI_NAMESPACE}")
    set(DJINNI_CPPCLI_NAMESPACE "${DJINNI_NAMESPACE}::cppcli")

    string(REPLACE "::" "." DJINNI_JAVA_PACKAGE ${DJINNI_NAMESPACE})
    string(TOLOWER ${DJINNI_JAVA_PACKAGE} DJINNI_JAVA_PACKAGE)
    string(TOLOWER ${DJINNI_JAVA_PACKAGE} DJINNI_JAVA_PATH)
    string(REPLACE "." "/" DJINNI_JAVA_PATH ${DJINNI_JAVA_PATH})

    string(REGEX REPLACE "[a-z:\\-_]" "" DJINNI_OBJC_PREFIX ${DJINNI_NAMESPACE})

    # prepare input variables
    set(DJINNI_CPP_DIR ${DJINNI_DIRECTORY}/cpp)
    set(DJINNI_CPP_SRC_DIR ${DJINNI_CPP_DIR}/src)
    set(DJINNI_CPP_INCLUDE_PREFIX ${DJINNI_NAMESPACE_PATH}/)
    set(DJINNI_CPP_INCLUDE_DIR ${DJINNI_CPP_DIR}/include/)
    set(DJINNI_CPP_HEADER_OUT ${DJINNI_CPP_INCLUDE_DIR}/${DJINNI_CPP_INCLUDE_PREFIX})
    set(DJINNI_JNI_OUT ${DJINNI_DIRECTORY}/jni/src)
    set(DJINNI_JNI_INCLUDE_PREFIX ${DJINNI_NAMESPACE_PATH}/jni/)
    set(DJINNI_JNI_INCLUDE_DIR ${DJINNI_DIRECTORY}/jni/include/)
    set(DJINNI_JNI_HEADER_OUT ${DJINNI_JNI_INCLUDE_DIR}/${DJINNI_JNI_INCLUDE_PREFIX})
    set(DJINNI_JNI_INCLUDE_CPP_PREFIX ${DJINNI_NAMESPACE_PATH}/)
    set(DJINNI_OBJC_OUT ${DJINNI_DIRECTORY}/objc/src)
    set(DJINNI_OBJC_INCLUDE_PREFIX ${LIBRARY_TARGET}/)
    set(DJINNI_OBJCPP_INCLUDE_CPP_PREFIX ${DJINNI_NAMESPACE_PATH}/)
    set(DJINNI_OBJC_INCLUDE_DIR ${DJINNI_DIRECTORY}/objc/include/)
    set(DJINNI_OBJC_HEADER_OUT ${DJINNI_OBJC_INCLUDE_DIR}${LIBRARY_TARGET}/)
    set(DJINNI_OBJCPP_INCLUDE_DIR ${DJINNI_DIRECTORY}/objcpp/include/)
    set(DJINNI_OBJCPP_OUT ${DJINNI_DIRECTORY}/objcpp/src/)
    set(DJINNI_OBJCPP_HEADER_OUT ${DJINNI_OBJCPP_INCLUDE_DIR}${LIBRARY_TARGET}/)
    set(DJINNI_OBJCPP_INCLUDE_PREFIX ${LIBRARY_TARGET}/)
    set(DJINNI_CPPCLI_OUT ${DJINNI_DIRECTORY}/cppcli/src/)
    set(DJINNI_JAVA_OUT ${DJINNI_DIRECTORY}/java/${DJINNI_JAVA_PATH})
    set(DJINNI_OBJC_SWIFT_BRIDGING_HEADER ${LIBRARY_TARGET})
    set(DJINNI_JAVA_LIBRARY_TARGET ${LIBRARY_TARGET}-java)

    # trigger re-generation if IDL file changes
    set_directory_properties(PROPERTIES CMAKE_CONFIGURE_DEPENDS ${DJINNI_IDL})

    # find Djinni executable.
    # On Windows `find_program()` does not work for finding the `djinni.bat` script.
    # The script must either be
    # - on the PATH
    # - explicitly predefined in cache variable `DJINNI_EXECUTABLE`
    # - installed from conan
    if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
        # If the the generator is installed from conan, use find_package to get the installation path
        find_package(djinni-generator QUIET)
        if(djinni-generator_FOUND)
            find_file(DJINNI_EXECUTABLE bin/djinni.bat REQUIRED)
        else()
            # Otherwise just set the executable and hope that the binary is on the path
            set(DJINNI_EXECUTABLE djinni.bat CACHE FILEPATH "path of djinni binary")
        endif()
    else()
        find_program(DJINNI_EXECUTABLE djinni REQUIRED)
    endif()

    # output djinni version
    execute_process(COMMAND ${DJINNI_EXECUTABLE} --version
        OUTPUT_VARIABLE DJINNI_VERSION_OUTPUT)
    message(STATUS "${MESSAGE_PREFIX} ${DJINNI_VERSION_OUTPUT}")

    # generate Java sources and add prepare parameters for JNI generation.
    if("JAVA" IN_LIST DJINNI_LANGUAGES)
        if(DJINNI_NO_JNI_MAIN)
            set(DJINNI_GENERATE_MAIN false)
        else()
            set(DJINNI_GENERATE_MAIN true)
        endif()
        set(ADDITIONAL_DJINNI_PARAMETERS
            --java-out ${DJINNI_JAVA_OUT}
            --jni-out ${DJINNI_JNI_OUT}
            --jni-header-out ${DJINNI_JNI_HEADER_OUT}
            --jni-generate-main ${DJINNI_GENERATE_MAIN})
    endif()
    if("OBJC" IN_LIST DJINNI_LANGUAGES)
        set(ADDITIONAL_DJINNI_PARAMETERS
            --objc-out ${DJINNI_OBJC_OUT}
            --objc-header-out ${DJINNI_OBJC_HEADER_OUT}
            --objcpp-out ${DJINNI_OBJCPP_OUT}
            --objcpp-header-out ${DJINNI_OBJCPP_HEADER_OUT}
            --objc-swift-bridging-header ${DJINNI_OBJC_SWIFT_BRIDGING_HEADER})
    endif()
    if("CPPCLI" IN_LIST DJINNI_LANGUAGES)
        set(ADDITIONAL_DJINNI_PARAMETERS
            --cppcli-out ${DJINNI_CPPCLI_OUT}
        )
    endif()
    if("CPP" IN_LIST DJINNI_LANGUAGES)
        set(ADDITIONAL_DJINNI_PARAMETERS
            --cpp-out ${DJINNI_CPP_SRC_DIR}
            --cpp-header-out ${DJINNI_CPP_HEADER_OUT}
        )
    endif()

    set(DJINNI_GENERATED_FILES_OUTFILE ${CMAKE_CURRENT_BINARY_DIR}/djinni-generated-files.txt)
    message(STATUS "${MESSAGE_PREFIX} Generating Gluecode for ${DJINNI_LANGUAGES}")

    if(NOT DJINNI_NO_OBJC_PREFIX)
        list(APPEND ADDITIONAL_DJINNI_PARAMETERS --objc-type-prefix ${DJINNI_OBJC_PREFIX})
    endif()


    # generate c++ interface
    execute_process(COMMAND ${DJINNI_EXECUTABLE}
            --idl ${DJINNI_IDL}
            ${DJINNI_IDL_INCLUDE_PARAMETERS}
            --cppcli-namespace ${DJINNI_CPPCLI_NAMESPACE}
            --cppcli-include-cpp-prefix ${DJINNI_CPP_INCLUDE_PREFIX}
            --cpp-namespace ${DJINNI_NAMESPACE}
            --java-package ${DJINNI_JAVA_PACKAGE}
            --jni-namespace ${DJINNI_JNI_NAMESPACE}
            --jni-include-prefix ${DJINNI_JNI_INCLUDE_PREFIX}
            --jni-include-cpp-prefix ${DJINNI_JNI_INCLUDE_CPP_PREFIX}
            --cpp-include-prefix ${DJINNI_CPP_INCLUDE_PREFIX}
            --objc-include-prefix ${DJINNI_OBJC_INCLUDE_PREFIX}
            --objcpp-include-cpp-prefix ${DJINNI_OBJCPP_INCLUDE_CPP_PREFIX}
            --objcpp-include-objc-prefix ${DJINNI_OBJC_INCLUDE_PREFIX}
            --objcpp-include-prefix ${DJINNI_OBJCPP_INCLUDE_PREFIX}
            --objcpp-namespace ${DJINNI_OBJCPP_NAMESPACE}
            --list-out-files ${DJINNI_GENERATED_FILES_OUTFILE}
            ${ADDITIONAL_DJINNI_PARAMETERS}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    )

    file(STRINGS ${DJINNI_GENERATED_FILES_OUTFILE} DJINNI_GENERATED_FILES
        ENCODING UTF-8)

    # filter out java files from generated files
    set(DJINNI_GENERATED_JAVA_FILES_REGEX "${DJINNI_JAVA_OUT}.*")
    set(DJINNI_GENERATED_JAVA_FILES ${DJINNI_GENERATED_FILES})
    list(FILTER DJINNI_GENERATED_JAVA_FILES INCLUDE REGEX ${DJINNI_GENERATED_JAVA_FILES_REGEX})

    set(DJINNI_GENERATED_CPP_FILES ${DJINNI_GENERATED_FILES})
    list(FILTER DJINNI_GENERATED_CPP_FILES EXCLUDE REGEX ${DJINNI_GENERATED_JAVA_FILES_REGEX})

    if(DJINNI_STATIC)
        set(DJINNI_LIBRARY_TYPE STATIC)
    elseif(DJINNI_SHARED)
        set(DJINNI_LIBRARY_TYPE SHARED)
    endif()

    add_library(${LIBRARY_TARGET} ${DJINNI_LIBRARY_TYPE} ${DJINNI_GENERATED_CPP_FILES} ${DJINNI_SOURCES} ${DJINNI_GENERATED_OTHER_FILES})
    target_include_directories(${LIBRARY_TARGET} PUBLIC ${DJINNI_CPP_INCLUDE_DIR})

    if("JAVA" IN_LIST DJINNI_LANGUAGES)
        find_package(Java 1.8 REQUIRED)
        include(UseJava)

        add_jar(${DJINNI_JAVA_LIBRARY_TARGET}
                SOURCES ${DJINNI_GENERATED_JAVA_FILES}
                OUTPUT_DIR ${DJINNI_JAR_OUTPUT_DIR}
                OUTPUT_NAME ${LIBRARY_TARGET})

        add_dependencies(${LIBRARY_TARGET} ${DJINNI_JAVA_LIBRARY_TARGET})
        target_include_directories(${LIBRARY_TARGET} PUBLIC ${DJINNI_JNI_INCLUDE_DIR})
    endif()
    if("OBJC" IN_LIST DJINNI_LANGUAGES)
        target_include_directories(${LIBRARY_TARGET} PUBLIC ${DJINNI_OBJC_INCLUDE_DIR} ${DJINNI_OBJCPP_INCLUDE_DIR})

        set(DJINNI_OBJC_SWIFT_BRIDGING_HEADER_PATH "${DJINNI_OBJC_HEADER_OUT}${DJINNI_OBJC_SWIFT_BRIDGING_HEADER}.h")
        target_sources(${LIBRARY_TARGET} PUBLIC ${DJINNI_OBJC_SWIFT_BRIDGING_HEADER_PATH})
        # determine framework public headers
        set(DJINNI_GENERATED_PUBLIC_HEADER_FILES ${DJINNI_GENERATED_CPP_FILES})
        list(APPEND DJINNI_GENERATED_PUBLIC_HEADER_FILES ${DJINNI_OBJC_SWIFT_BRIDGING_HEADER_PATH})
        list(FILTER DJINNI_GENERATED_PUBLIC_HEADER_FILES INCLUDE REGEX "^${DJINNI_OBJC_HEADER_OUT}.*$")

        set_target_properties(${LIBRARY_TARGET} PROPERTIES
            FRAMEWORK TRUE
            MACOSX_FRAMEWORK_IDENTIFIER ${DJINNI_JAVA_PACKAGE}
            PUBLIC_HEADER "${DJINNI_GENERATED_PUBLIC_HEADER_FILES}"
            XCODE_ATTRIBUTE_DEFINES_MODULE YES
            XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC YES
        )
    endif()
    if("CPP" IN_LIST DJINNI_LANGUAGES)
        install(
            DIRECTORY
                ${DJINNI_CPP_INCLUDE_DIR}
            DESTINATION include
        )
        install(TARGETS ${LIBRARY_TARGET} EXPORT ${LIBRARY_TARGET}Targets
            LIBRARY DESTINATION lib
            FRAMEWORK DESTINATION lib
            INCLUDES DESTINATION include
            PUBLIC_HEADER DESTINATION include
        )
    endif()
endfunction()