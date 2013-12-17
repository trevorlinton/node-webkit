// (c) 2013 True Interactions

#include "base/values.h"
#include "content/nw/src/api/control/control.h"
#include "content/nw/src/api/control/control_delegate_mac.h"

@implementation ControlDelegateMac
- (id)initWithOptions:(const base::DictionaryValue&)option nativeObject:(nwapi::Control *)obj {
  if ((self = [super init])) {
    std::string name_;
    std::string type_;

    self.items = [NSMutableArray array];
    self.native = obj;

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
      control_ = [[NSButton alloc] initWithFrame:NSMakeRect(1, 1, 30, 30)];
      [(NSButton *)control_ setNextResponder:self];
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
  NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
  for(unsigned i=0; i < [self.items count]; i++) {
    nwapi::Control *control = (nwapi::Control *)[[self.items objectAtIndex:i] pointerValue];
    NSString *ident = [NSString stringWithCString:control->GetName().c_str() encoding:[NSString defaultCStringEncoding]];
    if([ident isEqualToString:itemIdentifier]) {
      std::string label;
      self.options->GetString("label", &label);
      std::string tooltip;
      self.options->GetString("tooltip", &tooltip);

      [item setView:(NSView *)control->GetNSObject()];
      [item setLabel:[NSString stringWithCString:label.c_str() encoding:[NSString defaultCStringEncoding]]];
      [item setPaletteLabel:[NSString stringWithCString:label.c_str() encoding:[NSString defaultCStringEncoding]]];
      [item setToolTip:[NSString stringWithCString:tooltip.c_str() encoding:[NSString defaultCStringEncoding]]];
      [item setEnabled:YES];
    }
  }
  return item;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
  return [self toolbarDefaultItemIdentifiers:toolbar];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
  NSMutableArray *identifiers = [NSMutableArray array];
  for(unsigned i=0; i < [self.items count]; i++) {
    nwapi::Control *control = (nwapi::Control *)[[self.items objectAtIndex:i] pointerValue];
    NSString *ident = [NSString stringWithCString:control->GetName().c_str() encoding:[NSString defaultCStringEncoding]];
    [identifiers addObject:ident];
  }
  return identifiers;
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
  [self.items addObject:obj];
  if([self.type isEqualToString:@"toolbar"]) {
    NSString *ident = [NSString stringWithCString:item->GetName().c_str() encoding:[NSString defaultCStringEncoding]];
    [((NSToolbar *)control_)
      insertItemWithItemIdentifier:(NSString *)ident
      atIndex:[self.items indexOfObject:obj]];
  }
}
- (void)insert:(nwapi::Control *)item atIndex:(int)pos {
  [self.items insertObject:[NSValue valueWithPointer:item] atIndex:pos];
}
- (void)removeAtIndex:(int)pos {
  [self.items removeObjectAtIndex:pos];
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
    [button setNeedsDisplay:YES];
    [button setButtonType:NSRegularSquareBezelStyle];
    [button setBezelStyle:NSRoundedBezelStyle];

    std::string label;
    std::string tooltip;
    if(option.GetString("label",&label)) {
      self.options->SetString("label",label);
      [button setTitle:[NSString stringWithCString:label.c_str() encoding:[NSString defaultCStringEncoding]]];
    }
    if(option.GetString("tooltip",&tooltip)) {
      self.options->SetString("tooltip",tooltip);
    }
    double width, height;
    if(option.GetDouble("width",&width) && option.GetDouble("height", &height)) {
      self.options->SetDouble("width",width);
      self.options->SetDouble("height",height);
      [button setFrameSize:NSMakeSize(width, height)];
    }
  }
}
- (NSObject *)getBackObj {
  return control_;
}

- (BOOL)acceptsFirstResponder {
  return YES;
}

- (void)mouseDown:(NSEvent *)theEvent {
  self.native->OnMouseDown();
}

- (void)mouseUp:(NSEvent *)theEvent {
  self.native->OnMouseUp();
  self.native->OnClick();

}

- (void)mouseMoved:(NSEvent *)theEvent {
  self.native->OnMouseMove();
}

- (void)mouseEntered:(NSEvent *)theEvent {
  self.native->OnMouseEnter();
}

- (void)mouseExited:(NSEvent *)theEvent {
  self.native->OnMouseExit();
}

- (void)keyDown:(NSEvent *)theEvent {
  self.native->OnKeyDown();
}

- (void)keyUp:(NSEvent *)theEvent {
  self.native->OnKeyUp();
}
@end

