// (c) 2013 True Interactions

#include "base/values.h"
#include "content/nw/src/api/control/control.h"
#include "content/nw/src/api/control/control_delegate_mac.h"

@implementation ControlDelegateMac
- (id) initWithOptions:(const base::DictionaryValue &)option {
  if ((self = [super init])) {
    std::string name_;
    std::string type_;

    items_ = [NSMutableArray array];

    option.GetString("name",&name_);
    option.GetString("type",&type_);

    self.name = [NSString stringWithCString:name_.c_str() encoding:[NSString defaultCStringEncoding]];
    self.type = [NSString stringWithCString:type_.c_str() encoding:[NSString defaultCStringEncoding]];

    self.options = new base::DictionaryValue();

    if([self.type isEqualToString:@"toolbar"]) {
      control_ = [[NSToolbar alloc] initWithIdentifier:self.name];

      // set our controller as the control delegate
      NSToolbar *toolbar = (NSToolbar *)control_;
      [toolbar setDelegate:self];
      [self processOptions:option];
    } else if ([self.type isEqualToString:@"button"]) {
      control_ = [[NSButton alloc]init];
      [self processOptions:option];
    } else if ([self.type isEqualToString:@"textfield"]) {
      
    } else if ([self.type isEqualToString:@"image"]) {
      
    }
  }
  return self;
}

/**
 ** Toolbar Delegates
 **/
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
     itemForItemIdentifier:(NSString *)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag
{
  NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
  for(unsigned i=0; i < [items_ count]; i++) {
    nwapi::Control *control = (nwapi::Control *)[[items_ objectAtIndex:i] pointerValue];
    NSString *ident = [NSString stringWithCString:control->GetName().c_str() encoding:[NSString defaultCStringEncoding]];
    if(ident==itemIdentifier) {
      std::string label;
      self.options->GetString("label", &label);
      std::string tooltip;
      self.options->GetString("tooltip", &tooltip);

      [item setView:(NSView *)control->GetNSObject()];
      [item setLabel:[NSString stringWithCString:label.c_str() encoding:[NSString defaultCStringEncoding]]];
      [item setPaletteLabel:[NSString stringWithCString:label.c_str() encoding:[NSString defaultCStringEncoding]]];
      [item setToolTip:[NSString stringWithCString:tooltip.c_str() encoding:[NSString defaultCStringEncoding]]];
    }
  }
  return item;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
  NSMutableArray *items = [[NSMutableArray array] autorelease];
  for(unsigned i=0; i < [items_ count]; i++) {
    nwapi::Control *control = (nwapi::Control *)[[items_ objectAtIndex:i] pointerValue];
    NSString *ident = [NSString stringWithCString:control->GetName().c_str() encoding:[NSString defaultCStringEncoding]];
    [items addObject:ident];
  }
  return items;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
  NSMutableArray *items = [[NSMutableArray array] autorelease];
  for(unsigned i=0; i < [items_ count]; i++) {
    nwapi::Control *control = (nwapi::Control *)[[items_ objectAtIndex:i] pointerValue];
    NSString *ident = [NSString stringWithCString:control->GetName().c_str() encoding:[NSString defaultCStringEncoding]];
    [items addObject:ident];
  }
  return items;
}

- (void)toolbarDidRemoveItem:(NSNotification *)notification {

}

- (void)toolbarWillAddItem:(NSNotification *)notification {

}

/**
 ** General Interface for Delegate
 **/
- (void)append:(nwapi::Control *)item {
  NSValue *obj = [NSValue valueWithPointer:item];
  [items_ addObject:obj];
  if([self.type isEqualToString:@"toolbar"]) {
    NSString *ident = [NSString stringWithCString:item->GetName().c_str() encoding:[NSString defaultCStringEncoding]];
    [((NSToolbar *)control_)
     insertItemWithItemIdentifier:(NSString *)ident
     atIndex:[items_ indexOfObject:obj]];
  }
}
- (void)insert:(nwapi::Control *)item atIndex:(int)pos {
  [items_ insertObject:[NSValue valueWithPointer:item] atIndex:pos];
}
- (void)removeAtIndex:(int)pos {
  [items_ removeObjectAtIndex:pos];
}

- (void)processOptions:(const base::DictionaryValue&)option {
  if([self.type isEqualToString:@"toolbar"]) {
    NSToolbar *toolbar = (NSToolbar *)control_;
    // set initial control properties
    bool customizable;
    if(option.GetBoolean("customizable", &customizable)) {
      if(customizable)
        [toolbar setAllowsUserCustomization:YES];
      else
        [toolbar setAllowsUserCustomization:NO];
      self.options->SetBoolean("customizable",customizable);
    }

    [toolbar setAutosavesConfiguration:NO];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
    [toolbar setSizeMode:NSToolbarSizeModeSmall];

  } else if ([self.type isEqualToString:@"button"]) {
    NSButton *button = (NSButton *)control_;
    [button setBordered:NO];
    [button setNeedsDisplay:YES];
    //[button setImage:[NSImage imageNamed:TITLE_BUTTON_NAME]];
    //[button setAlternateImage:[NSImage imageNamed:TITLE_BUTTON_PRESSED_NAME]];
    [button setButtonType:NSMomentaryChangeButton];

    std::string label;
    std::string tooltip;
    if(option.GetString("label",&label)) {
      self.options->SetString("label",label);
      [button setTitle:[NSString stringWithCString:label.c_str() encoding:[NSString defaultCStringEncoding]]];
    }
    if(option.GetString("tooltip",&tooltip)) {
      self.options->SetString("tooltip",tooltip);
    }
  }
}
- (NSObject *)getBackObj {
  return control_;
}

@end

