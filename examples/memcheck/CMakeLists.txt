cmake_minimum_required(VERSION 3.9)

if(${CMAKE_VERSION} VERSION_LESS "3.9.0")
    SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -flto")
else()
    cmake_minimum_required(VERSION 3.9)
    include(CheckIPOSupported)
    check_ipo_supported(RESULT ipo_supported)
    if(ipo_supported)
        message("-- IPO is supported!")
        set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)
    else()
        message(WARNING "IPO is not supported!")
    endif()
endif()

set (CMAKE_CXX_STANDARD 11)
set (CMAKE_C_STANDARD 11)

project (memcheck)

find_package(TapascoPlatform REQUIRED)
find_package(Tapasco REQUIRED)

add_executable(memcheck memcheck.c)
target_link_libraries(memcheck tapasco pthread platform)

add_executable(memcheck-mt memcheck-mt.c)
target_link_libraries(memcheck-mt pthread tapasco platform)

install(TARGETS memcheck memcheck-mt
        ARCHIVE  DESTINATION bin/
        LIBRARY  DESTINATION bin/
        RUNTIME  DESTINATION bin/)

