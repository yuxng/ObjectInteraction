/*
  compute messages in BP algorithm
  author: Yu Xiang
  Date: 04/21/2011
*/

#ifndef MESSAGE_H
#define MESSAGE_H

#include "matrix.h"

void compute_message(CUMATRIX M, CUMATRIX V, int sbin, float dc, float ac, float wx, float wy);

#endif
