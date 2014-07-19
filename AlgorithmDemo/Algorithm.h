//
//  Algorithm.h
//  PrefixMatchDemo
//
//  Created by Bai Haoquan on 13-9-30.
//  Copyright (c) 2013年 Bai Haoquan. All rights reserved.
//

#ifndef PrefixMatchDemo_Algorithm_h
#define PrefixMatchDemo_Algorithm_h
#include <string>
#include <iostream>
#include <vector>

typedef enum {
    Asc = 0,
    Desc = 1,
} SortType;

typedef enum {
    NA,
    Up,
    LeftUp,
} Dir;

typedef struct {
    int v;
    Dir dir;
} DPItem;

namespace Algorithm {

    /**
     * Is string a the prefix of string b.
     */
    bool isStringPrefix(std::string const &a, std::string const &b);
    
    /**
     *  Binary search
     */
    class BinarySearch {
    public:
        template<class T>
        static int BSearchFirstPrefixIndex(const T * arr[], const T * query, int n)
        {
            int start = 0, end = n - 1;
            while (start < end) {
                int mid = (start + end) / 2;
                if (*query > *arr[mid]) {
                    start = mid + 1;
                } else {
                    end = mid;
                }
            }
            
            return (*query >= *arr[end]) ? end : -1;
        }
    };
    
    /**
     *  Trie tree node
     */
    class TrieNode {
    public:
        static const int cNumOfChild = 26;
        
        TrieNode(std::string *word = NULL, TrieNode **childArr = NULL);
        ~TrieNode();
        
        void OrderPrintAndGet(std::vector<std::string *> &container, int k);
        
        TrieNode **childArr; // only lowercase
        std::string *word;
    };
    
    /**
     *  Trie tree
     */
    class TrieTree {
    public:
        TrieTree(std::string *input[] = NULL, int n = 0);
        ~TrieTree();

        void Insert(std::string *word);
        void InsertFromNode(std::string *word, int curIdx, TrieNode *node);
        void OrderPrintAndGet(std::vector<std::string *> &container, int k);
        void SearchPrefixMatchItem(std::string *query, int k, std::vector<std::string *> &ret);
        
        TrieNode *root;
    };
    
    /**
     *  DP solve package problem
     */
    int sumOfArr(int arr[], int n);
    void dpSol(int arr[], int n, int wantedSum,
                           int *retArr, int &retLen);
    
    /**
     *  Disjoint-Set
     */
    class DisJointSet {
    public:
        DisJointSet(int n = 0);
        ~DisJointSet();
        
        uint32_t FindParent(uint32_t itemId);
        void UnionSet(uint32_t itemId1, uint32_t itemId2);
        uint32_t GetNumOfIsolatedSet();
        
        void PrintTable();
        
    private:
        int itemSize;
        uint32_t *parentTable;
        uint32_t *rankTable;
    };
}

#endif
