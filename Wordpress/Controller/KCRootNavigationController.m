//
//  KCRootNavigationController.m
//  Wordpress
//
//  Created by kavi chen on 14-3-26.
//  Copyright (c) 2014年 kavi chen. All rights reserved.
//

#import "KCRootNavigationController.h"
#import "WPRequestManager.h"
#import "KCPostsTableViewController.h"
#import "KCCategoryManager.h"

@interface KCRootNavigationController ()
{
    UIBarButtonItem *leftNavigationBarButtomItem;
}
@property (nonatomic,strong) KCPostsTableViewController *recentPostsTableViewController;
@property (nonatomic,strong) KCCategoryManager *categoryManager;

@property (nonatomic,strong) KCPostRequestManager *postRequestManager;
@property (nonatomic,strong) KCBlogInfoRequestManager *blogInfoRequestManager;
@end

@implementation KCRootNavigationController
@synthesize recentPostsTableViewController = _recentPostsTableViewController;
@synthesize postRequestManager = _postRequestManager;
@synthesize blogInfoRequestManager = _blogInfoRequestManager;
@synthesize categoryManager = _categoryManager;

#pragma mark - Setter & Getter
- (KCPostsTableViewController *)recentPostsTableViewController
{
    if (!_recentPostsTableViewController) {
        _recentPostsTableViewController = [[KCPostsTableViewController alloc] init];
        _recentPostsTableViewController.view.frame = [[UIScreen mainScreen] bounds];
    }
    return _recentPostsTableViewController;
}


- (KCPostRequestManager *)postRequestManager
{
    if (!_postRequestManager) {
        _postRequestManager = [[KCPostRequestManager alloc] init];
    }
    return _postRequestManager;
}

- (KCBlogInfoRequestManager *)blogInfoRequestManager
{
    if (!_blogInfoRequestManager) {
        _blogInfoRequestManager = [[KCBlogInfoRequestManager alloc] init];
    }
    return _blogInfoRequestManager;
}

- (KCCategoryManager *)categoryManager
{
    if (!_categoryManager) {
        _categoryManager = [[KCCategoryManager alloc] init];
    }
    return _categoryManager;
}
#pragma mark - inital method
/**
 *  Send getBlogNameRequest to get your blog information.
 *  Send getPostsRequest to get recent 10 posts.
 *  Both request set delegate as self.
 *
 *  @param nibNameOrNil
 *  @param nibBundleOrNil
 *
 *  @return self
 */
- (instancetype)init
{
    self = [super init];
    if (self) {
        // if the navigation bar is translucent, SVPullToRefresh give rise to first tableview cell cut-off.
        self.navigationBar.translucent = NO;
        self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
        [self setupSVProgressHUD];
    }
    return self;
}

+ (instancetype)sharedInstance
{
    static KCRootNavigationController *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[KCRootNavigationController alloc] init];
    });
    return _sharedInstance;
}

- (void)setupSVProgressHUD
{
    [SVProgressHUD setBackgroundColor:[UIColor blackColor]];
    [SVProgressHUD setForegroundColor:[UIColor whiteColor]];
}

#pragma mark - View controller life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.blogInfoRequestManager sendGetBlogInfoRequest];
    

    self.postRequestManager.delegate = self;
    self.blogInfoRequestManager.delegate = self;
    
    [self.postRequestManager.myFilter setValue:@"publish" forKey:@"post_status"];
    [self.postRequestManager.myFilter setValue:@"8" forKey:@"number"];
    [self.postRequestManager.myFilter setValue:@"1" forKey:@"author"];
    [self.postRequestManager.myFilter setValue:@"0" forKey:@"offset"];
    

    __weak KCRootNavigationController *self_ = self;
    [self pushViewController:self.recentPostsTableViewController animated:YES];
    [self.recentPostsTableViewController.tableView addPullToRefreshWithActionHandler:^(void){
        [self_.postRequestManager sendGetPostsRequest];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }position:SVPullToRefreshPositionBottom];
    
    [self.recentPostsTableViewController.tableView.pullToRefreshView setHidden:YES];
    [self.recentPostsTableViewController.tableView triggerPullToRefresh];
}


#pragma mark - Switch View Controller

- (void)selectCategoriesTableViewController
{
    [self pushViewController:self.categoryManager.tableViewController animated:YES];
//    [SVProgressHUD show];
}

#pragma mark - KCPostRequestManagerDelegate
- (void)achievePostResponse:(NSArray *)response
{
    [self.recentPostsTableViewController handleMyPostsWithRawResponse:response];
    
    NSString *newOffSet = [NSString stringWithFormat:@"%lu",(unsigned long)[self.recentPostsTableViewController.myPosts count]];
    [self.postRequestManager.myFilter setObject:newOffSet forKey:@"offset"];
    
    [self.recentPostsTableViewController.tableView.pullToRefreshView setHidden:NO];
    [self.recentPostsTableViewController.tableView.pullToRefreshView stopAnimating];
    [self.recentPostsTableViewController stopNetworkActivity];

}

#pragma mark - KCBlogInfoRequestManagerDelegate
- (void)achieveBlogInfoResponse:(NSArray *)response
{
    self.recentPostsTableViewController.title = [[response lastObject] objectForKey:@"blogName"];
    self.recentPostsTableViewController.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@"分类"
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(selectCategoriesTableViewController)];
}

@end
