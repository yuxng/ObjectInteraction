/*
  matlab interface for the model
  Author: Yu Xiang
  Date: 5/30/2012
*/

#include <stdio.h>
#include "mex.h"
#ifdef __cplusplus
extern "C" {
#endif
#include "svm_light/svm_common.h"
#ifdef __cplusplus
}
#endif
#include "svm_struct_api.h"
#include "cad.h"
#include "tree.h"
#include "matrix.h"
#include "hog.h"
#include "rectify.h"
#include "convolve.h"
#include "select_gpu.h"

STRUCTMODEL read_struct_model_matlab(const mxArray *model, STRUCT_LEARN_PARM *sparm);
CAD* read_cad_matlab(mxArray *cell, int hog_length);
void read_cad_model_matlab(const mxArray *cad_cell, STRUCTMODEL *sm, STRUCT_LEARN_PARM *sparm);
CUMATRIX read_cumatrix_matlab(const mxArray *array);
void print_label_matlab(LABEL y, STRUCTMODEL *sm, STRUCT_LEARN_PARM *sparm);
mxArray* construct_label_structure(LABEL *y, int num, STRUCTMODEL *sm, STRUCT_LEARN_PARM *sparm);
LABEL* classify_struct_example_matlab(PATTERN x, int *label_num, int flag, STRUCTMODEL *sm, STRUCT_LEARN_PARM *sparm);
mxArray* construct_potential_location(STRUCTMODEL *sm);
void find_location(TREENODE *node, int index, float **location, int *dims);
void find_children(TREENODE *node, int index, int **children, int *child_num);

void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int i, j, num, count, rank;
  STRUCTMODEL model; 
  STRUCT_LEARN_PARM sparm;
  PATTERN x;
  CUMATRIX matrix, gradient;
  LABEL *y = NULL;

  if(nrhs != 4)
    mexErrMsgTxt("Four inputs required.");
  if(nlhs > 2)
    mexErrMsgTxt("Too many output arguments.");

  rank = (int)mxGetScalar(prhs[3]) - 1;
  /* select GPU */
  select_gpu(rank);

  model = read_struct_model_matlab(prhs[2], &sparm);
  read_cad_model_matlab(prhs[1], &model, &sparm);

  /* process input image */
  matrix = read_cumatrix_matlab(prhs[0]);
  gradient = compute_gradient_image(matrix);
  /* pad gradient image */
  x.image = pad_3d_maxtrix(gradient, sparm.padx, sparm.pady);

  /* predict */
  y = classify_struct_example_matlab(x, &num, 0, &model, &sparm);

  /* print label */
  /*
  count = 0;
  for(i = 0; i < num; i++)
  {
    if(y[i].object_label)
    {
      count++;
      print_label_matlab(y[i], &model, &sparm);
    }
  }
  mexPrintf("%d objects have been detected.\n", count);
  */

  /* construct output */
  plhs[0] = construct_label_structure(y, num, &model, &sparm);
  plhs[1] = construct_potential_location(&model);

  /* free messages */
  for(i = 0; i < model.cad_num; i++)
  {
    for(j = 0; j < model.cads[i]->view_num; j++)
      free_message(model.cads[i]->objects2d[j]->tree, model.cads[i]->part_num);
  }
  free_cumatrix(&matrix);
  free_cumatrix(&gradient);
  free_pattern(x);
  for(i = 0; i < num; i++)
    free_label(y[i]);
  free(y);
  /* free model */
  for(i = 0; i < model.cad_num; i++)
    destroy_cad(model.cads[i]);
  free(model.cads);
  free_struct_model(model);
}

/* store unary potentials and locations for future use */
LABEL* classify_struct_example_matlab(PATTERN x, int *label_num, int flag, STRUCTMODEL *sm, STRUCT_LEARN_PARM *sparm)
{
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
    potentials = (CUMATRIX*)my_malloc(sizeof(CUMATRIX)*cad->part_num);
    for(v = 0; v < cad->view_num; v++)
    {
      occ_energy = 0;
      /* extract features and convolve them with the weights */
      weights = weights_cad;
      for(i = 0; i < cad->part_num; i++)
      {
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
    
      /* run BP algorithm */
      child_to_parent(cad->objects2d[v]->tree+cad->objects2d[v]->root_index, NULL, cad->objects2d[v], cad->objects2d[v]->graph, cad->part_templates[0]->sbin, NULL, sparm);
      compute_root_scores(cad->objects2d[v]->tree+cad->objects2d[v]->root_index, occ_energy, cad->part_templates[0]->sbin, cad->part_num, NULL, sparm);
      mask = non_maxima_suppression(cad->objects2d[v]->tree[cad->objects2d[v]->root_index].dims, cad->objects2d[v]->tree[cad->objects2d[v]->root_index].messages[0]);
      get_multiple_detection(&y, &count, o, v, cad->objects2d[v]->tree+cad->objects2d[v]->root_index, mask, cad->part_templates[0]->sbin, cad->part_num, sm, sparm);

      /* clean up, do not free messages */
      free(mask);
      for(i = 0; i < cad->part_num; i++)
        free_cumatrix(&(potentials[i]));
    } /* end for each v */
    weights_cad += cad->feature_len;
    free(potentials);
  } /* end for each o */

  /* sort labels*/
  qsort(y, count, sizeof(LABEL), compare_label);
  /* non-maxima suppression by bounding box overlap */
  /*
  num = nms_bbox(y, count);
  */
  num = 0;
  
  if(flag == 1)
  {
    for(i = 0; i < count; i++)
    {
      if(y[i].object_label)
        print_label(y[i], sm, sparm);
    }
    printf("%d objects have been detected.\n", count-num);
  }

  *label_num = count;
  return y;
}

/* extract unary potentials and locatinos from structmodel */
mxArray* construct_potential_location(STRUCTMODEL *sm)
{
  int i, j, k, l, dims[2], dims3D[3], *children, child_num;
  const char *fnames_view[] = {"root_index", "root_score", "parts"};
  const char *fnames_part[] = {"location", "children"};
  float *ptr;
  float *location;
  mxArray *output, *temp, *temp1, *temp2;
  CAD *cad;

  /* a cell structure for cad models */
  output = mxCreateCellMatrix(sm->cad_num, 1);

  for(i = 0; i < sm->cad_num; i++)
  {
    cad = sm->cads[i];
    temp = mxCreateStructMatrix(cad->view_num, 1, 3, fnames_view);
    /* for each view */
    for(j = 0; j < cad->view_num; j++)
    {
      /* root index */
      temp1 = mxCreateNumericMatrix(1, 1, mxSINGLE_CLASS, mxREAL);
      ptr = (float*)mxGetData(temp1);
      ptr[0] = cad->objects2d[j]->root_index + 1;
      mxSetFieldByNumber(temp, j, 0, temp1);

      /* root score */
      dims[0] = cad->objects2d[j]->tree[cad->objects2d[j]->root_index].dims[0];
      dims[1] = cad->objects2d[j]->tree[cad->objects2d[j]->root_index].dims[1];
      temp1 = mxCreateNumericMatrix(dims[0], dims[1], mxSINGLE_CLASS, mxREAL);
      ptr = (float*)mxGetData(temp1);
      for(l = 0; l < dims[0]*dims[1]; l++)
        ptr[l] = cad->objects2d[j]->tree[cad->objects2d[j]->root_index].messages[0][l];
      mxSetFieldByNumber(temp, j, 1, temp1);

      /* for parts */
      temp1 = mxCreateStructMatrix(cad->part_num, 1, 2, fnames_part);
      for(k = 0; k < cad->part_num; k++)
      {
        location = NULL;
        find_location(cad->objects2d[j]->tree+cad->objects2d[j]->root_index, k, &location, dims3D);
        if(location)
        {
          temp2 = mxCreateNumericArray(3, dims3D, mxSINGLE_CLASS, mxREAL);
          ptr = (float*)mxGetData(temp2);
          for(l = 0; l < dims3D[0]*dims3D[1]*dims3D[2]; l++)
            ptr[l] = location[l];
          mxSetFieldByNumber(temp1, k, 0, temp2);
        }
        else
          mxSetFieldByNumber(temp1, k, 0, NULL);

        children = NULL;
        find_children(cad->objects2d[j]->tree+cad->objects2d[j]->root_index, k, &children, &child_num);
        if(children)
        {
          temp2 = mxCreateNumericMatrix(1, child_num, mxSINGLE_CLASS, mxREAL);
          ptr = (float*)mxGetData(temp2);
          for(l = 0; l < child_num; l++)
            ptr[l] = children[l] + 1;
          mxSetFieldByNumber(temp1, k, 1, temp2);
        }
        else
          mxSetFieldByNumber(temp1, k, 1, NULL);
      }
      mxSetFieldByNumber(temp, j, 2, temp1);
    }
    mxSetCell(output, i, temp);
  }

  return output;
}

void find_location(TREENODE *node, int index, float **location, int *dims)
{
  int i, flag;

  flag = 0;
  for(i = 0; i < node->child_num; i++)
  {
    if(node->children[i]->index == index)
    {
      dims[0] = node->dims[0];
      dims[1] = node->dims[1];
      dims[2] = 2;
      *location = node->locations[i+1];
      flag = 1;
      break;
    }
  }
  if(flag == 0)
  {
    for(i = 0; i < node->child_num; i++)
      find_location(node->children[i], index, location, dims);  
  }
}

void find_children(TREENODE *node, int index, int **children, int *child_num)
{
  int i, *temp;

  if(node->index == index)
  {
    if(node->child_num == 0)
      temp = NULL;
    else
    {
      temp = (int*)my_malloc(sizeof(int)*node->child_num);
      for(i = 0; i < node->child_num; i++)
        temp[i] = node->children[i]->index;
    }
    *children = temp;
    *child_num = node->child_num;
  }
  else
  {
    for(i = 0; i < node->child_num; i++)
      find_children(node->children[i], index, children, child_num);
  }
}

mxArray* construct_label_structure(LABEL *y, int num, STRUCTMODEL *sm, STRUCT_LEARN_PARM *sparm)
{
  int i, j, count, nfields = 7, part_num;
  const char *fnames[] = {"object_label", "cad_label", "view_label", "part_label", "occlusion", "bbox", "energy"};
  double *ptr, l;
  mxArray *output, *temp;

  count = 0;
  for(i = 0; i < num; i++)
  {
    if(y[i].object_label)
      count++;
  }
  output = mxCreateStructMatrix(count, 1, nfields, fnames);

  count = 0;
  for(i = 0; i < num; i++)
  {
    if(y[i].object_label)
    {
      temp = mxCreateNumericMatrix(1, 1, mxDOUBLE_CLASS, mxREAL);
      ptr = (double*)mxGetData(temp);
      ptr[0] = y[i].object_label;
      mxSetFieldByNumber(output, count, 0, temp);

      temp = mxCreateNumericMatrix(1, 1, mxDOUBLE_CLASS, mxREAL);
      ptr = (double*)mxGetData(temp);
      ptr[0] = y[i].cad_label + 1;
      mxSetFieldByNumber(output, count, 1, temp);

      temp = mxCreateNumericMatrix(1, 1, mxDOUBLE_CLASS, mxREAL);
      ptr = (double*)mxGetData(temp);
      ptr[0] = y[i].view_label + 1;
      mxSetFieldByNumber(output, count, 2, temp);

      part_num = y[i].part_num;
      temp = mxCreateNumericMatrix(part_num, 2, mxDOUBLE_CLASS, mxREAL);
      ptr = (double*)mxGetData(temp);
      for(j = 0; j < part_num*2; j++)
      {
        l = y[i].part_label[j];
        if(l)
        {
          if(j < part_num)
            l -= sparm->padx;
          else
            l -= sparm->pady;
        }
        ptr[j] = l;
      }
      mxSetFieldByNumber(output, count, 3, temp);

      if(y[i].occlusion != NULL)
      {
        temp = mxCreateNumericMatrix(part_num, 1, mxDOUBLE_CLASS, mxREAL);
        ptr = (double*)mxGetData(temp);
        for(j = 0; j < part_num; j++)
          ptr[j] = y[i].occlusion[j];
        mxSetFieldByNumber(output, count, 4, temp);
      }
      else
        mxSetFieldByNumber(output, count, 4, NULL);

      temp = mxCreateNumericMatrix(1, 4, mxDOUBLE_CLASS, mxREAL);
      ptr = (double*)mxGetData(temp);
      for(j = 0; j < 4; j++)
      {
        if(j % 2 == 0)
          ptr[j] = y[i].bbox[j] - sparm->padx;
        else
          ptr[j] = y[i].bbox[j] - sparm->pady;
      }
      mxSetFieldByNumber(output, count, 5, temp);

      temp = mxCreateNumericMatrix(1, 1, mxDOUBLE_CLASS, mxREAL);
      ptr = (double*)mxGetData(temp);
      ptr[0] = y[i].energy;
      mxSetFieldByNumber(output, count, 6, temp);

      count++;
    }
  }
  return output;
}

/* read struct model from mxArray */
STRUCTMODEL read_struct_model_matlab(const mxArray *model, STRUCT_LEARN_PARM *sparm)
{
  /* Reads structural model sm from file file. This function is used
     only in the prediction module, not in the learning module. */
  long i;
  int padx, pady;
  STRUCTMODEL sm;
  double *ptr;
  mxArray *temp;

  temp = mxGetField(model, 0, "C");
  sparm->C = (double)mxGetScalar(temp);
  /* read loss parameters */
  temp = mxGetField(model, 0, "loss_function");
  sparm->loss_function = (int)mxGetScalar(temp);
  temp = mxGetField(model, 0, "object_loss");
  sparm->object_loss = (double)mxGetScalar(temp);
  temp = mxGetField(model, 0, "cad_loss");
  sparm->cad_loss = (double)mxGetScalar(temp);
  temp = mxGetField(model, 0, "view_loss");
  sparm->view_loss = (double)mxGetScalar(temp);
  temp = mxGetField(model, 0, "location_loss");
  sparm->location_loss = (double)mxGetScalar(temp);
  temp = mxGetField(model, 0, "loss_value");
  sparm->loss_value = (double)mxGetScalar(temp);
  temp = mxGetField(model, 0, "wxy");
  sparm->wpair = (double)mxGetScalar(temp);
  /* read padding */
  temp = mxGetField(model, 0, "padx");
  sparm->padx = (int)mxGetScalar(temp);
  temp = mxGetField(model, 0, "pady");
  sparm->pady = (int)mxGetScalar(temp);

  /* read weights */
  temp = mxGetField(model, 0, "psi_size");
  sm.sizePsi = (long)mxGetScalar(temp);

  temp = mxGetField(model, 0, "weights");
  ptr = (double*)mxGetData(temp);
  sm.weights = (float*)my_malloc(sizeof(float)*sm.sizePsi);
  for(i = 0; i < sm.sizePsi; i++)
    sm.weights[i] = (float)(ptr[i]);

  sm.w = NULL;
  sm.svm_model = NULL;
  if((sm.fp = fopen("test.log", "w")) == NULL)
  {
    mexPrintf("Can not open test.log.\n");
    exit(1);
  }
  return sm;
}

/* read cad model from mxArray */
void read_cad_model_matlab(const mxArray *cad_cell, STRUCTMODEL *sm, STRUCT_LEARN_PARM *sparm)
{
  int i, j, len;
  CAD *cad;
  mxArray *cell;

  /* initialize cad models */
  sm->cad_num = mxGetNumberOfElements(cad_cell);
  sm->cads = (CAD**)my_malloc(sizeof(CAD*)*sm->cad_num);
  for(i = 0; i < sm->cad_num; i++)
  {
    cell = mxGetCell(cad_cell, i);
    sm->cads[i] = read_cad_matlab(cell, HOGLENGTH);
  }

  /* compute cad feature length */
  for(i = 0; i < sm->cad_num; i++)
  {
    cad = sm->cads[i];
    cad->feature_len = 0;
    for(j = 0; j < cad->part_num; j++)
    {
      len = cad->part_templates[j]->length;
      /* add one weight for self-occluded part and occluded part */
      cad->feature_len += len + 1;
    }
  }
}

/* parse cad model from matlab cell */
CAD* read_cad_matlab(mxArray *cell, int hog_length)
{
  int i, j, k, part_num, view_num, root_index;
  CAD *cad;
  char *buffer;
  double *ptr;
  mxArray *temp, *temp1, *temp2;

  /* allocate memory */
  cad = (CAD*)malloc(sizeof(CAD));
  if(cad == NULL)
  {
    mexPrintf("out of memory\n");
    return NULL;
  }

  /* read part number */
  temp = mxGetField(cell, 0, "pnames");
  part_num = mxGetNumberOfElements(temp);
  cad->part_num = part_num;

  /* read part names */
  cad->part_names = (char**)malloc(sizeof(char*)*part_num);
  if(cad->part_names == NULL)
  {
    mexPrintf("out of memory\n");
    return NULL;
  }
  for(i = 0; i < part_num; i++)
  {
    temp1 = mxGetCell(temp, i);
    cad->part_names[i] = (char*)malloc(sizeof(char)*(mxGetM(temp1)*mxGetN(temp1)+1));
    if(cad->part_names[i] == NULL)
    {
      mexPrintf("out of memory\n");
      return NULL;
    }
    buffer = mxArrayToString(temp1);
    strcpy(cad->part_names[i], buffer);
  }

  /* read root indexes */
  temp = mxGetField(cell, 0, "roots");
  ptr = (double*)mxGetData(temp);
  cad->roots = (int*)malloc(sizeof(int)*part_num);
  if(cad->roots == NULL)
  {
    mexPrintf("out of memory\n");
    return NULL;
  }
  for(i = 0; i < part_num; i++)
    cad->roots[i] = (int)(ptr[i]);

  /* read part templates */
  temp = mxGetField(cell, 0, "parts2d_front");
  cad->part_templates = (PARTTEMPLATE**)malloc(sizeof(PARTTEMPLATE*)*part_num);
  if(cad->part_templates == NULL)
  {
    mexPrintf("out of memory\n");
    return NULL;
  }
  for(i = 0; i < part_num; i++)
  {
    cad->part_templates[i] = (PARTTEMPLATE*)malloc(sizeof(PARTTEMPLATE));
    if(cad->part_templates[i] == NULL)
    {
      mexPrintf("out of memory\n");
      return NULL;
    }
    temp1 = mxGetField(temp, i, "width");
    cad->part_templates[i]->width = (int)mxGetScalar(temp1);
    temp1 = mxGetField(temp, i, "height");
    cad->part_templates[i]->height = (int)mxGetScalar(temp1);
    cad->part_templates[i]->sbin = HOGBINSIZE;
    cad->part_templates[i]->b0 = (int)round((double)(cad->part_templates[i]->height)/(double)(cad->part_templates[i]->sbin));
    cad->part_templates[i]->b1 = (int)round((double)(cad->part_templates[i]->width)/(double)(cad->part_templates[i]->sbin));
    cad->part_templates[i]->length = cad->part_templates[i]->b0 * cad->part_templates[i]->b1 * hog_length;
    cad->part_templates[i]->weights = NULL; 
  }

  /* read view number */
  temp = mxGetField(cell, 0, "parts2d");
  view_num = mxGetNumberOfElements(temp);
  cad->view_num = view_num;

  /* read objects in 2D */
  cad->objects2d = (OBJECT2D**)malloc(sizeof(OBJECT2D*)*view_num);
  if(cad->objects2d == NULL)
  {
    mexPrintf("out of memory\n");
    return NULL;
  }
  for(i = 0; i < view_num; i++)
  {
    cad->objects2d[i] = (OBJECT2D*)malloc(sizeof(OBJECT2D));
    if(cad->objects2d[i] == NULL)
    {
      mexPrintf("out of memory\n");
      return NULL;
    }
    temp1 = mxGetField(temp, i, "azimuth");
    cad->objects2d[i]->azimuth = (float)mxGetScalar(temp1);
    temp1 = mxGetField(temp, i, "elevation");
    cad->objects2d[i]->elevation = (float)mxGetScalar(temp1);
    temp1 = mxGetField(temp, i, "distance");
    cad->objects2d[i]->distance = (float)mxGetScalar(temp1);
    temp1 = mxGetField(temp, i, "viewport");
    cad->objects2d[i]->viewport_size = (int)mxGetScalar(temp1);
    cad->objects2d[i]->part_num = part_num;

    /* read part locations */
    temp1 = mxGetField(temp, i, "centers");
    ptr = (double*)mxGetData(temp1);
    cad->objects2d[i]->part_locations = (float*)malloc(sizeof(float)*2*part_num);
    if(cad->objects2d[i]->part_locations == NULL)
    {
      mexPrintf("out of memory\n");
      return NULL;
    }
    for(j = 0; j < 2*part_num; j++)
      cad->objects2d[i]->part_locations[j] = (float)(ptr[j]);

    /* set occlusion flag */
    cad->objects2d[i]->occluded = (int*)malloc(sizeof(int)*part_num);
    if(cad->objects2d[i]->occluded == NULL)
    {
      mexPrintf("out of memory\n");
      return NULL;
    }
    for(j = 0; j < part_num; j++)
    {
      if(cad->objects2d[i]->part_locations[j] != 0)
        cad->objects2d[i]->occluded[j] = 0;
      else
        cad->objects2d[i]->occluded[j] = 1;
    }

    /* read homographies */
    temp1 = mxGetField(temp, i, "homographies");
    cad->objects2d[i]->homographies = (float**)malloc(sizeof(float*)*part_num);
    if(cad->objects2d[i]->homographies == NULL)
    {
      mexPrintf("out of memory\n");
      return NULL;
    }
    for(j = 0; j < part_num; j++)
    {
      if(cad->objects2d[i]->occluded[j] == 1)
        cad->objects2d[i]->homographies[j] = NULL;
      else
      {
        cad->objects2d[i]->homographies[j] = (float*)malloc(sizeof(float)*9);
        if(cad->objects2d[i]->homographies[j] == NULL)
        {
          mexPrintf("out of memory\n");
          return NULL;
        }
        temp2 = mxGetCell(temp1, j);
        ptr = (double*)mxGetData(temp2);
        for(k = 0; k < 9; k++)
          cad->objects2d[i]->homographies[j][k] = (float)(ptr[k]);
      }
    }

    /* read part shapes */
    cad->objects2d[i]->part_shapes = (float**)malloc(sizeof(float*)*part_num);
    if(cad->objects2d[i]->part_shapes == NULL)
    {
      mexPrintf("out of memory\n");
      return NULL;
    }
    for(j = 0; j < part_num; j++)
    {
      if(cad->objects2d[i]->occluded[j] == 1)
        cad->objects2d[i]->part_shapes[j] = NULL;
      else
      {
        cad->objects2d[i]->part_shapes[j] = (float*)malloc(sizeof(float)*8);
        if(cad->objects2d[i]->part_shapes[j] == NULL)
        {
          mexPrintf("out of memory\n");
          return NULL;
        }
        temp1 = mxGetField(temp, i, cad->part_names[j]);
        ptr = (double*)mxGetData(temp1);
        for(k = 0; k < 8; k++)
        {
          if(k < 4)
            cad->objects2d[i]->part_shapes[j][k] = (float)(ptr[k]);
          else
            cad->objects2d[i]->part_shapes[j][k] = (float)(ptr[k+1]);
        }
      }
    }

    /* read graph */
    temp1 = mxGetField(temp, i, "graph");
    ptr = (double*)mxGetData(temp1);
    cad->objects2d[i]->graph = (int**)malloc(sizeof(int*)*part_num);
    if(cad->objects2d[i]->graph == NULL)
    {
      mexPrintf("out of memory\n");
      return NULL;
    }
    for(j = 0; j < part_num; j++)
    {
      cad->objects2d[i]->graph[j] = (int*)malloc(sizeof(int)*part_num);
      if(cad->objects2d[i]->graph[j] == NULL)
      {
        mexPrintf("out of memory\n");
        return NULL;
      }
      for(k = 0; k < part_num; k++)
        cad->objects2d[i]->graph[j][k] = (int)(ptr[j*part_num+k]);
    }
  
    /* construct tree */
    temp1 = mxGetField(temp, i, "root");
    root_index = (int)mxGetScalar(temp1) - 1;
    cad->objects2d[i]->root_index = root_index;
    cad->objects2d[i]->tree = construct_tree(part_num, root_index, cad->objects2d[i]->graph);
  }
  return cad;
}

/* construct cumatrix from mxArray */
CUMATRIX read_cumatrix_matlab(const mxArray *array)
{
  int i;
  CUMATRIX matrix;
  const mwSize *dims;
  double *ptr;

  /* initialization */
  matrix.dims_num = 0;
  matrix.dims = NULL;
  matrix.length = 0;
  matrix.data = NULL;

  /* read dimension */
  matrix.dims_num = mxGetNumberOfDimensions(array);

  /* allocate dims */
  dims = mxGetDimensions(array);
  matrix.dims = (int*)malloc(sizeof(int)*matrix.dims_num);
  matrix.length = 1;
  for(i = 0; i < matrix.dims_num; i++)
  {
    matrix.dims[i] = dims[i];
    matrix.length *= matrix.dims[i];
  }

  /* allocate data */
  ptr = (double*)mxGetData(array);
  matrix.data = (float*)malloc(sizeof(float)*matrix.length);
  for(i = 0; i < matrix.length; i++)
    matrix.data[i] = (float)(ptr[i]);

  return matrix;
}

void print_label_matlab(LABEL y, STRUCTMODEL *sm, STRUCT_LEARN_PARM *sparm)
{
  int i;
  float lx, ly;

  mexPrintf("object label = %d\n", y.object_label);
  mexPrintf("cad label = %d\n", y.cad_label);
  mexPrintf("view label = %d\n", y.view_label);
  mexPrintf("energy = %f\n", y.energy);
  for(i = 0; i < sm->cads[y.cad_label]->part_num; i++)
  {
    lx = y.part_label[i];
    ly = y.part_label[sm->cads[y.cad_label]->part_num+i];
    if(lx)
    {
      lx = lx - sparm->padx;
      ly = ly - sparm->pady;
    }
    mexPrintf("part %d: %f %f\n", i+1, lx, ly);
  }
  mexPrintf("bbox: ");
  for(i = 0; i < 4; i++)
  {
    if(i % 2 == 0)
      mexPrintf("%f ", y.bbox[i]-sparm->padx);
    else
      mexPrintf("%f ", y.bbox[i]-sparm->pady);
  }
  mexPrintf("\n");
}
