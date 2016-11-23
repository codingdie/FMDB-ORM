//
//  DBManager.m
//  DocPatient
//
//  Created by apple on 15/9/16.
//  Copyright (c) 2015年 Yihua Cao. All rights reserved.
//
#import "FMDB.h"

#import "FMDBManager.h"
@implementation FMDBManager
- (instancetype)initWithFileName:(NSString*)filename version:(int) version{
    self=[super init];
    if (self) {
        self.filename=filename;
        self.version=version;
        NSLog(@"DBPATH:%@",[[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:filename].path);
        self.queue= [FMDatabaseQueue databaseQueueWithPath:[[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:filename].path ];
        [self initOrUpdateDB ];
    }

    return self;

}

- (void)excuteUpdateSqlsInFile:(NSString*)path inDB:(FMDatabase*)db{
        NSString*initSql=[[NSString alloc]initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        NSArray*sqls= [initSql componentsSeparatedByString:@";"];
        for (NSString*sql in sqls) {
           NSString* sqlWithNoSpace=[sql stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (sqlWithNoSpace.length!=0) {
                [db executeUpdate:sqlWithNoSpace];

            }
        }

}
- (NSString*) getDbPath{
    return [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:self.filename].path;
}


- (void)initOrUpdateDB{
    [self safeDoInDB:^(FMDatabase *db) {
        if (![self checkTableExit:@"DBVERSION" inDB:db]) {
            [self createDBVersionTable:db];
            [self performSelector:NSSelectorFromString(@"createDBTables:") withObject:db];
        }
        __block int curentVersion=[self queryCurrentDBVersion:db];
        [self updateDB:db currentVersion:curentVersion];

    }];
  


    
}
- (void)createDBVersionTable:(FMDatabase*) db{
    [db executeUpdate:@"create table DBVERSION('VERSION' INTERGER DEFAULT 1)"];
    [db executeUpdate:@"INSERT INTO DBVERSION('VERSION' ) VALUES(1) "];

}
- (void)updateDB:(FMDatabase*) db currentVersion:(int) currentVersion{
    for (int i=currentVersion; i<self.version; i++) {
    
        [self performSelector:NSSelectorFromString([[NSString alloc]initWithFormat:@"version%dToVersion%d:",i,i+1]) withObject:db];
    }
    [db executeUpdate:@"update DBVERSION set version=?",@(self.version)];
}

- (void)safeDoInDB:(void (^)(FMDatabase *db))block{
    [self.queue inDatabase:^(FMDatabase *db) {
        BOOL isRollBack = NO;
        [db beginTransaction];
        @try{
            block(db);
        }@catch(NSException * ex){
            NSLog(@"%@",ex);
            isRollBack = YES;
            [db rollback];
        }@finally{
            if (!isRollBack) {
                [db commit];
            }
        }
    }];
}
- (BOOL)checkTableExit:(NSString*)tableName inDB:(FMDatabase*) db{
     BOOL flag=false;
       FMResultSet*result=[db executeQuery:@"select count(*) as count from  sqlite_master where type='table' and name=?",tableName];
       int count=0;
       while ([result next]) {
           count=[result intForColumn:@"count"];
       }
       if (count==1) {
           flag=true;
       }
       [result close];
    return flag;
}
- (int)queryCurrentDBVersion:(FMDatabase*) db{
     int version=1;
        FMResultSet*result=[db executeQuery:@"select version  from  DBVERSION limit 1"];
        while ([result next]) {
            version=[result intForColumn:@"version"];
        }
        [result close];
    return version;
}

@end