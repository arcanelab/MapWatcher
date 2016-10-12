//
//  OJRegex.h
//  MapWatcher
//
//  Created by Zoltán Majoros on 30/Aug/2015.
//  Copyright © 2016 Zoltán Majoros. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef OJRegex_h
#define OJRegex_h

@interface OJRegex : NSObject

- (NSString *)getMapNameFromString:(NSString *)html;
- (NSString *)getImageURL:(NSString *)html;
- (NSString *)getNumberOfPlayers:(NSString *)html;

@end

#endif /* OJRegex_h */
