//
//  TWMainViewController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 12/29/12.
//  Copyright (c) 2012 Stuart Moore. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "TWMainViewController.h"

#import "TWShowViewController.h"
#import "TWEpisodeViewController.h"
#import "TWEpisodeCell.h"

@interface TWMainViewController ()
- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath;
@end

@implementation TWMainViewController

- (void)awakeFromNib
{
    /* 
     TODO: iPad

     Don't clear selection, and link to episode container view.
     
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
        self.clearsSelectionOnViewWillAppear = NO;
    */
    
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // TODO: Save state?
    sectionVisible = TWSectionShows;
    
    /*
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
    */
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView addObserver:self forKeyPath:@"contentOffset"
                        options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld)
                        context:NULL];
}

/*
- (void)insertNewObject:(id)sender
{
    NSManagedObjectContext *context = [self.fetchedEpisodesController managedObjectContext];
    NSEntityDescription *entity = [[self.fetchedEpisodesController fetchRequest] entity];
    NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
    
    // If appropriate, configure the new managed object.
    // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
    [newManagedObject setValue:[NSDate date] forKey:@"timeStamp"];
    
    // Save the context.
    NSError *error = nil;
    if (![context save:&error])
    {
         // Replace this implementation with code to handle the error appropriately.
         // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}
*/

#pragma mark - Actions

- (void)switchVisibleSection:(UIButton*)sender
{
    sectionVisible = sender.tag;
    [self.tableView reloadData];
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
}

- (void)tableView:(UITableView*)tableView didSelectColumn:(int)column AtIndexPath:(NSIndexPath*)indexPath
{
    NSDictionary *sender = @{@"section":@(indexPath.section), @"row":@(indexPath.row), @"column":@(column)};
    [self performSegueWithIdentifier:@"showDetail" sender:sender];
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"episodeDetail"])
    {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSManagedObject *object = [self.fetchedEpisodesController objectAtIndexPath:indexPath];
        [segue.destinationViewController setDetailItem:object];
    }
    else if([segue.identifier isEqualToString:@"showDetail"])
    {
        //TWShowsCell *showCell = (TWShowsCell*)[self.tableView cellForRowAtIndexPath:self.tableView.indexPathForSelectedRow];
        //int index = [sender[@"row"] intValue]*showCell.columns + [sender[@"column"] intValue];
        //NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:[sender[@"section"] intValue]];
        
        //NSManagedObject *show = [self.fetchedShowsController objectAtIndexPath:indexPath];
        //[segue.destinationViewController setShow:show];
        
        [segue.destinationViewController setManagedObjectContext:self.managedObjectContext];
    }
}

#pragma mark - Table View

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    
    CGPoint newPoint = [[change valueForKey:NSKeyValueChangeNewKey] CGPointValue];
    
    if(object == self.tableView)
    {
        if(newPoint.y < 0)
        {
            CGRect frame = self.headerView.frame;
            frame.origin.y = newPoint.y;
            frame.size.height = ceilf(headerHeight-newPoint.y);
            self.headerView.frame = frame;
            
            self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(frame.size.height+28, 0, 0, 1);
            self.sectionHeader.layer.shadowOpacity = 0;
        }
        else
        {
            CGRect frame = self.headerView.frame;
            frame.origin.y = 0;
            frame.size.height = headerHeight;
            self.headerView.frame = frame;
            
            self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(headerHeight+28, 0, 0, 1);
            self.sectionHeader.layer.shadowOpacity = newPoint.y-headerHeight < 0 ? 0 : (newPoint.y-headerHeight)/20;
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    if(sectionVisible == TWSectionEpisodes)
        return self.fetchedEpisodesController.sections.count;
    else if(sectionVisible == TWSectionShows)
        return self.fetchedShowsController.sections.count;
    
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo>sectionInfo;
    
    if(sectionVisible == TWSectionEpisodes)
    {
        sectionInfo = self.fetchedEpisodesController.sections[section];
        
        return sectionInfo.numberOfObjects;
    }
    else if(sectionVisible == TWSectionShows)
    {
        sectionInfo = self.fetchedShowsController.sections[section];
        int num = sectionInfo.numberOfObjects;
        
        return ceil(num/3.0);
    }
    
    return 0;
}

- (float)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
    if(section == 0)
        return 28;
    
    return 0;
}

- (float)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if(sectionVisible == TWSectionEpisodes)
        return 62;
    else if(sectionVisible == TWSectionShows)
        return 102;

    return 0;
}

// TODO: Add white line to top of shows section, bottom of episodes section

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
    if(section == 0)
    {
        float width = tableView.frame.size.width;
        self.sectionHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 28)];
        self.sectionHeader.backgroundColor = [UIColor colorWithWhite:244/255.0 alpha:1];
        
        UIImage *buttonUpBackground = [[UIImage imageNamed:@"main-header-button-up.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:11];
        UIImage *buttonDownBackground = [[UIImage imageNamed:@"main-header-button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:11];
        
        UIButton *episodesButton = [UIButton buttonWithType:UIButtonTypeCustom];
        episodesButton.frame = CGRectMake(1, 2, 158, 24);
        [episodesButton setTitle:@"EPISODES" forState:UIControlStateNormal];
        episodesButton.tag = TWSectionEpisodes;
        episodesButton.selected = (sectionVisible == episodesButton.tag);
        [episodesButton addTarget:self action:@selector(switchVisibleSection:) forControlEvents:UIControlEventTouchUpInside];
        [episodesButton setTitleShadowColor:[UIColor colorWithWhite:0 alpha:0.25f] forState:UIControlStateSelected];
        [episodesButton setTitleShadowColor:[UIColor colorWithWhite:1 alpha:0.25f] forState:UIControlStateNormal];
        [episodesButton setBackgroundImage:buttonDownBackground forState:UIControlStateHighlighted];
        [episodesButton setBackgroundImage:buttonDownBackground forState:UIControlStateSelected];
        [episodesButton setBackgroundImage:buttonUpBackground forState:UIControlStateNormal];
        episodesButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
        [episodesButton setTitleColor:[UIColor colorWithWhite:132/255.0 alpha:1] forState:UIControlStateNormal];
        [episodesButton setTitleColor:[UIColor colorWithWhite:244/255.0 alpha:1] forState:UIControlStateSelected];
        [episodesButton.titleLabel setFont:[UIFont boldSystemFontOfSize:14]];
        [self.sectionHeader addSubview:episodesButton];
        
        UIButton *showsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        showsButton.frame = CGRectMake(161, 2, 158, 24);
        [showsButton setTitle:@"SHOWS" forState:UIControlStateNormal];
        showsButton.tag = TWSectionShows;
        showsButton.selected = (sectionVisible == showsButton.tag);
        [showsButton addTarget:self action:@selector(switchVisibleSection:) forControlEvents:UIControlEventTouchUpInside];
        [showsButton setTitleShadowColor:[UIColor colorWithWhite:1 alpha:0.25f] forState:UIControlStateNormal];
        [showsButton setBackgroundImage:buttonDownBackground forState:UIControlStateHighlighted];
        [showsButton setBackgroundImage:buttonDownBackground forState:UIControlStateSelected];
        [showsButton setBackgroundImage:buttonUpBackground forState:UIControlStateNormal];
        showsButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
        [showsButton setTitleColor:[UIColor colorWithWhite:132/255.0 alpha:1] forState:UIControlStateNormal];
        [showsButton setTitleColor:[UIColor colorWithWhite:244/255.0 alpha:1] forState:UIControlStateSelected];
        [showsButton setTitleShadowColor:[UIColor colorWithWhite:0 alpha:0.25f] forState:UIControlStateSelected];
        [showsButton.titleLabel setFont:[UIFont boldSystemFontOfSize:14]];
        [self.sectionHeader addSubview:showsButton];
        
        UILabel *topLine = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 1)];
        topLine.backgroundColor = [UIColor colorWithWhite:1 alpha:1];
        [self.sectionHeader addSubview:topLine];
        
        UILabel *botLine = [[UILabel alloc] initWithFrame:CGRectMake(0, 27, 320, 1)];
        botLine.backgroundColor = [UIColor colorWithWhite:222/255.0 alpha:1];
        [self.sectionHeader addSubview:botLine];
        
        float offest = self.tableView.contentOffset.y-headerHeight;
        self.sectionHeader.layer.shadowOpacity = offest < 0 ? 0 : offest/20;
        self.sectionHeader.layer.shadowColor = [[UIColor colorWithWhite:0 alpha:0.5f] CGColor];
        self.sectionHeader.layer.shadowOffset = CGSizeMake(0, 3);
        self.sectionHeader.layer.shadowRadius = 3;
        
        return self.sectionHeader;
    }
    return nil;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSString *identifier = (sectionVisible == TWSectionEpisodes) ? @"episodeCell" : @"showsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if(!cell && [identifier isEqualToString:@"episodeCell"])
        cell = [[TWEpisodeCell alloc] initWithStyle:NO reuseIdentifier:identifier];
    else if(!cell && [identifier isEqualToString:@"showsCell"])
        cell = [[TWShowsCell alloc] initWithStyle:NO reuseIdentifier:identifier];
    
    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

#pragma mark - Configure

- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    if([cell.reuseIdentifier isEqualToString:@"episodeCell"])
    {
        NSManagedObject *object = [self.fetchedEpisodesController objectAtIndexPath:indexPath];
        TWEpisodeCell *episodeCell = (TWEpisodeCell*)cell;
        
        episodeCell.albumArt.image = [UIImage imageNamed:@"aaa600.jpg"];
        episodeCell.titleLabel.text = [[object valueForKey:@"timeStamp"] description];
        episodeCell.subtitleLabel.text = @"subtitle";
    }
    else if([cell.reuseIdentifier isEqualToString:@"showsCell"])
    {
        // TODO: CACHE THIS MUCHERFUCKER!
        TWShowsCell *showsCell = (TWShowsCell*)cell;
        
        showsCell.spacing = 14;
        showsCell.size = 88;
        showsCell.columns = 3;
        showsCell.delegate = self;
        showsCell.table = self.tableView;
        showsCell.indexPath = indexPath;
        
        id <NSFetchedResultsSectionInfo>sectionInfo = self.fetchedShowsController.sections[indexPath.section];
        int num = sectionInfo.numberOfObjects;
        int columns = showsCell.columns;
        
        NSMutableArray *shows = [NSMutableArray array];
        for(int column = 0; column < columns; column++)
        {
            int index = indexPath.row*columns + column;
            if(num > index)
            {
                if(column == 0)
                    [shows addObject:[UIImage imageNamed:@"aaa600.jpg"]];
                else if(column == 1)
                    [shows addObject:[UIImage imageNamed:@"byb600.jpg"]];
                else if(column == 2)
                    [shows addObject:[UIImage imageNamed:@"fr600.jpg"]];
                
                //NSIndexPath *columnedIndexPath = [NSIndexPath indexPathForRow:index inSection:indexPath.section];
                //NSManagedObject *show = [self.fetchedShowsController objectAtIndexPath:columnedIndexPath];
                //[shows addObject:show];
            }
        }
        [showsCell setShows:shows];
    }
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController*)fetchedEpisodesController
{
    if(_fetchedEpisodesController != nil)
        return _fetchedEpisodesController;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:10];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedEpisodesController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Master"];
    aFetchedEpisodesController.delegate = self;
    self.fetchedEpisodesController = aFetchedEpisodesController;
    
	NSError *error = nil;
	if(![self.fetchedEpisodesController performFetch:&error])
    {
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	}
    
    return _fetchedEpisodesController;
}
- (NSFetchedResultsController*)fetchedShowsController
{
    if(_fetchedShowsController != nil)
        return _fetchedShowsController;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:15];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedShowsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Master"];
    aFetchedShowsController.delegate = self;
    self.fetchedShowsController = aFetchedShowsController;
    
	NSError *error = nil;
	if(![self.fetchedShowsController performFetch:&error])
    {
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	}
    
    return _fetchedShowsController;
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

#pragma mark - Kill

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.tableView removeObserver:self forKeyPath:@"contentOffset"];
}

@end
