//
//  FMDBResultUtil.m
//  DPBase
//
//  Created by xupeng on 16/4/4.
//  Copyright © 2016年 Yihua Cao. All rights reserved.
//

#import "FMDBResultUtil.h"
#import "ObjectUtil.h"
#import "FMResultSet.h"
@implementation FMDBResultUtil
+(int)getIndexByNames:(NSMutableArray*)names from:(FMResultSet*)result{
    
    for (NSString* name in names) {
        int index=[result columnIndexForName:name];
        if (index!=-1) {
            return index;
        }
    }
    return -1;
}
//临时方案
+ (BOOL)isNull:(id)obj{
    BOOL flag=false;
    NSMutableArray*keys=[NSMutableArray array];
    if ([obj respondsToSelector:NSSelectorFromString(@"keys")]) {
        NSMutableArray*arry= [obj performSelector:NSSelectorFromString(@"keys") withObject:nil];
        [keys addObjectsFromArray:arry];
    }
    for (NSString*propName in keys) {
        id value=[obj valueForKey:propName];
        if (value==nil) {
            flag=true;
            
        }
        else if ([value isKindOfClass:[NSNumber class ]]) {
            if ([value integerValue]==0) {
                flag=true;
            }
        }
        
    }
    return flag;
}
+(id)fillObject:(Class)cla from:(FMResultSet*)set{
    id obj=[cla alloc];
    for (NSDictionary*dic in [ObjectUtil getAllProperty:cla]) {
        NSString *typeStr =[dic valueForKey:@"type"];
        NSString *propName =[dic valueForKey:@"name"];
        NSMutableArray*alias=[NSMutableArray array];
        if ([obj respondsToSelector:NSSelectorFromString([propName stringByAppendingString:@"Alias"])]) {
            NSMutableArray*arry = [obj performSelector:NSSelectorFromString([propName stringByAppendingString:@"Alias"]) withObject:nil];
            [alias addObjectsFromArray:arry];
        }
        [alias addObject:propName];
        int index=   [self getIndexByNames:alias from:set];
        if (index!=-1) {
            if ([[typeStr lowercaseString] isEqualToString:@"i"]||[[typeStr lowercaseString] isEqualToString:@"s"])
            {
                int value=[set intForColumnIndex:index];
                [obj setValue:@(value) forKey:propName];
            } else if ([[typeStr lowercaseString] isEqualToString:@"l"]||[[typeStr lowercaseString] isEqualToString:@"q"])
            {
                
                long value=[set longForColumnIndex:index];
                [obj setValue:@(value) forKey:propName];
            }
            else if ([typeStr isEqualToString:@"@\"NSString\""])
            {
                NSString* value=[set stringForColumnIndex:index];
                [obj setValue:value forKey:propName];
            }
            else if([typeStr isEqualToString:@"d"]||[typeStr isEqualToString:@"f"]){
                double value=[set doubleForColumnIndex:index];
                [obj setValue:@(value) forKey:propName];
            }else{
                NSLog(@"不识别 propName:%@/typeStr:%@",propName,typeStr);
            }
        }else
        {
            if ([typeStr isEqualToString:@"@\"NSMutableArray\""]||[typeStr isEqualToString:@"@\"NSArray\""])            {
                Class class = [obj performSelector:NSSelectorFromString([propName stringByAppendingString:@"Class"]) withObject:nil];
                id itemobj=  [self fillObject:class from:set];
                NSMutableArray *value = [NSMutableArray array];
                if (![self isNull:itemobj ]) {
                    [value addObject:itemobj];
                    
                }
                [obj setValue:value forKey:propName];
                
            }
            
        }
    }
    return obj;
    
}
+(void)add:(id)b to:(id)a{
    NSMutableArray*array= [ObjectUtil getArrayProperty:[a class]];
    for (NSDictionary*dic in array) {
        NSString *propName =[dic valueForKey:@"name"];
        //  Class class = [pre performSelector:NSSelectorFromString([propName stringByAppendingString:@"Class"]) withObject:nil];
        NSMutableArray*valuepre=[a valueForKey:propName];
        NSMutableArray*valuenow=[b valueForKey:propName];
        
        if (valuenow!=nil&&valuenow.count>0) {
            id new=[valuenow objectAtIndex:0];
            
            BOOL flag=false;
            for (id item in valuepre) {
                if ([ObjectUtil compareObjWithOutArrayProp:item :new ]) {
                    flag=true;
                    break;
                }
                
            }
            if (!flag) {
                [valuepre addObject:new];
                [a setValue:valuepre forKey:propName];
            }
        }
    }
    
}
+(id)toObject:(Class)cla from:(FMResultSet*)set{
    id obj=nil;
    while ([set next]) {
        id  tmp=[self fillObject:cla from:set];
        if (obj==nil) {
            obj=tmp;
        }else{
            if (![ObjectUtil compareObjWithOutArrayProp:tmp :obj]) {
                break;
            }
            [self add:tmp to:obj];
            
        }
    }
    [set close];
    return obj;
}
+(NSMutableArray*)toObjectArray:(Class)cla from:(FMResultSet*)set{
    NSMutableArray*arry=[NSMutableArray array];
    id obj=nil;
    while ([set next]) {
        id  tmp=[self fillObject:cla from:set];
        if (obj==nil) {
            obj=tmp;
            [arry addObject:obj];
        }else{
            if (![ObjectUtil compareObjWithOutArrayProp:tmp :obj]) {
                obj=tmp;
                [arry addObject:obj];
                
            }
            [self add:tmp to:obj];
            
        }
    }
    [set close];
    return arry;
}


@end
