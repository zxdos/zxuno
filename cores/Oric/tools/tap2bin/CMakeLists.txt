cmake_minimum_required(VERSION 3.0)
add_definitions(-std=c++11)
set(CMAKE_EXE_LINKER_FLAGS "-static-libgcc -static-libstdc++ -static")
add_executable(tap2bin tap2bin.cpp)

