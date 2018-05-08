cmake_minimum_required(VERSION 3.9 FATAL_ERROR)
project(tapasco VERSION 1.0 LANGUAGES C CXX)

SET(CPACK_GENERATOR "RPM" "DEB" "TGZ" "ZIP" "STGZ" "TBZ2")
SET(CPACK_PACKAGE_CONTACT "Jens Korinth")
SET(CPACK_PACKAGE_CONTACT "korinth@esa.tu-darmstadt.de")

INCLUDE(CPack)

include(GNUInstallDirs)

set(CMNDIR "${CMAKE_CURRENT_SOURCE_DIR}/common")

include(CheckIPOSupported)
check_ipo_supported(RESULT ipo_supported)
if(ipo_supported)
    message("-- IPO is supported!")
    set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)
else()
    message(WARNING "IPO is not supported!")
endif()

set(CMAKE_DEBUG_POSTFIX d)

set (CMAKE_CXX_STANDARD 11)
set (CMAKE_C_STANDARD 11)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Werror")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Werror")

add_subdirectory(platform)
add_subdirectory(arch/axi4mm)
add_subdirectory(arch/tests)