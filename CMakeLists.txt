cmake_minimum_required(VERSION 3.0)
project(tapasco VERSION 1.0 LANGUAGES C CXX)

SET(CPACK_GENERATOR "RPM" "DEB" "TGZ" "ZIP" "STGZ" "TBZ2")
SET(CPACK_PACKAGE_CONTACT "korinth@esa.tu-darmstadt.de")

INCLUDE(CPack)

include(GNUInstallDirs)

set(CMNDIR "${CMAKE_CURRENT_SOURCE_DIR}/common")


if(${CMAKE_VERSION} VERSION_LESS "3.9.0")
    SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -flto -fno-fat-lto-objects")
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

set(CMAKE_DEBUG_POSTFIX d)

set (CMAKE_CXX_STANDARD 11)
set (CMAKE_C_STANDARD 11)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Werror")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Werror")

add_subdirectory(platform)
add_subdirectory(arch/axi4mm)
add_subdirectory(arch/tests)