/* CAD model for an object category
   Author: Yu Xiang
   Date: 03/16/2011
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "cad.h"

CAD* read_cad(FILE *fp, int hog_length)
{
  int i, j, k, part_num, view_num, root_index;
  CAD *cad;
  char buffer[256];

  /* allocate memory */
  cad = (CAD*)malloc(sizeof(CAD));
  if(cad == NULL)
  {
    printf("out of memory\n");
    return NULL;
  }

  /* read part number */
  fscanf(fp, "%d", &part_num);
  cad->part_num = part_num;

  /* read part names */
  cad->part_names = (char**)malloc(sizeof(char*)*part_num);
  if(cad->part_names == NULL)
  {
    printf("out of memory\n");
    return NULL;
  }
  for(i = 0; i < part_num; i++)
  {
    fscanf(fp, "%s", buffer);
    cad->part_names[i] = (char*)malloc(sizeof(char)*(strlen(buffer)+1));
    if(cad->part_names[i] == NULL)
    {
      printf("out of memory\n");
      return NULL;
    }
    strcpy(cad->part_names[i], buffer);
  }

  /* read root indexes */
  cad->roots = (int*)malloc(sizeof(int)*part_num);
  if(cad->roots == NULL)
  {
    printf("out of memory\n");
    return NULL;
  }
  for(i = 0; i < part_num; i++)
    fscanf(fp, "%d", &(cad->roots[i]));

  /* read part templates */
  cad->part_templates = (PARTTEMPLATE**)malloc(sizeof(PARTTEMPLATE*)*part_num);
  if(cad->part_templates == NULL)
  {
    printf("out of memory\n");
    return NULL;
  }
  for(i = 0; i < part_num; i++)
  {
    cad->part_templates[i] = (PARTTEMPLATE*)malloc(sizeof(PARTTEMPLATE));
    if(cad->part_templates[i] == NULL)
    {
      printf("out of memory\n");
      return NULL;
    }
    fscanf(fp, "%d", &(cad->part_templates[i]->width));
    fscanf(fp, "%d", &(cad->part_templates[i]->height));
    cad->part_templates[i]->sbin = HOGBINSIZE;
    cad->part_templates[i]->b0 = (int)round((double)(cad->part_templates[i]->height)/(double)(cad->part_templates[i]->sbin));
    cad->part_templates[i]->b1 = (int)round((double)(cad->part_templates[i]->width)/(double)(cad->part_templates[i]->sbin));
    cad->part_templates[i]->length = cad->part_templates[i]->b0 * cad->part_templates[i]->b1 * hog_length;
    cad->part_templates[i]->weights = NULL; 
  }

  /* read view number */
  fscanf(fp, "%d", &view_num);
  cad->view_num = view_num;

  /* read objects in 2D */
  cad->objects2d = (OBJECT2D**)malloc(sizeof(OBJECT2D*)*view_num);
  if(cad->objects2d == NULL)
  {
    printf("out of memory\n");
    return NULL;
  }
  for(i = 0; i < view_num; i++)
  {
    cad->objects2d[i] = (OBJECT2D*)malloc(sizeof(OBJECT2D));
    if(cad->objects2d[i] == NULL)
    {
      printf("out of memory\n");
      return NULL;
    }
    fscanf(fp, "%f", &(cad->objects2d[i]->azimuth));
    fscanf(fp, "%f", &(cad->objects2d[i]->elevation));
    fscanf(fp, "%f", &(cad->objects2d[i]->distance));
    fscanf(fp, "%d", &(cad->objects2d[i]->viewport_size));
    cad->objects2d[i]->part_num = part_num;
    /* read part locations */
    cad->objects2d[i]->part_locations = (float*)malloc(sizeof(float)*2*part_num);
    if(cad->objects2d[i]->part_locations == NULL)
    {
      printf("out of memory\n");
      return NULL;
    }
    for(j = 0; j < 2*part_num; j++)
      fscanf(fp, "%f", &(cad->objects2d[i]->part_locations[j]));

    /* set occlusion flag */
    cad->objects2d[i]->occluded = (int*)malloc(sizeof(int)*part_num);
    if(cad->objects2d[i]->occluded == NULL)
    {
      printf("out of memory\n");
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
    cad->objects2d[i]->homographies = (float**)malloc(sizeof(float*)*part_num);
    if(cad->objects2d[i]->homographies == NULL)
    {
      printf("out of memory\n");
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
          printf("out of memory\n");
          return NULL;
        }
        for(k = 0; k < 9; k++)
          fscanf(fp, "%f", &(cad->objects2d[i]->homographies[j][k]));
      }
    }

    /* read part shapes */
    cad->objects2d[i]->part_shapes = (float**)malloc(sizeof(float*)*part_num);
    if(cad->objects2d[i]->part_shapes == NULL)
    {
      printf("out of memory\n");
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
          printf("out of memory\n");
          return NULL;
        }
        for(k = 0; k < 8; k++)
          fscanf(fp, "%f", &(cad->objects2d[i]->part_shapes[j][k]));
      }
    }

    /* read graph */
    cad->objects2d[i]->graph = (int**)malloc(sizeof(int*)*part_num);
    if(cad->objects2d[i]->graph == NULL)
    {
      printf("out of memory\n");
      return NULL;
    }
    for(j = 0; j < part_num; j++)
    {
      cad->objects2d[i]->graph[j] = (int*)malloc(sizeof(int)*part_num);
      if(cad->objects2d[i]->graph[j] == NULL)
      {
        printf("out of memory\n");
        return NULL;
      }
      for(k = 0; k < part_num; k++)
        fscanf(fp, "%d", &(cad->objects2d[i]->graph[j][k]));
    }
  
    /* construct tree */
    fscanf(fp, "%d", &root_index);
    cad->objects2d[i]->root_index = root_index;
    cad->objects2d[i]->tree = construct_tree(part_num, root_index, cad->objects2d[i]->graph);
  }
  return cad;
}

/* release memory */
void destroy_cad(CAD *cad)
{
  int i, j;

  if(cad == NULL)
    return;

  for(i = 0; i < cad->part_num; i++)
  {
    if(cad->part_names[i] != NULL)
      free(cad->part_names[i]);
    if(cad->part_templates[i]->weights != NULL)
      free(cad->part_templates[i]->weights);
    free(cad->part_templates[i]);
  }

  for(i = 0; i < cad->view_num; i++)
  {
    for(j = 0; j < cad->part_num; j++)
    {
      if(cad->objects2d[i]->homographies[j] != NULL)
        free(cad->objects2d[i]->homographies[j]);
      if(cad->objects2d[i]->part_shapes[j] != NULL)
        free(cad->objects2d[i]->part_shapes[j]);
      free(cad->objects2d[i]->graph[j]);
    }
    free(cad->objects2d[i]->homographies);
    free(cad->objects2d[i]->part_shapes);
    free(cad->objects2d[i]->graph);
    free_tree(cad->objects2d[i]->tree, cad->part_num);
    free(cad->objects2d[i]->part_locations);
    free(cad->objects2d[i]);
  }

  free(cad->part_names);
  free(cad->roots);
  free(cad->part_templates);
  free(cad->objects2d);
  free(cad);
}

void print_cad(CAD *cad)
{
  int i, j, k;

  printf("Part number = %d\n", cad->part_num);
  printf("Part names: ");
  for(i = 0; i < cad->part_num; i++)
    printf("%s ", cad->part_names[i]);
  printf("\n");

  printf("Root indexes: ");
  for(i = 0; i < cad->part_num; i++)
    printf("%d ", cad->roots[i]);
  printf("\n");

  printf("Part templates:\n");
  for(i = 0; i < cad->part_num; i++)
    printf("width = %d, height = %d, sbin = %d\n", cad->part_templates[i]->width, cad->part_templates[i]->height, cad->part_templates[i]->sbin);

  for(i = 0; i < cad->view_num; i++)
  {
    printf("a=%f, ", cad->objects2d[i]->azimuth);
    printf("e=%f, ", cad->objects2d[i]->elevation);
    printf("d=%f, ", cad->objects2d[i]->distance);
    printf("vsize=%d, ", cad->objects2d[i]->viewport_size);
    printf("P: ");
    for(j = 0; j < cad->part_num*2; j++)
      printf("%f ", cad->objects2d[i]->part_locations[j]);
    for(j = 0; j < cad->part_num; j++)
    {
      printf("H%d: ", j+1);
      if(cad->objects2d[i]->occluded[j] == 0)
      {
        for(k = 0; k < 9; k++)
          printf("%f ", cad->objects2d[i]->homographies[j][k]);
      }
      else
        printf("null ");
    }
    for(j = 0; j < cad->part_num; j++)
    {
      printf("%s: ", cad->part_names[j]);
      if(cad->objects2d[i]->occluded[j] == 0)
      {
        for(k = 0; k < 8; k++)
          printf("%f ", cad->objects2d[i]->part_shapes[j][k]);
      }
      else
        printf("null ");
    }
    printf("Graph:\n");
    for(j = 0; j < cad->part_num; j++)
    {
      for(k = 0; k < cad->part_num; k++)
        printf("%d ", cad->objects2d[i]->graph[j][k]);
      printf("\n");
    }
    print_tree(cad->objects2d[i]->tree + cad->objects2d[i]->root_index);
    printf("\n");
  }
}

/* test routine */
/*
int main(int argc, char *argv[]) 
{
  FILE *fp;
  CAD *cad;
 
  fp = fopen(argv[1], "r");
  if(fp == NULL)
  {
    printf("Can not open cad file %s.\n", argv[1]);
    return 1;
  }

  cad = read_cad(fp, HOGLENGTH);
  print_cad(cad);
  destroy_cad(cad);

  return 0;
}
*/
