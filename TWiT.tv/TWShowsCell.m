//
//  TWShowsCell.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/1/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWShowsCell.h"
#import "Show.h"

@implementation TWShowsCell

- (CGRect)frameForColumn:(NSInteger)column
{
    CGFloat x = self.spacing + column * (self.size + self.spacing);
    return CGRectMake(x, self.spacing/2, self.size, self.size);
}

- (void)setShows:(NSArray*)shows
{
    if([_shows isEqualToArray:shows])
        return;
    
    _shows = shows;
}

- (void)setIcons:(UIImage*)icons
{
    _icons = icons;
    
    [self setNeedsDisplayInRect:self.bounds];
}

#pragma mark - Draw

- (void)layoutSubviews
{
    [super layoutSubviews];
  
    if(self.icons && self.icons.size.width == self.frame.size.width)
    {
        [self setNeedsDisplayInRect:self.bounds];
        return;
    }
    
    UIGraphicsBeginImageContextWithOptions(self.frame.size, YES, UIScreen.mainScreen.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillRect(context, self.bounds);
    
    for(NSInteger column = 0, showsCount = self.shows.count; column < showsCount; column++)
    {
        CGContextSetFillColorWithColor(context, self.tintColor.CGColor);
        CGRect frame = [self frameForColumn:column];
        
        CGContextSetFillColorWithColor(context, self.tintColor.CGColor);
        CGContextFillRect(context, frame);
        
        [[self.shows[column] title] drawInRect:frame withAttributes:@{NSForegroundColorAttributeName: UIColor.whiteColor,
                                                                      NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]}];
    }
    
    self.icons = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self setNeedsDisplayInRect:self.bounds];
    
    __block NSMutableArray *albumArtPathes = [NSMutableArray array];
    __block NSMutableArray *showTitles = [NSMutableArray array];
    __weak TWShowsCell *weak = self;
    
    for(Show *show in self.shows)
    {
        [albumArtPathes addObject:show.albumArt.path.copy];
        [showTitles addObject:show.title.copy];
    }
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
    dispatch_async(queue, ^{
        UIGraphicsBeginImageContextWithOptions(weak.frame.size, YES, UIScreen.mainScreen.scale);
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
        CGContextFillRect(context, weak.bounds);
        weak.icons = UIGraphicsGetImageFromCurrentImageContext();
        
        weak.accessibleElements = [NSMutableArray array];
        
        for(NSInteger column = 0, showsCount = weak.shows.count; column < showsCount; column++)
        {
            CGRect frame = [weak frameForColumn:column];
            
            if(column < albumArtPathes.count && column < showTitles.count && [UIImage imageWithContentsOfFile:albumArtPathes[column]])
            {
                UIImage *image = [UIImage imageWithContentsOfFile:albumArtPathes[column]];
                [image drawInRect:frame];
                
                UIAccessibilityElement *element = [[UIAccessibilityElement alloc] initWithAccessibilityContainer:self];
                element.isAccessibilityElement = YES;
                element.accessibilityFrame = frame;
                element.accessibilityLabel = showTitles[column];
                element.accessibilityHint = @"Opens the show view.";
                [weak.accessibleElements addObject:element];
            }
        }
        
        weak.icons = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [weak didDrawIcons];
        });
    });
}
- (void)didDrawIcons
{
    [self.delegate showsCell:self didDrawIconsAtIndexPath:self.indexPath];
    [self setNeedsDisplayInRect:self.bounds];
}

- (void)drawRect:(CGRect)rect
{
    [self.icons drawInRect:self.bounds];
}

#pragma mark - Touches

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
    UITouch *touch = touches.anyObject;
    CGPoint location = [touch locationInView:self];
    
    for(NSInteger column = 0, showsCount = self.shows.count; column < showsCount; column++)
    {
        if(CGRectContainsPoint([self frameForColumn:column], location))
        {   
            [self.delegate tableView:self.table didSelectColumn:column AtIndexPath:self.indexPath];
            break;
        }
    }
}

#pragma mark - Accessibility

- (BOOL)isAccessibilityElement
{
    return NO;
}

- (NSInteger)accessibilityElementCount
{
    return self.accessibleElements.count;
}

- (id)accessibilityElementAtIndex:(NSInteger)index
{
    UIAccessibilityElement *element = [self.accessibleElements objectAtIndex:index];
    CGRect rect = element.accessibilityFrame;
    rect.origin.y = 7;
    element.accessibilityFrame = [self.window convertRect:rect fromView:self];
    return element;
}

- (NSInteger)indexOfAccessibilityElement:(id)element
{
    return [self.accessibleElements indexOfObject:element];
}

- (NSArray*)accessibleElements
{
    return _accessibleElements;
}

@end
