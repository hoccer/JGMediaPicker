//
//  JGAlbumViewController.m
//  JGMediaBrowser
//
//  Created by Jamin Guy on 12/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "JGAlbumViewController.h"

#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVAsset.h>

#import "MPMediaItem+JGExtensions.h"
#import "MPMediaItemCollection+JGExtensions.h"
#import "JGAlbumTrackTableViewCell.h"

#import "JGMediaQueryViewController.h"

@interface JGAlbumViewController ()

- (void)updateUI;

@end

@implementation JGAlbumViewController

#define kSeparatorColor [UIColor colorWithRed:236.0/255.0 green:236.0/255.0 blue:236.0/255.0 alpha:1.0]
#define kGrayBackgroundColor [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0]

@synthesize albumArtImageView;
@synthesize albumArtistLabel;
@synthesize albumTitleLabel;
@synthesize albumReleaseDateLabel;
@synthesize albumTrackCountTimeLabel;
@synthesize albumTrackTableViewCell;

@synthesize delegate;
@synthesize albumCollection;
@synthesize showsCancelButton;
@synthesize allowsSelectionOfNonPlayableItem;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self updateDoneButton];
    
    [[self tableView] setSeparatorColor:kSeparatorColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaLibraryDidChange:) name:MPMediaLibraryDidChangeNotification object:nil];
    [[MPMediaLibrary defaultMediaLibrary] beginGeneratingLibraryChangeNotifications];
}

- (void)viewDidUnload
{
    [self setAlbumArtImageView:nil];
    [self setAlbumArtistLabel:nil];
    [self setAlbumTitleLabel:nil];
    [self setAlbumReleaseDateLabel:nil];
    [self setAlbumTrackCountTimeLabel:nil];
    [[MPMediaLibrary defaultMediaLibrary] endGeneratingLibraryChangeNotifications];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateUI];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)updateUI {
    MPMediaItem *mediaItem = [[self albumCollection] representativeItem];
    if(mediaItem) {
        self.title = [mediaItem jg_artist];
        self.albumArtistLabel.text = [mediaItem jg_artist];
        self.albumTitleLabel.text = [mediaItem jg_albumTitle];
        self.albumArtImageView.image = [mediaItem jg_artworkWithSize:self.albumArtImageView.bounds.size] ?: [UIImage imageNamed:@"AlbumArtPlaceholderLarge.png"];
        
        NSString *yearString = [mediaItem jg_releaseYearString];
        self.albumReleaseDateLabel.text = yearString ? [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Released", @"Released"), yearString] : nil;
        NSNumber *totalTimeInSeconds = [[self albumCollection] jg_playbackLength];
        int totalTimeInMinutes = [totalTimeInSeconds doubleValue] / 60;
        self.albumTrackCountTimeLabel.text = [NSString stringWithFormat:@"%@ %@, %d Mins.", @(self.albumCollection.count), NSLocalizedString(@"Songs", @"Songs"), totalTimeInMinutes];
    }
}

- (void)setAlbumCollection:(MPMediaItemCollection *)newAlbumCollection {
    if(newAlbumCollection != albumCollection) {
        albumCollection = newAlbumCollection;
        [self.tableView reloadData];
        [self updateUI];
    }
}

- (void)mediaLibraryDidChange:(NSNotification *)notification {
    [self updateUI];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.albumCollection.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"AlbumTrackCell";
    JGAlbumTrackTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        [[NSBundle mainBundle] loadNibNamed:@"JGAlbumTrackTableViewCell" owner:self options:nil];
        cell = self.albumTrackTableViewCell;
        self.albumTrackTableViewCell = nil;
    }
    [self configureCell: cell indexPath: indexPath];
    return cell;
}

- (void) configureCell: (JGAlbumTrackTableViewCell*) cell indexPath: (NSIndexPath*) indexPath {

    MPMediaItem *mediaItem = [[[self albumCollection] items] objectAtIndex:indexPath.row];
    cell.trackNumberLabel.text = [NSString stringWithFormat:@"%d",[[mediaItem jg_trackNumber] intValue]];
    cell.trackNameLabel.text = [mediaItem jg_title];
    cell.trackLengthLabel.text = [mediaItem jg_trackLengthString];

    BOOL isSelectable = self.allowsSelectionOfNonPlayableItem || [mediaItem jg_isPlayable];
    cell.trackNameLabel.textColor = isSelectable ? [UIColor blackColor] : [UIColor lightGrayColor];
    cell.userInteractionEnabled = isSelectable;

    //make odd rows gray    
    cell.backgroundView.backgroundColor = indexPath.row % 2 != 0 ? kGrayBackgroundColor : [UIColor whiteColor];

    cell.accessoryType = UITableViewCellAccessoryNone;
    if ([self.delegate respondsToSelector: @selector(jgMediaQueryViewController:isItemSelected:)]) {
        cell.accessoryType = [self.delegate jgMediaQueryViewController: nil/*self*/ isItemSelected: mediaItem] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MPMediaItem *selectedItem = [self.albumCollection.items objectAtIndex:indexPath.row];
    if([self.delegate respondsToSelector:@selector(jgMediaQueryViewController:isItemSelected:)] && [self.delegate jgMediaQueryViewController:nil/*self*/ isItemSelected: selectedItem]) {
        if([self.delegate respondsToSelector:@selector(jgMediaQueryViewController:deselectItem:)]) {
            [self.delegate jgMediaQueryViewController: nil/*self*/ deselectItem: selectedItem];
        }
    } else {
        if([self.delegate respondsToSelector:@selector(jgMediaQueryViewController:didPickMediaItems:selectedItem:)]) {
            [self.delegate jgMediaQueryViewController: nil/*self*/ didPickMediaItems:self.albumCollection selectedItem:selectedItem];
        }
    }
    JGAlbumTrackTableViewCell * cell = (JGAlbumTrackTableViewCell*)[self.tableView cellForRowAtIndexPath: indexPath];
    if (cell) {
        [self.tableView beginUpdates];
        [self configureCell: cell indexPath: indexPath];
        [self.tableView endUpdates];
    }
    [self updateDoneButton];
}


- (void) updateDoneButton {
    UIBarButtonItem * button = nil;
    if(self.showsCancelButton) {
        BOOL hasSelection = self.selectedItems.count > 0;
        SEL action = hasSelection ? @selector(doneButtonTap:) : @selector(cancelButtonTap:);
        UIBarButtonSystemItem buttonType = hasSelection ? UIBarButtonSystemItemDone : UIBarButtonSystemItemCancel;
        button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: buttonType target: self.delegate action: action];
    }
    self.navigationItem.rightBarButtonItem = button;
}

- (NSArray*) selectedItems {
    return [self.delegate selectedItems];
}

- (NSArray*) toolbarItems {
    return [self.delegate toolbarItems];
}

@end
