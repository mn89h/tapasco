cmake_minimum_required(VERSION 3.5.1 FATAL_ERROR)
include($ENV{TAPASCO_HOME_RUNTIME}/cmake/Tapasco.cmake NO_POLICY_SCOPE)
project (memorybenchseq)

if(NOT TARGET tapasco)
find_package(TapascoTLKM REQUIRED)
find_package(TapascoCommon REQUIRED)
find_package(TapascoPlatform REQUIRED)
find_package(Tapasco REQUIRED)
endif(NOT TARGET tapasco)

find_package (Threads)

add_executable(memorybenchseq memorybenchseq-example.c)
set_tapasco_defaults(memorybenchseq)
target_link_libraries(memorybenchseq tapasco ${CMAKE_THREAD_LIBS_INIT} platform tlkm)

install(TARGETS memorybenchseq
        ARCHIVE  DESTINATION share/Tapasco/bin/
        LIBRARY  DESTINATION share/Tapasco/bin/
        RUNTIME  DESTINATION share/Tapasco/bin/)

