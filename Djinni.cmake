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

function(djinni LIBRARY_TARGET)
    cmake_parse_arguments(DJINNI
        # options
            ""
        # one-value keywords
            "IDL;NAMESPACE;DIRECTORY;JAR_OUTPUT_DIR"
        # multi-value keywords
            ""
        # args
            ${ARGN}
    )

    find_package(djinni-support-lib)

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
    set(DJINNI_OBJCPP_NAMESPACE "${DJINNI_NAMESPACE}::objcpp")

    string(REPLACE "::" "." DJINNI_JAVA_PACKAGE ${DJINNI_NAMESPACE})
    string(TOLOWER ${DJINNI_JAVA_PACKAGE} DJINNI_JAVA_PACKAGE)
    string(TOLOWER ${DJINNI_JAVA_PACKAGE} DJINNI_JAVA_PATH)
    string(REPLACE "." "/" DJINNI_JAVA_PATH ${DJINNI_JAVA_PATH})

    string(REGEX REPLACE "[a-z:\\-_]" "" DJINNI_OBJC_PREFIX ${DJINNI_NAMESPACE})

    # prepare input variables
    set(DJINNI_INCLUDE_DIR ${DJINNI_DIRECTORY}/include)
    set(DJINNI_CPP_OUT ${DJINNI_DIRECTORY}/cpp/src)
    set(DJINNI_CPP_INCLUDE_PREFIX ${DJINNI_NAMESPACE_PATH}/)
    set(DJINNI_CPP_INCLUDE_DIR ${DJINNI_DIRECTORY}/cpp/include/)
    set(DJINNI_CPP_HEADER_OUT ${DJINNI_CPP_INCLUDE_DIR}/${DJINNI_CPP_INCLUDE_PREFIX})
    set(DJINNI_JNI_OUT ${DJINNI_DIRECTORY}/jni/src)
    set(DJINNI_JNI_INCLUDE_PREFIX ${DJINNI_NAMESPACE_PATH}/jni/)
    set(DJINNI_JNI_INCLUDE_DIR ${DJINNI_DIRECTORY}/jni/include/)
    set(DJINNI_JNI_HEADER_OUT ${DJINNI_JNI_INCLUDE_DIR}/${DJINNI_JNI_INCLUDE_PREFIX})
    set(DJINNI_JNI_INCLUDE_CPP_PREFIX ${DJINNI_NAMESPACE_PATH}/)
    set(DJINNI_OBJC_OUT ${DJINNI_DIRECTORY}/objc/src)
    set(DJINNI_OBJC_INCLUDE_PREFIX ${DJINNI_NAMESPACE_PATH}/objc/)
    set(DJINNI_OBJCPP_INCLUDE_CPP_PREFIX ${DJINNI_NAMESPACE_PATH}/)
    set(DJINNI_OBJC_INCLUDE_DIR ${DJINNI_DIRECTORY}/objc/include/)
    set(DJINNI_OBJC_HEADER_OUT ${DJINNI_OBJC_INCLUDE_DIR}/${DJINNI_OBJC_INCLUDE_PREFIX})
    set(DJINNI_OBJCPP_OUT ${DJINNI_DIRECTORY}/objcpp/src/)
    set(DJINNI_JAVA_OUT ${DJINNI_DIRECTORY}/java/${DJINNI_JAVA_PATH})
    set(DJINNI_OBJC_SWIFT_BRIDGING_HEADER ${LIBRARY_TARGET})
    set(DJINNI_JAVA_LIBRARY_TARGET ${LIBRARY_TARGET}-android)

    find_program(DJINNI_EXECUTABLE djinni REQUIRED)

    # output djinni version
    execute_process(COMMAND ${DJINNI_EXECUTABLE} --version
        OUTPUT_VARIABLE DJINNI_VERSION_OUTPUT)
    message(STATUS "${MESSAGE_PREFIX} ${DJINNI_VERSION_OUTPUT}")

    set(DARWIN_OS_LIST "Darwin;iOS;tvOS;watchOS")
    if(CMAKE_SYSTEM_NAME IN_LIST DARWIN_OS_LIST)
        set(DARWIN 1)
    endif()
    if(ANDROID)
        find_package(Java 1.8 REQUIRED)
        include(UseJava)

        set(DJINNI_GENERATED_JAVA_FILES_OUTFILE ${CMAKE_CURRENT_BINARY_DIR}/djinni-generated-java-files.txt)

        message(STATUS "${MESSAGE_PREFIX} Generating Java Gluecode")
        # generate java code
        execute_process(COMMAND ${DJINNI_EXECUTABLE}
                --idl ${DJINNI_IDL}
                --java-out ${DJINNI_JAVA_OUT}
                --java-package ${DJINNI_JAVA_PACKAGE}
                --list-out-files ${DJINNI_GENERATED_JAVA_FILES_OUTFILE}
                WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                )

        file(STRINGS ${DJINNI_GENERATED_JAVA_FILES_OUTFILE} DJINNI_GENERATED_JAVA_FILES
                ENCODING UTF-8)

        add_jar(${DJINNI_JAVA_LIBRARY_TARGET}
                SOURCES ${DJINNI_GENERATED_JAVA_FILES}
                OUTPUT_DIR ${DJINNI_JAR_OUTPUT_DIR}
                OUTPUT_NAME ${LIBRARY_TARGET})

        set(ADDITIONAL_DJINNI_PARAMETERS
                --jni-out ${DJINNI_JNI_OUT}
                --jni-header-out ${DJINNI_JNI_HEADER_OUT}
                --jni-namespace ${DJINNI_JNI_NAMESPACE}
                --jni-include-prefix ${DJINNI_JNI_INCLUDE_PREFIX}
                --jni-include-cpp-prefix ${DJINNI_JNI_INCLUDE_CPP_PREFIX})

    elseif(DARWIN)
        set(ADDITIONAL_DJINNI_PARAMETERS
                --objc-out ${DJINNI_OBJC_OUT}
                --objc-header-out ${DJINNI_OBJC_HEADER_OUT}
                --objc-type-prefix ${DJINNI_OBJC_PREFIX}
                --objcpp-out ${DJINNI_OBJCPP_OUT}
                --objcpp-namespace ${DJINNI_OBJCPP_NAMESPACE}
                --objc-include-prefix ${DJINNI_OBJC_INCLUDE_PREFIX}
                --objcpp-include-cpp-prefix ${DJINNI_OBJCPP_INCLUDE_CPP_PREFIX}
                --objcpp-include-objc-prefix ${DJINNI_OBJC_INCLUDE_PREFIX}
                --objc-swift-bridging-header ${DJINNI_OBJC_SWIFT_BRIDGING_HEADER})
    endif()

    set(DJINNI_GENERATED_FILES_OUTFILE ${CMAKE_CURRENT_BINARY_DIR}/djinni-generated-files.txt)

    message(STATUS "${MESSAGE_PREFIX} Generating C++ Gluecode")
    # generate c++ interface
    execute_process(COMMAND ${DJINNI_EXECUTABLE}
            --idl ${DJINNI_IDL}
            --cpp-out ${DJINNI_CPP_OUT}
            --cpp-namespace ${DJINNI_NAMESPACE}
            --cpp-header-out ${DJINNI_CPP_HEADER_OUT}
            --cpp-include-prefix ${DJINNI_CPP_INCLUDE_PREFIX}
            --list-out-files ${DJINNI_GENERATED_FILES_OUTFILE}
            ${ADDITIONAL_DJINNI_PARAMETERS}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    )

    file(STRINGS ${DJINNI_GENERATED_FILES_OUTFILE} DJINNI_GENERATED_CPP_FILES
        ENCODING UTF-8)

    add_library(${LIBRARY_TARGET} ${DJINNI_GENERATED_CPP_FILES})

    target_compile_features(${LIBRARY_TARGET} PUBLIC cxx_std_17)

    target_include_directories(${LIBRARY_TARGET} PUBLIC ${DJINNI_CPP_INCLUDE_DIR})

    target_link_libraries(${LIBRARY_TARGET} PUBLIC djinni-support-lib::djinni-support-lib)

    install(DIRECTORY ${DJINNI_DIRECTORY}/cpp/include/
            DESTINATION include)

    if(ANDROID)
        add_dependencies(${LIBRARY_TARGET} ${DJINNI_JAVA_LIBRARY_TARGET})
        target_include_directories(${LIBRARY_TARGET} PUBLIC ${DJINNI_JNI_INCLUDE_DIR})
        install(DIRECTORY ${DJINNI_DIRECTORY}/jni/include/
                DESTINATION include)
    elseif(DARWIN)
        target_compile_options(${LIBRARY_TARGET} PRIVATE -fobjc-arc)
        target_include_directories(${LIBRARY_TARGET} PUBLIC ${DJINNI_OBJC_INCLUDE_DIR})
        install(DIRECTORY ${DJINNI_DIRECTORY}/objc/include/
                DESTINATION include)
    endif()

endfunction()