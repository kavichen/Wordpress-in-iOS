//
//  KCCategoryManager.m
//  Wordpress
//
//  Created by kavi chen on 14-4-9.
//  Copyright (c) 2014年 kavi chen. All rights reserved.
//

#import "KCCategoryManager.h"
#import <SVPullToRefresh.h>


@implementation KCCategoryManager
@synthesize getTermsRequestManager = _getTermsRequestManager;
@synthesize tableViewController = _tableViewController;
@synthesize myCategories = _myCategories;


#pragma mark - Getter && Setter
- (KCGetTermsRequestManager *)getTermsRequestManager
{
    if (!_getTermsRequestManager) {
        _getTermsRequestManager = [[KCGetTermsRequestManager alloc] init];
    }
    return _getTermsRequestManager;
}

- (KCCategoryTableViewController *)tableViewController
{
    if (!_tableViewController) {
        _tableViewController = [[KCCategoryTableViewController alloc] init];
    }
    return _tableViewController;
}

#pragma mark - Initial method
+ (instancetype)sharedInstance
{
    static KCCategoryManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[KCCategoryManager alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self.getTermsRequestManager sendRequestFromOwner:self];
        self.getTermsRequestManager.delegate = self;
        [SVProgressHUD showWithStatus:@"载入中..."];
    }
    return self;
}

#pragma mark - KCGetTermsRequestManagerDelegate
- (void)achieveGetTermsResponse:(NSArray *)response
{
    [self.tableViewController.tableView.pullToRefreshView stopAnimating];
    [self.tableViewController.tableView.pullToRefreshView setHidden:YES];
    
    self.myCategories = [self retrieveResponse:(NSMutableArray *)response];
    [self.tableViewController assignCategories:self.myCategories];
    
    [SVProgressHUD popActivity];
    [self.tableViewController.tableView reloadData];
}

#pragma mark - Categories Function
- (NSMutableArray *)retrieveResponse:(NSArray *)response
{
    NSMutableArray *firstLevelCategories = [[NSMutableArray alloc] init];
    for (NSDictionary *category in response) {
        if ([[category objectForKey:@"parent"] isEqualToString:@"0"]) {
            [firstLevelCategories addObject:category];
        }
    }
    NSSet *ignoredCategories = [NSSet setWithObjects:@"其他", @"李孟蓉的日記", @"阅读收藏", nil]; // the name of ignored categories
    return [self trimCategaries:firstLevelCategories withIgnoredSet:ignoredCategories];
    //    return firstLevelCategories;
}

- (NSMutableArray *)trimCategaries:(NSMutableArray *)categories withIgnoredSet:(NSSet *)set
{
    for (int i = 0; i < [categories count]; i++) {
        NSDictionary *category = [categories objectAtIndex:i];
        if ([set containsObject:[category objectForKey:@"name"]]) {
            [categories removeObjectAtIndex:i];
        }
    }
    return categories;
}

#pragma mark - KCErrorNotificationCenterProtocol
- (void)handleRequest:(WPRequest *)request Error:(NSError *)error
{
    [self.tableViewController.tableView.pullToRefreshView stopAnimating];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    __weak KCCategoryManager *self_ = self;
    [self.tableViewController.tableView addPullToRefreshWithActionHandler:^(void){
        [self_.getTermsRequestManager sendRequestFromOwner:self_];
    }position:SVPullToRefreshPositionTop];
}

@end
