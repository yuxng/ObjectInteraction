/*
  compute messages in BP algorithm
  author: Yu Xiang
  Date: 04/21/2011
*/

extern "C"
{
#include "message.h"
#include "matrix.h"
}
#include "cutil_inline.h"

#define BLOCK_SIZE 8
#define MINUS_INFINITY -1.0E15

__constant__ float potential[8192];
__global__ void message(CUMATRIX M, int sbin, float dc, float ac, float wx, float wy);

void compute_message(CUMATRIX M, CUMATRIX V, int sbin, float dc, float ac, float wx, float wy)
{
  CUMATRIX M_device;

  /* allocate device memory */
  M_device = alloc_device_cumatrix(M);

  cutilSafeCall(cudaMemcpyToSymbol(potential, V.data, sizeof(float)*V.length));

  // setup execution parameters
  dim3 threads(BLOCK_SIZE, BLOCK_SIZE);
  dim3 grid((M.dims[1]+BLOCK_SIZE-1) / BLOCK_SIZE, (M.dims[0]+BLOCK_SIZE-1) / BLOCK_SIZE);

  message<<< grid, threads >>>(M_device, sbin, dc, ac, wx, wy);
  cudaThreadSynchronize();

  // copy result from device to host
  cutilSafeCall(cudaMemcpy(M.data, M_device.data, sizeof(float)*M.length, cudaMemcpyDeviceToHost) );
  
  free_device_cumatrix(&M_device);
}

__global__ void message(CUMATRIX M, int sbin, float dc, float ac, float wx, float wy)
{
  int x, y, xi, yi, nx, ny;
  float max_val, val;

  nx = M.dims[1];
  ny = M.dims[0];
  x = blockIdx.x * blockDim.x + threadIdx.x;
  y = blockIdx.y * blockDim.y + threadIdx.y;

  if(x < nx && y < ny)
  {
    max_val = MINUS_INFINITY;
    for(xi = 0; xi < nx; xi++)
    {
      for(yi = 0; yi < ny; yi++)
      {
        val = potential[xi*ny+yi];
        val += powf(sbin*(xi-x) + dc*cosf(ac), 2.0) * wx;
        val += powf(sbin*(yi-y) + dc*sinf(ac), 2.0) * wy;
        if(val > max_val)
          max_val = val;
      }
    }
    M.data[x*ny+y] = max_val;
  }
}
