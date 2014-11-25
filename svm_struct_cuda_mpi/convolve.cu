/*
  convolution between hog features and hog templates
  author: Yu Xiang
  Date: 04/14/2011
*/

extern "C"
{
#include "convolve.h"
#include "matrix.h"
}
#include "cutil_inline.h"

#define BLOCK_SIZE 21

__constant__ float hog_template[2048];
__global__ void convolve2D(CUMATRIX C, CUMATRIX A, CUMATRIX B, int index);

CUMATRIX fconv(CUMATRIX A, CUMATRIX B)
{
  CUMATRIX A_device;
  CUMATRIX B_device;
  CUMATRIX C, C_device;

  A_device = alloc_device_cumatrix(A);
  B_device = alloc_device_cumatrix(B);

  // allocate hog response cumatrix
  C.dims_num = 2;
  C.dims = (int*)malloc(sizeof(int)*2);
  C.dims[0] = A.dims[0];
  C.dims[1] = A.dims[1];
  C.length = C.dims[0]*C.dims[1];
  C.data = (float*)malloc(sizeof(float)*C.length);
  C_device = alloc_device_cumatrix(C);
  cutilSafeCall(cudaMemset(C_device.data, 0, sizeof(float)*C_device.length));

  /* setup execution parameters */
  dim3 threads(BLOCK_SIZE, BLOCK_SIZE+2*(B.dims[0]/2));
  dim3 grid((C.dims[1]+BLOCK_SIZE-1) / BLOCK_SIZE, (C.dims[0]+BLOCK_SIZE-1) / BLOCK_SIZE);

  for(int i = 0; i < B.dims[2]; i++)
  {
    // copy to constant memory
    cutilSafeCall(cudaMemcpyToSymbol(hog_template, B.data+i*B.dims[0]*B.dims[1], sizeof(float)*B.dims[0]*B.dims[1]));
    convolve2D<<< grid, threads >>>(C_device, A_device, B_device, i);
    cudaThreadSynchronize();
  }

  /* copy result from device to host */
  cutilSafeCall(cudaMemcpy(C.data, C_device.data, sizeof(float)*C.length, cudaMemcpyDeviceToHost) );

  free_device_cumatrix(&A_device);
  free_device_cumatrix(&B_device);
  free_device_cumatrix(&C_device);
  return C;
}

// implementation of the convolution algorithm described in nvidia
// Image convolution with CUDA for nonseperable kernel
__global__ void convolve2D(CUMATRIX C, CUMATRIX A, CUMATRIX B, int index)
{
  __shared__ float data[3*BLOCK_SIZE][3*BLOCK_SIZE];

  // template size
  int nx = B.dims[1];
  int ny = B.dims[0];

  // feature size
  int fx = A.dims[1];
  int fy = A.dims[0];

  // location in A.data of the current thread
  int x = blockIdx.x*BLOCK_SIZE + threadIdx.x;
  int y = blockIdx.y*BLOCK_SIZE + threadIdx.y - ny/2;

  // load data
  float val;
  if(index == B.dims[2]-1)
    val = 1;
  else
    val = 0;

  int dx = x - BLOCK_SIZE;
  int dy = y;
  if(dx >= 0 && dx < fx && dy >= 0 && dy < fy)
    data[threadIdx.x][threadIdx.y] = A.data[index*fx*fy+dx*fy+dy];
  else
    data[threadIdx.x][threadIdx.y] = val;

  dx = x;
  dy = y;
  if(dx >= 0 && dx < fx && dy >= 0 && dy < fy)
    data[threadIdx.x+BLOCK_SIZE][threadIdx.y] = A.data[index*fx*fy+dx*fy+dy];
  else
    data[threadIdx.x+BLOCK_SIZE][threadIdx.y] = val;

  dx = x + BLOCK_SIZE;
  dy = y;
  if(dx >= 0 && dx < fx && dy >= 0 && dy < fy)
    data[threadIdx.x+2*BLOCK_SIZE][threadIdx.y] = A.data[index*fx*fy+dx*fy+dy];
  else
    data[threadIdx.x+2*BLOCK_SIZE][threadIdx.y] = val;
  __syncthreads();

  if(x < fx && y < fy && threadIdx.y >= ny/2 && threadIdx.y < ny/2 + BLOCK_SIZE)
  {
    // location in shared memory
    int xx = threadIdx.x + BLOCK_SIZE - nx/2;
    int yy = threadIdx.y - ny/2;
    float sum = 0;
    for(int i = 0; i < nx; i++)
    {
      for(int j = 0; j < ny; j++)
        sum += hog_template[i*ny+j] * data[xx+i][yy+j];
    }
    C.data[x*fy+y] += sum;
  }
}

/*
int main(int argc, char** argv)
{
  FILE *fp;
  MATRIX A, A_device;
  MATRIX B, B_device;
  MATRIX C, C_device;

  // load hog features
  fp = fopen(argv[1], "r");
  if(fp == NULL)
  {
    printf("can not open file %s\n", argv[1]);
    return 1;
  }
  A = read_matrix(fp);
  fclose(fp);
  A_device = alloc_device_matrix(A);

  // generate a random hog template
  B.dims_num = 3;
  B.dims = (int*)malloc(sizeof(int)*3);
  B.dims[0] = 16;
  B.dims[1] = 17;
  B.dims[2] = 32;
  B.length = 16*17*32;
  B.data = (float*)malloc(sizeof(float)*B.length);
  for(int i = 0; i < B.length; i++)
    B.data[i] = 1;
  B_device = alloc_device_matrix(B);

  // allocate hog response matrix
  C.dims_num = 2;
  C.dims = (int*)malloc(sizeof(int)*2);
  C.dims[0] = A.dims[0];
  C.dims[1] = A.dims[1];
  C.length = C.dims[0]*C.dims[1];
  C.data = (float*)malloc(sizeof(float)*C.length);
  C_device = alloc_device_matrix(C);
  cutilSafeCall(cudaMemset(C_device.data, 0, sizeof(float)*C_device.length));

  // setup execution parameters
  dim3 threads(BLOCK_SIZE, BLOCK_SIZE+2*(B.dims[0]/2));
  dim3 grid((C.dims[1]+BLOCK_SIZE-1) / BLOCK_SIZE, (C.dims[0]+BLOCK_SIZE-1) / BLOCK_SIZE);

  unsigned int timer = 0;
  cutilCheckError(cutCreateTimer(&timer));
  cutilCheckError(cutStartTimer(timer));

  for(int i = 0; i < B.dims[2]; i++)
  {
    // copy to constant memory
    cutilSafeCall(cudaMemcpyToSymbol(hog_template, B.data+i*B.dims[0]*B.dims[1], sizeof(float)*B.dims[0]*B.dims[1]));
    convolve2D<<< grid, threads >>>(C_device, A_device, B_device, i);
    cudaThreadSynchronize();
  }

  // stop and destroy timer
  cutilCheckError(cutStopTimer(timer));
  float dSeconds = cutGetTimerValue(timer)/1000.0;
  cutilCheckError(cutDeleteTimer(timer));
  printf("time = %f\n", dSeconds);

  // copy result from device to host
  cutilSafeCall(cudaMemcpy(C.data, C_device.data, sizeof(float)*C.length, cudaMemcpyDeviceToHost) );

  fp = fopen(argv[2], "w");
  write_matrix(&C, fp);
  fclose(fp);

  free_device_matrix(&A_device);
  free_device_matrix(&B_device);
  free_device_matrix(&C_device);
  free_matrix(&A);
  free_matrix(&B);
  free_matrix(&C);
  return 0;
}
*/
