//
//  TWEpisodeViewController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 12/29/12.
//  Copyright (c) 2012 Stuart Moore. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "TWEpisodeViewController.h"
#import "TWSegmentedButton.h"
#import "TWPlayButton.h"

#import "Episode.h"
#import "Enclosure.h"

@implementation TWEpisodeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    
    [self configureView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(updateProgress:)
                                               name:@"enclosureDownloadDidReceiveData"
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(updateProgress:)
                                               name:@"enclosureDownloadDidFinish"
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(updateProgress:)
                                               name:@"enclosureDownloadDidFail"
                                             object:nil];
}

#pragma mark - Episode

- (void)setEpisode:(Episode*)episode
{
    if(_episode != episode)
    {
        _episode = episode;
        [self configureView];
    }
}

- (void)configureView
{
    if(self.episode)
    {
        self.title = self.episode.title;
        self.posterView.image = self.episode.poster.image;
        self.dateLabel.text = self.episode.publishedString;
        self.timeLabel.text = self.episode.durationString;
        self.numberLabel.text = @(self.episode.number).stringValue;
        self.guestsLabel.text = self.episode.guests;
        self.descLabel.text = self.episode.desc;
        
        self.playButton.percentage = (self.episode.duration != 0) ? (float)self.episode.lastTimecode/(float)self.episode.duration : 0;
   
        
        self.segmentedButton.buttonState = self.episode.downloadedEnclosures ? TWButtonSegmentDelete : TWButtonSegmentDownload;
        
        self.segmentedButton.listenEnabled = YES;
        self.segmentedButton.watchEnabled = YES;
        
        [self.segmentedButton addTarget:self action:@selector(watchPressed:) forButton:TWButtonSegmentWatch];
        [self.segmentedButton addTarget:self action:@selector(listenPressed:) forButton:TWButtonSegmentListen];
        [self.segmentedButton addTarget:self action:@selector(downloadPressed:) forButton:TWButtonSegmentDownload];
        [self.segmentedButton addTarget:self action:@selector(cancelPressed:) forButton:TWButtonSegmentCancel];
        [self.segmentedButton addTarget:self action:@selector(deletePressed:) forButton:TWButtonSegmentDelete];
    }
}

#pragma mark - Actions

- (void)watchPressed:(TWSegmentedButton*)sender
{
}
- (void)listenPressed:(TWSegmentedButton*)sender
{
}

- (void)downloadPressed:(TWSegmentedButton*)sender
{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Choose Download Quality"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:nil];
    
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"quality" ascending:NO];
    NSArray *enclosures = [self.episode.enclosures sortedArrayUsingDescriptors:@[descriptor]];
    
    for(Enclosure *enclosure in enclosures)
       [sheet addButtonWithTitle:[NSString stringWithFormat:@"%@ - %@", enclosure.title, enclosure.subtitle]];
    
    [sheet addButtonWithTitle:@"Cancel"];
    sheet.cancelButtonIndex = sheet.numberOfButtons - 1;
    
    [sheet showFromRect:self.segmentedButton.downloadButton.frame inView:self.segmentedButton animated:YES];
}
- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == -1 || buttonIndex >= actionSheet.numberOfButtons-1)
        return;
    
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"quality" ascending:NO];
    NSArray *enclosures = [self.episode.enclosures sortedArrayUsingDescriptors:@[descriptor]];
    Enclosure *enclosure = enclosures[buttonIndex];
    [self.episode downloadEnclosure:enclosure];
    
    self.segmentedButton.progress = 0;
    self.segmentedButton.buttonState = TWButtonSegmentCancel;
}

- (void)updateProgress:(NSNotification*)notification
{
    Enclosure *enclosure = notification.object;
    
    if(enclosure.episode != self.episode)
        return;
    
    if([notification.name isEqualToString:@"enclosureDownloadDidReceiveData"])
    {
        if(self.segmentedButton.buttonState != TWButtonSegmentCancel)
            self.segmentedButton.buttonState = TWButtonSegmentCancel;
        
        self.segmentedButton.progress = (enclosure.expectedLength != 0)? enclosure.downloadedLength/(float)enclosure.expectedLength : 0;
    }
    else if([notification.name isEqualToString:@"enclosureDownloadDidFinish"])
    {
        self.segmentedButton.buttonState = TWButtonSegmentDelete;
    }
    else if([notification.name isEqualToString:@"enclosureDownloadDidFail"])
    {
        self.segmentedButton.buttonState = TWButtonSegmentDownload;
    }
}

- (void)cancelPressed:(TWSegmentedButton*)sender
{
    [self.episode cancelDownloads];
}

- (void)deletePressed:(TWSegmentedButton*)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete"
                                                    message:@"Are you sure you want to delete this download?"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Delete", nil];
    [alert show];
}
- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 1 && [alertView.title isEqualToString:@"Delete"])
    {
        [self.episode deleteDownloads];
        self.segmentedButton.buttonState = TWButtonSegmentDownload;
    }
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

#pragma mark - Kill

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"enclosureDownloadDidReceiveData" object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"enclosureDownloadDidFinish" object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"enclosureDownloadDidFail" object:nil];
    
    [super viewWillDisappear:animated];
}

@end
