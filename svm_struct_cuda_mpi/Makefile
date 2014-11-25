# Makefile for empty SVM-struct API, 03.10.06

#Call 'make' using the following line to make CYGWIN produce stand-alone Windows executables
#		make 'SFLAGS=-mno-cygwin'

#Use the following to compile under unix or cygwin
#CC = gcc
#LD = gcc

#CC = attolcc -mempro -perfpro -block -proc -- gcc
#LD = attolcc -mempro -perfpro -block -proc -- gcc
CFLAGS =   $(SFLAGS) -O3 -fomit-frame-pointer -ffast-math -Wall 
LDFLAGS =  $(SFLAGS) -O3 -lm -Wall
#CFLAGS =  $(SFLAGS) -g -Wall
#LDFLAGS = $(SFLAGS) -g -lm
#CFLAGS =  $(SFLAGS) -pg -Wall
#LDFLAGS = $(SFLAGS) -pg -lm -Wall 

all: svm_empty_learn_hideo svm_empty_classify svm_empty_classify_matlab

.PHONY: clean_svm clean
clean_svm: svm_light_clean
	rm -f *.o *.tcov *.d core gmon.out *.stackdump 

#-----------------------#
#----   SVM-light   ----#
#-----------------------#
svm_light_hideo_noexe: 
	cd svm_light; make svm_learn_hideo_noexe

svm_light_loqo_noexe: 
	cd svm_light; make svm_learn_loqo_noexe

svm_light_clean: 
	cd svm_light; make clean

#----------------------#
#----     CUDA     ----#
#----------------------#
# Add source files here
EXECUTABLE := 
# CUDA source files ( compiled with cudacc )
CUFILES := matrix.cu hog.cu rectify.cu convolve.cu message.cu select_gpu.cu
# CUDA dependency files
CU_DEPS := matrix.h hog.h rectify.h convolve.h message.h select_gpu.h
# C/C++ source files ( compiled with gcc / c++)
CCFILES := \

#set directory for common.mk
CUDA_SDK_PATH ?= /n/ludington/v/yuxiang/NVIDIA_GPU_Computing_SDK/C/common
ROOTDIR := $(CUDA_SDK_PATH)
ROOTBINDIR := bin
ROOTOBJDIR := obj
verbose := 1
include common.mk

cuda: makedirectories $(OBJS) $(CUBINS) $(PTXBINS) Makefile

#-------------------------#
#----  SVM empty API  ----#
#-------------------------#

svm_empty_classify_matlab: cuda svm_light_hideo_noexe svm_struct_api.o svm_struct_classify_matlab.o svm_struct_common.o svm_struct_main.o tree.o cad.o distance_transform.o non_maximum_suppression
	mex -cxx svm_struct_api.o svm_struct_classify_matlab.o svm_light/svm_common.o svm_struct_common.o tree.o cad.o distance_transform.o -o svm_empty_classify_matlab $(OBJS) $(LIB)

non_maximum_suppression: non_maximum_suppression.c
	mex non_maximum_suppression.c

svm_empty_classify: cuda svm_light_hideo_noexe svm_struct_api.o svm_struct_classify.o svm_struct_common.o svm_struct_main.o tree.o cad.o distance_transform.o
	$(LINK) $(LDFLAGS) svm_struct_api.o svm_struct_classify.o svm_light/svm_common.o svm_struct_common.o tree.o cad.o distance_transform.o -o svm_empty_classify $(OBJS) $(LIB)

svm_empty_learn_loqo: cuda svm_light_loqo_noexe svm_struct_api.o svm_struct_learn.o svm_struct_common.o svm_struct_main.o tree.o cad.o distance_transform.o
	$(LINK) $(LDFLAGS) svm_struct_learn.o svm_struct_api.o svm_light/svm_loqo.o svm_light/pr_loqo/pr_loqo.o svm_light/svm_learn.o svm_light/svm_common.o svm_struct_common.o svm_struct_main.o tree.o cad.o distance_transform.o -o svm_empty_learn $(OBJS) $(LIB)

svm_empty_learn_hideo: cuda svm_light_hideo_noexe svm_struct_api.o  svm_struct_learn.o svm_struct_common.o svm_struct_main.o tree.o cad.o distance_transform.o
	$(LINK) $(LDFLAGS) svm_struct_learn.o svm_struct_api.o svm_light/svm_hideo.o svm_light/svm_learn.o svm_light/svm_common.o svm_struct_common.o svm_struct_main.o tree.o cad.o distance_transform.o -o svm_empty_learn $(OBJS) $(LIB)

svm_struct_api.o: svm_struct_api.c svm_struct_api.h svm_struct_api_types.h svm_struct_common.h
	$(CC) -c $(CFLAGS) svm_struct_api.c -o svm_struct_api.o

svm_struct_common.o: svm_struct_common.c svm_struct_common.h svm_struct_api_types.h
	$(CC) -c $(CFLAGS) svm_struct_common.c -o svm_struct_common.o

svm_struct_learn.o: svm_struct_learn.c svm_light/svm_learn.h svm_struct_common.h svm_struct_api.h svm_struct_api_types.h
	$(CC) -c $(CFLAGS) svm_struct_learn.c -o svm_struct_learn.o

svm_struct_main.o: svm_struct_main.c svm_light/svm_common.h svm_light/svm_learn.h svm_struct_learn.h svm_struct_common.h svm_struct_api.h svm_struct_api_types.h
	$(CC) -c $(CFLAGS) -o svm_struct_main.o -c svm_struct_main.c

svm_struct_classify_matlab.o: svm_struct_classify_matlab.c svm_struct_common.h svm_struct_api_types.h svm_struct_api.h svm_light/svm_common.h 
	mex -c svm_struct_classify_matlab.c -o svm_struct_classify_matlab.o

svm_struct_classify.o: svm_struct_classify.c svm_struct_common.h svm_struct_api_types.h svm_struct_api.h svm_light/svm_common.h 
	$(CC) -c $(CFLAGS) svm_struct_classify.c -o svm_struct_classify.o

tree.o: tree.c tree.h
	$(CC) -c $(CFLAGS) tree.c -o tree.o

cad.o: cad.c cad.h
	$(CC) -c $(CFLAGS) cad.c -o cad.o

distance_transform.o: distance_transform.c distance_transform.h
	$(CC) -c $(CFLAGS) distance_transform.c -o distance_transform.o
