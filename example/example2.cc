#include <iostream>

#include <myresources/resources.h>

int main(int argc, char** argv)
{
  // range based loop over all resources
  std::cout << "Range based loop" << std::endl;
  for (const auto& res : myresources::embeddedResources())
  {
    std::cout << " - " << res.prefix << res.name << ", size=" << res.size << std::endl;
    // res.data: pointer to data array of size res->size
  }

  return 0;
}