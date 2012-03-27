//
//  TrackPointsDAO.m
//  trail
//
//  Created by Jacek Marchwicki on 12/14/11.
//  Copyright (c) 2011 AppUnite.com. All rights reserved.
//

#import "RMTrackPointsDAO.h"
#import "AUOpenGISParser.h"

static RMTrackPointsDAO *sharedTrackPoints;

@implementation RMTrackPointsDAO

+ (RMTrackPointsDAO *)sharedRMTrackPointsDAO
{
    if (!sharedTrackPoints) {
        sharedTrackPoints = [[RMTrackPointsDAO alloc] init];
    }
    return sharedTrackPoints;
}

#pragma mark delegate

- (void) callNewData {
    for (id<RMTrackPointsDAODelegate> delegate in _delegates) {
        [delegate trackPointsDAONewData:self];
    }
}

- (void) addDelegate: (id<RMTrackPointsDAODelegate>) delegate {
    [_delegates addObject:delegate];
}
- (void) removeDelegate: (id<RMTrackPointsDAODelegate>) delegate {
    [_delegates removeObject:delegate];
}

#pragma mark loading from string

- (void) loadedFromString: (NSMutableArray *) trackPoints {
    [_trackPoints release];
    _trackPoints = nil;
    
    _trackPoints = [trackPoints retain];
    NSLog(@"finished parsing: %d read", [trackPoints count]);
    [self callNewData];
}

- (void) loadFromStringAsync: (NSString *) data {
    NSArray * trackPoints = [AUOpenGISParser parseLineString:data];
    NSMutableArray * mutableTrackPoints = [trackPoints mutableCopy];
    [self performSelectorOnMainThread:@selector(loadedFromString:) withObject:mutableTrackPoints waitUntilDone:false];
    [mutableTrackPoints release];
}

- (void) loadFromString: (NSString*) data {
    NSLog(@"parsing track");
    [NSThread detachNewThreadSelector:@selector(loadFromStringAsync:) toTarget:self withObject:data];
}

- (void) clearPoints {
    [_trackPoints release];
    _trackPoints = nil;
    
    NSArray *markers = [NSArray arrayWithObjects:_startingMarker, _stopMarker, nil];
    
    for (id<RMTrackPointsDAODelegate> delegate in _delegates) {
        if ([delegate respondsToSelector:@selector(removeMarkers:)]) {
            [delegate removeMarkers:markers];
        }
    } 
    [_startingMarker release], _startingMarker = nil;
    [_stopMarker release], _stopMarker = nil;
    
    _trackPoints = [[NSMutableArray alloc] init];
    [self callNewData];
}

- (void) addPoint:(AUOpenGISCoordinate *) coordinate {
    [_trackPoints addObject:coordinate];
    [self callNewData];
}

- (NSArray *)trackPoints {
    return _trackPoints;
}

- (void) setStartingPoint:(CLLocationCoordinate2D)location
{
    if (!_startingMarker) {
        UIImage* markerImage = [UIImage imageNamed:@"marker_start"];
        
        RMMarker *newMarker = [[RMMarker alloc] initWithUIImage:markerImage anchorPoint:CGPointMake(0.5, 1.0)];
        for (id<RMTrackPointsDAODelegate> delegate in _delegates) {
            [delegate setStartingMarker:newMarker atLatLong:location];
        }        
        [_startingMarker release];
        _startingMarker = newMarker;
    }
}

- (void) setStopPoint:(CLLocationCoordinate2D)location
{
    if (!_stopMarker) {
        UIImage* markerImage = [UIImage imageNamed:@"marker_end"];
        
        RMMarker *newMarker = [[RMMarker alloc] initWithUIImage:markerImage anchorPoint:CGPointMake(0.5, 1.0)];
        for (id<RMTrackPointsDAODelegate> delegate in _delegates) {
            [delegate setStopMarker:newMarker atLatLong:location];
        } 
        [_stopMarker release];
        _stopMarker = newMarker;
    }
}


#pragma mark init

- (id)init {
    self = [super init];
    if (self) {
        _trackPoints = [[NSMutableArray alloc] init];
        _delegates = [[NSMutableArray alloc] init];
    }
    return self;
}   

- (void)dealloc {
    [_trackPoints release];
    [_delegates release];
}


@end
