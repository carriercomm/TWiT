//
//  Enclosure.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/3/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "Feed.h"

@class Episode;

@interface Enclosure : NSManagedObject <NSURLConnectionDelegate>

@property (nonatomic, strong) NSString *title, *subtitle;
@property (nonatomic, strong) NSString *url, *path;
@property (nonatomic) TWQuality quality;
@property (nonatomic) TWType type;
@property (nonatomic, strong) Episode *episode;

@property (nonatomic, strong) NSFileHandle *downloadingFile;
@property (nonatomic) long long expectedLength, downloadedLength;
@property (nonatomic, strong) NSString *downloadPath;
@property (nonatomic, strong) NSURLConnection *downloadConnection;
@property (nonatomic) UIBackgroundTaskIdentifier downloadTaskID;

- (void)download;
- (void)cancelDownload;
- (void)closeDownload;
- (void)deleteDownload;

@end
