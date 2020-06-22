cmake_minimum_required(VERSION 3.1)

# Add directory of CMake-Resources to the cmake module path.
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../cmake")

# Now it can be included like this:
include(Resources)

# Examples project
project(Resources-Demo LANGUAGES CXX)

# Example resource library put together with two json configs
add_resources_library(reslib1 FILES res-example1.json res-example2.json)

# Example resource library put together with one json config and custom PREFIX name
add_resources_library(reslib2 PREFIX myresources FILES res-example3.json)


# Create example executable that uses the example resource library
add_executable(example example.cc)
target_link_libraries(example PRIVATE reslib1)

# Create example executable that uses the example resource library
add_executable(example2 example2.cc)
target_link_libraries(example2 PRIVATE reslib2)