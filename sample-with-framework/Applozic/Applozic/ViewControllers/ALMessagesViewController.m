//
//  ViewController.m
//  ChatApp
//
//  Copyright (c) 2015 AppLozic. All rights reserved.
//

#import "ALMessagesViewController.h"
#import "ALConstant.h"
#import "ALMessageService.h"
#import "ALMessage.h"
#import "ALChatViewController.h"
#import "ALUtilityClass.h"
#import "ALContact.h"
#import "ALMessageDBService.h"
#import "ALRegisterUserClientService.h"
#import "ALDBHandler.h"
#import "ALContact.h"
#import "ALUserDefaultsHandler.h"
#import "ALContactDBService.h"
#import "UIImageView+WebCache.h"
//#import "ApplozicLoginViewController.h"

// Constants
#define DEFAULT_TOP_LANDSCAPE_CONSTANT -34
#define DEFAULT_TOP_PORTRAIT_CONSTANT -64



//------------------------------------------------------------------------------------------------------------------
// Private interface
//------------------------------------------------------------------------------------------------------------------

@interface ALMessagesViewController ()<UITableViewDataSource,UITableViewDelegate,ALMessagesDelegate>

- (IBAction)logout:(id)sender;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *logoutButton;
@property (strong, nonatomic) IBOutlet UINavigationItem *navBar;

// Constants

// IBOutlet
@property (weak, nonatomic) IBOutlet UITableView *mTableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mTableViewTopConstraint;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *mActivityIndicator;

// Private Varibles
@property (nonatomic, strong) NSMutableArray * mContactsMessageListArray;
@property (nonatomic, strong) UIColor *navColor;

@end

@implementation ALMessagesViewController

//------------------------------------------------------------------------------------------------------------------
#pragma mark - View lifecycle
//------------------------------------------------------------------------------------------------------------------

- (void)viewDidLoad {
    
    [super viewDidLoad];

    [self setUpView];
    [self setUpTableView];
    self.mTableView.allowsMultipleSelectionDuringEditing = NO;
    [self.mActivityIndicator startAnimating];
    ALMessageDBService *dBService = [ALMessageDBService new];
    dBService.delegate = self;
    [dBService getMessages];
    
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if([ALUserDefaultsHandler isLogoutButtonHidden])
    {
        [self.navBar setRightBarButtonItems:nil];
    }
    
    [self.tabBarController.tabBar setHidden: [ALUserDefaultsHandler isBottomTabBarHidden]];
    
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        // iOS 6.1 or earlier
        self.navigationController.navigationBar.tintColor = (UIColor *)[ALUtilityClass parsedALChatCostomizationPlistForKey:APPLOZIC_TOPBAR_COLOR];
    } else {
        // iOS 7.0 or later
        self.navigationController.navigationBar.barTintColor = (UIColor *)[ALUtilityClass parsedALChatCostomizationPlistForKey:APPLOZIC_TOPBAR_COLOR];
    }
    
    //register for notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushNotificationhandler:) name:@"pushNotification" object:nil];
    if ([_detailChatViewController refreshMainView])
    {
        ALMessageDBService *dBService = [ALMessageDBService new];
        dBService.delegate = self;
        [dBService getMessages];
        [_detailChatViewController setRefreshMainView:FALSE];
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    
    [self.tabBarController.tabBar setHidden: [ALUserDefaultsHandler isBottomTabBarHidden]];
    //unregister for notification
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"pushNotification" object:nil];
    
    [super viewWillDisappear:animated];
    
    self.navigationController.navigationBar.barTintColor = self.navColor;
}

- (IBAction)logout:(id)sender {
    
        ALRegisterUserClientService *registerUserClientService = [[ALRegisterUserClientService alloc] init];
        [registerUserClientService logout];
        
//        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil]; // ApplozicLoginViewController.m
        //ALLoginViewController *add = [storyboard instantiateViewControllerWithIdentifier:@"ALLoginViewController"];
    
    //   [self presentViewController:add animated:YES completion:nil];
    
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
}

-(void)setUpView {
    UIColor *color = [ALUtilityClass parsedALChatCostomizationPlistForKey:APPLOGIC_TOPBAR_TITLE_COLOR];
    if (!color) {
        color = [UIColor blackColor];
    }
    NSLog(@"%@",[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]);
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    color,NSForegroundColorAttributeName,nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    self.navigationItem.title = @"Conversation";
    
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1)
        self.navColor = [self.navigationController.navigationBar tintColor];
    else
        self.navColor = [self.navigationController.navigationBar barTintColor];
}

-(void)setUpTableView {
    self.mContactsMessageListArray = [NSMutableArray new];
    self.mTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateConversationTableNotification:) name:@"updateConversationTableNotification" object:nil];
}

//------------------------------------------------------------------------------------------------------------------
#pragma mark - ALMessagesDelegate
//------------------------------------------------------------------------------------------------------------------

-(void)getMessagesArray:(NSMutableArray *)messagesArray {
    [self.mActivityIndicator stopAnimating];
    self.mContactsMessageListArray = messagesArray;
    [self.mTableView reloadData];
}


//------------------------------------------------------------------------------------------------------------------
#pragma mark - Table View DataSource Methods
//------------------------------------------------------------------------------------------------------------------

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return (self.mTableView==nil)?0:1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.mContactsMessageListArray.count>0?[self.mContactsMessageListArray count]:0;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"ContactCell";

    
    ALContactCell *contactCell = (ALContactCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    ALMessage *message = (ALMessage *)self.mContactsMessageListArray[indexPath.row];
    
    UILabel* nameIcon=(UILabel*)[contactCell viewWithTag:102];
    //    contactCell.mUserImageView.image = [UIImage imageNamed:@"ic_mobicom.png"];
    

    ALContactDBService *theContactDBService = [[ALContactDBService alloc] init];
    ALContact *alContact = [theContactDBService loadContactByKey:@"userId" value: message.to];             
    contactCell.mUserNameLabel.text = [alContact displayName];

    contactCell.mMessageLabel.text = message.message;
    contactCell.mMessageLabel.hidden = FALSE;
    if ([message.type integerValue] == [FORWARD_STATUS integerValue])
        contactCell.mLastMessageStatusImageView.image = [UIImage imageNamed:@"mobicom_social_forward.png"];
    else if ([message.type integerValue] == [REPLIED_STATUS integerValue])
        contactCell.mLastMessageStatusImageView.image = [UIImage imageNamed:@"mobicom_social_reply.png"];
    
    BOOL isToday = [ALUtilityClass isToday:[NSDate dateWithTimeIntervalSince1970:[message.createdAtTime doubleValue]/1000]];
    contactCell.mTimeLabel.text = [message getCreatedAtTime:isToday];
    
    [self displayAttachmentMediaType:message andContactCell: contactCell];
   
    // here for msg dashboard profile pic
    NSString *firstLetter = [[alContact displayName] substringToIndex:1];
    nameIcon.text=firstLetter;
   
    contactCell.mUserImageView.hidden=FALSE;

    NSLog(@"message.to and index %@   %i", message.to, indexPath.row);

    if (alContact.localImageResourceName)
    {
        UIImage *someImage = [UIImage imageNamed:alContact.localImageResourceName];

        [contactCell.mUserImageView  setImage:someImage];
        nameIcon.hidden = TRUE;
        NSLog(@"image from local : %@", alContact.localImageResourceName);
    }
    else if(alContact.contactImageUrl)
    {
        NSURL * theUrl1 = [NSURL URLWithString:alContact.contactImageUrl];
        [contactCell.mUserImageView sd_setImageWithURL:theUrl1];
        nameIcon.hidden = TRUE;
        NSLog(@"DASHBOARD IF URL: %@", alContact.contactImageUrl);
    }
    
    else
    {
         nameIcon.hidden = FALSE;
         NSString *firstLetter = [[alContact displayName] substringToIndex:1];
         nameIcon.text=firstLetter;
         contactCell.mUserImageView.hidden=TRUE ;

    }
  
    return contactCell;
}

-(void)displayAttachmentMediaType:(ALMessage *)message andContactCell:(ALContactCell *)contactCell{
    
    if([message.fileMetas.contentType isEqual:@"image/jpeg"]||[message.fileMetas.contentType isEqual:@"image/png"]
       ||[message.fileMetas.contentType isEqual:@"image/gif"]||[message.fileMetas.contentType isEqual:@"image/tiff"]
       ||[message.fileMetas.contentType isEqual:@"video/mp4"])
    {
        contactCell.mMessageLabel.hidden = YES;
        contactCell.imageMarker.hidden = NO;
        contactCell.imageNameLabel.hidden = NO;
        
        if([message.fileMetas.contentType isEqual:@"video/mp4"])
        {
//            contactCell.imageNameLabel.text = NSLocalizedString(@"MEDIA_TYPE_VIDEO", nil);
            contactCell.imageNameLabel.text = NSLocalizedString(@"Video", nil);
            contactCell.imageMarker.image = [UIImage imageNamed:@"applozic_ic_action_video.png"];
        }
        else
        {
           // contactCell.imageNameLabel.text = NSLocalizedString(@"MEDIA_TYPE_IMAGE", nil);
            contactCell.imageNameLabel.text = NSLocalizedString(@"Image", nil);
        }
    }
    else if (message.message.length == 0)           //other than video and image
    {
//        contactCell.imageNameLabel.text = NSLocalizedString(@"MEDIA_TYPE_ATTACHMENT", nil);
        contactCell.imageNameLabel.text = NSLocalizedString(@"Attachment", nil);
        contactCell.imageMarker.image = [UIImage imageNamed:@"ic_action_attachment.png"];
    }
    else
    {
        contactCell.imageNameLabel.hidden = YES;
        contactCell.imageMarker.hidden = YES;
    }

}

//------------------------------------------------------------------------------------------------------------------
#pragma mark - Table View Delegate Methods                 //method to enter achat/ select aparticular cell in table
//------------------------------------------------------------------------------------------------------------------

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ALMessage * message =  self.mContactsMessageListArray[indexPath.row];
    
    [self createDetailChatViewController: message.contactIds];
    
}

-(void)createDetailChatViewController: (NSString *) contactIds
{
    if (!(self.detailChatViewController))
    {
        _detailChatViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ALChatViewController"];
    }
    _detailChatViewController.contactIds = contactIds;
    [self.navigationController pushViewController:_detailChatViewController animated:YES];
}

//------------------------------------------------------------------------------------------------------------------
#pragma mark - Table View Editing Methods
//------------------------------------------------------------------------------------------------------------------

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {

    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        NSLog(@"Delete Pressed");
        ALMessage * alMessageobj=  self.mContactsMessageListArray[indexPath.row];
        
        [ALMessageService deleteMessageThread:alMessageobj.contactIds withCompletion:^(NSString *string, NSError *error) {
            
            if(error){
                NSLog(@"failure %@",error.description);
                [ ALUtilityClass displayToastWithMessage:@"Delete failed" ];
                return;
            }
            
            NSArray * theFilteredArray = [self.mContactsMessageListArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"contactIds = %@",alMessageobj.contactIds]];
            
            NSLog(@"getting filteredArray ::%lu", (unsigned long)theFilteredArray.count );
            [self.mContactsMessageListArray removeObjectsInArray:theFilteredArray ];
            
            [self.mTableView reloadData];
        }];
    }
}

//------------------------------------------------------------------------------------------------------------------
#pragma mark - Notification observers
//------------------------------------------------------------------------------------------------------------------

-(void) updateConversationTableNotification:(NSNotification *) notification
{
    ALMessage * theMessage = notification.object;
    NSLog(@"notification for table update...%@", theMessage.message);
    NSArray * theFilteredArray = [self.mContactsMessageListArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"contactIds = %@",theMessage.contactIds]];
    
    ALMessage * theLatestMessage = theFilteredArray.firstObject;
    if ([theMessage.createdAtTime isEqualToString:theLatestMessage.createdAtTime] == NO) {
        [self.mContactsMessageListArray removeObject:theLatestMessage];
        [self.mContactsMessageListArray insertObject:theMessage atIndex:0];
        [self.mTableView reloadData];
    }
}

//------------------------------------------------------------------------------------------------------------------
#pragma mark - View orientation methods
//------------------------------------------------------------------------------------------------------------------

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    UIInterfaceOrientation toOrientation   = (UIInterfaceOrientation)[[UIDevice currentDevice] orientation];
    if ([[UIDevice currentDevice]userInterfaceIdiom]==UIUserInterfaceIdiomPhone && (toOrientation == UIInterfaceOrientationLandscapeLeft || toOrientation == UIInterfaceOrientationLandscapeRight)) {
        self.mTableViewTopConstraint.constant = DEFAULT_TOP_LANDSCAPE_CONSTANT;
    }else{
        self.mTableViewTopConstraint.constant = DEFAULT_TOP_PORTRAIT_CONSTANT;
    }
    
    [self.view layoutIfNeeded];
}


-(void)pushNotificationhandler:(NSNotification *) notification{
    NSString * contactId = notification.object;
    NSDictionary *dict = notification.userInfo;
    NSNumber *updateUI = [dict valueForKey:@"updateUI"];
    
    if (self.isViewLoaded && self.view.window && [updateUI boolValue])
    {
        //Show notification...
        ALMessageDBService *dBService = [ALMessageDBService new];
        dBService.delegate = self;
        [dBService fetchAndRefreshFromServerForPush];
    }
    else if(![updateUI boolValue])
    {
        NSLog(@"#################It should never come here");
        [self createDetailChatViewController: contactId];
        [self.detailChatViewController fetchAndRefresh];
    }
    
    [self.detailChatViewController setRefresh: TRUE];
}

- (void)dealloc {
    
}
@end