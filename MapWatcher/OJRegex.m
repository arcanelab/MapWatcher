//
//  OJRegex.m
//  MapWatcher
//
//  Created by Zoltán Majoros on 30/Aug/2015.
//  Copyright © 2016 Zoltán Majoros. All rights reserved.
//

#import "NSString+Matcher.h"
#import "OJRegex.h"

@implementation OJRegex

- (NSString *)getMapNameFromString:(NSString *)html
{
    NSString *regex = @"id=\"HTML_curr_map\">\\s*(.*)\\s*<";
    return [html firstMatchedGroupWithRegex:regex];
}

- (NSString *)getImageURL:(NSString *)html
{
    NSString *regex = @"id=\"HTML_map_ss_img\">\\s*<img src=\"(.*)\"\\s*alt";
    return [html firstMatchedGroupWithRegex:regex];
}

- (NSString *)getNumberOfPlayers:(NSString *)html
{
    NSString *regex = @"<span id=\"HTML_num_players\">(\\d+)<\\/span>";
    return [html firstMatchedGroupWithRegex:regex];
}

@end
