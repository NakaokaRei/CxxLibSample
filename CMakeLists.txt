cmake_minimum_required(VERSION 3.15)
project(CxxLibSample VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED YES)

add_library(CxxLibSample STATIC
    source/sample.cpp
    include/sample.h
)

target_include_directories(CxxLibSample PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)
