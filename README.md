# CMake-Resources

Python script and CMake functionality to easily embed and maintain resource files into
C++ executables and libraries.

## Example Usage

For a ready to use example have a look into the `./example` directory.

### 1. Configure resources in JSON file(s)

Configure resources you want to embed in a JSON file, example: `resources.json`

```json
{
  "CRES": [
    {
      "prefix": "sources/",
      "files": [
        { "name": "example.cc" },
        { "name": "example.cc", "alias": "example-alias.cc" }
      ]
    },
    {
      "prefix": "other-data/",
      "files": [
        { "name": "CMakeLists.txt" },
        { "name": "resources.json" }
      ]
    }
  ]
}
```
### 2. Include module in your `CMakeLists.txt` and add resource library

Example:

```cmake
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(Resources)

# Creates a library target `resources` that can be used by and linked against all other targets.
add_resources_library(myresources resources.json)
```

### 3. Link against the resource library

```cmake
add_executable(example example.cc)
target_link_libraries(example PRIVATE myresources)
```

### 4. Include header and list or access embedded files

`example.cc`
```cpp
#include <iostream>
#include <myresources/resources.h>

int main(int argc, char** argv)
{
  // List all embedded resources
  for (const auto& res : myresources::embeddedResources())
  {
    std::cout << " - " << res.prefix << res.name << ", size=" << res.size << std::endl;
  }

  // Find and access specific embedded resource file
  // via operator[]
  if (const auto res = myresources::embeddedResources()["sources/example.cc"])
  {
    std::cout << " - " << res->prefix << res->name << ", size=" << res->size << std::endl;
    // res->data: pointer to data array of size res->size
  }

  // via get_resource function
  if (const auto res = myresources::get_resource("sources/example.cc"))
  {
    std::cout << " - " << res->prefix << res->name << ", size=" << res->size << std::endl;
  }

  return 0;
}
```


## Future Ideas/Todos

* Do some benchmarking and compare current implementation with an implementation that uses
  compile time maps (or unordered_maps) (See: https://github.com/serge-sans-paille/frozen)