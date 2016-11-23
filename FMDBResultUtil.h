//
//  FMDBResultUtil.h
//  DPBase
//
//  Created by xupeng on 16/4/4.
//  Copyright © 2016年 Yihua Cao. All rights reserved.
//

#import <Foundation/Foundation.h>
@class FMResultSet;

@interface FMDBResultUtil : NSObject
+(id)toObject:(Class)cla from:(FMResultSet*)set;
+(NSMutableArray*)toObjectArray:(Class)cla from:(FMResultSet*)set;

@end
