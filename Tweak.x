#import <Foundation/Foundation.h>
#import <libpowercuts/libpowercuts.h>

@interface BBSectionInfo : NSObject
@property NSInteger authorizationStatus;
@end

@interface BBServer : NSObject
- (void)getSectionInfoForSectionID:(NSString *)sectionID
                       withHandler:(void (^)(BBSectionInfo *))handler;
- (void)setSectionInfo:(BBSectionInfo *)sectionInfo forSectionID:(NSString *)sectionID;
@end

@interface NotificationsAction : PCAction
@end

@interface WFAction : NSObject
@property NSString *identifier;
@end

@interface WFCustomAction : WFAction
@end

BBServer *server;

@implementation NotificationsAction
- (void)performActionForIdentifier:(NSString *)identifier
                    withParameters:(NSDictionary *)parameters {
  [server getSectionInfoForSectionID:parameters[@"AppIdentifier"]
                         withHandler:^(BBSectionInfo *sectionInfo) {
                           BOOL enableNotifications =
                               [parameters[@"operation"] isEqualToString:@"Turn"]
                                   ? [parameters[@"OnValue"] boolValue]
                                   : sectionInfo.authorizationStatus != 2;
                           sectionInfo.authorizationStatus = enableNotifications + 1;
                           [server setSectionInfo:sectionInfo
                                     forSectionID:parameters[@"AppIdentifier"]];
                         }];
}
- (NSString *)nameForIdentifier:(NSString *)identifier {
  return @"Toggle Notifications for an Application";
}
- (NSString *)descriptionSummaryForIdentifier:(NSString *)identifier {
  return @"Enable or disable a specific application's notifications.";
}
- (NSString *)associatedAppBundleIdForIdentifier:(NSString *)identifier {
  return nil;
}
- (NSArray<NSString *> *)keywordsForIdentifier:(NSString *)identifier {
  return @[ @"local", @"notification", @"alert", @"reminder", @"push" ];
}
- (NSArray *)parametersDefinitionForIdentifier:(NSString *)identifier {
  return @[
    @{
      @"type" : @"enum",
      @"key" : @"operation",
      @"label" : @"Operation",
      @"items" : @[ @"Turn", @"Toggle" ],
      @"defaultValue" : @"Turn",
    },
    @{
      @"type" : @"boolean",
      @"key" : @"OnValue",
      @"label" : @"State",
      @"condition" : @{
        @"key" : @"operation",
        @"value" : @"Turn",
      },
    },
    @{
      @"type" : @"application",
      @"key" : @"AppIdentifier",
      @"label" : @"Application",
    },
  ];
}
- (id)parameterSummaryForIdentifier:(NSString *)identifier {
  return @{
    @"OnValue,operation,AppIdentifier" :
        @"${operation} Notifications ${OnValue} for ${AppIdentifier}",
    @"operation,AppIdentifier" : @"${operation} Notifications for ${AppIdentifier}"
  };
}
@end

%group SpringBoard

%hook BBServer
- (instancetype)initWithQueue:(id)queue {
  if ((self = %orig)) {
    server = self;
  }
  return self;
}
%end

%end

%hook PCParametersParser
+ (NSString *)shortcutsParameterClassForType:(NSString *)type {
  return [type isEqualToString:@"application"] ? @"WFAppPickerParameter" : %orig;
}
%end

%hook WFCustomAction
+ (NSMutableDictionary *)customDefinitionForIdentifier:(NSString *)identifier {
  NSMutableDictionary *definition = %orig;
  if ([identifier isEqualToString:@"com.level3tjg.powercuts.action.notifications"]) {
    definition[@"Attribution"] = @"Notifications";
    definition[@"Subcategory"] = @"Notification";
  }
  return definition;
}
- (NSString *)iconName {
  return [self.identifier isEqualToString:@"com.level3tjg.powercuts.action.notifications"]
             ? @"Notification.png"
             : %orig;
}
%end

%ctor {
  %init(_ungrouped);
  if ([NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
    %init(SpringBoard);
    [[PowercutsManager sharedInstance]
        registerActionWithIdentifier:@"com.level3tjg.powercuts.action.notifications"
                              action:[NotificationsAction new]];
  }
}
