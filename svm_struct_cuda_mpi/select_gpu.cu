/*
  Select a device according to rank
  author: Yu Xiang
  Date: 05/12/2011
*/

extern "C"
{
#include "select_gpu.h"
}
#include "cutil_inline.h"

void select_gpu(int rank)
{
  /* get device count */
  int deviceCount = 0;
  if(cudaGetDeviceCount(&deviceCount) != cudaSuccess)
  {
    printf("cudaGetDeviceCount FAILED CUDA Driver and Runtime version may be mismatched.\n");
    exit(1);
  }
  if(rank == 0)
    printf("%d CUDA enabled devices available.\n", deviceCount);

  int deviceID = rank % deviceCount;
  if(cudaSetDevice(deviceID) != cudaSuccess)
  {
    printf("cudaSetDevice FAILED\n");
    exit(1);
  }
  printf("Process %d is running on GPU %d.\n", rank, deviceID);
}
