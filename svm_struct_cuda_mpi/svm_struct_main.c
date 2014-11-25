/***********************************************************************/
/*                                                                     */
/*   svm_struct_main.c                                                 */
/*                                                                     */
/*   Command line interface to the alignment learning module of the    */
/*   Support Vector Machine.                                           */
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


/* the following enables you to use svm-learn out of C++ */
#ifdef __cplusplus
extern "C" {
#endif
#include "svm_light/svm_common.h"
#include "svm_light/svm_learn.h"
#ifdef __cplusplus
}
#endif
# include "svm_struct_learn.h"
# include "svm_struct_common.h"
# include "svm_struct_api.h"

#include <mpi.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <time.h>
#include "select_gpu.h"

char trainfile[200];           /* file with training examples */
char cadfile[200];             /* file with cad models */
char modelfile[200];           /* file for resulting classifier */
char testfile[200];            /* file for negative training examples */

void save_constraints(STRUCT_LEARN_PARM *sparm, STRUCTMODEL *sm);
void select_examples_part(char *trainfile, SAMPLE sample, CAD *cad, int cad_index, int part_index);
void select_examples_aspectlet(char *trainfile, CAD **cads, int cad_index);
void data_mining_hard_examples(char *trainfile, char *testfile, STRUCT_LEARN_PARM *sparm, STRUCTMODEL *sm);
int compare_energy(const void *a, const void *b);
void   read_input_parameters(int, char **, char *, char *, char *, long *, long *, STRUCT_LEARN_PARM *, LEARN_PARM *, KERNEL_PARM *, int *);
void   wait_any_key(void);
void   print_help(void);


int main (int argc, char* argv[])
{
  int o, i, j, cad_num;
  char filename[256];
  CAD **cads, *cad;
  SAMPLE sample, sample_part;  /* training sample */
  LEARN_PARM learn_parm;
  KERNEL_PARM kernel_parm;
  STRUCT_LEARN_PARM struct_parm;
  STRUCTMODEL structmodel;
  int alg_type;
  int rank;

  MPI_Init(&argc, &argv);
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);

  /* select GPU */
  select_gpu(rank);

  svm_struct_learn_api_init(argc,argv);

  read_input_parameters(argc, argv, trainfile, cadfile, testfile, &verbosity,
			&struct_verbosity, &struct_parm, &learn_parm,
			&kernel_parm, &alg_type);

  /* read cad models */
  cads = read_cad_model(cadfile, &cad_num, 0, &struct_parm);

  /* if cad_num == 1, train the final model */
  if(cad_num == 1)
  {
    printf("Train the hierarchical model\n");

    /* set the cad model for structmodel */
    structmodel.cad_num = 1;
    structmodel.cads = cads;

    printf("Read training samples\n");
    sample = read_struct_examples(trainfile, &struct_parm, &structmodel);
    printf("Read training samples done\n");

    if(struct_parm.is_root == 1 || struct_parm.is_aspectlet == 1)
    {
      /* first train weights for root parts */
      printf("Train root models\n");
      cad = cads[0];

      struct_parm.cad_index = 0;
      /* for each part */
      for(i = 0; i < cad->part_num; i++)
      {
        /* choose what parts to train */
        if((cad->roots[i] == -1 && struct_parm.is_root == 1) || (cad->roots[i] == 1 && struct_parm.is_aspectlet == 1))
        {
          printf("Train part %d\n", i);
          /* training iteration index */
          struct_parm.iter = 0;

          struct_parm.part_index = i;
          /* select training samples for part */
          if(rank == 0)
            select_examples_part(trainfile, sample, cad, 0, i);
          MPI_Barrier(MPI_COMM_WORLD);
          sample_part = read_struct_examples("temp_part.dat", &struct_parm, &structmodel);

          /* train the root template */
          struct_parm.deep = 0;

          /* Do the learning and return structmodel. */
          if(alg_type == 1)
            svm_learn_struct(sample_part, &struct_parm, &learn_parm, &kernel_parm, &structmodel);
          else if(alg_type == 2)
            svm_learn_struct_joint(sample_part, &struct_parm, &learn_parm, &kernel_parm, &structmodel, PRIMAL_ALG);
          else if(alg_type == 3)
            svm_learn_struct_joint(sample_part, &struct_parm, &learn_parm, &kernel_parm, &structmodel, DUAL_ALG);
          else if(alg_type == 4)
            svm_learn_struct_joint(sample_part, &struct_parm, &learn_parm, &kernel_parm, &structmodel, DUAL_CACHE_ALG);
          else
            exit(1);

          /* if aspectlet, train the subtree */
          if(cad->roots[i] == 1 && struct_parm.is_aspectlet == 1)
          {
            printf("Train subtree for part %d\n", i);
            struct_parm.deep = 1;
            struct_parm.iter++;

            /* select training samples for part */
            if(rank == 0)
              select_examples_part(trainfile, sample, cad, 0, i);
            MPI_Barrier(MPI_COMM_WORLD);
            free_struct_sample(sample_part);
            sample_part = read_struct_examples("temp_part.dat", &struct_parm, &structmodel);

            free_struct_model(structmodel);
            /* set the cad model for structmodel */
            structmodel.cad_num = 1;
            structmodel.cads = cads;

            if(alg_type == 1)
              svm_learn_struct(sample_part, &struct_parm, &learn_parm, &kernel_parm, &structmodel);
            else if(alg_type == 2)
              svm_learn_struct_joint(sample_part, &struct_parm, &learn_parm, &kernel_parm, &structmodel, PRIMAL_ALG);
            else if(alg_type == 3)
              svm_learn_struct_joint(sample_part, &struct_parm, &learn_parm, &kernel_parm, &structmodel, DUAL_ALG);
            else if(alg_type == 4)
              svm_learn_struct_joint(sample_part, &struct_parm, &learn_parm, &kernel_parm, &structmodel, DUAL_CACHE_ALG);
            else
              exit(1);
          }

          /* data mining hard examples */
          for(j = 0; j < struct_parm.hard_negative; j++)
          {
            /* increase iteration number */
            struct_parm.iter++;

            data_mining_hard_examples("temp_part.dat", testfile, &struct_parm, &structmodel);

            /* read the training examples */
            if(struct_verbosity>=1) 
            {
              printf("Reading training examples...");
              fflush(stdout);
            }
            free_struct_sample(sample_part);
            sample_part = read_struct_examples("temp.dat", &struct_parm, &structmodel);
            if(struct_verbosity>=1) 
            {
              printf("done\n");
              fflush(stdout);
            }
 
            /* Do the learning and return structmodel. */
            free_struct_model(structmodel);

            /* set the cad model for structmodel */
            structmodel.cad_num = 1;
            structmodel.cads = cads;

            if(alg_type == 1)
              svm_learn_struct(sample_part, &struct_parm, &learn_parm, &kernel_parm, &structmodel);
            else if(alg_type == 2)
              svm_learn_struct_joint(sample_part, &struct_parm, &learn_parm, &kernel_parm, &structmodel, PRIMAL_ALG);
            else if(alg_type == 3)
              svm_learn_struct_joint(sample_part, &struct_parm, &learn_parm, &kernel_parm, &structmodel, DUAL_ALG);
            else if(alg_type == 4)
              svm_learn_struct_joint(sample_part, &struct_parm, &learn_parm, &kernel_parm, &structmodel, DUAL_CACHE_ALG);
            else
              exit(1);
          }

          /* save constraints for training the full model */
          if(rank == 0)
            save_constraints(&struct_parm, &structmodel);
          MPI_Barrier(MPI_COMM_WORLD);

          free_struct_sample(sample_part);
          free_struct_model(structmodel);

          /* set the cad model for structmodel */
          structmodel.cad_num = 1;
          structmodel.cads = cads;
        }
      } /* end for each part */

      if(rank == 0)
      {
        write_constraints(struct_parm.cset, &struct_parm);
        free(struct_parm.cset.rhs); 
        for(i = 0; i < struct_parm.cset.m; i++) 
          free_example(struct_parm.cset.lhs[i], 1);
        free(struct_parm.cset.lhs);
      }
      MPI_Barrier(MPI_COMM_WORLD);
    }  /* end if is_root == 1 */

    /* train the full model */
    printf("Train the full model\n");
    struct_parm.iter = 0;
    struct_parm.cad_index = -1;
    struct_parm.part_index = -1;
    struct_parm.deep = 1;

    /* Do the learning and return structmodel. */
    if(alg_type == 1)
      svm_learn_struct(sample, &struct_parm, &learn_parm, &kernel_parm, &structmodel);
    else if(alg_type == 2)
      svm_learn_struct_joint(sample, &struct_parm, &learn_parm, &kernel_parm, &structmodel, PRIMAL_ALG);
    else if(alg_type == 3)
      svm_learn_struct_joint(sample, &struct_parm, &learn_parm, &kernel_parm, &structmodel, DUAL_ALG);
    else if(alg_type == 4)
      svm_learn_struct_joint(sample, &struct_parm, &learn_parm, &kernel_parm, &structmodel, DUAL_CACHE_ALG);
    else
      exit(1);
  
    /* data mining hard examples */
    while(struct_parm.hard_negative > 0)
    {
      /* increase iteration number */
      struct_parm.iter++;

      data_mining_hard_examples(trainfile, testfile, &struct_parm, &structmodel);

      /* read the training examples */
      if(struct_verbosity>=1) 
      {
        printf("Reading training examples...");
        fflush(stdout);
      }
      free_struct_sample(sample);
      sample = read_struct_examples("temp.dat", &struct_parm, &structmodel);
      if(struct_verbosity>=1) 
      {
        printf("done\n");
        fflush(stdout);
      }
 
      /* Do the learning and return structmodel. */
      free_struct_model(structmodel);

      /* set the cad model for structmodel */
      structmodel.cad_num = 1;
      structmodel.cads = cads;

      if(alg_type == 1)
        svm_learn_struct(sample, &struct_parm, &learn_parm, &kernel_parm, &structmodel);
      else if(alg_type == 2)
        svm_learn_struct_joint(sample, &struct_parm, &learn_parm, &kernel_parm, &structmodel, PRIMAL_ALG);
      else if(alg_type == 3)
        svm_learn_struct_joint(sample, &struct_parm, &learn_parm, &kernel_parm, &structmodel, DUAL_ALG);
      else if(alg_type == 4)
        svm_learn_struct_joint(sample, &struct_parm, &learn_parm, &kernel_parm, &structmodel, DUAL_CACHE_ALG);
      else
        exit(1);

      struct_parm.hard_negative--;
    }

    if(rank == 0)
    {
      if(struct_verbosity >= 1) 
      {
        printf("Writing learned model...");
        fflush(stdout);
      }
      sprintf(modelfile, "%s.mod", struct_parm.cls);
      write_struct_model(modelfile, &structmodel, &struct_parm);
      if(struct_verbosity>=1) 
      {
        printf("done\n");
        fflush(stdout);
      }
    }
    MPI_Barrier(MPI_COMM_WORLD);

    free_struct_sample(sample);
    free_struct_model(structmodel);
  }

  /* train weights for aspectlets */
  /* start with the second aspectlet, the first one is the whole object */
  for(o = 1; o < cad_num; o++)
  {
    printf("Train aspectlet %d\n", o);
    cad = cads[o];

    /* set the cad model for structmodel */
    structmodel.cad_num = 1;
    structmodel.cads = &cad;

    /* training iteration index */
    struct_parm.iter = 0;
    struct_parm.cad_index = -1;
    struct_parm.part_index = -1;
    struct_parm.deep = 1;

    /* select training samples for the aspectlet */
    if(rank == 0)
      select_examples_aspectlet(trainfile, cads, o);
    MPI_Barrier(MPI_COMM_WORLD);
    printf("Read training samples\n");
    sample_part = read_struct_examples("temp_part.dat", &struct_parm, &structmodel);
    printf("Read training samples done\n");

    /* Do the learning and return structmodel. */
    if(alg_type == 1)
      svm_learn_struct(sample_part, &struct_parm, &learn_parm, &kernel_parm, &structmodel);
    else if(alg_type == 2)
      svm_learn_struct_joint(sample_part, &struct_parm, &learn_parm, &kernel_parm, &structmodel, PRIMAL_ALG);
    else if(alg_type == 3)
      svm_learn_struct_joint(sample_part, &struct_parm, &learn_parm, &kernel_parm, &structmodel, DUAL_ALG);
    else if(alg_type == 4)
      svm_learn_struct_joint(sample_part, &struct_parm, &learn_parm, &kernel_parm, &structmodel, DUAL_CACHE_ALG);
    else
      exit(1);

    /* data mining hard examples */
    for(i = 0; i < struct_parm.hard_negative; i++)
    {
      /* increase iteration number */
      struct_parm.iter++;

      data_mining_hard_examples("temp_part.dat", testfile, &struct_parm, &structmodel);

      /* read the training examples */
      if(struct_verbosity>=1) 
      {
        printf("Reading training examples...");
        fflush(stdout);
      }
      free_struct_sample(sample_part);
      sample_part = read_struct_examples("temp.dat", &struct_parm, &structmodel);
      if(struct_verbosity>=1) 
      {
        printf("done\n");
        fflush(stdout);
      }
 
      /* Do the learning and return structmodel. */
      free_struct_model(structmodel);

      /* set the cad model for structmodel */
      structmodel.cad_num = 1;
      structmodel.cads = &cad;

      if(alg_type == 1)
        svm_learn_struct(sample_part, &struct_parm, &learn_parm, &kernel_parm, &structmodel);
      else if(alg_type == 2)
        svm_learn_struct_joint(sample_part, &struct_parm, &learn_parm, &kernel_parm, &structmodel, PRIMAL_ALG);
      else if(alg_type == 3)
        svm_learn_struct_joint(sample_part, &struct_parm, &learn_parm, &kernel_parm, &structmodel, DUAL_ALG);
      else if(alg_type == 4)
        svm_learn_struct_joint(sample_part, &struct_parm, &learn_parm, &kernel_parm, &structmodel, DUAL_CACHE_ALG);
      else
        exit(1);
    }

    if(rank == 0)
    {
      if(struct_verbosity>=1) 
      {
        printf("Writing learned model...");
        fflush(stdout);
      }
      sprintf(modelfile, "%s_cad%03d.mod", struct_parm.cls, o);
      write_struct_model(modelfile, &structmodel, &struct_parm);
      if(struct_verbosity>=1) 
      {
        printf("done\n");
        fflush(stdout);
      }
    }
    MPI_Barrier(MPI_COMM_WORLD);

    free_struct_sample(sample_part);
    free_struct_model(structmodel);
  }  /* end for each cad model */

  for(i = 0; i < cad_num; i++)
    destroy_cad(cads[i]);
  free(cads);

  svm_struct_learn_api_exit();

  MPI_Finalize();

  return 0;
}

/* save constraints in structmodel for training the full model in the future */
void save_constraints(STRUCT_LEARN_PARM *sparm, STRUCTMODEL *sm)
{
  int i, count;
  CONSTSET c;

  /* read the constraints */
  c = read_constraints(sparm->confile, sm);
  count = 0;
  for(i = 0; i < c.m; i++)
  {
    sparm->cset.lhs = (DOC**)realloc(sparm->cset.lhs, sizeof(DOC*)*(sparm->cset.m+1));
    sparm->cset.lhs[sparm->cset.m] = create_example(sparm->cset.m, 0, 1000000+sparm->cset.m, 1, create_svector(c.lhs[i]->fvec->words, "", 1.0));
    sparm->cset.rhs = (double*)realloc(sparm->cset.rhs, sizeof(double)*(sparm->cset.m+1));
    sparm->cset.rhs[sparm->cset.m] = c.rhs[i];
    sparm->cset.m++;
    count++;
  }

  /* clean up */
  free(c.rhs); 
  for(i = 0; i < c.m; i++) 
    free_example(c.lhs[i], 1);
  free(c.lhs);

  printf("%d constraints added, totally %d constraints\n", count, sparm->cset.m);
}

/* select training samples for part */
void select_examples_part(char *trainfile, SAMPLE sample, CAD *cad, int cad_index, int part_index)
{
  int i, n, count, count_pos, count_neg;
  int *flag;
  float cx, cy;
  char line[BUFFLE_SIZE];
  LABEL y;
  FILE *fp, *ftrain;

  n = sample.n;
  flag = (int*)my_malloc(sizeof(int)*n);
  memset(flag, 0, sizeof(int)*n);

  /* select positive samples */
  count_pos = 0;
  for(i = 0; i < n; i++)
  {
    y = sample.examples[i].y;
    if(y.object_label == 1 && y.cad_label == cad_index)
    {
      cx = y.part_label[part_index];
      cy = y.part_label[cad->part_num+part_index];
      if(cad->objects2d[y.view_label]->occluded[part_index] == 0 && cx != 0 && cy != 0)
      {
        flag[i] = 1;
        count_pos++;
      }
    }
  }

  /* randomly select negative samples */
  srand(time(NULL));
  count_neg = 0;
  for(i = 0; i < n; i++)
  {
    y = sample.examples[i].y;
    if(y.object_label == -1 && rand()%2 == 0)
    {
      flag[i] = 1;
      count_neg++;
      if(count_neg >= count_pos)
        break;
    }
  }

  /* write samples */
  printf("Writing data to temp_part.dat: %d positive samples, %d negative samples...\n", count_pos, count_neg);
  fp = fopen("temp_part.dat", "w");
  ftrain = fopen(trainfile, "r");
  if(ftrain == NULL)
  {
    printf("Cannot open file %s to read\n", trainfile);
    exit(1);
  }
  fscanf(ftrain, "%d\n", &n);

  fprintf(fp, "%d\n", count_pos+count_neg);
  count = 0;
  for(i = 0; i < n; i++)
  {
    fgets(line, BUFFLE_SIZE, ftrain);
    if(flag[i] == 1)
    {
      count++;
      fputs(line, fp);
      if(count >= count_pos + count_neg)
        break;
    }
  }
  fclose(fp);
  fclose(ftrain);
  printf("Done\n");
  free(flag);
}

/* select training samples for aspectlet */
void select_examples_aspectlet(char *trainfile, CAD **cads, int cad_index)
{
  int i, j, n, count, count_pos, part_num, view_label;
  int *flag;
  char *pname;
  float azimuth, elevation, distance;
  FILE *fp;
  LABEL y;
  EXAMPLE  example, *examples_aspectlet;

  /* find corresponding parts between two cads */
  part_num = cads[cad_index]->part_num;
  flag = (int*)my_malloc(sizeof(int)*part_num);
  for(i = 0; i < part_num; i++)
  {
    pname = cads[cad_index]->part_names[i];
    for(j = 0; j < cads[0]->part_num; j++)
    {
      if(strcmp(pname, cads[0]->part_names[j]) == 0)
      {
        flag[i] = j;
        break;
      }
    }
  }

  examples_aspectlet = NULL;

  /* select positive samples */
  /* open data file */
  if((fp = fopen(trainfile, "r")) == NULL)
  {
    printf("Can not open data file %s\n", trainfile);
    exit(1);
  }
  fscanf(fp, "%d", &n);

  count = 0;
  for(i = 0; i < n; i++)
  {
    /* read example */
    example = read_one_example(fp, cads);
    y = example.y;
    if(y.object_label == 1)
    {
      azimuth = cads[0]->objects2d[y.view_label]->azimuth;
      elevation = cads[0]->objects2d[y.view_label]->elevation;
      distance = cads[0]->objects2d[y.view_label]->distance;
      /* find the view label */
      view_label = -1;
      for(j = 0; j < cads[cad_index]->view_num; j++)
      {
        if(cads[cad_index]->objects2d[j]->azimuth == azimuth && cads[cad_index]->objects2d[j]->elevation == elevation && cads[cad_index]->objects2d[j]->distance == distance)
        {
          view_label = j;
          break;
        }
      }

      /* select the sample */
      if(view_label != -1)
      {
        examples_aspectlet = (EXAMPLE*)realloc(examples_aspectlet, sizeof(EXAMPLE)*(count+1));
        if(examples_aspectlet == NULL)
        {
          printf("out of memory\n");
          exit(1);
        }

        /* construct the sample */
        examples_aspectlet[count].y.object_label = y.object_label;
        examples_aspectlet[count].y.cad_label = y.cad_label;
        examples_aspectlet[count].y.view_label = view_label;
        examples_aspectlet[count].y.part_num = part_num;
        examples_aspectlet[count].y.part_label = (float*)my_malloc(sizeof(float)*2*part_num);
        /* get part labels */
        for(j = 0; j < part_num; j++)
        {
          if(cads[cad_index]->roots[j] != -1)  /* not root template */
          {
            examples_aspectlet[count].y.part_label[j] = y.part_label[flag[j]];
            examples_aspectlet[count].y.part_label[j+part_num] = y.part_label[flag[j]+cads[0]->part_num];
          }
          else /* is root template */
          {
            if(y.part_label[flag[j]] == 0 && y.part_label[flag[j]+cads[0]->part_num] == 0)  /* root not visible */
            {
              examples_aspectlet[count].y.part_label[j] = 0;
              examples_aspectlet[count].y.part_label[j+part_num] = 0;
            }
            else  /* compute root location and bounding box */
              compute_bbox_root(&(examples_aspectlet[count].y), j, cads[cad_index]);
          }
        }
        /* get occlusion label */
        examples_aspectlet[count].y.occlusion = (int*)my_malloc(sizeof(int)*part_num);
        for(j = 0; j < part_num; j++)
          examples_aspectlet[count].y.occlusion[j] = y.occlusion[flag[j]];
        examples_aspectlet[count].y.energy = 0;
        /* copy the image */
        examples_aspectlet[count].x.image = copy_cumatrix(example.x.image);
        count++;
      }  /* end if view_label != -1 */
      free_pattern(example.x);
      free_label(example.y);
    }  /* end if y.object_label == 1 */
    else
      break;
  }

  /* select negative samples */
  count_pos = count;
  for(; i < n; i++)
  {
    if(y.object_label == -1)
    {
      examples_aspectlet = (EXAMPLE*)realloc(examples_aspectlet, sizeof(EXAMPLE)*(count+1));
      if(examples_aspectlet == NULL)
      {
        printf("out of memory\n");
        exit(1);
      }

      examples_aspectlet[count].y.object_label = -1;
      examples_aspectlet[count].y.cad_label = -1;
      examples_aspectlet[count].y.view_label = -1;
      examples_aspectlet[count].y.part_num = -1;
      examples_aspectlet[count].y.part_label = NULL;
      examples_aspectlet[count].y.occlusion = NULL;
      for(j = 0; j < 4; j++)
        examples_aspectlet[count].y.bbox[j] = 0;
      examples_aspectlet[count].y.energy = 0;
      /* copy the image */
      examples_aspectlet[count].x.image = copy_cumatrix(example.x.image);
      count++;
      if(count >= 2*count_pos)
        break;
    }
    free_pattern(example.x);
    free_label(example.y);
    example = read_one_example(fp, cads);
    y = example.y;
  }

  free_pattern(example.x);
  free_label(example.y);
  free(flag);
  fclose(fp);

  /* write examples */
  printf("Writing data to temp_part.dat: %d positive samples, %d negative samples...\n", count_pos, count-count_pos);
  fp = fopen("temp_part.dat", "w");
  fprintf(fp, "%d\n", count);
  for(i = 0; i < count; i++)
  {
    /* write object label */
    fprintf(fp, "%d ", examples_aspectlet[i].y.object_label);
    if(examples_aspectlet[i].y.object_label == 1)
    {
      /* write cad label */
      fprintf(fp, "%d ", examples_aspectlet[i].y.cad_label);
      /* write view label */
      fprintf(fp, "%d ", examples_aspectlet[i].y.view_label);
      /* write part label */
      for(j = 0; j < 2*part_num; j++)
        fprintf(fp, "%f ", examples_aspectlet[i].y.part_label[j]);
      /* write occlusion label */
      for(j = 0; j < part_num; j++)
        fprintf(fp, "%d ", examples_aspectlet[i].y.occlusion[j]);
      /* write bounding box */
      for(j = 0; j < 4; j++)
        fprintf(fp, "%f ", examples_aspectlet[i].y.bbox[j]);
    }
    /* write image size */
    fprintf(fp, "%d ", examples_aspectlet[i].x.image.dims_num);
    for(j = 0; j < examples_aspectlet[i].x.image.dims_num; j++)
      fprintf(fp, "%d ", examples_aspectlet[i].x.image.dims[j]);
    /* write image pixel */
    for(j = 0; j < examples_aspectlet[i].x.image.length; j++)
      fprintf(fp, "%u ", (unsigned int)examples_aspectlet[i].x.image.data[j]);
    fprintf(fp, "\n");
  }
  fclose(fp);
  printf("Done\n");

  /* clean up */
  for(i = 0; i < count; i++)
  {
    free_pattern(examples_aspectlet[i].x);
    free_label(examples_aspectlet[i].y);
  }
  free(examples_aspectlet);
}

/* data mining hard negative samples */
void data_mining_hard_examples(char *trainfile, char *testfile, STRUCT_LEARN_PARM *sparm, STRUCTMODEL *sm)
{
  int i, j, n, ntrain, ntest, num, object_label, count, count_pos, count_neg;
  char line[BUFFLE_SIZE];
  double *energy, *energies;
  SAMPLE testsample;
  LABEL *y = NULL;
  ENERGYINDEX *energy_index;
  FILE *fp, *ftrain, *ftest;

  /* MPI process */
  int rank;
  int procs_num;
  int start, end, block_size;

  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  MPI_Comm_size(MPI_COMM_WORLD, &procs_num);

  /* read negative examples */
  printf("Reading negative samples for data mining...");
  testsample = read_struct_examples(testfile, sparm, sm);
  printf("Done\n");

  n = testsample.n;
  block_size = (n+procs_num-1) / procs_num;
  start = rank*block_size;
  end = start+block_size-1 > n-1 ? n-1 : start+block_size-1;

  energy = (double*)my_malloc(sizeof(double)*n);
  energies = (double*)my_malloc(sizeof(double)*n);
  memset(energy, 0, sizeof(double)*n);
  memset(energies, 0, sizeof(double)*n);
  for(i = start; i <= end; i++) 
  {
    y = classify_struct_example(testsample.examples[i].x, &num, 0, sm, sparm);
    count = 0;
    for(j = 0; j < num; j++)
    {
      if(y[j].object_label)
        count++;
    }
    printf("Data mining hard negative example %d/%d: %d objects detected\n", i+1, n, count);
    if(count == 0)
      energy[i] = -sparm->loss_value;
    else
    {
      for(j = 0; j < num; j++)
      {
        if(y[j].object_label)
        {
          energy[i] = y[j].energy;
          break;
        }
      }
    }
    /* free labels */
    for(j = 0; j < num; j++)
      free_label(y[j]);
    free(y);
  }
  MPI_Allreduce(energy, energies, n, MPI_DOUBLE, MPI_SUM, MPI_COMM_WORLD);

  if(rank == 0)
  {
    energy_index = (ENERGYINDEX*)my_malloc(sizeof(ENERGYINDEX)*n);
    for(i = 0; i < n; i++)
    {
      energy_index[i].index = i;
      energy_index[i].energy = energies[i];
    }
    /* sort energies */
    qsort(energy_index, n, sizeof(ENERGYINDEX), compare_energy);

    /* construct new training data and write to file */
    printf("Writing data to temp.dat...\n");
    fp = fopen("temp.dat", "w");
    ftrain = fopen(trainfile, "r");
    if(ftrain == NULL)
    {
      printf("Cannot open file %s to read\n", trainfile);
      exit(1);
    }
    ftest = fopen(testfile, "r");
    if(ftest == NULL)
    {
      printf("Cannot open file %s to read\n", testfile);
      exit(1);
    }

    /* positive samples from training data file */
    fscanf(ftrain, "%d\n", &ntrain);
    count_pos = ntrain/2;
    fscanf(ftest, "%d\n", &ntest);
    if(ntest < ntrain/2)
      n = ntest + ntrain/2;
    else
      n = ntrain;
    count_neg = n - count_pos;

    fprintf(fp, "%d\n", n);
    for(i = 0; i < ntrain; i++)
    {
      fgets(line, BUFFLE_SIZE, ftrain);
      sscanf(line, "%d", &object_label);
      if(object_label == 1)
        fputs(line, fp);
      else
        break;
    }
    fclose(ftrain);

    /* negative samples from hard negative examples */
    count = 0;
    for(i = 0; i < ntest; i++)
    {
      fgets(line, BUFFLE_SIZE, ftest);
      for(j = 0; j < count_neg; j++)
      {
        if(i == energy_index[j].index)
        {
          count++;
          fputs(line, fp);
          break;
        }
      }
      if(count >= count_neg)
        break;
    }
    fclose(ftest);
    fclose(fp);
    free(energy_index);
    printf("Done\n");
  }
  MPI_Barrier(MPI_COMM_WORLD);

  free(energy);
  free(energies);
  free_struct_sample(testsample);
}

int compare_energy(const void *a, const void *b)
{
  double diff;
  diff =  ((ENERGYINDEX*)a)->energy - ((ENERGYINDEX*)b)->energy;
  if(diff < 0)
    return 1;
  else if(diff > 0)
    return -1;
  else
    return 0;
}

/*---------------------------------------------------------------------------*/

void read_input_parameters(int argc,char *argv[],char *trainfile,
			   char *cadfile, char *testfile,
			   long *verbosity,long *struct_verbosity, 
			   STRUCT_LEARN_PARM *struct_parm,
			   LEARN_PARM *learn_parm, KERNEL_PARM *kernel_parm,
			   int *alg_type)
{
  int len;
  long i;
  char type[100];
  
  /* set default */
  (*alg_type)=DEFAULT_ALG_TYPE;
  struct_parm->C=-0.01;
  struct_parm->slack_norm=1;
  struct_parm->epsilon=DEFAULT_EPS;
  struct_parm->custom_argc=0;
  struct_parm->loss_function=DEFAULT_LOSS_FCT;
  struct_parm->loss_type=DEFAULT_RESCALING;
  struct_parm->newconstretrain=100;
  struct_parm->ccache_size=5;

  /* loss parameters */
  struct_parm->object_loss = 10;
  struct_parm->cad_loss = 1;
  struct_parm->view_loss = 1;
  struct_parm->location_loss = 0;
  struct_parm->loss_value = 100;
  struct_parm->wpair = 1;
  struct_parm->hard_negative = 0;
  struct_parm->is_root = 0;
  struct_parm->is_aspectlet = 0;

  struct_parm->cset.lhs = NULL;
  struct_parm->cset.rhs = NULL;
  struct_parm->cset.m = 0;

  strcpy (modelfile, "svm_struct_model");
  strcpy (testfile, "");
  strcpy (learn_parm->predfile, "trans_predictions");
  strcpy (learn_parm->alphafile, "");
  (*verbosity)=0;/*verbosity for svm_light*/
  (*struct_verbosity)=1; /*verbosity for struct learning portion*/
  learn_parm->biased_hyperplane=1;
  learn_parm->remove_inconsistent=0;
  learn_parm->skip_final_opt_check=0;
  learn_parm->svm_maxqpsize=10;
  learn_parm->svm_newvarsinqp=0;
  learn_parm->svm_iter_to_shrink=-9999;
  learn_parm->maxiter=100000;
  learn_parm->kernel_cache_size=40;
  learn_parm->svm_c=99999999;  /* overridden by struct_parm->C */
  learn_parm->eps=0.001;       /* overridden by struct_parm->epsilon */
  learn_parm->transduction_posratio=-1.0;
  learn_parm->svm_costratio=1.0;
  learn_parm->svm_costratio_unlab=1.0;
  learn_parm->svm_unlabbound=1E-5;
  learn_parm->epsilon_crit=0.001;
  learn_parm->epsilon_a=1E-10;  /* changed from 1e-15 */
  learn_parm->compute_loo=0;
  learn_parm->rho=1.0;
  learn_parm->xa_depth=0;
  kernel_parm->kernel_type=0;
  kernel_parm->poly_degree=3;
  kernel_parm->rbf_gamma=1.0;
  kernel_parm->coef_lin=1;
  kernel_parm->coef_const=1;
  strcpy(kernel_parm->custom,"empty");
  strcpy(type,"c");

  for(i=1;(i<argc) && ((argv[i])[0] == '-');i++) {
    switch ((argv[i])[1]) 
      { 
      case '?': print_help(); exit(0);
      case 'a': i++; strcpy(learn_parm->alphafile,argv[i]); break;
      case 'c': i++; struct_parm->C=atof(argv[i]); break;
      case 'p': i++; struct_parm->slack_norm=atol(argv[i]); break;
      case 'e': i++; struct_parm->epsilon=atof(argv[i]); break;
      case 'k': i++; struct_parm->newconstretrain=atol(argv[i]); break;
      case 'h': i++; learn_parm->svm_iter_to_shrink=atol(argv[i]); break;
      case '#': i++; learn_parm->maxiter=atol(argv[i]); break;
      case 'm': i++; learn_parm->kernel_cache_size=atol(argv[i]); break;
      case 'w': i++; (*alg_type)=atol(argv[i]); break;
      case 'o': i++; struct_parm->loss_type=atol(argv[i]); break;
      case 'n': i++; learn_parm->svm_newvarsinqp=atol(argv[i]); break;
      case 'q': i++; learn_parm->svm_maxqpsize=atol(argv[i]); break;
      case 'l': i++; struct_parm->loss_function=atol(argv[i]); break;
      case 'f': i++; struct_parm->ccache_size=atol(argv[i]); break;
      case 't': i++; kernel_parm->kernel_type=atol(argv[i]); break;
      case 'd': i++; kernel_parm->poly_degree=atol(argv[i]); break;
      case 'g': i++; kernel_parm->rbf_gamma=atof(argv[i]); break;
      case 's': i++; kernel_parm->coef_lin=atof(argv[i]); break;
      case 'r': i++; kernel_parm->coef_const=atof(argv[i]); break;
      case 'u': i++; strcpy(kernel_parm->custom,argv[i]); break;
      case '-': strcpy(struct_parm->custom_argv[struct_parm->custom_argc++],argv[i]);i++; strcpy(struct_parm->custom_argv[struct_parm->custom_argc++],argv[i]);break; 
      case 'v': i++; (*struct_verbosity)=atol(argv[i]); break;
      case 'y': i++; (*verbosity)=atol(argv[i]); break;
      default: printf("\nUnrecognized option %s!\n\n",argv[i]);
	       print_help();
	       exit(0);
      }
  }
  if(i >= argc) 
  {
    printf("\nNot enough input parameters!\n\n");
    wait_any_key();
    print_help();
    exit(0);
  }
  strcpy (trainfile, argv[i]);
  i++;
  strcpy (cadfile, argv[i]);
  if(i+1 < argc)
  {
    i++;
    strcpy(testfile, argv[i]);
  }

  /* construct class name */
  len = strlen(trainfile);
  strncpy(struct_parm->cls, trainfile, len-4);
  struct_parm->cls[len-4] = '\0';

  if(learn_parm->svm_iter_to_shrink == -9999) {
    learn_parm->svm_iter_to_shrink=100;
  }

  if((learn_parm->skip_final_opt_check) 
     && (kernel_parm->kernel_type == LINEAR)) {
    printf("\nIt does not make sense to skip the final optimality check for linear kernels.\n\n");
    learn_parm->skip_final_opt_check=0;
  }    
  if((learn_parm->skip_final_opt_check) 
     && (learn_parm->remove_inconsistent)) {
    printf("\nIt is necessary to do the final optimality check when removing inconsistent \nexamples.\n");
    wait_any_key();
    print_help();
    exit(0);
  }    
  if((learn_parm->svm_maxqpsize<2)) {
    printf("\nMaximum size of QP-subproblems not in valid range: %ld [2..]\n",learn_parm->svm_maxqpsize); 
    wait_any_key();
    print_help();
    exit(0);
  }
  if((learn_parm->svm_maxqpsize<learn_parm->svm_newvarsinqp)) {
    printf("\nMaximum size of QP-subproblems [%ld] must be larger than the number of\n",learn_parm->svm_maxqpsize); 
    printf("new variables [%ld] entering the working set in each iteration.\n",learn_parm->svm_newvarsinqp); 
    wait_any_key();
    print_help();
    exit(0);
  }
  if(learn_parm->svm_iter_to_shrink<1) {
    printf("\nMaximum number of iterations for shrinking not in valid range: %ld [1,..]\n",learn_parm->svm_iter_to_shrink);
    wait_any_key();
    print_help();
    exit(0);
  }
  if(struct_parm->C<0) {
    printf("\nYou have to specify a value for the parameter '-c' (C>0)!\n\n");
    wait_any_key();
    print_help();
    exit(0);
  }
  if(((*alg_type) < 1) || ((*alg_type) > 4)) {
    printf("\nAlgorithm type must be either '1', '2', '3', or '4'!\n\n");
    wait_any_key();
    print_help();
    exit(0);
  }
  if(learn_parm->transduction_posratio>1) {
    printf("\nThe fraction of unlabeled examples to classify as positives must\n");
    printf("be less than 1.0 !!!\n\n");
    wait_any_key();
    print_help();
    exit(0);
  }
  if(learn_parm->svm_costratio<=0) {
    printf("\nThe COSTRATIO parameter must be greater than zero!\n\n");
    wait_any_key();
    print_help();
    exit(0);
  }
  if(struct_parm->epsilon<=0) {
    printf("\nThe epsilon parameter must be greater than zero!\n\n");
    wait_any_key();
    print_help();
    exit(0);
  }
  if((struct_parm->slack_norm<1) || (struct_parm->slack_norm>2)) {
    printf("\nThe norm of the slacks must be either 1 (L1-norm) or 2 (L2-norm)!\n\n");
    wait_any_key();
    print_help();
    exit(0);
  }
  if((struct_parm->loss_type != SLACK_RESCALING) 
     && (struct_parm->loss_type != MARGIN_RESCALING)) {
    printf("\nThe loss type must be either 1 (slack rescaling) or 2 (margin rescaling)!\n\n");
    wait_any_key();
    print_help();
    exit(0);
  }
  if(learn_parm->rho<0) {
    printf("\nThe parameter rho for xi/alpha-estimates and leave-one-out pruning must\n");
    printf("be greater than zero (typically 1.0 or 2.0, see T. Joachims, Estimating the\n");
    printf("Generalization Performance of an SVM Efficiently, ICML, 2000.)!\n\n");
    wait_any_key();
    print_help();
    exit(0);
  }
  if((learn_parm->xa_depth<0) || (learn_parm->xa_depth>100)) {
    printf("\nThe parameter depth for ext. xi/alpha-estimates must be in [0..100] (zero\n");
    printf("for switching to the conventional xa/estimates described in T. Joachims,\n");
    printf("Estimating the Generalization Performance of an SVM Efficiently, ICML, 2000.)\n");
    wait_any_key();
    print_help();
    exit(0);
  }

  parse_struct_parameters(struct_parm);
}

void wait_any_key()
{
  printf("\n(more)\n");
  (void)getc(stdin);
}

void print_help()
{
  printf("\nSVM-struct learning module: %s, %s, %s\n",INST_NAME,INST_VERSION,INST_VERSION_DATE);
  printf("   includes SVM-struct %s for learning complex outputs, %s\n",STRUCT_VERSION,STRUCT_VERSION_DATE);
  printf("   includes SVM-light %s quadratic optimizer, %s\n",VERSION,VERSION_DATE);
  copyright_notice();
  printf("   usage: svm_struct_learn [options] example_file model_file\n\n");
  printf("Arguments:\n");
  printf("         example_file-> file with training data\n");
  printf("         model_file  -> file to store learned decision rule in\n");

  printf("General options:\n");
  printf("         -?          -> this help\n");
  printf("         -v [0..3]   -> verbosity level (default 1)\n");
  printf("         -y [0..3]   -> verbosity level for svm_light (default 0)\n");
  printf("Learning options:\n");
  printf("         -c float    -> C: trade-off between training error\n");
  printf("                        and margin (default 0.01)\n");
  printf("         -p [1,2]    -> L-norm to use for slack variables. Use 1 for L1-norm,\n");
  printf("                        use 2 for squared slacks. (default 1)\n");
  printf("         -o [1,2]    -> Rescaling method to use for loss.\n");
  printf("                        1: slack rescaling\n");
  printf("                        2: margin rescaling\n");
  printf("                        (default %d)\n",DEFAULT_RESCALING);
  printf("         -l [0..]    -> Loss function to use.\n");
  printf("                        0: zero/one loss\n");
  printf("                        (default %d)\n",DEFAULT_LOSS_FCT);
  printf("Kernel options:\n");
  printf("         -t int      -> type of kernel function:\n");
  printf("                        0: linear (default)\n");
  printf("                        1: polynomial (s a*b+c)^d\n");
  printf("                        2: radial basis function exp(-gamma ||a-b||^2)\n");
  printf("                        3: sigmoid tanh(s a*b + c)\n");
  printf("                        4: user defined kernel from kernel.h\n");
  printf("         -d int      -> parameter d in polynomial kernel\n");
  printf("         -g float    -> parameter gamma in rbf kernel\n");
  printf("         -s float    -> parameter s in sigmoid/poly kernel\n");
  printf("         -r float    -> parameter c in sigmoid/poly kernel\n");
  printf("         -u string   -> parameter of user defined kernel\n");
  printf("Optimization options (see [2][3]):\n");
  printf("         -w [1,2,3,4]-> choice of structural learning algorithm (default %d):\n",(int)DEFAULT_ALG_TYPE);
  printf("                        1: algorithm described in [2]\n");
  printf("                        2: joint constraint algorithm (primal) [to be published]\n");
  printf("                        3: joint constraint algorithm (dual) [to be published]\n");
  printf("                        4: joint constraint algorithm (dual) with constr. cache\n");
  printf("         -q [2..]    -> maximum size of QP-subproblems (default 10)\n");
  printf("         -n [2..q]   -> number of new variables entering the working set\n");
  printf("                        in each iteration (default n = q). Set n<q to prevent\n");
  printf("                        zig-zagging.\n");
  printf("         -m [5..]    -> size of cache for kernel evaluations in MB (default 40)\n");
  printf("                        (used only for -w 1 with kernels)\n");
  printf("         -f [5..]    -> number of constraints to cache for each example\n");
  printf("                        (default 5) (used with -w 4)\n");
  printf("         -e float    -> eps: Allow that error for termination criterion\n");
  printf("                        (default %f)\n",DEFAULT_EPS);
  printf("         -h [5..]    -> number of iterations a variable needs to be\n"); 
  printf("                        optimal before considered for shrinking (default 100)\n");
  printf("         -k [1..]    -> number of new constraints to accumulate before\n"); 
  printf("                        recomputing the QP solution (default 100) (-w 1 only)\n");
  printf("         -# int      -> terminate QP subproblem optimization, if no progress\n");
  printf("                        after this number of iterations. (default 100000)\n");
  printf("Output options:\n");
  printf("         -a string   -> write all alphas to this file after learning\n");
  printf("                        (in the same order as in the training set)\n");
  printf("Structure learning options:\n");
  print_struct_help();
  wait_any_key();

  printf("\nMore details in:\n");
  printf("[1] T. Joachims, Learning to Align Sequences: A Maximum Margin Aproach.\n");
  printf("    Technical Report, September, 2003.\n");
  printf("[2] I. Tsochantaridis, T. Joachims, T. Hofmann, and Y. Altun, Large Margin\n");
  printf("    Methods for Structured and Interdependent Output Variables, Journal\n");
  printf("    of Machine Learning Research (JMLR), Vol. 6(Sep):1453-1484, 2005.\n");
  printf("[3] T. Joachims, Making Large-Scale SVM Learning Practical. Advances in\n");
  printf("    Kernel Methods - Support Vector Learning, B. Sch\F6lkopf and C. Burges and\n");
  printf("    A. Smola (ed.), MIT Press, 1999.\n");
  printf("[4] T. Joachims, Learning to Classify Text Using Support Vector\n");
  printf("    Machines: Methods, Theory, and Algorithms. Dissertation, Kluwer,\n");
  printf("    2002.\n\n");
}
