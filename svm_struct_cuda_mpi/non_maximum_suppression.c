#include "mex.h"
#include <stdio.h>
#include <stdlib.h>

int* non_maxima_suppression(int *dims, double *data);

void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int i, dims_num;
  int *mask, *dims;
  double *ptr;

  if(nrhs != 1)
    mexErrMsgTxt("one inputs required.");
  if(nlhs != 1)
    mexErrMsgTxt("Too many output arguments.");

  dims_num = mxGetNumberOfDimensions(prhs[0]);
  if(dims_num != 2)
    mexErrMsgTxt("2D matrix inputs required.");
  dims = mxGetDimensions(prhs[0]);
  ptr = (double*)mxGetData(prhs[0]);
  mask = non_maxima_suppression(dims, ptr);

  plhs[0] = mxCreateNumericArray(2, dims, mxDOUBLE_CLASS, mxREAL);
  ptr = (double*)mxGetData(plhs[0]);
  for(i = 0; i < dims[0]*dims[1]; i++)
    ptr[i] = mask[i];

  free(mask);
}

/* non-maxima suppression 3 x 3 neighborhood */
/* Code from "Non-maximum Suppression Using Fewer than Two Comparisons per Pixel" by Tuan Q Pham */
int* non_maxima_suppression(int *dims, double *data)
{
  int c, r, h, w;
  int *skip, *skip_next, *mask, *tmp;

  h = dims[0];
  w = dims[1];
  skip = (int*)malloc(sizeof(int)*h);
  memset(skip, 0, sizeof(int)*h);
  skip_next = (int*)malloc(sizeof(int)*h);
  memset(skip_next, 0, sizeof(int)*h);
  mask = (int*)malloc(sizeof(int)*h*w);
  memset(mask, 0, sizeof(int)*h*w);

  /* for each column */
  for(c = 1; c < w-1; c++)
  {
    /* for each row */
    r = 1;
    while(r < h-1)
    {
      /* skip current pixel */
      if(skip[r])
      {
        r++;
        continue;
      }

      /* compare to next pixel */
      if(data[c*h+r] <= data[c*h+r+1])
      {
        r++;
        while(r < h-1 && data[c*h+r] <= data[c*h+r+1]) r++;
        if(r == h-1) break;
      }
      else
      {
        if(data[c*h+r] <= data[c*h+r-1])
        {
          r++;
          continue;
        }
      }
      skip[r+1] = 1;

      /* compare to 3 future then 3 past neighbors */
      if(data[c*h+r] <= data[(c+1)*h+r-1])
      {
        r++;
        continue;
      }
      skip_next[r-1] = 1;

      if(data[c*h+r] <= data[(c+1)*h+r])
      {
        r++;
        continue;
      }
      skip_next[r] = 1;

      if(data[c*h+r] <= data[(c+1)*h+r+1])
      {
        r++;
        continue;
      }
      skip_next[r+1] = 1;

      if(data[c*h+r] <= data[(c-1)*h+r-1])
      {
        r++;
        continue;
      }

      if(data[c*h+r] <= data[(c-1)*h+r])
      {
        r++;
        continue;
      }

      if(data[c*h+r] <= data[(c-1)*h+r+1])
      {
        r++;
        continue;
      }
      /* a local maxima is found */
      mask[c*h+r] = 1;
      r++;
    }
    tmp = skip;
    skip = skip_next;
    skip_next = tmp;
    memset(skip_next, 0, sizeof(int)*h);
  }

  free(skip);
  free(skip_next);
  return mask;
}
