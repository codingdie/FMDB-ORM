# FMDB-ORM
基于FMDB扩展的OC数据库ORM框架
参照j2ee中mybatis框架基于fmdb框架扩展的oc数据库orm框架,公司目前使用(几十万级别本地数据处理)，由于fmdb机制本身的缺陷，对sqlite3性能利用没达到极致。可看我另外一个全新ios读写分离数据库框架。这个框架懒得补全文档了。

```
#define DBVERSION 5
@interface MDDBManager : FMDBManager
+ (MDDBManager*)shareInstance:(NSString*)filename;

@end


#import "MDDBManager.h"
#import "MDAppDelegate.h"
#import "MDUser.h"

static MDDBManager *singleInstance = nil;

@implementation MDDBManager
+ (MDDBManager*)shareInstance:(NSString*)filename{
    @synchronized(singleInstance) {
        if (singleInstance==nil||(singleInstance!=nil&&![singleInstance.filename isEqualToString:filename])) {
            singleInstance=nil;
            singleInstance =[[MDDBManager alloc]initWithFileName:filename version:DBVERSION] ;
            
        }
    }
    return singleInstance;
}
- (void)createDBTables:(FMDatabase*)db{
    [self excuteUpdateSqlsInFile:[ [NSBundle mainBundle] pathForResource:@"DoctorDBInitFile"  ofType:@"sql"] inDB:db];
    //保留coredata时代的聊天消息
    if ([self checkTableExit:@"ZCHATMESSAGE" inDB:db]) {
        [db executeUpdate:@"  INSERT INTO CHATMESSAGE "
         " (CHATTYPE,IFREAD,STATUS,TYPE,CC,CONTENT,SENDTIME,UUIDFROM,UUIDTO)"
         " SELECT ZCHATTYPE,ZIFREAD,ZSTATUS,ZTYPE,ZCC,ZCONTENT,ZSENDTIME,ZUUIDFROM,ZUUIDTO"
         " FROM ZCHATMESSAGE"];
        [db executeUpdate:@"UPDATE CHATMESSAGE SET RECEIVETIME=SENDTIME"];
        [db executeUpdate:@"DROP TABLE IF EXISTS  ZCHATMESSAGE"];
    }

}

- (void)version1ToVersion2:(FMDatabase*)db
{
    ...
}

- (void)version2ToVersion3:(FMDatabase *)db
{
    ...
}

- (void)version(XXX)ToVersion(XXX):(FMDatabase *)db
{
    ...
}


@end  

```
```
- (NSMutableArray *)queryGroupArticleListByGroupId:(long)groupId
{
    __block NSMutableArray *articleList =[NSMutableArray array];
    [self.manager safeDoInDB:^(FMDatabase *db) {
        FMResultSet*result=  [db executeQuery:
                             @" select "
                              "     a.*, "
                              "     agc.* "
                              " from "
                              "    Article a "
                              " inner join ArticleGroupCoowner agc "
                              "    on a.articleId = agc.articleId "
                              " where "
                              "     a.delflag = 0 and agc.groupId = ? "
                              "     and agc.directionType = 2 "
                              " order by a.updateTime desc ", @(groupId)];
        articleList = [FMDBResultUtil toObjectArray:[MDArticle class] from:result];
    }];
    return articleList;
}

```  
```
- (MDPatient *)queryUnconfirmedPatientById:(NSString *)patientId
{
    __block MDPatient *patient = nil;
    [self.manager safeDoInDB:^(FMDatabase *db) {
        FMResultSet *result= [db executeQuery:@"select * from patient where directionType = 0 and relationStatus in (0,2) and patientStatus = 1 and hatePatientFlag=0 and patientId = ?",patientId];
        patient = [FMDBResultUtil toObject:[MDPatient class] from:result];
    }];
    
    return patient;
    
}
```
