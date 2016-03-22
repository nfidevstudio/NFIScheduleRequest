//
//  NFISimplePersist.m
//  ExampleSimplePersist
//
//  Created by José Carlos on 15/2/16.
//  Copyright © 2016 José Carlos. All rights reserved.
//

#import "NFISimplePersistObject.h"
#import "NFISimplePersist.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <sqlite3.h>

NSString * const kCustomDBName = @"NFISimplePersist.db";
NSString * const kCreatePersistTable = @"CREATE TABLE persistedObjects (key TEXT NOT NULL, object BLOB, class TEXT NOT NULL, PRIMARY KEY (key, class))";
NSString * const kTableExist = @"SELECT name FROM sqlite_master WHERE type='table' AND name='persistedObjects'";
NSString * const kInsert = @"INSERT INTO persistedObjects VALUES(?, ?, ?);";
NSString * const kCountFields = @"SELECT COUNT(*) FROM persistedObjects";

NSString * const kLoadAll = @"SELECT * FROM persistedObjects";
NSString * const kLoadWithKeyAndClass = @"SELECT * FROM persistedObjects WHERE key like '%@' AND class like '%@'";
NSString * const kLoadWithClass = @"SELECT * FROM persistedObjects WHERE class like '%@'";

NSString * const kDeleteWithClass = @"DELETE FROM persistedObjects WHERE class like '%@'";
NSString * const kDeleteWithKey = @"DELETE FROM persistedObjects WHERE key like '%@' AND class like '%@'";
NSString * const kDeleteAll = @"DELETE FROM persistedObjects";

NSString * const kClass = @"class";
NSString * const kObject = @"object";
NSString * const kKey = @"key";

@interface NFISimplePersist ()

@property (nonatomic) sqlite3 *database;
@property (nonatomic, copy) NSString *databasePath;

@end

@implementation NFISimplePersist

#pragma mark - Private Methods.
#pragma mark -
#pragma mark - DB methods.

/**
 *  Load the DB
 */
- (void)loadDBWithName:(NSString *)name {
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    _databasePath = [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent: [name isEqualToString:kCustomDBName] ? kCustomDBName : [NSString stringWithFormat:@"%@.db",name]]];
    NSFileManager *filemgr = [NSFileManager defaultManager];
    if ([filemgr fileExistsAtPath: _databasePath ] == NO) {
        const char *dbpath = [_databasePath UTF8String];
        if (sqlite3_open(dbpath, &_database) == SQLITE_OK) {
            char *errMsg;
            if (sqlite3_exec(_database, [kCreatePersistTable UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) {
                NSAssert1(0, @"Failed to create table '%s'", sqlite3_errmsg(_database));
            }
            sqlite3_close(_database);
        } else {
             NSLog(@"Failed to open/create database");
        }
    }
}

/**
 * Load object from Dictionary
 */
- (id)objectFromDictionary:(NSDictionary *)dictionary {
    if (dictionary) {
        Class objectClass = NSClassFromString(dictionary[kClass]);
        id object = nil;
        if ([[objectClass alloc] respondsToSelector:@selector(initWithDictionary:)]) {
            object = [[objectClass alloc] initWithDictionary:dictionary[kObject]];
            return object;
        } else {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                           reason:[NSString stringWithFormat:@"To persist this object, you must implement NFISimplePersistObject protocol and add all required methods."]
                                         userInfo:nil];
        }
    }
    return nil;
}

- (NSString *)propertyValueOf:(NSString *)propertyString inObject:(id)object {
    if ([[object valueForKey:propertyString] isKindOfClass:[NSString class]] || [[object valueForKey:propertyString] isKindOfClass:[NSNumber class]]) {
        return [object valueForKey:propertyString];
    } else {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"The property key of the object must be a NSString or a NSNumber (include NSInteger, long, float...)."]
                                     userInfo:nil];
    }
}

#pragma mark - Public Methods.
#pragma mark -
#pragma mark - Instance.

/** Unique shared instance for NFISimplePersist.
 */
+ (instancetype)standarSimplePersist {
    static NFISimplePersist *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[NFISimplePersist alloc] init];
        [_sharedInstance loadDBWithName:kCustomDBName];
    });
    return _sharedInstance;
}

/** Custom Simple Persist instance
 */
- (instancetype)initWithSimplePersistName:(NSString *)name {
    self = [super init];
    if (self) {
        [self loadDBWithName:name];
    }
    return self;
}

#pragma mark - Persist method

/**
 *  Persist the object
 */
- (void)saveObject:(id)object {
    if (sqlite3_open([_databasePath UTF8String], &_database) == SQLITE_OK) {
        if ([object respondsToSelector:@selector(saveAsDictionary)]) {
            if ([[object class] respondsToSelector:@selector(uniqueIdentifier)]) {
                NSString *keyProperty = [[object class] uniqueIdentifier];
                id propertyValue = [self propertyValueOf:keyProperty inObject:object];
                NSString *key = [propertyValue isKindOfClass:[NSString class]] ? [self propertyValueOf:keyProperty inObject:object] : [NSString stringWithFormat:@"%@",[self propertyValueOf:keyProperty inObject:object]];
                NSDictionary *dictToSave = [[NSDictionary alloc] initWithObjects:@[NSStringFromClass([object class]), [object saveAsDictionary], [self propertyValueOf:keyProperty inObject:object]]
                                                                         forKeys:@[kClass, kObject, kKey]];
                NSString *class = dictToSave[kClass];
                NSDictionary *object = dictToSave[kObject];
                NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
                
                sqlite3_stmt *updateStmt = nil;
                if(sqlite3_prepare_v2(_database, [kInsert UTF8String], -1, &updateStmt, NULL) != SQLITE_OK)  {
                    NSAssert1(0, @"Error while creating save statement. '%s'", sqlite3_errmsg(_database));
                } else {
                    sqlite3_bind_text(updateStmt, 1, [key UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_blob(updateStmt, 2, [data bytes], (int)[data length], SQLITE_TRANSIENT);
                    sqlite3_bind_text(updateStmt, 3, [class UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_step(updateStmt);
                }
                sqlite3_reset(updateStmt);
                sqlite3_finalize(updateStmt);
            } else {
                @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                               reason:[NSString stringWithFormat:@"To persist this object, you must implement NFISimplePersistObject protocol and add all required methods."]
                                             userInfo:nil];
            }
        } else {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                           reason:[NSString stringWithFormat:@"To persist this object, you must implement NFISimplePersistObject protocol and add all required methods."]
                                         userInfo:nil];
        }
    }
    sqlite3_close(_database);
}

- (void)saveObjects:(NSArray *)objects withCompletionBlock:(SaveObjectsCompletionBlock)completionBlock {
    if (sqlite3_open([_databasePath UTF8String], &_database) == SQLITE_OK) {
        for (id object in objects) {
            if ([object respondsToSelector:@selector(saveAsDictionary)]) {
                if ([[object class] respondsToSelector:@selector(uniqueIdentifier)]) {
                    NSString *keyProperty = [[object class] uniqueIdentifier];
                    id propertyValue = [self propertyValueOf:keyProperty inObject:object];
                    NSString *key = [propertyValue isKindOfClass:[NSString class]] ? [self propertyValueOf:keyProperty inObject:object] : [NSString stringWithFormat:@"%@",[self propertyValueOf:keyProperty inObject:object]];
                    NSDictionary *dictToSave = [[NSDictionary alloc] initWithObjects:@[NSStringFromClass([object class]), [object saveAsDictionary], [self propertyValueOf:keyProperty inObject:object]]
                                                                             forKeys:@[kClass, kObject, kKey]];
                    NSString *class = dictToSave[kClass];
                    NSDictionary *object = dictToSave[kObject];
                    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
                    
                    sqlite3_stmt *updateStmt = nil;
                    if(sqlite3_prepare_v2(_database, [kInsert UTF8String], -1, &updateStmt, NULL) != SQLITE_OK)  {
                        NSAssert1(0, @"Error while saving multiple objects. '%s'", sqlite3_errmsg(_database));
                    } else {
                        sqlite3_bind_text(updateStmt, 1, [key UTF8String], -1, SQLITE_TRANSIENT);
                        sqlite3_bind_blob(updateStmt, 2, [data bytes], (int)[data length], SQLITE_TRANSIENT);
                        sqlite3_bind_text(updateStmt, 3, [class UTF8String], -1, SQLITE_TRANSIENT);
                        sqlite3_step(updateStmt);
                    }
                    sqlite3_reset(updateStmt);
                    sqlite3_finalize(updateStmt);
                } else {
                    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                                   reason:[NSString stringWithFormat:@"To persist this object, you must implement NFISimplePersistObject protocol and add all required methods."]
                                                 userInfo:nil];
                }
            } else {
                @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                               reason:[NSString stringWithFormat:@"To persist this object, you must implement NFISimplePersistObject protocol and add all required methods."]
                                             userInfo:nil];
            }
        }
    } else {
        completionBlock(NO);
    }
    completionBlock(YES);
    sqlite3_close(_database);
}

#pragma mark - Load methods

/**
 *  Load all objects in table
 */
- (NSArray *)loadAllObjects {
    NSMutableArray *objects = [[NSMutableArray alloc] init];
    if (sqlite3_open([_databasePath UTF8String], &_database) == SQLITE_OK) {
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(_database, [kLoadAll UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                char *keyDB = (char *) sqlite3_column_text(statement, 0);
                const void *ptr = sqlite3_column_blob(statement, 1);
                int size = sqlite3_column_bytes(statement, 1);
                char *classDB = (char *) sqlite3_column_text(statement, 2);
                
                NSString *class = [[NSString alloc] initWithUTF8String:classDB];
                NSString *key = [[NSString alloc] initWithUTF8String:keyDB];
                NSData *data = [[NSData alloc] initWithBytes:ptr length:size];
                
                NSMutableDictionary *object = [[NSMutableDictionary alloc] init];
                
                NSDictionary *dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                [object setObject:dictionary forKey:kObject];
                [object setObject:key forKey:kKey];
                [object setObject:class forKey:kClass];
                
                [objects addObject:[self objectFromDictionary:object]];
            }
            sqlite3_finalize(statement);
        } else {
            NSAssert1(0, @"Error loading all objects. '%s'", sqlite3_errmsg(_database));
        }

    }
    sqlite3_close(_database);
    return objects;
}


/**
 *  Load the object with the given key and class. Return nil if the table is empty
 */
- (id)loadObjectWithKey:(NSString *)key andClass:(Class)class {
    if (sqlite3_open([_databasePath UTF8String], &_database) == SQLITE_OK) {
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(_database, [[NSString stringWithFormat:kLoadWithKeyAndClass, key, NSStringFromClass(class)] UTF8String], -1, &statement, nil)
            == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                char *keyDB = (char *) sqlite3_column_text(statement, 0);
                const void *ptr = sqlite3_column_blob(statement, 1);
                int size = sqlite3_column_bytes(statement, 1);
                char *classDB = (char *) sqlite3_column_text(statement, 2);
                
                NSString *class = [[NSString alloc] initWithUTF8String:classDB];
                NSString *key = [[NSString alloc] initWithUTF8String:keyDB];
                NSData *data = [[NSData alloc] initWithBytes:ptr length:size];
                
                NSMutableDictionary *object = [[NSMutableDictionary alloc] init];
                
                NSDictionary *dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                [object setObject:dictionary forKey:kObject];
                [object setObject:key forKey:kKey];
                [object setObject:class forKey:kClass];
                
                sqlite3_close(_database);
                
                return [self objectFromDictionary:object];
            }
            sqlite3_finalize(statement);
        }

    }
    sqlite3_close(_database);
    return nil;
}


/**
 *  Load all objects with the same class
 */
- (NSArray *)loadAllObjectsWithClass:(__unsafe_unretained Class)class {
    NSMutableArray *objects = [[NSMutableArray alloc] init];
    if (sqlite3_open([_databasePath UTF8String], &_database) == SQLITE_OK) {
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(_database, [[NSString stringWithFormat:kLoadWithClass,NSStringFromClass(class)] UTF8String], -1, &statement, nil)
            == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                char *keyDB = (char *) sqlite3_column_text(statement, 0);
                const void *ptr = sqlite3_column_blob(statement, 1);
                int size = sqlite3_column_bytes(statement, 1);
                char *classDB = (char *) sqlite3_column_text(statement, 2);
                
                NSString *class = [[NSString alloc] initWithUTF8String:classDB];
                NSString *key = [[NSString alloc] initWithUTF8String:keyDB];
                NSData *data = [[NSData alloc] initWithBytes:ptr length:size];
                
                NSMutableDictionary *object = [[NSMutableDictionary alloc] init];
                
                NSDictionary *dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                [object setObject:dictionary forKey:kObject];
                [object setObject:key forKey:kKey];
                [object setObject:class forKey:kClass];
                
                [objects addObject:[self objectFromDictionary:object]];
            }
            sqlite3_finalize(statement);
        }
    }
    sqlite3_close(_database);
    return objects;
}


#pragma mark - Remove methods

/**
 * Remove object from db
 */
- (BOOL)removeObject:(id)object {
    if ([[object class] respondsToSelector:@selector(uniqueIdentifier)]) {
        NSString *key = [[object class] uniqueIdentifier];
        return [self removeObjectWithKey:[self propertyValueOf:key inObject:object] andClass:[object class]];
    } else {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"To persist this object, you must implement NFISimplePersistObject protocol and add all required methods."]
                                     userInfo:nil];
    }
}

/**
 *  Remove all objects
 */
- (BOOL)removeAllObjects {
    if (sqlite3_open([_databasePath UTF8String], &_database) == SQLITE_OK) {
        if(sqlite3_exec(_database, [kDeleteAll UTF8String], NULL, NULL, nil) == SQLITE_OK) {
            return YES;
        }
    }
    sqlite3_close(_database);
    return NO;
}

/**
 *  Remove object with the given class. Return a BOOL with the result
 */
- (BOOL)removeObjectsWithClass:(__unsafe_unretained Class)class {
    if (sqlite3_open([_databasePath UTF8String], &_database) == SQLITE_OK) {
        if(sqlite3_exec(_database, [[NSString stringWithFormat:kDeleteWithClass, NSStringFromClass(class)] UTF8String], NULL, NULL, nil) == SQLITE_OK) {
            return YES;
        }
    }
    sqlite3_close(_database);
    return NO;
}

/**
 *  Remove object with the given key and class. Return a BOOL with the result
 */
- (BOOL)removeObjectWithKey:(NSString *)key andClass:(__unsafe_unretained Class)class {
    if (sqlite3_open([_databasePath UTF8String], &_database) == SQLITE_OK) {
        if(sqlite3_exec(_database, [[NSString stringWithFormat:kDeleteWithKey, key, NSStringFromClass(class)] UTF8String], NULL, NULL, nil) == SQLITE_OK) {
            return YES;
        }
    }
    sqlite3_close(_database);
    return NO;
}

#pragma mark - Deprecated Methods


/**
 *  Persist the object
 */
- (void)saveObject:(id)object withKey:(NSString *)key {
    if (sqlite3_open([_databasePath UTF8String], &_database) == SQLITE_OK) {
        if ([object respondsToSelector:@selector(saveAsDictionary)]) {
            
            NSDictionary *dictToSave = [[NSDictionary alloc] initWithObjects:@[NSStringFromClass([object class]), [object saveAsDictionary], key]
                                                                     forKeys:@[kClass, kObject, kKey]];
            NSString *class = dictToSave[kClass];
            NSDictionary *object = dictToSave[kObject];
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
            
            sqlite3_stmt *updateStmt = nil;
            if(sqlite3_prepare_v2(_database, [kInsert UTF8String], -1, &updateStmt, NULL) != SQLITE_OK)  {
                NSAssert1(0, @"Error while creating save statement. '%s'", sqlite3_errmsg(_database));
            } else {
                sqlite3_bind_text(updateStmt, 1, [key UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_blob(updateStmt, 2, [data bytes], (int)[data length], SQLITE_TRANSIENT);
                sqlite3_bind_text(updateStmt, 3, [class UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_step(updateStmt);
            }
            sqlite3_reset(updateStmt);
            sqlite3_finalize(updateStmt);
        } else {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                           reason:[NSString stringWithFormat:@"To persist this object, you must implement NFISimplePersistObject protocol and add all required methods."]
                                         userInfo:nil];
        }
    }
    sqlite3_close(_database);
}


/**
 * Persist an array of objects.
 *
 * @params key - This represent the property name of the key to save in the data base (The property ALWAYS must be a NSString). i.e (for save the user.id => @"id").
 *
 * All the objects will be saved with the same key
 */
- (void)saveObjects:(NSArray *)objects withPropertyKey:(NSString *)key andCompletionBlock:(SaveObjectsCompletionBlock)completionBlock {
    if (sqlite3_open([_databasePath UTF8String], &_database) == SQLITE_OK) {
        for (id object in objects) {
            if ([object respondsToSelector:@selector(saveAsDictionary)]) {
                NSDictionary *dictToSave = [[NSDictionary alloc] initWithObjects:@[NSStringFromClass([object class]), [object saveAsDictionary], [self propertyValueOf:key inObject:object]] forKeys:@[kClass, kObject, kKey]];
                NSString *class = dictToSave[kClass];
                NSDictionary *object = dictToSave[kObject];
                NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
                
                sqlite3_stmt *updateStmt = nil;
                if(sqlite3_prepare_v2(_database, [kInsert UTF8String], -1, &updateStmt, NULL) != SQLITE_OK)  {
                    NSAssert1(0, @"Error while saving multiple objects. '%s'", sqlite3_errmsg(_database));
                } else {
                    sqlite3_bind_text(updateStmt, 1, [[self propertyValueOf:key inObject:object] UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_blob(updateStmt, 2, [data bytes], (int)[data length], SQLITE_TRANSIENT);
                    sqlite3_bind_text(updateStmt, 3, [class UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_step(updateStmt);
                }
                sqlite3_reset(updateStmt);
                sqlite3_finalize(updateStmt);
            } else {
                @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                               reason:[NSString stringWithFormat:@"To persist this object, you must implement NFISimplePersistObject protocol and add all required methods."]
                                             userInfo:nil];
            }
        }
    } else {
        completionBlock(NO);
    }
    completionBlock(YES);
    sqlite3_close(_database);
}


@end
