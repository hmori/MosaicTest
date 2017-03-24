#import "FilterTableViewController.h"
#import "EditViewController.h"

@interface FilterTableViewController ()
@property (nonatomic) NSArray *filterNames;
@end

@implementation FilterTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _filterNames = [CIFilter filterNamesInCategory:kCICategoryBuiltIn];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _filterNames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.textLabel.text = _filterNames[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    __block EditViewController *editViewController = (EditViewController *)((UINavigationController *)self.presentingViewController).topViewController;
    _filter = [CIFilter filterWithName:_filterNames[indexPath.row]];
    editViewController.filter = _filter;
    [self dismissViewControllerAnimated:YES
                             completion:^{
                                 [editViewController refresh];
                                 [editViewController randomValue];
                             }];
}

#pragma mark - Action

- (IBAction)closeAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
