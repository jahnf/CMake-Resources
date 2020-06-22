# CMake Module for embedding resources in cmake c++ targets.
# https://github.com/jahnf/CMake-Resources - see LICENSE
#
# USAGE: 1) include this file
#        2) use add_resources_library function
#        3) link any of your executable targets to your resources library target
#
# EXAMPLE:
#   (assumption: all related module files are in ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules)
#
#   ## -- myresource.json
#   {
#     "CRES": [
#       {
#         "prefix": "sources/",
#         "files": [
#           { "name": "example.cc" },
#           { "name": "example.cc", "alias": "example-alias.cc" }
#         ]
#       },
#       {
#         "prefix": "data-files/",
#         "files": [
#           { "name": "../.gitignore", "alias": "ignored-files.txt"},
#           { "name": "../README.md", "alias": "README.txt" }
#         ]
#       }
#     ]
#   }
#
#
#   ## -- CMakeLists.txt
#   list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules")
#   include(Resources)
#
#   add_resources_library(myresources myresource.json)
#
#   add_executable(example main.cc)
#   target_link_libraries(example myresources)
#
#   ## -- main.cc
#   #include <myresources/resources.h>
#   #include <iostream>
#
#   int main(int argc, char** argv)
#   {
#     // access your embedded resources here.. (see example for details)
#     exit 0;
#   }
#

set(_Resources_Module_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}")

# add_resource_library(<name> [PREFIX <prefix>] FILES config1.json... [QUIET])
function(add_resources_library tgtname)
  # currently we need at least python 2.7 because of the usage argparse
  find_package(PythonInterp 2.7 REQUIRED)

  if(TARGET ${tgtname})
    message(FATAL_ERROR "Target '${tgtname}' already exists.")
  endif()

  set(options QUIET)
  set(oneValueArgs PREFIX) # Custom prefix/name, must be a valid c identifier, default is a c-identifier form targetname
  set(multiValueArgs FILES) # List of resource config files
  set(requiredArgs FILES)
  cmake_parse_arguments(RES "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  foreach(arg IN LISTS requiredArgs)
    if("${RES_${arg}}" STREQUAL "")
      message(FATAL_ERROR "Required argument '${arg}' is not set.")
    endif()
  endforeach()

  string(MAKE_C_IDENTIFIER "${tgtname}" tgtid)
  if(NOT RES_PREFIX)
    set(RES_PREFIX "${tgtid}")
  endif()

  set(mkcres_script ${_Resources_Module_DIRECTORY}/Resources.py)
  set(mkcres_res_target "${tgtname}-res-update")
  set(mkcres_res_force_target "${tgtname}-res-force-rewrite")
  set(mkcres_outdir ${CMAKE_CURRENT_BINARY_DIR}/${tgtname}_resources)
  set(mkcres_outfile ${mkcres_outdir}/cres_files.cmake)

  # script update command arguments
  set(resources_update_args create --list-outfile "${mkcres_outfile}" --list-cmake-prefix=${tgtid}
                                   --outdir "${mkcres_outdir}" --name "${RES_PREFIX}"
                                   ${RES_FILES})

  if(RES_QUIET)
    list(APPEND resources_update_args "--quiet")
  endif()

  add_custom_target(${mkcres_res_target} "${PYTHON_EXECUTABLE}" "${mkcres_script}"
                    ${resources_update_args}
                    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})

  add_custom_target(${mkcres_res_force_target} "${PYTHON_EXECUTABLE}" "${mkcres_script}"
                    ${resources_update_args} --force
                    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})

  set_target_properties(${mkcres_res_target} ${mkcres_res_force_target}
                        PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD ON)

  if(NOT EXISTS "${mkcres_outfile}")
    if(NOT RES_QUIET)
      message(STATUS "Creating initial resources for target '${tgtname}' in namespace '${RES_PREFIX}'")
    endif()
    execute_process(COMMAND "${PYTHON_EXECUTABLE}" "${mkcres_script}"
                    ${resources_update_args} --force
                    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                    ERROR_VARIABLE error_out
                    RESULT_VARIABLE result)
    if(NOT result EQUAL 0)
      message(FATAL_ERROR "Error during resource file creation: ${error_out}")
    endif()
  endif()

  set(resources_source_file "${CMAKE_BINARY_DIR}/cmake_resources/include/cmake_resources/resources.cc")
  configure_file("${_Resources_Module_DIRECTORY}/ResourceTypes.h.in"
                 "${CMAKE_BINARY_DIR}/cmake_resources/include/cmake_resources/types.h" @ONLY)
  configure_file("${_Resources_Module_DIRECTORY}/Resources.cc.in" "${resources_source_file}" @ONLY)

  include("${mkcres_outfile}")
  set(RESOURCES_COUNT ${${tgtname}_CRES_COUNT})
  set(SECTION_COUNT ${${tgtname}_CRES_SECTION_COUNT})
  set(PREFIX ${RES_PREFIX})

  configure_file("${_Resources_Module_DIRECTORY}/Resources.h.in"
                 "${mkcres_outdir}/${RES_PREFIX}/resources.h" @ONLY)

  if(NOT TARGET resourceslib)
    add_library(resourceslib STATIC EXCLUDE_FROM_ALL "${resources_source_file}")
    target_include_directories(resourceslib
      PUBLIC
        "${CMAKE_BINARY_DIR}/cmake_resources/include"
    )
  endif()

  add_library(${tgtname} STATIC EXCLUDE_FROM_ALL ${${tgtname}_CRES_SOURCE_FILES})
  add_dependencies(${tgtname} ${mkcres_res_target})
  target_link_libraries(${tgtname} PUBLIC resourceslib)
  target_include_directories(${tgtname} PUBLIC "${mkcres_outdir}")

  # Add .json config files to resource library target (makes them showing up in IDE projects)
  foreach(configfile ${RES_FILES})
    target_sources(${tgtname} PRIVATE "${configfile}")
    set_source_files_properties("${configfile}" PROPERTIES HEADER_FILE_ONLY TRUE)
  endforeach()

  if(NOT TARGET resources-update)
    add_custom_target(resources-update)
    set_target_properties(resources-update PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD ON)
  endif()
  add_dependencies(resources-update ${mkcres_res_target})

  if(NOT TARGET resources-force-rewrite)
    add_custom_target(resources-force-rewrite)
    set_target_properties(resources-force-rewrite PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD ON)
  endif()
  add_dependencies(resources-force-rewrite ${mkcres_res_force_target})
endfunction()
