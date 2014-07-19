 //
//  Algorithm.cpp
//  PrefixMatchDemo
//
//  Created by Bai Haoquan on 13-9-30.
//  Copyright (c) 2013年 Bai Haoquan. All rights reserved.
//


#include "Algorithm.h"

bool Algorithm::isStringPrefix(std::string const &a, std::string const &b)
{
    int minLen = (int)std::min(a.length(), b.length());
    int i = 0;
    for (; i<minLen; i++) {
        if (a[i] != b[i]) {
            return false;
        }
    }
    
    return (i == a.length() && i <= b.length());
}

Algorithm::TrieNode::TrieNode(std::string *word, TrieNode **childArr) : word(word), childArr(childArr)
{
}

/**
 *  DFS destruction
 */
Algorithm::TrieNode::~TrieNode()
{
    if (childArr) {
        for (int i=0; i<cNumOfChild; i++) {
            TrieNode *childNode = childArr[i];
            if (childNode) {
                delete childNode;
            }
        }
        
        delete childArr;
        childArr = NULL;
    }
}

void Algorithm::TrieNode::OrderPrintAndGet(std::vector<std::string *> &container, int k) {
    if (container.size() >= k) {
        return;
    }
    
    if (word != NULL) {
        container.push_back(word);
    }
    
    if (childArr) {
        for (int i=0; i<TrieNode::cNumOfChild; i++) {
            TrieNode *childNode = childArr[i];
            if (childNode != NULL) {
                childNode->OrderPrintAndGet(container, k);
            }
        }
    }
}

Algorithm::TrieTree::TrieTree(std::string *input[], int n) {
    root = new TrieNode;
    for (int i=0; i<n; i++) {
        Insert(input[i]);
    }
}

Algorithm::TrieTree::~TrieTree()
{
    delete root;
}

/**
 *  Description: Insert word to trie tree.
 *
 *  @param word: word to insert
 */
void Algorithm::TrieTree::Insert(std::string *word)
{
    InsertFromNode(word, 0, root);
}

/**
 *  Description: insert word from node
 *
 *  @param word: word to insert
 *  @param curIdx: word start index
 *  @param node: insert from node
 */
void Algorithm::TrieTree::InsertFromNode(std::string *word, int curIdx, Algorithm::TrieNode *node)
{
    if (!word || word->length() == 0) {
        return;
    }
    
    if (curIdx == word->length()) {
        node->word = word;
        return;
    }
    
    if (!node->childArr) {
        node->childArr = new TrieNode *[TrieNode::cNumOfChild];
        memset(node->childArr, NULL, sizeof(TrieNode *)*(TrieNode::cNumOfChild));
    }
    
    int childIdx = (*word)[curIdx] - 'a';
    TrieNode *childNode = node->childArr[childIdx];
    if (!childNode) {
        childNode = new TrieNode;
        node->childArr[childIdx] = childNode;
    }
    
    InsertFromNode(word, curIdx+1, childNode);
}

void Algorithm::TrieTree::OrderPrintAndGet(std::vector<std::string *> &container, int k)
{
    root->OrderPrintAndGet(container, k);
}

/**
 *  Description: search query prefix in trie tree
 *
 *  @param query: query string
 *  @param k: top k resust
 *  @param ret: ret container
 */
void Algorithm::TrieTree::SearchPrefixMatchItem(std::string *query, int k, std::vector<std::string *> &ret)
{
    clock_t start,finish;
    double totaltime;
    start = clock();
    
    TrieNode *childNode = root;
    for (int i=0; i<query->length() && childNode->childArr; i++) {
        int childIdx = (*query)[i] - 'a';
        childNode = childNode->childArr[childIdx];
        if (!childNode) {
            return;
        }
    }
    
    finish = clock();
    totaltime = (double)(finish-start) / CLOCKS_PER_SEC;
    std::cout.setf(std::ios::fixed);
    std::cout << "TrieTree shcema time elapse is " << totaltime <<  std::endl;
    
    childNode->OrderPrintAndGet(ret, k);
}


// DP solve
void Algorithm::dpSol(int arr[], int n, int wantedSum, int retArr[], int &retLen)
{
    DPItem dpTable[n+1][wantedSum+1];
    for (int i=0; i<n+1; i++) {
        for (int j=0; j<wantedSum+1; j++) {
            dpTable[i][j] = {0, NA};
        }
    }
    
    dpTable[0][0] = {0, LeftUp};
    for (int i=1; i<n+1; i++) {
        for (int j=wantedSum; j>0; j--) {
            if (j>=arr[i-1] && dpTable[i-1][j-arr[i-1]].v+arr[i-1] > dpTable[i-1][j].v) {
                dpTable[i][j] = {dpTable[i-1][j-arr[i-1]].v+arr[i-1], LeftUp};
            } else {
                dpTable[i][j] = {dpTable[i-1][j].v, Up};
            }
        }
    }
    
    int i = n, j=0;
    while (i > 0) {
        if (dpTable[i][wantedSum].dir == Up) {
            i--;
        } else if (dpTable[i][wantedSum].dir == LeftUp) {
            wantedSum -= arr[i-1];
            retArr[retLen++] = --i;
        } else {
            i--;
        }
    }
    
    i = 0, j = retLen-1;
    while (i < j) {
        std::swap(retArr[i++], retArr[j--]);
    }
}

int Algorithm::sumOfArr(int arr[], int n)
{
    int sum = 0;
    for (int i=0; i<n; i++) {
        sum += arr[i];
    }
    
    return sum;
}


// Disjoint-Set
Algorithm::DisJointSet::DisJointSet(int n) : itemSize(n)
{
    if (n > 0) {
        parentTable = new uint32_t[itemSize];
        rankTable = new uint32_t[itemSize];
        
        // init set
        for (int i=0; i<itemSize; i++) {
            parentTable[i] = i;
            rankTable[i] = 0;
        }
    } else {
        parentTable = rankTable = NULL;
    }
}

Algorithm::DisJointSet::~DisJointSet()
{
    delete [] parentTable;
    delete [] rankTable;
}

uint32_t Algorithm::DisJointSet::FindParent(uint32_t itemId)
{
    if (parentTable[itemId] != itemId) {
        parentTable[itemId] = FindParent(parentTable[itemId]);
    }
    
    return parentTable[itemId];
}

void Algorithm::DisJointSet::UnionSet(uint32_t itemId1, uint32_t itemId2)
{
    uint32_t itemParent1 = FindParent(itemId1);
    uint32_t itemParent2 = FindParent(itemId2);
    if (itemParent1 == itemParent2) {
        return;
    }
    
    if (rankTable[itemParent1] < rankTable[itemParent2]) {
        parentTable[itemParent1] = itemParent2;
    } else {
        if (rankTable[itemParent1] == rankTable[itemParent2]) {
            rankTable[itemParent1]++;
        }
        
        parentTable[itemParent2] = itemParent1;
    }
}

uint32_t Algorithm::DisJointSet::GetNumOfIsolatedSet()
{
    uint32_t count = 0;
    for (int i=0; i<itemSize; i++) {
        if (parentTable[i] == i) {
            count++;
        }
    }
    
    return count;
}

void Algorithm::DisJointSet::PrintTable()
{
    std::cout << "Parent table is:" << std::endl;
    for (int i=0; i<itemSize; i++) {
        std::cout << parentTable[i] << " ";
    }
    
    std::cout << std::endl;

    std::cout << "Rank table is:" << std::endl;
    for (int i=0; i<itemSize; i++) {
        std::cout << rankTable[i] << " ";
    }
    
    std::cout << std::endl;
}
