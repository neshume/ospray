## Copyright 2009-2021 Intel Corporation
## SPDX-License-Identifier: Apache-2.0

## Global settings ##

cmake_minimum_required(VERSION 3.1)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/dependencies)

if(NOT CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX
      "${CMAKE_BINARY_DIR}/install"
      CACHE STRING "Final install location." FORCE)
endif()

if (NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()
if (NOT DEPENDENCIES_BUILD_TYPE)
  set(DEPENDENCIES_BUILD_TYPE Release)
endif()

## Establish project ##

project(OSPRay_superbuild)

if(CMAKE_SIZEOF_VOID_P EQUAL 4)
  message(FATAL_ERROR "OSPRay can only be built on 64-bit platforms. This
  problem most commonly happens on Windows, where the right solution is to
  switch to a 64-bit generator: retry running CMake with '-G \"Visual
  Studio 15 2017 Win64\"'")
else()
  message(STATUS "Proceeding with a 64-bit generator. (${CMAKE_SIZEOF_VOID_P})")
endif()

if (POLICY CMP0114)
  # allow old CMake behavior: NO_DEPENDS for ExternalProject_Add_StepTargets
  cmake_policy(SET CMP0114 OLD) # 3.19
endif ()

include(ExternalProject)
include(GNUInstallDirs)
include(ProcessorCount)
include(CMakeDependentOption)

## Superbuild options ##

ProcessorCount(PROCESSOR_COUNT)

if(NOT PROCESSOR_COUNT EQUAL 0)
  set(BUILD_JOBS ${PROCESSOR_COUNT} CACHE STRING "Number of build jobs '-j <n>'")
else()
  set(BUILD_JOBS 4 CACHE STRING "Number of build jobs '-j <n>'")
endif()

option(ALWAYS_REBUILD "Force every project to always be rebuilt?" OFF)

option(DOWNLOAD_ISPC "Download ispc or use the one found in ${PATH}?" ON)
set(ISPC_VERSION "v1.15.0" CACHE STRING "Which version of ISCP to download?")

set(BUILD_RKCOMMON_VERSION "v1.6.0" CACHE STRING "Which version of rkcommon to build?")

option(DOWNLOAD_TBB "Download TBB or use the only found in the system environment?" ON)
set(TBB_VERSION "2021.1.1" CACHE STRING "Which version of TBB to download?")

set(BUILD_EMBREE_VERSION "v3.12.2" CACHE STRING "Which version of Embree to build?")
option(BUILD_EMBREE_FROM_SOURCE "Build Embree or use pre-built version?" ON)

set(BUILD_OPENVKL_VERSION "v0.12.0" CACHE STRING "Which version of OpenVKL to build?")

option(BUILD_OIDN "Build OpenImageDenoise as a part of the superbuild." OFF)
set(BUILD_OIDN_VERSION "v1.3.0" CACHE STRING "Which version of OpenImageDenoise to build?")
option(BUILD_OIDN_FROM_SOURCE "Build OpenImageDenoise or use pre-built version?" OFF)

option(BUILD_GLFW "Build glfw for OSPRay examples or use one in existing environment?" ON)

option(BUILD_DEPENDENCIES_ONLY "Don't build OSPRay itself, only its dependencies" OFF)
option(BUILD_OSPRAY_CI_EXTRAS "Enable OSPRay's extra compiler checks." OFF)

option(BUILD_OSPRAY_APPS "Enable building OSPRay apps" ON)
option(BUILD_OSPRAY_MODULE_MPI "Enable building module_mpi" OFF)

option(INSTALL_IN_SEPARATE_DIRECTORIES
  "Install libraries into their own directories under CMAKE_INSTALL_PREFIX"
  ON
)

option(INSTALL_DEPENDENCIES "Install OSPRay dependencies" ON)

## Setup top-level variables ##

set(installDir ${CMAKE_INSTALL_PREFIX})

get_filename_component(INSTALL_DIR_ABSOLUTE
  ${installDir} ABSOLUTE BASE_DIR ${CMAKE_CURRENT_BINARY_DIR})

if (${CMAKE_VERSION} VERSION_GREATER 3.11.4)
  set(PARALLEL_JOBS_OPTS -j ${BUILD_JOBS})
endif()

## Build dependencies ##
set(DEFAULT_BUILD_COMMAND ${CMAKE_COMMAND} --build . --config ${DEPENDENCIES_BUILD_TYPE} ${PARALLEL_JOBS_OPTS})

if (DOWNLOAD_ISPC)
  include(dep_ispc)
endif()

if (DOWNLOAD_TBB)
  include(dep_tbb)
endif()

include(dep_rkcommon)
include(dep_embree)
include(dep_openvkl)

if (BUILD_GLFW)
  include(dep_glfw)
endif()

if (BUILD_OIDN)
  include(dep_oidn)
endif()

include(dep_glm)

## Build main projects ##
set(DEFAULT_BUILD_COMMAND ${CMAKE_COMMAND} --build . --config ${CMAKE_BUILD_TYPE} ${PARALLEL_JOBS_OPTS})

if (BUILD_OSPRAY_MODULE_MPI)
  set(OSPRAY_ENABLE_MODULES ON)
  set(OSPRAY_MODULE_MPI ON)
endif()

if (NOT BUILD_DEPENDENCIES_ONLY)
  include(build_ospray.cmake)
endif()
