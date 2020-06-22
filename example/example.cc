#include <iostream>

#include <reslib1/resources.h>

int main(int argc, char** argv)
{
  // range based loop over all resources
  std::cout << "Range based loop" << std::endl;
  for (const auto& res : reslib1::embeddedResources())
  {
    std::cout << " - " << res.prefix << res.name << ", size=" << res.size << std::endl;
    // res.data: pointer to data array of size res->size
  }

  // lookup resource with file path
  std::cout << std::endl << "Resource lookup via [] operator" << std::endl;
  if (const auto res = reslib1::embeddedResources()["sources/example.cc"])
  {
    std::cout << " - " << res->prefix << res->name << ", size=" << res->size << std::endl;
    // res->data: pointer to data array of size res->size
  }
  std::cout << "Resource lookup via function" << std::endl;
  if (const auto res = reslib1::get_resource("sources/example.cc"))
  {
    std::cout << " - " << res->prefix << res->name << ", size=" << res->size << std::endl;
    // res->data: pointer to data array of size res->size
  }

  return 0;
}