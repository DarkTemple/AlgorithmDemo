//
//  DictSearchViewController.m
//  PrefixMatchDemo
//
//  Created by Bai Haoquan on 13-9-29.
//  Copyright (c) 2013年 Bai Haoquan. All rights reserved.
//

#import "DictSearchViewController.h"
#import "Algorithm.h"
#import "Config.h"
#import "FMDatabase.h"

#define FMDBQuickCheck(SomeBool) { if (!(SomeBool)) { NSLog(@"Failure on line %d", __LINE__); abort(); } }

static NSString *const kDictFileName = @"dict_merge";
static NSString *const kDatabaseName = @"dictStr.db";
static NSString *const kDBTableName = @"dict_table";
static const int kQuerySuggestionTopK = 10;

typedef enum {
    LinerSearch = 0,
    BinarySearch = 1,
    TrieTreeSearch = 2,
    SQLSearch = 3,
} DictPrefixSchema;

@interface DictSearchViewController () <UIScrollViewDelegate>
{
    std::string **stdStrWordTable;
    Algorithm::TrieTree *trieTree;
}

@property (nonatomic) int dictWordCount;
@property (nonatomic, strong) FMDatabase *db;
@property (nonatomic) BOOL isTableExist;
@property (retain, nonatomic) IBOutlet UISegmentedControl *schemaControl;
@property (retain, nonatomic) IBOutlet UISearchBar *searchBar;
@property (retain, nonatomic) IBOutlet UITableView *searchRetListView;
@property (nonatomic, retain) NSMutableArray *retArr;
@end

@implementation DictSearchViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.retArr = [NSMutableArray array];
        trieTree = new Algorithm::TrieTree;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Do any additional setup after loading the view from its nib.
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    // load dict into memory
    NSString *filePath = [[NSBundle mainBundle] pathForResource:kDictFileName ofType:@"txt"];
    NSString *content = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    NSArray *tempArr = [content componentsSeparatedByString:@"\n"];
    
    self.dictWordCount = (int)tempArr.count;
    stdStrWordTable = new std::string *[self.dictWordCount];
    memset(stdStrWordTable, NULL, sizeof(stdStrWordTable[0])*self.dictWordCount);
    
    for (int i=0; i<self.dictWordCount; i++) {
        NSString *wordStr = [[tempArr objectAtIndex:i] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        std::string *pWord = new std::string([wordStr UTF8String]);
        stdStrWordTable[i] = pWord;
        
        // insert into trie tree
        trieTree->Insert(pWord);
    }
    
    // create database and insert into database
    NSString *documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *dbPath = [documentPath stringByAppendingPathComponent:kDatabaseName];
    self.db = [FMDatabase databaseWithPath:dbPath];
    [self.db open];
    [self.db setShouldCacheStatements:YES];
    
    if (![self.db open]) {
        NSLog(@"Could not open db.");
    }

    
    FMResultSet *rs = [self.db executeQuery:@"select * FROM sqlite_master where type = 'table' and name = ?", kDBTableName];
    self.isTableExist = [rs next];
    if (!self.isTableExist) {
        [self.db executeUpdate:@"create table if not exists dict_table (word text);"];
        [self.db executeUpdate:@"create unique index u_idx on dict_table (word)"];

        [self.db beginTransaction];
        BOOL isRollBack = NO;
        @try {
            for (int i=0; i<self.dictWordCount; i++) {
                NSString *word = [[tempArr objectAtIndex:i] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
                [self.db executeUpdate:@"insert into dict_table (word) values (?)", word];
            }
        }
        @catch (NSException *exception) {
            isRollBack = YES;
            [self.db rollback];
        }
        @finally {
            if (!isRollBack) {
                [self.db commit];
            }
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    NSDate *startTime = [NSDate date];
    [self.retArr removeAllObjects];
    
    std::string query = [searchText UTF8String];
    if ([searchText length] > 0) {
        switch (self.schemaControl.selectedSegmentIndex) {
            case LinerSearch: {
                for (int i=0; i<self.dictWordCount; i++) {
                    std::string *pword = stdStrWordTable[i];
                    if (Algorithm::isStringPrefix(query, *pword)) {
                        [self.retArr addObject:[NSString stringWithUTF8String:pword->c_str()]];
                    }
                }
                
                NSLog(@"Liner schema time elapse is %f.", [[NSDate date] timeIntervalSinceDate:startTime]);
                
                if (self.retArr.count > kQuerySuggestionTopK) {
                    self.retArr = [NSMutableArray arrayWithArray:[self.retArr subarrayWithRange:NSMakeRange(0, kQuerySuggestionTopK)]];
                }
                
                break;
            }
            case BinarySearch: {
                int index = Algorithm::BinarySearch::BSearchFirstPrefixIndex<std::string>((const std::string **)stdStrWordTable, &query, self.dictWordCount);
                
                NSLog(@"Binary shcema time elapse is %f.", [[NSDate date] timeIntervalSinceDate:startTime]);
                
                if (index < 0) {
                    // Not found.
                    return;
                }
                
                for (int i=index; i<MIN(index+kQuerySuggestionTopK, self.dictWordCount); i++) {
                    std::string *pMatchStr = stdStrWordTable[i];
                    if (Algorithm::isStringPrefix(query, *pMatchStr)) {
                        [self.retArr addObject:[NSString stringWithUTF8String:pMatchStr->c_str()]];
                    } else {
                        break;
                    }
                }
                
                break;
            }
            case TrieTreeSearch: {
                std::vector<std::string *> ret;
                trieTree->SearchPrefixMatchItem(&query, kQuerySuggestionTopK, ret);
                for (int i=0; i<ret.size(); i++) {
                    [self.retArr addObject:[NSString stringWithUTF8String:ret[i]->c_str()]];
                }
                
                break;
            }
                
            case SQLSearch: {
                FMResultSet *rs = [self.db executeQuery:@"select word from dict_table where word > ? limit ?", [NSString stringWithFormat:@"%@%%", searchText], [NSNumber numberWithInt:kQuerySuggestionTopK]];

                NSLog(@"SQL schema time elapse is %f.", [[NSDate date] timeIntervalSinceDate:startTime]);
                
                while ([rs next]) {
                    [self.retArr addObject:[rs stringForColumn:@"word"]];
                }
                
                break;
            }
                
            default:
                break;
        }
    }
    
    [self.searchRetListView reloadData];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.retArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"Identifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    NSString *word = [self.retArr objectAtIndex:[indexPath row]];
    cell.textLabel.text = word;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)dealloc
{
    NSLog(@"%@ dealloc", NSStringFromClass([self class]));
    for (int i=0; i<self.dictWordCount; i++) {
        delete stdStrWordTable[i];
        stdStrWordTable[i] = NULL;
    }
    
    delete [] stdStrWordTable;
    delete trieTree;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.searchBar resignFirstResponder];
}

@end
