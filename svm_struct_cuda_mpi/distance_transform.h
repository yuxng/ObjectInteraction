/*
  Distance transform for message computation
  Author: Yu Xiang
  Data: 06/22/2011
*/

#ifndef DISTANCE_TRANSFORM_H
#define DISTANCE_TRANSFORM_H

#include "matrix.h"

void distance_transform_1D(float *f, float *d, float *l, int n, float bias, float w);
void distance_transform_2D(CUMATRIX M, CUMATRIX V, CUMATRIX L, int sbin, float dc, float ac, float wx, float wy);

#endif
