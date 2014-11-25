/*
  Distance transform for message computation
  Author: Yu Xiang
  Data: 06/22/2011
*/

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include "distance_transform.h"

#define PLUSINFINITY 1.0e32
#define MINUSINFINITY -1.0e32

/*
  f: input 1D function
  d: output
  n: data length
*/
void distance_transform_1D(float *f, float *d, float *l, int n, float bias, float w)
{
  int q, k, *v, max_q;
  float s, *z;

  v = (int*)malloc(sizeof(int)*n);
  z = (float*)malloc(sizeof(float)*(n+1));
  memset(v, 0, sizeof(int)*n);
  memset(z, 0, sizeof(float)*(n+1));

  if(w < 0)
  {
    k = 0;
    v[0] = 0;
    z[0] = MINUSINFINITY;
    z[1] = PLUSINFINITY;

    /* compute upper envelope */
    q = 1;
    while(q < n)
    {
      s = ((f[q]+w*q*q) - (f[v[k]]+w*v[k]*v[k])) / (float)(2*w*q - 2*w*v[k]) + bias;
      if(s <= z[k])
        k--;
      else
      {
        k++;
        v[k] = q;
        z[k] = s;
        z[k+1] = PLUSINFINITY;
        q++;
      }
    }

    /* fill in values of distance transform */
    k = 0;
    for(q = 0; q < n; q++)
    {
      while(z[k+1] < q) k++;
      d[q] = w*pow((q-v[k]-bias), 2.0) + f[v[k]];
      l[q] = v[k];
    }
  }
  else if(w > 0)
  {
    k = 0;
    v[0] = 0;
    z[0] = PLUSINFINITY;
    z[1] = MINUSINFINITY;

    /* compute upper envelope */
    q = 1;
    while(q < n)
    {
      s = ((f[q]+w*q*q) - (f[v[k]]+w*v[k]*v[k])) / (2*w*q - 2*w*v[k]) + bias;
      if(s >= z[k])
        k--;
      else
      {
        k++;
        v[k] = q;
        z[k] = s;
        z[k+1] = MINUSINFINITY;
        q++;
      }
    }

    /* fill in values of distance transform */
    k = 0;
    for(q = n-1; q >= 0; q--)
    {
      while(z[k+1] > q) k++;
      d[q] = w*pow((q-v[k]-bias), 2.0) + f[v[k]];
      l[q] = v[k];
    }
  }
  else
  {
    s = MINUSINFINITY;
    for(q = 0; q < n; q++)
    {
      if(f[q] > s)
      {
        s = f[q];
        max_q = q;
      }
    }
    for(q = 0; q < n; q++)
    {
      d[q] = s;
      l[q] = max_q;
    }
  }

  free(v);
  free(z);
}

/*
  M: output message
  V: input potential
*/
void distance_transform_2D(CUMATRIX M, CUMATRIX V, CUMATRIX L, int sbin, float dc, float ac, float wx, float wy)
{
  int x, y, nx, ny;
  float bias;
  float *dcolumn, *dtranspose, *drow, *lrow, *dst, *src, *location;

  dcolumn = (float*)malloc(sizeof(float)*V.length);
  dtranspose = (float*)malloc(sizeof(float)*V.length);
  drow = (float*)malloc(sizeof(float)*V.length);
  lrow = (float*)malloc(sizeof(float)*V.length);
  nx = V.dims[1];
  ny = V.dims[0];

  /* transform columns */
  bias = dc*sin(ac)/sbin;
  src = V.data;
  dst = dcolumn;
  location = L.data + nx*ny;
  for(x = 0; x < nx; x++)
  {
    distance_transform_1D(src, dst, location, ny, bias, wy*sbin*sbin);
    src += ny;
    dst += ny;
    location += ny;
  }

  /* transpose dcolumn */
  for(x = 0; x < nx; x++)
    for(y = 0; y < ny; y++)
      dtranspose[y*nx+x] = dcolumn[x*ny+y];

  /* transform rows */
  bias = dc*cos(ac)/sbin;
  src = dtranspose;
  dst = drow;
  location = lrow;
  for(x = 0; x < ny; x++)
  {
    distance_transform_1D(src, dst, location, nx, bias, wx*sbin*sbin);
    src += nx;
    dst += nx;
    location += nx;
  }

  /* transpose back to message */
  for(x = 0; x < ny; x++)
  {
    for(y = 0; y < nx; y++)
    {
      M.data[y*ny+x] = drow[x*nx+y];
      L.data[y*ny+x] = lrow[x*nx+y];
    }
  }

  free(dcolumn);
  free(dtranspose);
  free(drow);
  free(lrow);
}

/*
  test routine
*/
/*
void print_cumatrix(CUMATRIX *pmat)
{
  int i;

  printf("dims_num = %d\n", pmat->dims_num);
  for(i = 0; i < pmat->dims_num; i++)
    printf("%d ", pmat->dims[i]);
  printf("\n");
  for(i = 0; i < pmat->length; i++)
    printf("%.12f ", pmat->data[i]);
  printf("\n");
}

int main (int argc, char* argv[])
{
  CUMATRIX M, V;
  int x, y, xi, yi, xj, yj, sbin;
  float dc, ac, wx, wy, val, max_val;

  V.dims_num = 2;
  V.dims = (int*)malloc(sizeof(int)*2);
  V.dims[0] = 10;
  V.dims[1] = 10;
  V.length = 100;
  V.data = (float*)malloc(sizeof(float)*V.length);

  M.dims_num = 2;
  M.dims = (int*)malloc(sizeof(int)*2);
  M.dims[0] = 10;
  M.dims[1] = 10;
  M.length = 100;
  M.data = (float*)malloc(sizeof(float)*M.length);

  sbin = 6;
  dc = 10;
  ac = 1.5;
  wx = -0.2;
  wy = -0.3;

  srand(time(NULL));
  for(x = 0; x < V.dims[1]; x++)
    for(y = 0; y < V.dims[0]; y++)
      V.data[x*V.dims[0]+y] = (rand()%100) / 1000.0;

  for(xj = 0; xj < M.dims[1]; xj++)
  {
    for(yj = 0; yj < M.dims[0]; yj++)
    {
      max_val = MINUSINFINITY;
      for(xi = 0; xi < V.dims[1]; xi++)
      {
        for(yi = 0; yi < V.dims[0]; yi++)
        {
          val = V.data[xi*V.dims[0]+yi];
          val += pow(sbin*(xi-xj) + dc*cos(ac), 2.0) * wx;
          val += pow(sbin*(yi-yj) + dc*sin(ac), 2.0) * wy;
          if(val > max_val)
            max_val = val;
        }
      }
      M.data[xj*M.dims[0]+yj] = max_val;
    }
  }
  print_cumatrix(&M);

  distance_transform_2D(M, V, sbin, dc, ac, wx, wy);
  print_cumatrix(&M); 
}
*/
