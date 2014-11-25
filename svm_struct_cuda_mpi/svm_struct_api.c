/***********************************************************************/
/*                                                                     */
/*   svm_struct_api.c                                                  */
/*                                                                     */
/*   Definition of API for attaching implementing SVM learning of      */
/*   structures (e.g. parsing, multi-label classification, HMM)        */ 
/*                                                                     */
/*   Author: Thorsten Joachims                                         */
/*   Date: 03.07.04                                                    */
/*   Modified by: Yu Xiang                                             */
/*   Date: 05.01.12                                                    */
/*                                                                     */
/*   Copyright (c) 2004  Thorsten Joachims - All rights reserved       */
/*                                                                     */
/*   This software is available for non-commercial use only. It must   */
/*   not be modified and distributed without prior permission of the   */
/*   author. The author is not responsible for implications from the   */
/*   use of this software.                                             */
/*                                                                     */
/***********************************************************************/

#include <stdio.h>
#include <string.h>
#include <mpi.h>
#include "svm_struct_common.h"
#include "svm_struct_api.h"
#include "cad.h"
#include "tree.h"
#include "matrix.h"
#include "hog.h"
#include "rectify.h"
#include "convolve.h"
#include "message.h"
#include "distance_transform.h"

void        svm_struct_learn_api_init(int argc, char* argv[])
{
  /* Called in learning part before anything else is done to allow
     any initializations that might be necessary. */
}

void        svm_struct_learn_api_exit()
{
  /* Called in learning part at the very end to allow any clean-up
     that might be necessary. */
}

void        svm_struct_classify_api_init(int argc, char* argv[])
{
  /* Called in prediction part before anything else is done to allow
     any initializations that might be necessary. */
}

void        svm_struct_classify_api_exit()
{
  /* Called in prediction part at the very end to allow any clean-up
     that might be necessary. */
}

/* read cad model from cad file */
CAD** read_cad_model(char *file, int *cad_num_return, int istest, STRUCT_LEARN_PARM *sparm)
{
  int i, j, len, padx, pady, width, height, cad_num;
  CAD **cads, *cad;
  FILE *fp;

  /* open cad file */
  if((fp = fopen(file, "r")) == NULL)
  {
    printf("Can not open cad file %s\n", file);
    exit(1);
  }

  /* initialize cad models */
  fscanf(fp, "%d", &cad_num);
  cads = (CAD**)my_malloc(sizeof(CAD*)*cad_num);
  for(i = 0; i < cad_num; i++)
    cads[i] = read_cad(fp, HOGLENGTH);

  fclose(fp);

  /* compute cad feature length */
  for(i = 0; i < cad_num; i++)
  {
    cad = cads[i];
    cad->feature_len = 0;
    for(j = 0; j < cad->part_num; j++)
    {
      len = cad->part_templates[j]->length;
      /* add one weight for self-occluded part */
      cad->feature_len += len + 1;
    }
  }

  /* get padding length from CAD models */
  padx = pady = 0;
  if(istest == 1)
  {
    for(i = 0; i < cad_num; i++)
    {
      cad = cads[i];
      for(j = 0; j < cad->part_num; j++)
      {
        width = cad->part_templates[j]->width;
        if(padx < width)
          padx = width;
        height = cad->part_templates[j]->height;
        if(pady < height)
          pady = height;
      }
    }
  }
  sparm->padx = padx;
  sparm->pady = pady;

  /* test */
  /*
  print_cad(cads[0]);
  */

  *cad_num_return = cad_num;
  return cads;
}

SAMPLE      read_struct_examples(char *file, STRUCT_LEARN_PARM *sparm, STRUCTMODEL *sm)
{
  /* Reads struct examples and returns them in sample. The number of
     examples must be written into sample.n */
  SAMPLE   sample;  /* sample */
  EXAMPLE  *examples;
  long     i, j, n;       /* number of examples */
  FILE *fp;
  int object_label, cad_label, view_label, part_num;
  CUMATRIX matrix, gradient;

  int rank;
  int procs_num;
  int start, end, block_size;

  /* open data file */
  if((fp = fopen(file, "r")) == NULL)
  {
    printf("Can not open data file %s\n", file);
    exit(1);
  }

  fscanf(fp, "%ld", &n); /* replace by appropriate number of examples */
  examples = (EXAMPLE *)my_malloc(sizeof(EXAMPLE)*n);

  /* MPI process */
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  MPI_Comm_size(MPI_COMM_WORLD, &procs_num);
  block_size = (n+procs_num-1) / procs_num;
  start = rank*block_size;
  end = start+block_size-1 > n-1 ? n-1 : start+block_size-1;

  /* fill in your code here */
  for(i = 0; i < n; i++)
  {
    /* read object label */
    fscanf(fp, "%d", &object_label);
    examples[i].y.object_label = object_label;
    if(object_label == 1) /* positive sample */
    {
      fscanf(fp, "%d", &cad_label);
      examples[i].y.cad_label = cad_label;

      fscanf(fp, "%d", &view_label);
      examples[i].y.view_label = view_label;

      part_num = sm->cads[cad_label]->part_num;
      examples[i].y.part_num = part_num;
      examples[i].y.part_label = (float*)my_malloc(sizeof(float)*2*part_num);
      for(j = 0; j < 2*part_num; j++)
      {
        fscanf(fp, "%f", &(examples[i].y.part_label[j]));
        /* pad part label */
        if(examples[i].y.part_label[j])
        {
          if(j < part_num)
            examples[i].y.part_label[j] += sparm->padx;
          else
            examples[i].y.part_label[j] += sparm->pady;
        }
      }

      examples[i].y.occlusion = (int*)my_malloc(sizeof(int)*part_num);
      for(j = 0; j < part_num; j++)
        fscanf(fp, "%d", &(examples[i].y.occlusion[j]));

      for(j = 0; j < 4; j++)
      {
        fscanf(fp, "%f", &(examples[i].y.bbox[j]));
        /* pad bounding box */
        if(j % 2 == 0)
          examples[i].y.bbox[j] += sparm->padx;
        else
          examples[i].y.bbox[j] += sparm->pady;
      }
    }
    else /* negative sample */
    {
      examples[i].y.cad_label = -1;
      examples[i].y.view_label = -1;
      examples[i].y.part_num = -1;
      examples[i].y.part_label = NULL;
      examples[i].y.occlusion = NULL;
      for(j = 0; j < 4; j++)
        examples[i].y.bbox[j] = 0;
    }
    examples[i].y.energy = 0;
    /* read image data */
    matrix = read_cumatrix(fp);
    /* compute gradient image */
    if(i >= start && i <= end)
    {
      gradient = compute_gradient_image(matrix);
      /* pad gradient image */
      examples[i].x.image = pad_3d_maxtrix(gradient, sparm->padx, sparm->pady);
      free_cumatrix(&gradient);
    }
    else
    {
      examples[i].x.image.dims_num = 0;
      examples[i].x.image.length = 0;
      examples[i].x.image.dims = NULL;
      examples[i].x.image.data = NULL;
    }
    free_cumatrix(&matrix);
  }
  fclose(fp);
  sample.n = n;
  sample.examples = examples;
  return(sample);
}

/* read one example from file */
EXAMPLE read_one_example(FILE *fp, CAD **cads)
{
  EXAMPLE example;
  int j, object_label, cad_label, view_label, part_num;

  /* read object label */
  fscanf(fp, "%d", &object_label);
  example.y.object_label = object_label;
  if(object_label == 1) /* positive sample */
  {
    fscanf(fp, "%d", &cad_label);
    example.y.cad_label = cad_label;

    fscanf(fp, "%d", &view_label);
    example.y.view_label = view_label;

    part_num = cads[cad_label]->part_num;
    example.y.part_num = part_num;
    example.y.part_label = (float*)my_malloc(sizeof(float)*2*part_num);
    for(j = 0; j < 2*part_num; j++)
      fscanf(fp, "%f", &(example.y.part_label[j]));

    example.y.occlusion = (int*)my_malloc(sizeof(int)*part_num);
    for(j = 0; j < part_num; j++)
      fscanf(fp, "%d", &(example.y.occlusion[j]));

    for(j = 0; j < 4; j++)
      fscanf(fp, "%f", &(example.y.bbox[j]));
  }
  else /* negative sample */
  {
    example.y.cad_label = -1;
    example.y.view_label = -1;
    example.y.part_num = -1;
    example.y.part_label = NULL;
    example.y.occlusion = NULL;
    for(j = 0; j < 4; j++)
      example.y.bbox[j] = 0;
  }
  example.y.energy = 0;
  /* read image data */
  example.x.image = read_cumatrix(fp);

  return example;
}

/* compute bounding box from part shapes */
void compute_bbox_root(LABEL *y, int root_index, CAD *cad)
{
  int i, j;
  float xx, yy, x1, y1, x2, y2;
  OBJECT2D *object2d;

  object2d = cad->objects2d[y->view_label];
  x1 = PLUS_INFINITY;
  x2 = MINUS_INFINITY;
  y1 = PLUS_INFINITY;
  y2 = MINUS_INFINITY;

  for(i = 0; i < y->part_num; i++)
  {
    if(cad->roots[i] == 0)
    {
      for(j = 0; j < 4; j++)
      {
        xx = object2d->part_shapes[i][j] + y->part_label[i];
        x1 = (x1 > xx ? xx : x1);
        x2 = (x2 > xx ? x2 : xx);
      }
      for(j = 0; j < 4; j++)
      {
        yy = object2d->part_shapes[i][j+4] + y->part_label[i+y->part_num];
        y1 = (y1 > yy ? yy : y1);
        y2 = (y2 > yy ? y2 : yy);
      }
    }
  }

  /* set root label to be the bounding box center */
  y->part_label[root_index] = (x1 + x2) / 2;
  y->part_label[root_index+y->part_num] = (y1 + y2) / 2;

  /* set bounding box */
  y->bbox[0] = x1;
  y->bbox[1] = y1;
  y->bbox[2] = x2;
  y->bbox[3] = y2;
}

void        init_struct_model(SAMPLE sample, STRUCTMODEL *sm, 
			      STRUCT_LEARN_PARM *sparm, LEARN_PARM *lparm, 
			      KERNEL_PARM *kparm)
{
  /* Initialize structmodel sm. The weight vector w does not need to be
     initialized, but you need to provide the maximum size of the
     feature space in sizePsi. This is the maximum number of different
     weights that can be learned. Later, the weight vector w will
     contain the learned weights for the model. */
  int i, j, sizePsi, len;
  CAD *cad;

  sizePsi = 0;
  for(i = 0; i < sm->cad_num; i++)
  {
    cad = sm->cads[i];
    for(j = 0; j < cad->part_num; j++)
    {
      len = cad->part_templates[j]->length;
      /* add one weight for self-occluded part */
      sizePsi += len + 1;
    }
  }

  sm->sizePsi = sizePsi; /* replace by appropriate number of features */
  sm->weights = (float*)my_malloc(sizeof(float)*sizePsi);
  sm->fp = fopen("train.log", "w");
  if(sm->fp == NULL)
  {
    printf("Can not open train log file.\n");
    exit(1);
  }
}

CONSTSET    init_struct_constraints(SAMPLE sample, STRUCTMODEL *sm, 
				    STRUCT_LEARN_PARM *sparm)
{
  /* Initializes the optimization problem. Typically, you do not need
     to change this function, since you want to start with an empty
     set of constraints. However, if for example you have constraints
     that certain weights need to be positive, you might put that in
     here. The constraints are represented as lhs[i]*w >= rhs[i]. lhs
     is an array of feature vectors, rhs is an array of doubles. m is
     the number of constraints. The function returns the initial
     set of constraints. */
  CONSTSET c;

  if(sparm->iter == 0) /* normal case: start with empty set of constraints */ 
  {
    if(sparm->is_root == 1 && sparm->cad_index == -1 && sparm->part_index == -1)
    {
      printf("Initialize constraints from file %s\n", sparm->confile);
      c = read_constraints(sparm->confile, sm);
    }
    else
    {
      printf("Initialize with empty constraint\n");
      c.lhs = NULL;
      c.rhs = NULL;
      c.m = 0;
    }
  }
  else /* add constraints so that all learned weights are positive. WARNING: Currently, they are positive only up to precision epsilon set by -e. */
  {
    printf("Initialize constraints from file %s\n", sparm->confile);
    c = read_constraints(sparm->confile, sm);
  }
  printf("Initialization done\n");
  return(c);
}

LABEL* classify_struct_example(PATTERN x, int *label_num, int flag, STRUCTMODEL *sm, STRUCT_LEARN_PARM *sparm)
{
  /* Finds the label yhat for pattern x that scores the highest
     according to the linear evaluation function in sm, especially the
     weights sm.w. The returned label is taken as the prediction of sm
     for the pattern x. The weights correspond to the features defined
     by psi() and range from index 1 to index sm->sizePsi. If the
     function cannot find a label, it shall return an empty label as
     recognized by the function empty_label(y). */

  /* insert your code for computing the predicted label y here */
  int i, o, v, width, height, *mask, count, num;
  CAD *cad;
  float *weights, *weights_cad;
  float *homography, T[9];
  CUMATRIX rectified_image, hog, template, hog_response, *potentials;
  float occ_energy;
  LABEL *y = NULL;

  count = 0;
  /* for each O and V */
  weights_cad = sm->weights;
  for(o = 0; o < sm->cad_num; o++)
  {
    cad = sm->cads[o];
    if(sparm->cad_index >= 0 && sparm->part_index >= 0 && sparm->cad_index != o)
    {
      weights_cad += cad->feature_len;  
      continue;
    }

    potentials = (CUMATRIX*)my_malloc(sizeof(CUMATRIX)*cad->part_num);
    for(v = 0; v < cad->view_num; v++)
    {
      if(sparm->cad_index >= 0 && sparm->part_index >= 0 && cad->objects2d[v]->occluded[sparm->part_index] == 1)
        continue;

      occ_energy = 0;
      /* extract features and convolve them with the weights */
      weights = weights_cad;
      for(i = 0; i < cad->part_num; i++)
      {
        /* if root part */
        if(sparm->cad_index >= 0 && sparm->part_index >= 0 && sparm->deep == 0 && sparm->part_index != i)
        {
          potentials[i].dims = NULL;
          potentials[i].data = NULL;
          weights += cad->part_templates[i]->length + 1;
          continue;
        }

        /* if aspectlet */
        if(sparm->cad_index >= 0 && sparm->part_index >= 0 && cad->roots[sparm->part_index] == 1 && sparm->deep == 1 && isin_tree(cad->objects2d[v]->tree+sparm->part_index, i) == 0)
        {
          potentials[i].dims = NULL;
          potentials[i].data = NULL;
          weights += cad->part_templates[i]->length + 1;
          continue;
        }

        /* part not occluded */
        if(cad->objects2d[v]->occluded[i] == 0)
        {
          /* get homography */
          homography = cad->objects2d[v]->homographies[i];
          /* rectify image */
          rectified_image = rectify_image(x.image, homography, T);
          /* compute HOG features */
          hog = compute_hog_features(rectified_image, cad->part_templates[i]->sbin);

          /* compute the unary potential by convolution */
          template.dims_num = hog.dims_num;
          template.dims = (int*)my_malloc(sizeof(int)*template.dims_num);
          template.dims[0] = cad->part_templates[i]->b0;
          template.dims[1] = cad->part_templates[i]->b1;
          template.dims[2] = hog.dims[2];
          template.length = cad->part_templates[i]->length;
          template.data = (float*)my_malloc(sizeof(float)*template.length);
          memcpy(template.data, weights, sizeof(float)*template.length);
          hog_response = fconv(hog, template);

          /* rectify back the unary potentials */
          height = (int)round((double)(x.image.dims[0])/(double)(cad->part_templates[i]->sbin));
          width = (int)round((double)(x.image.dims[1])/(double)(cad->part_templates[i]->sbin));
          potentials[i] = rectify_potential(hog_response, width, height, cad->part_templates[i]->sbin, T);

          free_cumatrix(&rectified_image);
          free_cumatrix(&hog);
          free_cumatrix(&template);
          free_cumatrix(&hog_response);
        }
        else
        {
          height = (int)round((double)(x.image.dims[0])/(double)(cad->part_templates[i]->sbin));
          width = (int)round((double)(x.image.dims[1])/(double)(cad->part_templates[i]->sbin));
          potentials[i].dims_num = 2;
          potentials[i].dims = (int*)my_malloc(sizeof(int)*2);
          potentials[i].dims[0] = height;
          potentials[i].dims[1] = width;
          potentials[i].length = height*width;
          potentials[i].data = (float*)my_malloc(sizeof(float)*width*height);
          memset(potentials[i].data, 0, sizeof(float)*width*height);
          occ_energy += *(weights + cad->part_templates[i]->length);
        }

        /* set unary potential */
        set_potential(cad->objects2d[v]->tree+cad->objects2d[v]->root_index, i, potentials[i].data, potentials[i].dims);
        weights += cad->part_templates[i]->length + 1;
      }

      if(sparm->cad_index >= 0 && sparm->part_index >= 0 && sparm->deep == 0)
      {
        mask = non_maxima_suppression(potentials[sparm->part_index].dims, potentials[sparm->part_index].data);
        get_multiple_detection_part(&y, &count, o, v, potentials[sparm->part_index].dims, potentials[sparm->part_index].data, mask, cad->part_templates[0]->sbin, cad->part_num, sm, sparm);     
      }
      else if(sparm->cad_index >= 0 && sparm->part_index >= 0 && cad->roots[sparm->part_index] == 1 && sparm->deep == 1)
      { 
        /* run BP algorithm */
        child_to_parent(cad->objects2d[v]->tree+sparm->part_index, NULL, cad->objects2d[v], cad->objects2d[v]->graph, cad->part_templates[0]->sbin, NULL, sparm);
        compute_root_scores(cad->objects2d[v]->tree+sparm->part_index, occ_energy, cad->part_templates[0]->sbin, cad->part_num, NULL, sparm);
        mask = non_maxima_suppression(cad->objects2d[v]->tree[sparm->part_index].dims, cad->objects2d[v]->tree[sparm->part_index].messages[0]);
        get_multiple_detection(&y, &count, o, v, cad->objects2d[v]->tree+sparm->part_index, mask, cad->part_templates[0]->sbin, cad->part_num, sm, sparm);
      }
      else
      { 
        /* run BP algorithm */
        child_to_parent(cad->objects2d[v]->tree+cad->objects2d[v]->root_index, NULL, cad->objects2d[v], cad->objects2d[v]->graph, cad->part_templates[0]->sbin, NULL, sparm);
        compute_root_scores(cad->objects2d[v]->tree+cad->objects2d[v]->root_index, occ_energy, cad->part_templates[0]->sbin, cad->part_num, NULL, sparm);
        mask = non_maxima_suppression(cad->objects2d[v]->tree[cad->objects2d[v]->root_index].dims, cad->objects2d[v]->tree[cad->objects2d[v]->root_index].messages[0]);
        get_multiple_detection(&y, &count, o, v, cad->objects2d[v]->tree+cad->objects2d[v]->root_index, mask, cad->part_templates[0]->sbin, cad->part_num, sm, sparm);
      }

      /* clean up */
      if(sparm->cad_index >= 0 && sparm->part_index >= 0 && sparm->deep == 0)
        free_cumatrix(&(potentials[sparm->part_index]));
      else
      {
        free_message(cad->objects2d[v]->tree, cad->part_num);
        for(i = 0; i < cad->part_num; i++)
          free_cumatrix(&(potentials[i]));
      }
      free(mask);
    } /* end for each v */
    weights_cad += cad->feature_len;
    free(potentials);
  } /* end for each o */

  /* sort labels*/
  qsort(y, count, sizeof(LABEL), compare_label);
  /* non-maxima suppression by bounding box overlap */
  num = nms_bbox(y, count);

  if(flag == 1)
  {
    /*
    for(i = 0; i < count; i++)
    {
      if(y[i].object_label)
        print_label(y[i], sm, sparm);
    }
    */
    printf("%d objects have been detected.\n", count-num);
  }

  *label_num = count;
  return y;
}

/* non-maxima suppression by bounding box overlap */
int nms_bbox(LABEL *y, int num)
{
  int i, j, count;
  float *a, *b, area, x1, y1, x2, y2, w, h, o;

  count = 0;
  for(i = 1; i < num; i++)
  {
    a = y[i].bbox;
    area = (a[2]-a[0]+1) * (a[3]-a[1]+1);
    for(j = 0; j < i; j++)
    {
      if(y[j].object_label == 0)
        continue;
      b = y[j].bbox;
      x1 = (a[0] > b[0] ? a[0] : b[0]);
      y1 = (a[1] > b[1] ? a[1] : b[1]);
      x2 = (a[2] > b[2] ? b[2] : a[2]);
      y2 = (a[3] > b[3] ? b[3] : a[3]);
      w = x2-x1+1;
      h = y2-y1+1;
      if(w > 0 && h > 0)
      {
        /* compute overlap */
        o = w * h / area;
        if(o > 0.5)
        {
          y[i].object_label = 0;
          count++;
          break;
        }
      }      
    }
  }
  return count;
}

int compare_label(const void *a, const void *b)
{
  float diff;
  diff =  ((LABEL*)a)->energy - ((LABEL*)b)->energy;
  if(diff < 0)
    return 1;
  else if(diff > 0)
    return -1;
  else
    return 0;
}


/* compute bounding box from part shapes */
void compute_bbox(LABEL *y, STRUCTMODEL *sm)
{
  int i, j;
  float xx, yy, x1, y1, x2, y2;
  OBJECT2D *object2d;

  object2d = sm->cads[y->cad_label]->objects2d[y->view_label];
  x1 = PLUS_INFINITY;
  x2 = MINUS_INFINITY;
  y1 = PLUS_INFINITY;
  y2 = MINUS_INFINITY;

  for(i = 0; i < y->part_num; i++)
  {
    if(object2d->occluded[i] == 0 && y->part_label[i] != 0 && y->part_label[i+y->part_num] != 0)
    {
      for(j = 0; j < 4; j++)
      {
        xx = object2d->part_shapes[i][j] + y->part_label[i];
        x1 = (x1 > xx ? xx : x1);
        x2 = (x2 > xx ? x2 : xx);
      }
      for(j = 0; j < 4; j++)
      {
        yy = object2d->part_shapes[i][j+4] + y->part_label[i+y->part_num];
        y1 = (y1 > yy ? yy : y1);
        y2 = (y2 > yy ? y2 : yy);
      }
    }
  }

  y->bbox[0] = x1;
  y->bbox[1] = y1;
  y->bbox[2] = x2;
  y->bbox[3] = y2;
}

LABEL       find_most_violated_constraint_slackrescaling(PATTERN x, LABEL y, STRUCTMODEL *sm, STRUCT_LEARN_PARM *sparm)
{
  /* Finds the label ybar for pattern x that that is responsible for
     the most violated constraint for the slack rescaling
     formulation. For linear slack variables, this is that label ybar
     that maximizes

            argmax_{ybar} loss(y,ybar)*(1-psi(x,y)+psi(x,ybar)) 

     Note that ybar may be equal to y (i.e. the max is 0), which is
     different from the algorithms described in
     [Tschantaridis/05]. Note that this argmax has to take into
     account the scoring function in sm, especially the weights sm.w,
     as well as the loss function, and whether linear or quadratic
     slacks are used. The weights in sm.w correspond to the features
     defined by psi() and range from index 1 to index
     sm->sizePsi. Most simple is the case of the zero/one loss
     function. For the zero/one loss, this function should return the
     highest scoring label ybar (which may be equal to the correct
     label y), or the second highest scoring label ybar, if
     Psi(x,ybar)>Psi(x,y)-1. If the function cannot find a label, it
     shall return an empty label as recognized by the function
     empty_label(y). */
  LABEL ybar;

  /* insert your code for computing the label ybar here */
  ybar = find_most_violated_constraint_marginrescaling(x, y, sm, sparm);

  return(ybar);
}

/* copy double weights to float weights */
void copy_to_float_weights(STRUCTMODEL *sm)
{
  long i;
  for(i = 0; i < sm->sizePsi; i++)
    sm->weights[i] = (float)sm->w[i+1];
}

LABEL       find_most_violated_constraint_marginrescaling(PATTERN x, LABEL y, STRUCTMODEL *sm, STRUCT_LEARN_PARM *sparm)
{
  /* Finds the label ybar for pattern x that that is responsible for
     the most violated constraint for the margin rescaling
     formulation. For linear slack variables, this is that label ybar
     that maximizes

            argmax_{ybar} loss(y,ybar)+psi(x,ybar)

     Note that ybar may be equal to y (i.e. the max is 0), which is
     different from the algorithms described in
     [Tschantaridis/05]. Note that this argmax has to take into
     account the scoring function in sm, especially the weights sm.w,
     as well as the loss function, and whether linear or quadratic
     slacks are used. The weights in sm.w correspond to the features
     defined by psi() and range from index 1 to index
     sm->sizePsi. Most simple is the case of the zero/one loss
     function. For the zero/one loss, this function should return the
     highest scoring label ybar (which may be equal to the correct
     label y), or the second highest scoring label ybar, if
     Psi(x,ybar)>Psi(x,y)-1. If the function cannot find a label, it
     shall return an empty label as recognized by the function
     empty_label(y). */
  LABEL ybar;

  /* insert your code for computing the label ybar here */
  int i, o, v, width, height, sbin;
  CAD *cad;
  float *weights, *weights_cad;
  float *homography, T[9], *part_label;
  CUMATRIX rectified_image, hog, template, hog_response, *potentials;
  float energy, max_energy, occ_energy, potential;
  int isempty;
  float x1, y1, x2, y2;
  int x3, y3;

  ybar.part_label = NULL;
  ybar.occlusion = NULL;
  weights_cad = sm->weights;
  max_energy = MINUS_INFINITY;
  /* for each O and V */
  for(o = 0; o < sm->cad_num; o++)
  {
    cad = sm->cads[o];
    if(sparm->cad_index >= 0 && sparm->part_index >= 0 && sparm->cad_index != o)
    {
      weights_cad += cad->feature_len;  
      continue;
    }

    potentials = (CUMATRIX*)my_malloc(sizeof(CUMATRIX)*cad->part_num);
    part_label = (float*)my_malloc(sizeof(float)*cad->part_num*2);
    for(v = 0; v < cad->view_num; v++)
    {
      if(sparm->cad_index >= 0 && sparm->part_index >= 0 && cad->objects2d[v]->occluded[sparm->part_index] == 1)
        continue;

      occ_energy = 0;
      memset(part_label, 0, sizeof(float)*cad->part_num*2);
      /* extract features and convolve them with the weights */
      weights = weights_cad;
      for(i = 0; i < cad->part_num; i++)
      {
        /* if root part */
        if(sparm->cad_index >= 0 && sparm->part_index >= 0 && sparm->deep == 0 && sparm->part_index != i)
        {
          potentials[i].dims = NULL;
          potentials[i].data = NULL;
          weights += cad->part_templates[i]->length + 1;
          continue;
        }

        /* if aspectlet */
        if(sparm->cad_index >= 0 && sparm->part_index >= 0 && cad->roots[sparm->part_index] == 1 && sparm->deep == 1 && isin_tree(cad->objects2d[v]->tree+sparm->part_index, i) == 0)
        {
          potentials[i].dims = NULL;
          potentials[i].data = NULL;
          weights += cad->part_templates[i]->length + 1;
          continue;
        }

        /* part not self-occluded */
        if(cad->objects2d[v]->occluded[i] == 0)
        {
          homography = cad->objects2d[v]->homographies[i];
          /* rectify image */
          rectified_image = rectify_image(x.image, homography, T);
          /* compute HOG features */
          hog = compute_hog_features(rectified_image, cad->part_templates[i]->sbin);

          /* compute the unary potential by convolution */
          template.dims_num = hog.dims_num;
          template.dims = (int*)my_malloc(sizeof(int)*template.dims_num);
          template.dims[0] = cad->part_templates[i]->b0;
          template.dims[1] = cad->part_templates[i]->b1;
          template.dims[2] = hog.dims[2];
          template.length = cad->part_templates[i]->length;
          template.data = (float*)my_malloc(sizeof(float)*template.length);
          memcpy(template.data, weights, sizeof(float)*template.length);
          hog_response = fconv(hog, template);

          /* rectify back the unary potentials */
          height = (int)round((double)(x.image.dims[0])/(double)(cad->part_templates[i]->sbin));
          width = (int)round((double)(x.image.dims[1])/(double)(cad->part_templates[i]->sbin));
          potentials[i] = rectify_potential(hog_response, width, height, cad->part_templates[i]->sbin, T);

          free_cumatrix(&rectified_image);
          free_cumatrix(&hog);
          free_cumatrix(&template);
          free_cumatrix(&hog_response);
        }
        else
        {
          height = (int)round((double)(x.image.dims[0])/(double)(cad->part_templates[i]->sbin));
          width = (int)round((double)(x.image.dims[1])/(double)(cad->part_templates[i]->sbin));
          potentials[i].dims_num = 2;
          potentials[i].dims = (int*)my_malloc(sizeof(int)*2);
          potentials[i].dims[0] = height;
          potentials[i].dims[1] = width;
          potentials[i].length = height*width;
          potentials[i].data = (float*)my_malloc(sizeof(float)*width*height);
          memset(potentials[i].data, 0, sizeof(float)*width*height);
          occ_energy += *(weights + cad->part_templates[i]->length);
        }

        /* set unary potential */
        set_potential(cad->objects2d[v]->tree+cad->objects2d[v]->root_index, i, potentials[i].data, potentials[i].dims);
        weights += cad->part_templates[i]->length + 1;
      }

      if(sparm->cad_index >= 0 && sparm->part_index >= 0 && sparm->deep == 0)
      {
        memset(part_label, 0, sizeof(float)*cad->part_num*2);
        /* search for the best part location */
        width  = potentials[sparm->part_index].dims[1];
        height = potentials[sparm->part_index].dims[0];
        energy = MINUS_INFINITY;
        for(x3 = 0; x3 < width; x3++)
        {
          for(y3 = 0 ; y3 < height; y3++)
          {
            potential = potentials[sparm->part_index].data[x3*height+y3];
            if(sparm->loss_function)
            {
              if(y.object_label == 1 && y.cad_label == o && y.view_label == v && sparm->location_loss != 0)
              {
                sbin = cad->part_templates[0]->sbin;
                potential += sparm->location_loss * sqrt((sbin*x3+sbin/2-y.part_label[sparm->part_index])*(sbin*x3+sbin/2-y.part_label[sparm->part_index]) + (sbin*y3+sbin/2-y.part_label[sparm->part_index+cad->part_num])*(sbin*y3+sbin/2-y.part_label[sparm->part_index+cad->part_num]));
              }
              else if(y.object_label == 1 && o != y.cad_label)
                potential += sparm->cad_loss;
              else if(y.object_label == 1 && v != y.view_label)
                potential += sparm->view_loss;
            }
            if(potential > energy)
            {
              energy = potential;
              part_label[sparm->part_index] = cad->part_templates[0]->sbin*x3 + cad->part_templates[0]->sbin/2;
              part_label[sparm->part_index+cad->part_num] = cad->part_templates[0]->sbin*y3 + cad->part_templates[0]->sbin/2;
            }
          }
        }        
      }
      else if(sparm->cad_index >= 0 && sparm->part_index >= 0 && cad->roots[sparm->part_index] == 1 && sparm->deep == 1)   /* apsectlet, run BP on the subtree */
      {
        /* run BP algorithm */
        if(sparm->loss_function)
        {
          if(y.object_label == 1 && y.cad_label == o && y.view_label == v && sparm->location_loss != 0)
          {
            child_to_parent(cad->objects2d[v]->tree+sparm->part_index, NULL, cad->objects2d[v], cad->objects2d[v]->graph, cad->part_templates[0]->sbin, y.part_label, sparm);
            compute_root_scores(cad->objects2d[v]->tree+sparm->part_index, occ_energy, cad->part_templates[0]->sbin, cad->part_num, y.part_label, sparm);
            energy = get_maximum_label(cad->objects2d[v]->tree+sparm->part_index, cad->part_templates[0]->sbin, cad->part_num, part_label);
          }
          else
          {
            child_to_parent(cad->objects2d[v]->tree+sparm->part_index, NULL, cad->objects2d[v], cad->objects2d[v]->graph, cad->part_templates[0]->sbin, NULL, sparm);
            compute_root_scores(cad->objects2d[v]->tree+sparm->part_index, occ_energy, cad->part_templates[0]->sbin, cad->part_num, NULL, sparm);
            energy = get_maximum_label(cad->objects2d[v]->tree+sparm->part_index, cad->part_templates[0]->sbin, cad->part_num, part_label);

            /* add loss */
            if(y.object_label == 1 && o != y.cad_label)
              energy += sparm->cad_loss;
            else if(y.object_label == 1 && v != y.view_label)
              energy += sparm->view_loss;
          }
        }
        else
        {
          child_to_parent(cad->objects2d[v]->tree+sparm->part_index, NULL, cad->objects2d[v], cad->objects2d[v]->graph, cad->part_templates[0]->sbin, NULL, sparm);
          compute_root_scores(cad->objects2d[v]->tree+sparm->part_index, occ_energy, cad->part_templates[0]->sbin, cad->part_num, NULL, sparm);
          energy = get_maximum_label(cad->objects2d[v]->tree+sparm->part_index, cad->part_templates[0]->sbin, cad->part_num, part_label);
        }
      }
      else
      {
        /* run BP algorithm */
        if(sparm->loss_function)
        {
          if(y.object_label == 1 && y.cad_label == o && y.view_label == v && sparm->location_loss != 0)
          {
            child_to_parent(cad->objects2d[v]->tree+cad->objects2d[v]->root_index, NULL, cad->objects2d[v], cad->objects2d[v]->graph, cad->part_templates[0]->sbin, y.part_label, sparm);
            compute_root_scores(cad->objects2d[v]->tree+cad->objects2d[v]->root_index, occ_energy, cad->part_templates[0]->sbin, cad->part_num, y.part_label, sparm);
            energy = get_maximum_label(cad->objects2d[v]->tree+cad->objects2d[v]->root_index, cad->part_templates[0]->sbin, cad->part_num, part_label);
          }
          else
          {
            child_to_parent(cad->objects2d[v]->tree+cad->objects2d[v]->root_index, NULL, cad->objects2d[v], cad->objects2d[v]->graph, cad->part_templates[0]->sbin, NULL, sparm);
            compute_root_scores(cad->objects2d[v]->tree+cad->objects2d[v]->root_index, occ_energy, cad->part_templates[0]->sbin, cad->part_num, NULL, sparm);
            energy = get_maximum_label(cad->objects2d[v]->tree+cad->objects2d[v]->root_index, cad->part_templates[0]->sbin, cad->part_num, part_label);

            /* add loss */
            if(y.object_label == 1 && o != y.cad_label)
              energy += sparm->cad_loss;
            else if(y.object_label == 1 && v != y.view_label)
              energy += sparm->view_loss;
          }
        }
        else
        {
          child_to_parent(cad->objects2d[v]->tree+cad->objects2d[v]->root_index, NULL, cad->objects2d[v], cad->objects2d[v]->graph, cad->part_templates[0]->sbin, NULL, sparm);
          compute_root_scores(cad->objects2d[v]->tree+cad->objects2d[v]->root_index, occ_energy, cad->part_templates[0]->sbin, cad->part_num, NULL, sparm);
          energy = get_maximum_label(cad->objects2d[v]->tree+cad->objects2d[v]->root_index, cad->part_templates[0]->sbin, cad->part_num, part_label);
        }
      }

      /* set maximum */
      if(energy > max_energy)
      {
        max_energy = energy;
        ybar.object_label = 1;
        ybar.cad_label = o;
        ybar.view_label = v;
        if(ybar.part_label != NULL)
          free(ybar.part_label);
        ybar.part_num = cad->part_num;
        ybar.part_label = (float*)my_malloc(sizeof(float)*cad->part_num*2);
        for(i = 0; i < cad->part_num*2; i++)
          ybar.part_label[i] = part_label[i];
      }

      /* clean up */
      if(sparm->cad_index >= 0 && sparm->part_index >= 0 && sparm->deep == 0)
        free_cumatrix(&(potentials[sparm->part_index]));
      else
      {
        free_message(cad->objects2d[v]->tree, cad->part_num);
        for(i = 0; i < cad->part_num; i++)
          free_cumatrix(&(potentials[i]));
      }
    } /* end for each v */
    weights_cad += cad->feature_len;
    free(potentials);
    free(part_label);
  } /* end for each o */

  /* decide the object label */
  if(sparm->loss_function)
  {
    if((y.object_label == 1 && max_energy <= sparm->object_loss) || (y.object_label == -1 && max_energy + sparm->object_loss < 0))
      ybar.object_label = -1;
  }
  else
  {
    if((y.object_label == 1 && max_energy < sparm->loss_value) || (y.object_label == -1 && max_energy + sparm->loss_value < 0))
      ybar.object_label = -1;
  }
  ybar.energy = max_energy;

  /* assign occlusion label */
  if(ybar.object_label == 1 && y.object_label == 1 && ybar.cad_label == y.cad_label)
  {
    ybar.occlusion = (int*)my_malloc(sizeof(int)*ybar.part_num);
    for(i = 0; i < ybar.part_num; i++)
      ybar.occlusion[i] = y.occlusion[i];
  }

  /* check whether ybar is equal to y */
  isempty = 0;
  if(ybar.object_label == -1 && y.object_label == -1)
    isempty = 1;
  else if(ybar.object_label == y.object_label && ybar.cad_label == y.cad_label && ybar.view_label == y.view_label)
  {
    isempty = 1;
    for(i = 0; i < y.part_num; i++)
    {
      if(sparm->cad_index >= 0 && sparm->part_index >= 0 && sparm->deep == 0 && sparm->part_index != i)
        continue;
      if(sparm->cad_index >= 0 && sparm->part_index >= 0 && sm->cads[sparm->cad_index]->roots[sparm->part_index] == 1 && sparm->deep == 1 && isin_tree(sm->cads[sparm->cad_index]->objects2d[y.view_label]->tree+sparm->part_index, i) == 0) 
        continue;
      x1 = y.part_label[i];
      y1 = y.part_label[y.part_num+i];
      x2 = ybar.part_label[i];
      y2 = ybar.part_label[ybar.part_num+i];
      if(sm->cads[y.cad_label]->objects2d[y.view_label]->occluded[i] == 0 && sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2)) > sm->cads[y.cad_label]->part_templates[0]->sbin)
      {
        isempty = 0;
        break;
      }
    }
  }
  if(isempty == 1)
    ybar.object_label = 0;

  return(ybar);
}

/* compute the message at the root node */
void compute_root_scores(TREENODE *node, float occ_energy, int sbin, int part_num, float *part_label, STRUCT_LEARN_PARM *sparm)
{
  int i, x, y;
  float xlabel, ylabel, val;
  float *v;

  if(part_label != NULL)
  {
    xlabel = part_label[node->index];
    ylabel = part_label[part_num+node->index];
  }

  /* unary potential plus messages from children */
  v = (float*)my_malloc(sizeof(float)*node->dims[0]*node->dims[1]);
  for(x = 0; x < node->dims[1]; x++)
  {
    for(y = 0; y < node->dims[0]; y++)
    {
      val = node->potential[x*node->dims[0]+y];
      /* add the loss */
      if(part_label != NULL)
        val += sparm->location_loss * sqrt((sbin*x+sbin/2-xlabel)*(sbin*x+sbin/2-xlabel) + (sbin*y+sbin/2-ylabel)*(sbin*y+sbin/2-ylabel));
      /* sum incoming messages from children */
      for(i = 1; i < node->message_num; i++)
        val += node->messages[i][x*node->dims[0]+y];
      /* sum occlusion energy */
      val += occ_energy;
      /* assign energy */
      v[x*node->dims[0]+y] = val;
    }
  }

  /* put the scores in messages[0] */
  node->messages[0] = v;
}

/* non-maxima suppression 3 x 3 neighborhood */
/* Code from "Non-maximum Suppression Using Fewer than Two Comparisons per Pixel" by Tuan Q Pham */
int* non_maxima_suppression(int *dims, float *data)
{
  int c, r, h, w;
  int *skip, *skip_next, *mask, *tmp;

  h = dims[0];
  w = dims[1];
  skip = (int*)my_malloc(sizeof(int)*h);
  memset(skip, 0, sizeof(int)*h);
  skip_next = (int*)my_malloc(sizeof(int)*h);
  memset(skip_next, 0, sizeof(int)*h);
  mask = (int*)my_malloc(sizeof(int)*h*w);
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

/* compute detections by thresholding the energy values */
void get_multiple_detection(LABEL **ylabel, int *num, int o, int v, TREENODE *node, int *mask, int sbin, int part_num, STRUCTMODEL *sm, STRUCT_LEARN_PARM *sparm)
{
  int x, y;
  float val;
  float energy_threshold = -0.8*sparm->loss_value;

  for(x = 0; x < node->dims[1]; x++)
  {
    for(y = 0; y < node->dims[0]; y++)
    {
      if(*num >= MAX_LABEL_NUM)
        break;
      val = node->messages[0][x*node->dims[0]+y];
      if(mask[x*node->dims[0]+y] == 1 && val > energy_threshold)
      {
        *ylabel = (LABEL*)realloc(*ylabel, sizeof(LABEL)*(*num+1));
        (*ylabel)[*num].part_label = (float*)my_malloc(sizeof(float)*part_num*2);
        memset((*ylabel)[*num].part_label, 0, sizeof(float)*part_num*2);
        (*ylabel)[*num].energy = val;
        label_from_backtrack(node, NULL, x, y, sbin, part_num, (*ylabel)[*num].part_label);
        (*ylabel)[*num].object_label = 1;
        (*ylabel)[*num].cad_label = o;
        (*ylabel)[*num].view_label = v;
        (*ylabel)[*num].part_num = part_num;
        (*ylabel)[*num].occlusion = NULL;
        /* compute bounding box */
        compute_bbox(&(*ylabel)[*num], sm);
        (*num)++;
      }
    }
  }
}

/* compute detections by thresholding the energy values */
void get_multiple_detection_part(LABEL **ylabel, int *num, int o, int v, int *dims, float *potential, int *mask, int sbin, int part_num, STRUCTMODEL *sm, STRUCT_LEARN_PARM *sparm)
{
  int x, y;
  float val;
  float energy_threshold = -sparm->loss_value;

  for(x = 0; x < dims[1]; x++)
  {
    for(y = 0; y < dims[0]; y++)
    {
      if(*num >= MAX_LABEL_NUM)
        break;
      val = potential[x*dims[0]+y];
      if(mask[x*dims[0]+y] == 1 && val > energy_threshold)
      {
        *ylabel = (LABEL*)realloc(*ylabel, sizeof(LABEL)*(*num+1));
        (*ylabel)[*num].part_label = (float*)my_malloc(sizeof(float)*part_num*2);
        memset((*ylabel)[*num].part_label, 0, sizeof(float)*part_num*2);
        (*ylabel)[*num].part_label[sparm->part_index] = sbin*x + sbin/2;
        (*ylabel)[*num].part_label[sparm->part_index+part_num] = sbin*y + sbin/2;
        (*ylabel)[*num].energy = val;
        (*ylabel)[*num].object_label = 1;
        (*ylabel)[*num].cad_label = o;
        (*ylabel)[*num].view_label = v;
        (*ylabel)[*num].part_num = part_num;
        (*ylabel)[*num].occlusion = NULL;
        /* compute bounding box */
        compute_bbox(&(*ylabel)[*num], sm);
        (*num)++;
      }
    }
  }
}

/* get the part label with maximum energy from root score */
float get_maximum_label(TREENODE *node, int sbin, int part_num, float *part_label)
{
  int x, y, x_max, y_max;
  float val, val_max;

  val_max = MINUS_INFINITY;
  x_max = y_max = 0;
  for(x = 0; x < node->dims[1]; x++)
  {
    for(y = 0; y < node->dims[0]; y++)
    {
      val = node->messages[0][x*node->dims[0]+y];
      if(val > val_max)
      {
        val_max = val;
        x_max = x;
        y_max = y;
      }
    }
  }

  label_from_backtrack(node, NULL, x_max, y_max, sbin, part_num, part_label);
  return val_max;
}

/* get label from backtrack */
void label_from_backtrack(TREENODE *node, TREENODE *parent, int px, int py, int sbin, int part_num, float *part_dst)
{
  int i, max_x, max_y;
  float *location;

  if(parent == NULL)
  {
    max_x = px;
    max_y = py;

    /* set part label */
    part_dst[node->index] = (float)(sbin*max_x + sbin/2);
    part_dst[part_num+node->index] = (float)(sbin*max_y + sbin/2);
  }
  else
  {
    for(i = 0; i < parent->child_num; i++)
    {
      if(parent->children[i]->index == node->index)
      {
        location = parent->locations[i+1];
        max_x = location[px*node->dims[0]+py];
        max_y = location[node->dims[0]*node->dims[1]+px*node->dims[0]+py];
        break;
      }
    }

    /* set part label, average the labels for parents */
    part_dst[node->index] += (float)(sbin*max_x + sbin/2) / (float)node->parent_num;
    part_dst[part_num+node->index] += (float)(sbin*max_y + sbin/2) / (float)node->parent_num;
  }

  for(i = 0; i < node->child_num; i++)
    label_from_backtrack(node->children[i], node, max_x, max_y, sbin, part_num, part_dst);
}

/* pass messages from children to parents */
void child_to_parent(TREENODE *node, TREENODE *parent, OBJECT2D *object2d, int **graph, int sbin, float *part_label, STRUCT_LEARN_PARM *sparm)
{
  int i, xi, yi, xj, yj, max_x, max_y;
  float wx, wy;
  float *message, *v, *location;
  float val, max_val;
  float cx1, cy1, cx2, cy2, dc, ac;
  float xlabel, ylabel;
  CUMATRIX M, V, L;

  for(i = 0; i < node->child_num; i++)
    child_to_parent(node->children[i], node, object2d, graph, sbin, part_label, sparm);

  if(parent == NULL)
    return;

  if(part_label != NULL)
  {
    xlabel = part_label[node->index];
    ylabel = part_label[object2d->part_num+node->index];
  }

  /* initialize message */
  message = (float*)my_malloc(sizeof(float)*node->dims[0]*node->dims[1]);
  memset(message, 0, sizeof(float)*node->dims[0]*node->dims[1]);
  location = (float*)my_malloc(sizeof(float)*node->dims[0]*node->dims[1]*2);
  memset(location, 0, sizeof(float)*node->dims[0]*node->dims[1]*2);

  /* unary potential plus incoming messages from node's children */
  v = (float*)my_malloc(sizeof(float)*node->dims[0]*node->dims[1]);
  max_val = MINUS_INFINITY;
  max_x = max_y = 0;
  for(xi = 0; xi < node->dims[1]; xi++)
  {
    for(yi = 0; yi < node->dims[0]; yi++)
    {
      val = node->potential[xi*node->dims[0]+yi];
      /* add the loss */
      if(part_label != NULL)
        val += sparm->location_loss * sqrt((sbin*xi+sbin/2-xlabel)*(sbin*xi+sbin/2-xlabel) + (sbin*yi+sbin/2-ylabel)*(sbin*yi+sbin/2-ylabel));
      /* sum incoming messages */
      for(i = 1; i < node->message_num; i++)
        val += node->messages[i][xi*node->dims[0]+yi];
      v[xi*node->dims[0]+yi] = val;
      if(val > max_val)
      {
        max_val = val;
        max_x = xi;
        max_y = yi;
      }
    }
  }

  /* compute the message */
  if(object2d->occluded[node->index] == 0 && object2d->occluded[parent->index] == 0)
  {
    /* locations from 3d cad model */
    cx1 = object2d->part_locations[node->index];
    cy1 = object2d->part_locations[object2d->part_num + node->index];
    cx2 = object2d->part_locations[parent->index];
    cy2 = object2d->part_locations[object2d->part_num + parent->index];
    dc = sqrt((cx1-cx2)*(cx1-cx2) + (cy1-cy2)*(cy1-cy2));
    ac = atan2(cy2-cy1, cx2-cx1);

    wx = -sparm->wpair;
    wy = -sparm->wpair;

    M.dims_num = 2;
    M.dims = node->dims;
    M.length = node->dims[0]*node->dims[1];
    M.data = message;

    L.dims_num = 3;
    L.dims = (int*)my_malloc(sizeof(int)*3);
    L.dims[0] = node->dims[0];
    L.dims[1] = node->dims[1];
    L.dims[2] = 2;
    L.length = node->dims[0]*node->dims[1]*2;
    L.data = location;

    V.dims_num = 2;
    V.dims = node->dims;
    V.length = node->dims[0]*node->dims[1];
    V.data = v;

    /* distance transformation to compute the message */
    distance_transform_2D(M, V, L, sbin, dc, ac, wx, wy);

    /* use GPU to compute the message */
    /*
    compute_message(M, V, sbin, dc, ac, wx, wy);
    */

    /* brute force way to compute the message */
    /*
    for(xj = 0; xj < node->dims[1]; xj++)
    {
      for(yj = 0; yj < node->dims[0]; yj++)
      {
        max_val = MINUS_INFINITY;
        for(xi = 0; xi < node->dims[1]; xi++)
        {
          for(yi = 0; yi < node->dims[0]; yi++)
          {
            val = v[xi*node->dims[0]+yi];
            val += pow(sbin*(xi-xj) + dc*cos(ac), 2.0) * wx;
            val += pow(sbin*(yi-yj) + dc*sin(ac), 2.0) * wy;
            if(val > max_val)
              max_val = val;
          }
        }
        message[xj*node->dims[0]+yj] = max_val;
      }
    }
    */
  }
  else /* occlussion */
  {
    for(xi = 0; xi < node->dims[1]; xi++)
    {
      for(yi = 0; yi < node->dims[0]; yi++)
      {
        message[xi*node->dims[0]+yi] = max_val;
        location[xi*node->dims[0]+yi] = max_x;
        location[node->dims[0]*node->dims[1]+xi*node->dims[0]+yi] = max_y;
      }
    }
  }
  free(v);
  free(L.dims);

  /* send message to parent */
  for(i = 0; i < parent->child_num; i++)
  {
    if(parent->children[i]->index == node->index)
    {
      parent->messages[i+1] = message;     /* message[0] is the message from parent */
      parent->locations[i+1] = location;
      break;
    }
  }
}

/* rectify potential A to B according to transformation T */
CUMATRIX rectify_potential(CUMATRIX A, int width, int height, int sbin, float *T)
{
  int x, y, xi, yi, dx, dy, wA, hA;
  float xp, yp, ux, uy, val, cx[2], cy[2];
  CUMATRIX B;

  wA = A.dims[1];
  hA = A.dims[0];

  B.dims_num = 2;
  B.dims = (int*)my_malloc(sizeof(int)*2);
  B.dims[0] = height;
  B.dims[1] = width;
  B.length = height*width;
  B.data = (float*)my_malloc(sizeof(float)*B.length);

  for(x = 0; x < width; x++)
  {
    for(y = 0; y < height; y++)
    {
      /* transform (x,y) according to T */
      xp = T[0]*x + T[3]*y + T[6]/sbin;
      yp = T[1]*x + T[4]*y + T[7]/sbin;

      /* bilinear interpolation */
      if(xp < 0 || xp > wA || yp < 0 || yp > hA)
        B.data[x*height+y] = 0;
      else
      {
	xi = (int)floor((float)xp); 
	yi = (int)floor((float)yp);
	ux = xp - (float)xi;
	uy = yp - (float)yi;

	cx[0] = ux;
        cx[1] = 1 - ux;
	cy[0] = uy;
        cy[1] = 1 - uy;

        val = 0;
        for(dx = 0; dx <= 1; dx++)
        {
          for(dy = 0; dy <= 1; dy++)
            if(xi+dx >= 0 && xi+dx < wA && yi+dy >= 0 && yi+dy < hA)
              val += cx[1-dx] * cy[1-dy] * A.data[(xi+dx)*hA+yi+dy];
        }
        B.data[x*height+y] = val;
      }
    }
  }

  return B;
}

int         empty_label(LABEL y)
{
  /* Returns true, if y is an empty label. An empty label might be
     returned by find_most_violated_constraint_???(x, y, sm) if there
     is no incorrect label that can be found for x, or if it is unable
     to label x at all */
  return(y.object_label == 0);
}

SVECTOR     *psi(PATTERN x, LABEL y, STRUCTMODEL *sm,
		 STRUCT_LEARN_PARM *sparm)
{
  /* Returns a feature vector describing the match between pattern x
     and label y. The feature vector is returned as a list of
     SVECTOR's. Each SVECTOR is in a sparse representation of pairs
     <featurenumber:featurevalue>, where the last pair has
     featurenumber 0 as a terminator. Featurenumbers start with 1 and
     end with sizePsi. Featuresnumbers that are not specified default
     to value 0. As mentioned before, psi() actually returns a list of
     SVECTOR's. Each SVECTOR has a field 'factor' and 'next'. 'next'
     specifies the next element in the list, terminated by a NULL
     pointer. The list can be though of as a linear combination of
     vectors, where each vector is weighted by its 'factor'. This
     linear combination of feature vectors is multiplied with the
     learned (kernelized) weight vector to score label y for pattern
     x. Without kernels, there will be one weight in sm.w for each
     feature. Note that psi has to match
     find_most_violated_constraint_???(x, y, sm) and vice versa. In
     particular, find_most_violated_constraint_???(x, y, sm) finds
     that ybar!=y that maximizes psi(x,ybar,sm)*sm.w (where * is the
     inner vector product) and the appropriate function of the
     loss + margin/slack rescaling method. See that paper for details. */
  SVECTOR *fvec;

  /* insert code for computing the feature vector for x and y here */
  CAD *cad;
  int i, j, wpos, wnum;
  int cxprim, cyprim;
  float cx, cy;
  float *features, *homography, T[9];
  WORD *words;
  CUMATRIX rectified_image, cropped_hog, hog;

  /* the feature of negative sample is zero */
  if(y.object_label == -1)
  {
    words = (WORD*)my_malloc(sizeof(WORD));
    words[0].wnum = 0;
    words[0].weight = 0;
    fvec = create_svector(words, "", 1.0);
    free(words);
    return fvec;
  }

  cad = sm->cads[y.cad_label];
  words = (WORD*)my_malloc(sizeof(WORD)*(cad->feature_len+10));
  /* compute rectified HOG features for each part */
  wpos = 0;
  wnum = 1;
  for(i = 0; i < y.cad_label; i++)
    wnum += sm->cads[i]->feature_len;
  for(i = 0; i < cad->part_num; i++)
  {
    /* for training each part */

    /* if root part */
    if(sparm->cad_index >= 0 && sparm->part_index >= 0 && sparm->deep == 0 && i != sparm->part_index)
    {
      wnum += cad->part_templates[i]->length + 1;
      continue;
    }

    /* if aspectlet */
    if(sparm->cad_index >= 0 && sparm->part_index >= 0 && cad->roots[sparm->part_index] == 1 && sparm->deep == 1 && isin_tree(cad->objects2d[y.view_label]->tree+sparm->part_index, i) == 0)
    {
      wnum += cad->part_templates[i]->length + 1;
      continue;
    }

    /* part center */
    cx = y.part_label[i];
    cy = y.part_label[cad->part_num+i];
    if(cad->objects2d[y.view_label]->occluded[i] == 0 && cx != 0 && cy != 0)
    {
      homography = cad->objects2d[y.view_label]->homographies[i];
      /* rectify image */
      rectified_image = rectify_image(x.image, homography, T);
      /* compute HOG features */
      hog = compute_hog_features(rectified_image, cad->part_templates[i]->sbin);

      /* transform part center */
      cxprim = (int)round((T[0]*cx + T[3]*cy + T[6])/(float)cad->part_templates[i]->sbin);
      cyprim = (int)round((T[1]*cx + T[4]*cy + T[7])/(float)cad->part_templates[i]->sbin);
      cropped_hog = crop_hog(hog, cxprim, cyprim, cad->part_templates[i]->b0, cad->part_templates[i]->b1);

      features = cropped_hog.data;
      for(j = 0; j < cad->part_templates[i]->length; j++)
      {
        if(fabs(features[j]) > 1.0e-32)
        {
          words[wpos].wnum = wnum;
          words[wpos].weight = features[j];
          wpos++;
          wnum++;
        }
        else
          wnum++;
      }
      /* skip occlusion weight */
      wnum++;
      free_cumatrix(&rectified_image);
      free_cumatrix(&hog);
      free_cumatrix(&cropped_hog);
    }
    else /* self-occluded part */
    {
      wnum += cad->part_templates[i]->length;
      words[wpos].wnum = wnum;
      words[wpos].weight = 1.0;
      wpos++;
      wnum++;
    }
  }

  words[wpos].wnum = 0;
  fvec = create_svector(words, "", 1.0);

  free(words);
  return(fvec);
}

/* crop hog feature at center (cx, cy) with the given width and height */
CUMATRIX crop_hog(CUMATRIX hog, int cx, int cy, int b0, int b1)
{
  int i, x, y, xx, yy, w, h, z;
  CUMATRIX hog_out;

  w = hog.dims[1];
  h = hog.dims[0];
  z = hog.dims[2];

  hog_out.dims_num = hog.dims_num;
  hog_out.dims = (int*)my_malloc(sizeof(int)*hog_out.dims_num);
  hog_out.dims[1] = b1;
  hog_out.dims[0] = b0;
  hog_out.dims[2] = HOGLENGTH;
  hog_out.length = b0*b1*HOGLENGTH;
  hog_out.data = (float*)my_malloc(sizeof(float)*hog_out.length);

  for(x = 0; x < b1; x++)
  {
    for(y = 0; y < b0; y++)
    {
      xx = x - b1/2 + cx;
      yy = y - b0/2 + cy;
      if(xx >= 0 && xx < w && yy >= 0 && yy < h)
      {
        for(i = 0; i < z; i++)
          hog_out.data[i*b0*b1+x*b0+y] = hog.data[i*w*h+xx*h+yy];
      }
      else
      {
        for(i = 0; i < z; i++)
          hog_out.data[i*b0*b1+x*b0+y] = 0;
      }
    }
  }
  return hog_out;
}

double      loss(LABEL y, LABEL ybar, STRUCT_LEARN_PARM *sparm)
{
  /* loss for correct label y and predicted label ybar. The loss for
     y==ybar has to be zero. sparm->loss_function is set with the -l option. */
  double val, x1, y1, x2, y2;
  int i;

  if(sparm->loss_function == 0) 
  { /* type 0 loss: 0/1 loss return 0, if y==ybar. return 1 else */
    if(y.object_label == ybar.object_label)
      return 0;
    else
      return sparm->loss_value;
  }
  else 
  {
    /* Put your code for different loss functions here. But then
       find_most_violated_constraint_???(x, y, sm) has to return the
       highest scoring label with the largest loss. */
    if(y.object_label == -1 && ybar.object_label == -1)
      val = 0;
    else
    {
      val = 0;
      if(y.object_label != ybar.object_label)
        val += sparm->object_loss;
      else if(y.cad_label != ybar.cad_label)
        val += sparm->cad_loss;
      else if(y.view_label != ybar.view_label)
        val += sparm->view_loss;
      else
      {
        if(sparm->location_loss != 0)
        {
          for(i = 0; i < y.part_num; i++)
          {
            x1 = y.part_label[i];
            y1 = y.part_label[y.part_num+i];
            x2 = ybar.part_label[i];
            y2 = ybar.part_label[ybar.part_num+i];
            val += sparm->location_loss * sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2));
          }
        }
      }
    }
    return val;
  }
}

float compute_azimuth_difference(LABEL y, LABEL ybar, STRUCTMODEL *sm)
{
  float diff;
  if(y.object_label == 1 && ybar.object_label == 1)
    diff = fabs(sm->cads[0]->objects2d[y.view_label]->azimuth - sm->cads[0]->objects2d[ybar.view_label]->azimuth);
  else if(y.object_label == -1 && ybar.object_label == -1)
    diff = 0;
  else
    diff = 360;
  return diff;
}

int         finalize_iteration(double ceps, int cached_constraint,
			       SAMPLE sample, STRUCTMODEL *sm,
			       CONSTSET cset, double *alpha, 
			       STRUCT_LEARN_PARM *sparm)
{
  /* This function is called just before the end of each cutting plane iteration. 
     ceps is the amount by which the most violated constraint found in the current iteration was violated. 
     cached_constraint is true if the added constraint was constructed from the cache. 
     If the return value is FALSE, then the algorithm is allowed to terminate. 
     If it is TRUE, the algorithm will keep iterating even if the desired precision sparm->epsilon is already reached. */
  return(0);
}

void write_weights(STRUCTMODEL *sm)
{
  long i;
  for(i = 0; i < sm->sizePsi; i++)
    fprintf(sm->fp, "%.32f ", sm->weights[i]);
  fprintf(sm->fp, "\n");
  fflush(sm->fp);
}

void write_constraints(CONSTSET cset, STRUCT_LEARN_PARM *sparm)
{
  int i;
  SVECTOR *fvec;
  WORD *w;
  FILE *fp;

  sprintf(sparm->confile, "%s_%d.con", sparm->cls, sparm->iter);
  printf("Write constraints to file %s\n", sparm->confile);
  fp = fopen(sparm->confile, "w");
  fprintf(fp, "%d\n", cset.m);
  for(i = 0; i < cset.m; i++)
  {
    fvec = cset.lhs[i]->fvec;
    w = fvec->words;
    while(w->wnum)
    {
      fprintf(fp, "%d:%.32f ", w->wnum, w->weight*fvec->factor);
      w++;
    }
    fprintf(fp, "%d:%.32f ", 0, -1.0);
    fprintf(fp, "%f\n", cset.rhs[i]);
  }
  fclose(fp);
}

CONSTSET    read_constraints(char *file, STRUCTMODEL *sm)
{
  CONSTSET c;
  int     i, wnum, wpos;
  WORD     *words;
  float weight;
  FILE *fp;

  if((fp = fopen(file, "r")) == NULL)
  {
    printf("Can not open file %s to read constraints.\n", file);
    exit(1);
  }
  words = (WORD*)my_malloc(sizeof(WORD)*(sm->sizePsi+10));

  fscanf(fp, "%d", &(c.m));
  c.lhs = my_malloc(sizeof(DOC *)*c.m);
  c.rhs = my_malloc(sizeof(double)*c.m);
  for(i = 0; i < c.m; i++)
  {
    wpos = 0;
    fscanf(fp, "%d:%f", &wnum, &weight);
    while(wnum != 0)
    {
      words[wpos].wnum = wnum;
      words[wpos].weight = weight;
      wpos++;
      fscanf(fp, "%d:%f", &wnum, &weight);
    }
    words[wpos].wnum = wnum;
    words[wpos].weight = weight;
    c.lhs[i] = create_example(i, 0, 1000000+i, 1, create_svector(words, "", 1.0));
    fscanf(fp, "%lf", &(c.rhs[i]));
  }
  free(words);
  fclose(fp);

  return(c);
}

void print_label(LABEL y, STRUCTMODEL *sm, STRUCT_LEARN_PARM *sparm)
{
  int i;
  float lx, ly;

  printf("object label = %d\n", y.object_label);
  printf("cad label = %d\n", y.cad_label);
  printf("view label = %d\n", y.view_label);
  printf("energy = %f\n", y.energy);
  for(i = 0; i < sm->cads[y.cad_label]->part_num; i++)
  {
    lx = y.part_label[i];
    ly = y.part_label[sm->cads[y.cad_label]->part_num+i];
    if(lx)
    {
      lx = lx - sparm->padx;
      ly = ly - sparm->pady;
    }
    printf("part %d: %f %f\n", i+1, lx, ly);
  }
  printf("bbox: ");
  for(i = 0; i < 4; i++)
  {
    if(i % 2 == 0)
      printf("%f ", y.bbox[i]-sparm->padx);
    else
      printf("%f ", y.bbox[i]-sparm->pady);
  }
  printf("\n");
}

void        print_struct_learning_stats(SAMPLE sample, STRUCTMODEL *sm,
					CONSTSET cset, double *alpha, 
					STRUCT_LEARN_PARM *sparm)
{
  /* This function is called after training and allows final touches to
     the model sm. But primarly it allows computing and printing any
     kind of statistic (e.g. training error) you might want. */
}

void        print_struct_testing_stats(SAMPLE sample, STRUCTMODEL *sm,
				       STRUCT_LEARN_PARM *sparm, 
				       STRUCT_TEST_STATS *teststats)
{
  /* This function is called after making all test predictions in
     svm_struct_classify and allows computing and printing any kind of
     evaluation (e.g. precision/recall) you might want. You can use
     the function eval_prediction to accumulate the necessary
     statistics for each prediction. */
}

void        eval_prediction(long exnum, EXAMPLE ex, LABEL ypred, 
			    STRUCTMODEL *sm, STRUCT_LEARN_PARM *sparm, 
			    STRUCT_TEST_STATS *teststats)
{
  /* This function allows you to accumlate statistic for how well the
     predicition matches the labeled example. It is called from
     svm_struct_classify. See also the function
     print_struct_testing_stats. */
  if(exnum == 0) 
  { /* this is the first time the function is called. So initialize the teststats */
  }
}

void        write_struct_model(char *file, STRUCTMODEL *sm, 
			       STRUCT_LEARN_PARM *sparm)
{
  /* Writes structural model sm to file file. */
  long i;
  FILE *fp;

  if((fp = fopen(file, "w")) == NULL)
  {
    printf("Can not open file %s to write model.\n", file);
    exit(1);
  }

  fprintf(fp, "%lf\n", sparm->C);
  fprintf(fp, "%d\n", sparm->loss_function);
  fprintf(fp, "%f\n", sparm->object_loss);
  fprintf(fp, "%f\n", sparm->cad_loss);
  fprintf(fp, "%f\n", sparm->view_loss);
  fprintf(fp, "%f\n", sparm->location_loss);
  fprintf(fp, "%f\n", sparm->loss_value);
  fprintf(fp, "%f\n", sparm->wpair);

  fprintf(fp, "%ld\n", sm->sizePsi);
  for(i = 0; i < sm->sizePsi; i++)
    fprintf(fp, "%.32f ", sm->weights[i]);
  fprintf(fp, "\n");
  fclose(fp);
}

STRUCTMODEL read_struct_model(char *file, STRUCT_LEARN_PARM *sparm)
{
  /* Reads structural model sm from file file. This function is used
     only in the prediction module, not in the learning module. */
  long i;
  FILE *fp;
  STRUCTMODEL sm;
  double loss;

  if((fp = fopen(file, "r")) == NULL)
  {
    printf("Can not open file %s to read model.\n", file);
    exit(1);
  }

  fscanf(fp, "%lf", &(sparm->C));
  /* read loss parameters */
  fscanf(fp, "%d", &(sparm->loss_function));
  fscanf(fp, "%lf", &loss);
  sparm->object_loss = loss;
  fscanf(fp, "%lf", &loss);
  sparm->cad_loss = loss;
  fscanf(fp, "%lf", &loss);
  sparm->view_loss = loss;
  fscanf(fp, "%lf", &loss);
  sparm->location_loss = loss;
  fscanf(fp, "%lf", &loss);
  sparm->loss_value = loss;
  fscanf(fp, "%lf", &loss);
  sparm->wpair = loss;

  /* read weights */
  fscanf(fp, "%ld", &(sm.sizePsi));
  sm.weights = (float*)my_malloc(sizeof(float)*sm.sizePsi);
  for(i = 0; i < sm.sizePsi; i++)
    fscanf(fp, "%f", &(sm.weights[i]));
  fclose(fp);

  sm.w = NULL;
  sm.svm_model = NULL;
  if((sm.fp = fopen("test.log", "w")) == NULL)
  {
    printf("Can not open test.log.\n");
    exit(1);
  }
  return sm;
}

void        write_label(FILE *fp, LABEL y, STRUCTMODEL *sm, STRUCT_LEARN_PARM *sparm)
{
  /* Writes label y to file handle fp. */
  int i;
  float l;

  fprintf(fp, "%d ", y.object_label);
  fprintf(fp, "%d ", y.cad_label);
  fprintf(fp, "%d ", y.view_label);
  fprintf(fp, "%.12f ", y.energy);
  for(i = 0; i < 2*y.part_num; i++)
  {
    l = y.part_label[i];
    if(l)
    {
      if(i < y.part_num)
        l -= sparm->padx;
      else
        l -= sparm->pady;
    }
    fprintf(fp, "%f ", l);
  }
  for(i = 0; i < 4; i++)
  {
    if(i % 2 == 0)
      fprintf(fp, "%f ", y.bbox[i] - sparm->padx);
    else
      fprintf(fp, "%f ", y.bbox[i] - sparm->pady);
  }
  fprintf(fp, "\n");
} 

void        free_pattern(PATTERN x) {
  /* Frees the memory of x. */
  free_cumatrix(&(x.image));
}

void        free_label(LABEL y) {
  /* Frees the memory of y. */
  if(y.part_label)
    free(y.part_label);
  if(y.occlusion)
    free(y.occlusion);
}

void        free_struct_model(STRUCTMODEL sm) 
{
  /* Frees the memory of model. */
  /* if(sm.w) free(sm.w); */ /* this is free'd in free_model */
  if(sm.svm_model)
    free_model(sm.svm_model,1);
  /* add free calls for user defined data here */
  if(sm.weights)
    free(sm.weights);
  fclose(sm.fp);
}

void        free_struct_sample(SAMPLE s)
{
  /* Frees the memory of sample s. */
  int i;
  for(i = 0; i < s.n; i++) 
  { 
    free_pattern(s.examples[i].x);
    free_label(s.examples[i].y);
  }
  free(s.examples);
}

void        print_struct_help()
{
  /* Prints a help text that is appended to the common help text of
     svm_struct_learn. */
  printf("         --* string  -> custom parameters that can be adapted for struct\n");
  printf("                        learning. The * can be replaced by any character\n");
  printf("                        and there can be multiple options starting with --.\n");
}

void         parse_struct_parameters(STRUCT_LEARN_PARM *sparm)
{
  /* Parses the command line parameters that start with -- */
  int i;

  for(i=0; (i<sparm->custom_argc) && ((sparm->custom_argv[i])[0] == '-'); i++) 
  {
    switch ((sparm->custom_argv[i])[2]) 
    { 
      case 'l': 
        i++; 
        sparm->loss_value = atof(sparm->custom_argv[i]);
        sparm->object_loss = sparm->loss_value;
        sparm->cad_loss = 0.1*sparm->loss_value;
        sparm->view_loss = 0.1*sparm->loss_value;
        sparm->location_loss = 0;
        break;
      case 'h':
        i++;
        sparm->hard_negative = atoi(sparm->custom_argv[i]);
        break;
      case 'w':
        i++;
        sparm->wpair = atof(sparm->custom_argv[i]);
        break;
      case 'r':
        i++;
        sparm->is_root = atoi(sparm->custom_argv[i]);
        break;
      case 'a':
        i++;
        sparm->is_aspectlet = atoi(sparm->custom_argv[i]);
        break;
      default: 
        printf("\nUnrecognized option %s!\n\n",sparm->custom_argv[i]);
	exit(0);
    }
  }
}

void        print_struct_help_classify()
{
  /* Prints a help text that is appended to the common help text of
     svm_struct_classify. */
  printf("         --* string -> custom parameters that can be adapted for struct\n");
  printf("                       learning. The * can be replaced by any character\n");
  printf("                       and there can be multiple options starting with --.\n");
}

void         parse_struct_parameters_classify(char *attribute, char *value)
{
  /* Parses one command line parameters that start with -- . The name
     of the parameter is given in attribute, the value is given in
     value. */

  switch (attribute[2]) 
    { 
      /* case 'x': strcpy(xvalue,value); break; */
      default: printf("\nUnrecognized option %s!\n\n",attribute);
	       exit(0);
    }
}

/* copy file */
void copy_file(char *dst_name, char *src_name)
{
  char ch;
  FILE *fdst, *fsrc;

  fsrc = fopen(src_name, "r");
  if(fsrc == NULL)
  {
    printf("Can not open file %s to copy\n", src_name);
    exit(1);
  }
  fdst = fopen(dst_name, "w");

  while((ch = fgetc(fsrc)) != EOF)
    fputc(ch, fdst);

  fclose(fsrc);
  fclose(fdst);
}

/* combine multiple files into a single file */
void combine_files(char *dst_name, char *src_name, int num)
{
  int i;
  char ch, filename[256];
  FILE *fdst, *fsrc;

  fdst = fopen(dst_name, "w");

  for(i = 0; i < num; i++)
  {
    sprintf(filename, "%s_%d", src_name, i);
    fsrc = fopen(filename, "r");
    if(fsrc == NULL)
    {
      printf("Can not open file %s to copy\n", filename);
      exit(1);
    }

    while((ch = fgetc(fsrc)) != EOF)
      fputc(ch, fdst);
    fprintf(fdst, "\n");
    fclose(fsrc);
  }
  fclose(fdst);
}
