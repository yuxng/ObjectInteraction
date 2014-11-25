/* A tree data structure for belief propagation algrithm
   Author: Yu Xiang
   Date: 03/23/2011
*/

#include <stdio.h>
#include <stdlib.h>
#include "tree.h"

/* construct tree from adjcency matrix */
TREENODE* construct_tree(int node_num, int root_index, int **graph)
{
  int i;
  TREENODE *root, *nodes;

  /* allocate memory */
  nodes = (TREENODE*)malloc(sizeof(TREENODE)*node_num);
  if(nodes == NULL)
  {
    printf("Out of memory");
    return NULL;
  }

  /* initialization */
  for(i = 0; i < node_num; i++)
  {
    nodes[i].index = i;
    nodes[i].dims[0] = 0;
    nodes[i].dims[1] = 0;
    nodes[i].potential = NULL;
    nodes[i].message_num = 0;
    nodes[i].messages = NULL;
    nodes[i].locations = NULL;
    nodes[i].child_num = 0;
    nodes[i].children = NULL;
    nodes[i].parent_num = 0;
    nodes[i].parent = NULL;
  }

  /* set root */
  root = nodes + root_index;
  /* construct tree */
  construct(root, NULL, nodes, node_num, graph);

  initialize_message(nodes, node_num);

  return nodes;
}

void construct(TREENODE *node, TREENODE *parent, TREENODE *nodes, int node_num, int **graph)
{
  int i;
  TREENODE *child;

  if(parent != NULL)
  {
    /* set parent */
    node->parent = (TREENODE**)realloc(node->parent, sizeof(TREENODE*)*(node->parent_num+1));
    if(node->parent == NULL)
    {
      printf("Out of memory");
      return;
    }
    node->parent[node->parent_num] = parent;
    node->parent_num++;

    /* set child */
    parent->children = (TREENODE**)realloc(parent->children, sizeof(TREENODE*)*(parent->child_num+1));
    if(parent->children == NULL)
    {
      printf("Out of memory");
      return;
    }
    parent->children[parent->child_num] = node;
    parent->child_num++;
  }

  for(i = 0; i < node_num; i++)
  {
    if(graph[node->index][i] == 1)
    {
      child = nodes + i;
      construct(child, node, nodes, node_num, graph);
    }
  }
}

void initialize_message(TREENODE *nodes, int node_num)
{
  int i, j;

  for(i = 0; i < node_num; i++)
  {
    if(nodes[i].parent_num == 0 && nodes[i].child_num == 0)
      continue;
    nodes[i].message_num = nodes[i].child_num + 1;
    nodes[i].messages = (float**)malloc(sizeof(float*)*nodes[i].message_num);
    nodes[i].locations = (float**)malloc(sizeof(float*)*nodes[i].message_num);
    if(nodes[i].messages == NULL || nodes[i].locations == NULL)
    {
      printf("Out of memory");
      return;
    }
    for(j = 0; j < nodes[i].message_num; j++)
    {
      nodes[i].messages[j] = NULL;
      nodes[i].locations[j] = NULL;
    }
  }
}

void print_tree(TREENODE *node)
{
  int i;
  printf("node %d: ", node->index+1);

  printf("parent: ");
  for(i = 0; i < node->parent_num; i++)
    printf("%d ", node->parent[i]->index+1);

  printf("children: ");
  for(i = 0; i < node->child_num; i++)
    printf("%d ", node->children[i]->index+1);

  printf("unary dims: %d %d", node->dims[0], node->dims[1]);
  printf("\n");

  for(i = 0; i < node->child_num; i++)
    print_tree(node->children[i]);
}

void free_tree(TREENODE *nodes, int node_num)
{
  int i, j;

  for(i = 0; i < node_num; i++)
  {
    for(j = 0; j < nodes[i].message_num; j++)
    {
      if(nodes[i].messages[j] != NULL)
        free(nodes[i].messages[j]);
      if(nodes[i].locations[j] != NULL)
        free(nodes[i].locations[j]);
    }
    if(nodes[i].messages != NULL)
      free(nodes[i].messages);
    if(nodes[i].locations != NULL)
      free(nodes[i].locations);
    if(nodes[i].parent != NULL)
      free(nodes[i].parent);
    if(nodes[i].children != NULL)
      free(nodes[i].children);
  }
  free(nodes);
}

void free_message(TREENODE *nodes, int node_num)
{
  int i, j;

  for(i = 0; i < node_num; i++)
  {
    for(j = 0; j < nodes[i].message_num; j++)
    {
      if(nodes[i].messages[j] != NULL)
        free(nodes[i].messages[j]);
      nodes[i].messages[j] = NULL;
      if(nodes[i].locations[j] != NULL)
        free(nodes[i].locations[j]);
      nodes[i].locations[j] = NULL;
    }
  }
}

void set_potential(TREENODE *node, int index, float *potential, int *dims)
{
  int i;

  if(node->index == index)
  {
    node->dims[0] = dims[0];
    node->dims[1] = dims[1];
    node->potential = potential;
  }
  else
  {
    for(i = 0; i < node->child_num; i++)
      set_potential(node->children[i], index, potential, dims);
  }
}

int isin_tree(TREENODE *node, int index)
{
  int i, val;

  if(node->index == index)
    val = 1;
  else
  {
    val = 0;
    for(i = 0; i < node->child_num; i++)
    {
      if(isin_tree(node->children[i], index) == 1)
      {
        val = 1;
        break;
      }
    }
  }

  return val;
}

/* test rountine */
/*
int main()
{
  int i, j, N = 6, root_index = 0;
  TREENODE *root, *nodes;
  int **graph;

  graph = (int**)malloc(sizeof(int*)*N);
  for(i = 0; i < N; i++)
  {
    graph[i] = (int*)malloc(sizeof(int)*N);
    for(j = 0; j < N; j++)
      graph[i][j] = 0;
  }
  graph[0][1] = graph[0][2] = 1;
  graph[1][3] = graph[1][4] = graph[1][5] = 1;
  graph[2][3] = graph[2][5] = 1;
 
  nodes = construct_tree(N, root_index, graph);
  root = nodes + root_index;
  print_tree(root);

  for(i = 0; i < N; i++)
    printf("node %d is (not) in tree rooted at node %d: %d\n", i, 2, isin_tree(nodes + 2, i));

  for(i = 0; i < N; i++)
    free(graph[i]);
  free(graph);
  free_tree(nodes, N);
  return 0;
}
*/
