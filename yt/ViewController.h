#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate> {
    NSString *previousSearchText;
}

@property (nonatomic, strong) IBOutlet UITableView *tableView;           // connected only in iPhone XIB
@property (nonatomic, strong) IBOutlet UICollectionView *collectionView; // connected only in iPad XIB

@property (strong, nonatomic) NSArray *videos;
@property (strong, nonatomic) NSMutableDictionary *imageCache;

// Network properties (if still needed)
@property (strong, nonatomic) NSURLConnection *videoExtractConnection;
@property (strong, nonatomic) NSURLConnection *videoDownloadConnection;
@property (strong, nonatomic) NSMutableData *responseData;

@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
- (IBAction)searchVCBtn:(id)sender;
- (IBAction)settingsBtn:(id)sender;
@property (weak, nonatomic) IBOutlet UINavigationBar *titleBar;

@end