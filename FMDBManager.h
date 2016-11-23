//
//  DBManager.h
//  DocPatient
//
//  Created by apple on 15/9/16.
//  Copyright (c) 2015年 Yihua Cao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDB.h"
@interface FMDBManager : NSObject
@property (nonatomic, copy) NSString* filename;
@property (nonatomic, assign) int  version;

@property (retain, nonatomic) FMDatabaseQueue *queue;
- (BOOL)checkTableExit:(NSString*)tableName inDB:(FMDatabase*) db;
- (int)queryCurrentDBVersion:(FMDatabase*) db;
- (instancetype)initWithFileName:(NSString*)filename version:(int) version;

- (void)excuteUpdateSqlsInFile:(NSString*)path inDB:(FMDatabase*)db;
- (void)safeDoInDB:(void (^)(FMDatabase *db))block;
- (NSString*) getDbPath;

@end