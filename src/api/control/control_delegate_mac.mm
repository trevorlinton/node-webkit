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

    options = new base::DictionaryValue();

    if([self.type isEqualToString:@"toolbar"]) {
      control_ = [[NSToolbar alloc] initWithIdentifier:self.name];
      // set our controller as the control delegate
      NSToolbar *toolbar = (NSToolbar *)control_;
      [toolbar setDelegate:self];
    } else if ([self.type isEqualToString:@"button"]) {
      control_ = [[TintButton alloc] initWithFrame:NSMakeRect(1, 1, 30, 30)];
      [(TintButton *)control_ setNative:self.native];
    } else if ([self.type isEqualToString:@"searchfield"]) {
    } else if ([self.type isEqualToString:@"slider"]) {
    } else if ([self.type isEqualToString:@"textfield"]) {
    } else if ([self.type isEqualToString:@"popupbutton"]) {
    } else if ([self.type isEqualToString:@"segmentedbutton"]) {
    } else if ([self.type isEqualToString:@"comboxbox"]) {
    }

    [self setOptions:option];
  }
  return self;
}
- (NSObject *)getBackObj {
  return control_;
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
      options->GetString("label", &label);
      std::string tooltip;
      options->GetString("tooltip", &tooltip);

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
 ** General Interface for Control Add/Remove Subcontrols
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
  NSValue *obj = [NSValue valueWithPointer:item];
  [self.items insertObject:obj atIndex:pos];
  if([self.type isEqualToString:@"toolbar"]) {
    NSString *ident = [NSString stringWithCString:item->GetName().c_str() encoding:[NSString defaultCStringEncoding]];
    [((NSToolbar *)control_)
     insertItemWithItemIdentifier:(NSString *)ident
     atIndex:[self.items indexOfObject:obj]];
  }
}
- (void)removeAtIndex:(int)pos {
  [self.items removeObjectAtIndex:pos];
  if([self.type isEqualToString:@"toolbar"]) {
    [((NSToolbar *)control_) removeItemAtIndex:pos];
  }
}



/**
 ** General Interface for Control Options and Values
 **/
- (base::ListValue *)getValue {
  // TODO
  return NULL;
}
- (void)setValue:(const base::ListValue&)value {
  // TODO
}
- (base::DictionaryValue *)getOptions {
  return options;
}
- (void)setOptions:(const base::DictionaryValue&)option {
  if([self.type isEqualToString:@"toolbar"]) {
    NSToolbar *toolbar = (NSToolbar *)control_;

    std::string toolbarsize;
    std::string displaytype;
    bool customizable;
    bool saveconfig;
    bool visible;

    // toolbar customizable by user
    if(option.GetBoolean("customizable", &customizable)) {
      if(customizable)
        [toolbar setAllowsUserCustomization:YES];
      else
        [toolbar setAllowsUserCustomization:NO];
      options->SetBoolean("customizable",customizable);
    }

    // Toolbar save configuration
    if(option.GetBoolean("saveconfig", &saveconfig)) {
      if(saveconfig)
        [toolbar setAutosavesConfiguration:YES];
      else
        [toolbar setAutosavesConfiguration:NO];
      options->SetBoolean("saveconfig",saveconfig);
    } else
      [toolbar setAutosavesConfiguration:NO];

    // toolbar display type
    if(option.GetString("displaytype", &displaytype)) {
      if(displaytype=="default")
        [toolbar setDisplayMode:NSToolbarDisplayModeDefault];
      else if(displaytype=="iconandlabel")
        [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
      else if(displaytype=="icon")
        [toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
      else if(displaytype=="label")
        [toolbar setDisplayMode:NSToolbarDisplayModeLabelOnly];
      options->SetString("displaytype",displaytype);
    } else
      [toolbar setDisplayMode:NSToolbarDisplayModeDefault];

    // toolbar size
    if(option.GetString("toolbarsize", &toolbarsize)) {
      if(toolbarsize=="default")
        [toolbar setSizeMode:NSToolbarSizeModeDefault];
      else if(toolbarsize=="regular")
        [toolbar setSizeMode:NSToolbarSizeModeRegular];
      else if(toolbarsize=="small")
        [toolbar setSizeMode:NSToolbarSizeModeSmall];
      options->SetString("toolbarsize",toolbarsize);
    }

    // Toolbar visible
    if(option.GetBoolean("visible", &visible)) {
      if(visible)
        [toolbar setVisible:YES];
      else
        [toolbar setVisible:NO];
      options->SetBoolean("visible",visible);
    } else
      [toolbar setAutosavesConfiguration:NO];

    [toolbar setSizeMode:NSToolbarSizeModeSmall];
  } else if ([self.type isEqualToString:@"button"]) {

    /* Settings for button */
    NSButton *button = (NSButton *)control_;
    [button setNeedsDisplay:YES];

    bool border;
    std::string label;
    std::string tooltip;
    std::string buttontype;
    std::string style;
    std::string gradient;

    // Button border
    if(option.GetBoolean("border", &border)) {
      if(border) [button setBordered:YES];
      else [button setBordered:NO];
      options->SetBoolean("border",border);
    }

    // Button label (actually title)
    if(option.GetString("label",&label)) {
      options->SetString("label",label);
      [button setTitle:[NSString stringWithCString:label.c_str() encoding:[NSString defaultCStringEncoding]]];
    }

    // Button Tooltip, used when converted to toolbaritem.
    if(option.GetString("tooltip",&tooltip)) {
      options->SetString("tooltip",tooltip);
    }

    // Button style
    if(option.GetString("style",&style)) {
      options->SetString("style",style);
      if(style == "rounded") [button setBezelStyle:NSRoundedBezelStyle];
      else if(style == "default") [button setBezelStyle:NSRegularSquareBezelStyle];
      else if(style == "thick") [button setBezelStyle:NSThickSquareBezelStyle];
      else if(style == "thicker") [button setBezelStyle:NSThickerSquareBezelStyle];
      else if(style == "disclosuresquared") [button setBezelStyle:NSDisclosureBezelStyle];
      else if(style == "shadowless") [button setBezelStyle:NSShadowlessSquareBezelStyle];
      else if(style == "circular") [button setBezelStyle:NSCircularBezelStyle];
      else if(style == "texturedsquare") [button setBezelStyle:NSTexturedSquareBezelStyle];
      else if(style == "help") [button setBezelStyle:NSHelpButtonBezelStyle];
      else if(style == "smallsquare") [button setBezelStyle:NSSmallSquareBezelStyle];
      else if(style == "texturedrounded") [button setBezelStyle:NSTexturedRoundedBezelStyle];
      else if(style == "roundrect") [button setBezelStyle:NSRoundRectBezelStyle];
      else if(style == "recessed") [button setBezelStyle:NSRecessedBezelStyle];
      else if(style == "disclosurerounded") [button setBezelStyle:NSDisclosureBezelStyle];
      else if(style == "inline") [button setBezelStyle:NSInlineBezelStyle];
    }

    // Button type
    if(option.GetString("buttontype",&buttontype)) {
      options->SetString("buttontype",buttontype);
      if(buttontype == "light") [button setButtonType:NSMomentaryLightButton];
      else if(buttontype == "pushonoff") [button setButtonType:NSPushOnPushOffButton];
      else if(buttontype == "toggle") [button setButtonType:NSToggleButton];
      else if(buttontype == "switch") [button setButtonType:NSSwitchButton];
      else if(buttontype == "radio") [button setButtonType:NSRadioButton];
      else if(buttontype == "momentarychange") [button setButtonType:NSMomentaryChangeButton];
      else if(buttontype == "onoff") [button setButtonType:NSOnOffButton];
      else if(buttontype == "momentarypushin") [button setButtonType:NSMomentaryPushInButton];
      else if(buttontype == "momentarypush") [button setButtonType:NSMomentaryPushButton];
    }

    /* Button gradient -- needs NSButtonCell
    if(option.GetString("gradient",&gradient)) {
      options->SetString("gradient",gradient);
      if(gradient == "none") [button setGradientType:NSGradientNone];
      else if(gradient == "concaveweak") [button setGradientType:NSGradientConcaveWeak];
      else if(gradient == "concavestrong") [button setGradientType:NSGradientConcaveStrong];
      else if(gradient == "convexstrong") [button setGradientType:NSGradientConvexStrong];
      else if(gradient == "convexweak") [button setGradientType:NSGradientConvexWeak];
    } */

    // Button height and width
    double width, height;
    if(option.GetDouble("width",&width) && option.GetDouble("height", &height)) {
      options->SetDouble("width",width);
      options->SetDouble("height",height);
      [button setFrameSize:NSMakeSize(width, height)];
    }
  }
}
@end

@implementation TintButton
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



