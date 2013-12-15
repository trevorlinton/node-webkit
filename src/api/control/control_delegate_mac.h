// (c) 2013 True Interactions
#ifndef NW_SRC_API_CONTROL_CONTROL_DELEGATE_MAC
#define NW_SRC_API_CONTROL_CONTROL_DELEGATE_MAC
#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
namespace nwapi {
  class Control;
}
@interface ControlDelegateMac : NSObject <NSToolbarDelegate> {
@private
  NSMutableArray *items_;
  NSObject *control_;
}
@property base::DictionaryValue *options;
@property (copy) NSString *name;
@property (copy) NSString *type;
- (id)initWithOptions:(const base::DictionaryValue&)option;
- (void)append:(nwapi::Control *)item;
- (void)insert:(nwapi::Control *)item atIndex:(int)pos;
- (void)removeAtIndex:(int)pos;
/** NSToolbar Delegate **/
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar;
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar;
- (void)toolbarDidRemoveItem:(NSNotification *)notification;
- (void)toolbarWillAddItem:(NSNotification *)notification;
- (void)processOptions:(const base::DictionaryValue&)option;
- (NSObject *)getBackObj;
@end
#endif
