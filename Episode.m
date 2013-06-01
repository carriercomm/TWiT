//
//  Episode.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/3/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "Episode.h"
#import "Enclosure.h"
#import "Show.h"

@implementation Episode

@dynamic desc, downloadedQuality, downloadState, duration, guests, lastTimecode, number;
@dynamic published, title, watched, website, enclosures, poster, show;

@synthesize downloadedEnclosures = _downloadedEnclosures;

- (NSString*)durationString
{
    NSInteger interval = self.duration;
    NSInteger seconds = interval % 60;
    NSInteger minutes = (interval / 60) % 60;
    NSInteger hours = (interval / 3600);
    
    return [NSString stringWithFormat:@"%01i:%02i:%02i", hours, minutes, seconds];
}

- (NSString*)publishedString
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"MMM dd, yyyy";
    
    return [df stringFromDate:self.published];
}

#pragma mark - Episodes

- (NSSet*)enclosuresForType:(enum TWType)type
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type == %d", type];
    NSSet *enclosures = [self.enclosures filteredSetUsingPredicate:predicate];
    
    if(enclosures.count == 0)
        return nil;
    
    return enclosures;
}
- (Enclosure*)enclosureForQuality:(TWQuality)quality
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"quality == %d", quality];
    NSSet *enclosures = [self.enclosures filteredSetUsingPredicate:predicate];
    
    if(enclosures.count == 0)
        return nil;
    
    return enclosures.anyObject;
}
- (Enclosure*)enclosureForType:(enum TWType)type andQuality:(enum TWQuality)quality
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type == %d AND quality == %d", type, quality];
    NSSet *enclosures = [self.enclosures filteredSetUsingPredicate:predicate];
    
    if(enclosures.count == 0)
        return nil;
    
    return enclosures.anyObject;
    
    // TODO: Load all enclosures of type and less than quality, sorted by quality and if downloaded. Choose top.
}

#pragma mark - Download

- (void)downloadEnclosure:(Enclosure*)enclosure
{
    [enclosure download];
}

- (void)cancelDownloads
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"downloadConnection != nil"];
    NSSet *enclosures = [self.enclosures filteredSetUsingPredicate:predicate];
    [enclosures makeObjectsPerformSelector:@selector(cancelDownload)];
}

- (NSSet*)downloadedEnclosures
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"path != nil"];
    NSSet *enclosures = [self.enclosures filteredSetUsingPredicate:predicate];
    
    if(enclosures.count == 0)
        return nil;
        
    return enclosures;
}
- (void)deleteDownloads
{
    [self.downloadedEnclosures makeObjectsPerformSelector:@selector(deleteDownload)];
}

#pragma mark - iCloud

- (void)setWatched:(BOOL)watched
{
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
    
    NSString *key = [NSString stringWithFormat:@"%@:%@:%@", self.show.title, self.title, @(self.number)];
    NSMutableDictionary *episode = [[store dictionaryForKey:key] mutableCopy];
    
    if(!episode)
    {
        episode = [NSMutableDictionary dictionary];
        [episode setValue:self.published forKey:@"pubDate"];
        [episode setValue:@(self.lastTimecode) forKey:@"timecode"];
    }
    
    [episode setValue:@(watched) forKey:@"watched"];
    [store setDictionary:episode forKey:key];
    
    NSLog(@"episode %@", episode);
    NSLog(@"%@", store.dictionaryRepresentation);
    
    [self willChangeValueForKey:@"watched"];
    [self setPrimitiveValue:@(watched) forKey:@"watched"];
    [self didChangeValueForKey:@"watched"];
}

#pragma mark - Notifications

- (void)updatePoster:(NSNotification*)notification
{
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"MPMoviePlayerThumbnailImageRequestDidFinishNotification" object:nil];

    UIImage *poster = notification.userInfo[@"MPMoviePlayerThumbnailImageKey"];
    
    if(poster)
        [self.poster setImage:poster];
}

@end
