#import "SelectTableViewController.h"
#import <Photos/Photos.h>
#import "EditViewController.h"
#import "AppDelegate.h"
#import "UIAlertController+Window.h"

@interface SelectTableViewController ()
@property (nonatomic) Mosaic *mosaic;
@end

@implementation SelectTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _mosaic = ((AppDelegate *)UIApplication.sharedApplication.delegate).mosaic;

    [self readAlbum];
}

#pragma mark - UITableViewDelegate & UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _mosaic.tiles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    UIImageView *imageView = [cell viewWithTag:1];
    Tile *tile = _mosaic.tiles[indexPath.row];
    imageView.image = tile.thumbnail;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    __block EditViewController *editViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil]
                                                              instantiateViewControllerWithIdentifier:@"EditViewController"];
    Tile *tile = _mosaic.tiles[indexPath.row];
    editViewController.originalImage = tile.image;
    [self.navigationController pushViewController:editViewController animated:YES];
}

#pragma mark -

- (void)readAlbum {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusDenied || status == PHAuthorizationStatusRestricted) {
        [UIAlertController showMessage:@"Allow to use photo library from setting"];
        return;
    } else if (status == PHAuthorizationStatusNotDetermined) {
        typeof(self) wself = self;
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status){
            if (status == PHAuthorizationStatusAuthorized) {
                [wself readImages];
            } else {
                [UIAlertController showMessage:@"Allow to use photo library from setting"];
            }
        }];
        return;
    }
    [self readImages];
}

- (void)readImages {
    PHFetchResult *assetCollections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                                                                               subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary
                                                                               options:nil];
    
    __block PHAssetCollection * myAlbum;
    [assetCollections enumerateObjectsUsingBlock:^(PHAssetCollection *album, NSUInteger idx, BOOL *stop) {
        myAlbum = album;
        *stop = YES;
    }];
    
    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:myAlbum options:nil];
    [fetchResult enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
        Tile *tile = [[Tile alloc] initWithAsset:asset];
        [_mosaic.tiles addObject:tile];
    }];
    
    [self.tableView reloadData];
}

@end
