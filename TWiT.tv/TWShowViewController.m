//
//  TWShowViewController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/2/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "TWSplitViewContainer.h"
#import "TWMainViewController.h"
#import "TWShowViewController.h"
#import "TWEpisodeViewController.h"
#import "TWEpisodeCell.h"

#import "Show.h"
#import "AlbumArt.h"
#import "Episode.h"

@implementation TWShowViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.show.title;
    self.albumArt.image = self.show.albumArt.image;
    self.posterView.image = self.show.poster.image;
    self.scheduleLabel.text = self.show.scheduleString;
    self.descLabel.text = self.show.desc;
    
    self.favoriteButton.selected = self.show.favorite;
    self.remindButton.selected = self.show.remind;
    self.emailButton.hidden = !self.show.email;
    self.phoneButton.hidden = !self.show.phone;
    
    CAGradientLayer *liveGradient = [CAGradientLayer layer];
    liveGradient.anchorPoint = CGPointMake(0, 0);
    liveGradient.position = CGPointMake(0, 0);
    liveGradient.startPoint = CGPointMake(0, 1);
    liveGradient.endPoint = CGPointMake(0, 0);
    liveGradient.bounds = self.gradientView.bounds;
    liveGradient.colors = [NSArray arrayWithObjects:
                           (id)[UIColor colorWithWhite:0 alpha:1].CGColor,
                           (id)[UIColor colorWithWhite:0 alpha:0.6f].CGColor,
                           (id)[UIColor colorWithWhite:0 alpha:0].CGColor, nil];
    [self.gradientView.layer addSublayer:liveGradient];
    
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
        self.navigationItem.hidesBackButton = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    CGSize maxSize = CGSizeMake(self.descLabel.frame.size.width, CGFLOAT_MAX);
    CGSize size = [self.descLabel.text sizeWithFont:self.descLabel.font constrainedToSize:maxSize];
    CGRect frame = self.descLabel.frame;
    frame.size.height = size.height;
    self.descLabel.frame = frame;
    
    [self.tableView addObserver:self forKeyPath:@"contentOffset"
                        options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld)
                        context:NULL];
}

#pragma mark - Actions

- (IBAction)setFavorite:(UIButton*)sender
{
    self.show.favorite = !self.show.favorite;
    sender.selected = self.show.favorite;
}

- (IBAction)setReminder:(UIButton*)sender
{
    self.show.remind = !self.show.remind;
    sender.selected = self.show.remind;
}

- (IBAction)openDetailView:(UIButton*)sender
{
    if(self.tableView.contentOffset.y <= -self.view.bounds.size.height+showHeaderHeight)
    {
        self.tableView.scrollEnabled = YES;
        [UIView animateWithDuration:0.3f animations:^
        {
            self.tableView.contentOffset = CGPointMake(0, 0);
            sender.transform = CGAffineTransformMakeRotation(0);
            [sender setImage:[UIImage imageNamed:@"toolbar-disclose"] forState:UIControlStateNormal];
        }];
    }
    else
    {
        self.tableView.scrollEnabled = NO;
        [UIView animateWithDuration:0.3f animations:^
        {
            self.tableView.contentOffset = CGPointMake(0, -self.view.bounds.size.height+showHeaderHeight);
            sender.transform = CGAffineTransformMakeRotation(M_PI);
            [sender setImage:[UIImage imageNamed:@"toolbar-disclose-up"] forState:UIControlStateNormal];
        }];
    }
}

- (IBAction)email:(UIButton*)sender
{
    MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
    controller.mailComposeDelegate = self;
    [controller setToRecipients:[NSArray arrayWithObject:self.show.email]];
    [self presentModalViewController:controller animated:YES];
    
    CGAffineTransform transform = CGAffineTransformMakeScale(0.8f, 0.8f);
    
    [UIView animateWithDuration:0.3f animations:^
    {
        self.navigationController.view.transform = transform;
    }];
}
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self dismissModalViewControllerAnimated:YES];
    
    CGAffineTransform transform = CGAffineTransformMakeScale(0.8f, 0.8f);
    self.navigationController.view.transform = transform;
    
    [UIView animateWithDuration:0.3f animations:^
    {
        self.navigationController.view.transform = CGAffineTransformIdentity;
    }];
}

- (IBAction)phone:(UIButton*)sender
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", self.show.phone]];
    [UIApplication.sharedApplication openURL:url];
}

- (NSIndexPath*)tableView:(UITableView*)tableView willSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        if([tableView.indexPathForSelectedRow isEqual:indexPath])
        {
            TWSplitViewContainer *splitViewContainer = (TWSplitViewContainer*)self.navigationController.parentViewController;
            
            CGRect frame = splitViewContainer.modalFlyout.frame;
            frame.origin.x -= frame.size.width;
            
            [UIView animateWithDuration:0.3f animations:^{
                splitViewContainer.modalFlyout.frame = frame;
                splitViewContainer.modalBlackground.alpha = 0;
            } completion:^(BOOL fin){
                splitViewContainer.modalContainer.hidden = YES;
                splitViewContainer.modalBlackground.alpha = 1;
            }];
            
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
        else
        {
            TWSplitViewContainer *splitViewContainer = (TWSplitViewContainer*)self.navigationController.parentViewController;
            UINavigationController *modalController = (UINavigationController*)splitViewContainer.modalController;
            TWEpisodeViewController *episodeController = (TWEpisodeViewController*)modalController.topViewController;
            
            Episode *episode = [self.fetchedEpisodesController objectAtIndexPath:indexPath];
            episodeController.episode = episode;
            
            if(splitViewContainer.modalContainer.hidden)
            {
                splitViewContainer.modalBlackground.alpha = 0;
                splitViewContainer.modalContainer.hidden = NO;
                
                CGRect frame = splitViewContainer.modalFlyout.frame;
                frame.origin.x += frame.size.width;
                
                [UIView animateWithDuration:0.3f animations:^{
                    splitViewContainer.modalBlackground.alpha = 1;
                    splitViewContainer.modalFlyout.frame = frame;
                }];
            }
            
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
        return nil;
    }
    
    return indexPath;
}

#pragma mark - Table

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    CGPoint newPoint = [[change valueForKey:NSKeyValueChangeNewKey] CGPointValue];
    
    if(object == self.tableView)
    {
        CGRect frame = self.headerView.frame;
        if(newPoint.y < 0)
        {
            frame.origin.y = newPoint.y;
            frame.size.height = ceilf(showHeaderHeight-newPoint.y);
            
        }
        else
        {
            frame.origin.y = 0;
            frame.size.height = showHeaderHeight;
        }
        
        self.headerView.frame = frame;
        self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(frame.size.height, 0, 0, 1);
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return self.fetchedEpisodesController.sections.count;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo>sectionInfo = self.fetchedEpisodesController.sections[section];
    return sectionInfo.numberOfObjects;
}

- (UITableViewCell *)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSString *identifier = @"episodeCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];

    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

#pragma mark - Configure

- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    if([cell.reuseIdentifier isEqualToString:@"episodeCell"])
    {
        Episode *episode = [self.fetchedEpisodesController objectAtIndexPath:indexPath];
        TWEpisodeCell *episodeCell = (TWEpisodeCell*)cell;
        episodeCell.episode = episode;
    }
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController*)fetchedEpisodesController
{
    if(_fetchedEpisodesController != nil)
        return _fetchedEpisodesController;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Episode" inManagedObjectContext:self.show.managedObjectContext];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"published" ascending:NO];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"show = %@", self.show];
    
    [fetchRequest setFetchBatchSize:10];
    [fetchRequest setEntity:entity];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    [fetchRequest setPredicate:predicate];
    
    NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.show.managedObjectContext sectionNameKeyPath:nil cacheName:[NSString stringWithFormat:@"EpisodesOf%@", self.show.title]];
    controller.delegate = self;
    self.fetchedEpisodesController = controller;
    
	NSError *error = nil;
	if(![self.fetchedEpisodesController performFetch:&error])
    {
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	}
    
    return _fetchedEpisodesController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController*)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController*)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    if(controller == self.fetchedEpisodesController)
    {
        switch(type)
        {
            case NSFetchedResultsChangeInsert:
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            case NSFetchedResultsChangeDelete:
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                break;
        }
    }
}

- (void)controller:(NSFetchedResultsController*)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath*)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath*)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    if(controller == self.fetchedEpisodesController)
    {
        switch(type)
        {
            case NSFetchedResultsChangeInsert:
                [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            case NSFetchedResultsChangeDelete:
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            case NSFetchedResultsChangeUpdate:
                [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
                break;
                
            case NSFetchedResultsChangeMove:
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
        }
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController*)controller
{
    [self.tableView endUpdates];
}

#pragma mark - Settings

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
        return YES;
    else
        return (interfaceOrientation == UIInterfaceOrientationMaskPortrait);
}

- (NSUInteger)supportedInterfaceOrientations
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
        return UIInterfaceOrientationMaskAll;
    else
        return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Leave

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"episodeDetail"])
    {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Episode *episode = [self.fetchedEpisodesController objectAtIndexPath:indexPath];
        [segue.destinationViewController setEpisode:episode];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.tableView removeObserver:self forKeyPath:@"contentOffset"];
    
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
    self.fetchedEpisodesController = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
