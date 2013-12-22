// (c) 2013 True Interactions

#include "base/values.h"
#include "content/nw/src/api/control/control.h"
#include "content/nw/src/api/control/control_delegate_mac.h"
#include "content/nw/src/net/util/embed_utils.h"
#include "content/nw/src/nw_shell.h"
#include "content/nw/src/nw_package.h"

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
      NSToolbar *toolbar = (NSToolbar *)control_;
      [toolbar setDelegate:self];
    } else if ([self.type isEqualToString:@"button"]) {
      control_ = [[TintButton alloc] initWithFrame:NSMakeRect(1, 1, 30, 30)];
      [(TintButton *)control_ setNative:self.native];
    } else if ([self.type isEqualToString:@"searchfield"]) {
      control_ = [[TintSearchField alloc] initWithFrame:NSMakeRect(1, 1, 30, 30)];
      [(TintSearchField *)control_ setNative:self.native];
    } else if ([self.type isEqualToString:@"slider"]) {
      control_ = [[TintSlider alloc] initWithFrame:NSMakeRect(1, 1, 30, 30)];
      [(TintSlider *)control_ setNative:self.native];
    } else if ([self.type isEqualToString:@"textfield"]) {
      control_ = [[TintSearchField alloc] initWithFrame:NSMakeRect(1, 1, 30, 30)];
      [(TintSearchField *)control_ setNative:self.native];
    } else if ([self.type isEqualToString:@"popupbutton"]) {
      control_ = [[TintPopUpButton alloc] initWithFrame:NSMakeRect(1, 1, 30, 30) pullsDown:YES];
      [(TintSearchField *)control_ setNative:self.native];
    } else if ([self.type isEqualToString:@"segmentedbutton"]) {
    } else if ([self.type isEqualToString:@"comboxbox"]) {
      control_ = [[TintComboBox alloc] initWithFrame:NSMakeRect(1, 1, 30, 30)];
      [(TintComboBox *)control_ setNative:self.native];
    } else if ([self.type isEqualToString:@"popupitem"]) {
    } else if ([self.type isEqualToString:@"comboboxitem"]) {
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
  if([self.type isEqualToString:@"toolbar"]) {
    NSValue *obj = [NSValue valueWithPointer:item];
    [self.items addObject:obj];
    NSString *ident = [NSString stringWithCString:item->GetName().c_str() encoding:[NSString defaultCStringEncoding]];
    [((NSToolbar *)control_)
      insertItemWithItemIdentifier:(NSString *)ident
      atIndex:[self.items indexOfObject:obj]];
  } else if ([self.type isEqualToString:@"popupbutton"]) {
    NSValue *obj = [NSValue valueWithPointer:item];
    TintPopUpButton *field = (TintPopUpButton *)control_;
    [self.items addObject:obj];
    [field addItemWithTitle:(NSString *)item->GetNSObject()];
  } else if ([self.type isEqualToString:@"comboxbox"]) {
    NSValue *obj = [NSValue valueWithPointer:item];
    TintComboBox *field = (TintComboBox *)control_;
    [self.items addObject:obj];
    [field addItemWithObjectValue:(NSString *)item->GetNSObject()];
  }
}
- (void)insert:(nwapi::Control *)item atIndex:(int)pos {
  if([self.type isEqualToString:@"toolbar"]) {
    NSValue *obj = [NSValue valueWithPointer:item];
    [self.items insertObject:obj atIndex:pos];
    NSString *ident = [NSString stringWithCString:item->GetName().c_str() encoding:[NSString defaultCStringEncoding]];
    [((NSToolbar *)control_)
     insertItemWithItemIdentifier:(NSString *)ident
     atIndex:[self.items indexOfObject:obj]];
  } else if ([self.type isEqualToString:@"popupbutton"]) {
    /* Settings for popup */
    NSValue *obj = [NSValue valueWithPointer:item];
    TintPopUpButton *field = (TintPopUpButton *)control_;
    [self.items insertObject:obj atIndex:pos];
    [field insertItemWithTitle:(NSString *)item->GetNSObject() atIndex:pos];
  } else if ([self.type isEqualToString:@"comboxbox"]) {
    NSValue *obj = [NSValue valueWithPointer:item];
    TintComboBox *field = (TintComboBox *)control_;
    [self.items insertObject:obj atIndex:pos];
    [field insertItemWithObjectValue:(NSString *)item->GetNSObject() atIndex:pos];
  }
}
- (void)removeAtIndex:(int)pos {
  if([self.type isEqualToString:@"toolbar"]) {
    [((NSToolbar *)control_) removeItemAtIndex:pos];
    [self.items removeObjectAtIndex:pos];
  } else if ([self.type isEqualToString:@"popupbutton"]) {
    [((TintPopUpButton *)control_) removeItemAtIndex:pos];
    [self.items removeObjectAtIndex:pos];
  } else if ([self.type isEqualToString:@"popupbutton"]) {
    [((TintComboBox *)control_) removeItemAtIndex:pos];
    [self.items removeObjectAtIndex:pos];
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
  if([self.type isEqualToString:@"toolbar"])
  {
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
  }
  else if ([self.type isEqualToString:@"button"] || [self.type isEqualToString:@"popupbutton"])
  {
    /* Settings for button */
    NSButton *button = (NSButton *)control_;

    bool border;
    std::string label;
    std::string tooltip;
    std::string buttontype;
    std::string style;
    std::string gradient;
    std::string image;

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

    // Button image
    if(option.GetString("image",&image)) {
      options->SetString("image",image);
      if (!image.empty()) {
        NSImage *icon;
        embed_util::FileMetaInfo meta;
        if(embed_util::Utility::GetFileInfo(image,&meta) && embed_util::Utility::GetFileData(&meta)) {
          icon = [[NSImage alloc] initWithData:[NSData dataWithBytes:meta.data length:meta.data_size]];
        } else {
          nw::Package* pkg = content::Shell::GetPackage();
          icon = [[NSImage alloc]
                  initWithContentsOfFile:[NSString stringWithUTF8String:pkg->path().AppendASCII(image.c_str()).AsUTF8Unsafe().c_str()]];
        }
        [icon setScalesWhenResized:YES];
        [icon setSize:[button frame].size];
        [button setImage:icon];
        [icon release];
      } else {
        [button setImage:nil];
      }
    }

    // Button height and width
    double width, height;
    if(option.GetDouble("width",&width) && option.GetDouble("height", &height)) {
      options->SetDouble("width",width);
      options->SetDouble("height",height);
      [button setFrameSize:NSMakeSize(width, height)];
    } else
      [button sizeToFit];
    [button setNeedsDisplay:YES];
  }
  else if ([self.type isEqualToString:@"combobox"] || [self.type isEqualToString:@"textfield"] || [self.type isEqualToString:@"searchfield"])
  {
    /* Settings for text field*/
    NSTextField *field = (NSTextField *)control_;

    bool editable;
    bool selectable;
    bool border;
    bool bezeled;
    std::string bezeledstyle;

    // Text field border
    if(option.GetBoolean("border", &border)) {
      if(border) [field setBordered:YES];
      else [field setBordered:NO];
      options->SetBoolean("border",border);
    }

    // Text field bezel
    if(option.GetBoolean("bezeled", &bezeled)) {
      if(border) [field setBezeled:YES];
      else [field setBezeled:NO];
      options->SetBoolean("bezeled",bezeled);
    }

    // Text field editable
    if(option.GetBoolean("editable", &editable)) {
      if(border) [field setEditable:YES];
      else [field setEditable:NO];
      options->SetBoolean("editable",editable);
    }

    // Text field selectable
    if(option.GetBoolean("selectable", &selectable)) {
      if(border) [field setSelectable:YES];
      else [field setSelectable:NO];
      options->SetBoolean("selectable",selectable);
    }

    // Text field bezeled  style
    if(option.GetString("bezeledstyle",&bezeledstyle)) {
      options->SetString("bezeledstyle",bezeledstyle);
      if(bezeledstyle=="round")
        [field setBezelStyle:NSTextFieldRoundedBezel];
      else
        [field setBezelStyle:NSTextFieldSquareBezel];
    }

    double width, height;
    if(option.GetDouble("width",&width) && option.GetDouble("height", &height)) {
      options->SetDouble("width",width);
      options->SetDouble("height",height);
      [field setFrameSize:NSMakeSize(width, height)];
    } else
      [field sizeToFit];
    [field setNeedsDisplay:YES];
  }
  else if ([self.type isEqualToString:@"slider"])
  {
    /* Settings for slider */
    TintSlider *field = (TintSlider *)control_;

    double max, min;
    if(option.GetDouble("max",&max) && option.GetDouble("min", &min)) {
      options->SetDouble("max",max);
      options->SetDouble("min",min);
      [field setMaxValue:max];
      [field setMinValue:min];
    }

    double width, height;
    if(option.GetDouble("width",&width) && option.GetDouble("height", &height)) {
      options->SetDouble("width",width);
      options->SetDouble("height",height);
      [field setFrameSize:NSMakeSize(width, height)];
    } else
      [field sizeToFit];
    [field setNeedsDisplay:YES];
  }
  else if ([self.type isEqualToString:@"popupitem"] || [self.type isEqualToString:@"comboboxitem"])
  {
    std::string label;

    // Popup label (actually title)
    if(option.GetString("label",&label)) {
      options->SetString("label",label);
      control_ = [NSString stringWithCString:label.c_str() encoding:[NSString defaultCStringEncoding]];
    }
  }

}
@end

@implementation TintButton
- (id)initWithFrame:(NSRect)frame {
  NSTrackingArea *trackingArea;
  self = [super initWithFrame:frame];
  if (self) {
    trackingArea = [[NSTrackingArea alloc] initWithRect:frame
                                                options: (NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow )
                                                  owner:self userInfo:nil];
    [self addTrackingArea:trackingArea];
  }
  return self;
}
- (BOOL)acceptsFirstResponder {
  return YES;
}
- (void)mouseDown:(NSEvent *)theEvent {
  [super mouseDown:theEvent];
  self.native->OnMouseDown();
}
- (void)mouseUp:(NSEvent *)theEvent {
  [super mouseUp:theEvent];
  self.native->OnMouseUp();
  self.native->OnClick();
}
- (void)mouseMoved:(NSEvent *)theEvent {
  [super mouseMoved:theEvent];
  self.native->OnMouseMove();
}
- (void)mouseEntered:(NSEvent *)theEvent {
  [super mouseEntered:theEvent];
  self.native->OnMouseEnter();
}
- (void)mouseExited:(NSEvent *)theEvent {
  [super mouseExited:theEvent];
  self.native->OnMouseExit();
}
- (void)keyDown:(NSEvent *)theEvent {
  [super keyDown:theEvent];
  self.native->OnKeyDown();
}
- (void)keyUp:(NSEvent *)theEvent {
  [super keyUp:theEvent];
  self.native->OnKeyUp();
}
@end

@implementation TintTextField
- (id)initWithFrame:(NSRect)frame {
  NSTrackingArea *trackingArea;
  self = [super initWithFrame:frame];
  if (self) {
    trackingArea = [[NSTrackingArea alloc] initWithRect:frame
                                                options: (NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow )
                                                  owner:self userInfo:nil];
    [self addTrackingArea:trackingArea];
  }
  return self;
}
- (BOOL)acceptsFirstResponder {
  return YES;
}
- (void)mouseDown:(NSEvent *)theEvent {
  [super mouseDown:theEvent];
  self.native->OnMouseDown();
}
- (void)mouseUp:(NSEvent *)theEvent {
  [super mouseUp:theEvent];
  self.native->OnMouseUp();
  self.native->OnClick();
}
- (void)mouseMoved:(NSEvent *)theEvent {
  [super mouseMoved:theEvent];
  self.native->OnMouseMove();
}
- (void)mouseEntered:(NSEvent *)theEvent {
  [super mouseEntered:theEvent];
  self.native->OnMouseEnter();
}
- (void)mouseExited:(NSEvent *)theEvent {
  [super mouseExited:theEvent];
  self.native->OnMouseExit();
}
- (void)keyDown:(NSEvent *)theEvent {
  [super keyDown:theEvent];
  self.native->OnKeyDown();
}
- (void)keyUp:(NSEvent *)theEvent {
  [super keyUp:theEvent];
  self.native->OnKeyUp();
}
@end

@implementation TintSearchField
- (id)initWithFrame:(NSRect)frame {
  NSTrackingArea *trackingArea;
  self = [super initWithFrame:frame];
  if (self) {
    trackingArea = [[NSTrackingArea alloc] initWithRect:frame
                                                options: (NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow )
                                                  owner:self userInfo:nil];
    [self addTrackingArea:trackingArea];
  }
  return self;
}
- (BOOL)acceptsFirstResponder {
  return YES;
}
- (void)mouseDown:(NSEvent *)theEvent {
  [super mouseDown:theEvent];
  self.native->OnMouseDown();
}
- (void)mouseUp:(NSEvent *)theEvent {
  [super mouseUp:theEvent];
  self.native->OnMouseUp();
  self.native->OnClick();
}
- (void)mouseMoved:(NSEvent *)theEvent {
  [super mouseMoved:theEvent];
  self.native->OnMouseMove();
}
- (void)mouseEntered:(NSEvent *)theEvent {
  [super mouseEntered:theEvent];
  self.native->OnMouseEnter();
}
- (void)mouseExited:(NSEvent *)theEvent {
  [super mouseExited:theEvent];
  self.native->OnMouseExit();
}
- (void)keyDown:(NSEvent *)theEvent {
  [super keyDown:theEvent];
  self.native->OnKeyDown();
}
- (void)keyUp:(NSEvent *)theEvent {
  [super keyUp:theEvent];
  self.native->OnKeyUp();
}
@end

@implementation TintSlider
- (id)initWithFrame:(NSRect)frame {
  NSTrackingArea *trackingArea;
  self = [super initWithFrame:frame];
  if (self) {
    trackingArea = [[NSTrackingArea alloc] initWithRect:frame
                                                options: (NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow )
                                                  owner:self userInfo:nil];
    [self addTrackingArea:trackingArea];
  }
  return self;
}
- (BOOL)acceptsFirstResponder {
  return YES;
}
- (void)mouseDown:(NSEvent *)theEvent {
  [super mouseDown:theEvent];
  self.native->OnMouseDown();
}
- (void)mouseUp:(NSEvent *)theEvent {
  [super mouseUp:theEvent];
  self.native->OnMouseUp();
  self.native->OnClick();
}
- (void)mouseMoved:(NSEvent *)theEvent {
  [super mouseMoved:theEvent];
  self.native->OnMouseMove();
}
- (void)mouseEntered:(NSEvent *)theEvent {
  [super mouseEntered:theEvent];
  self.native->OnMouseEnter();
}
- (void)mouseExited:(NSEvent *)theEvent {
  [super mouseExited:theEvent];
  self.native->OnMouseExit();
}
- (void)keyDown:(NSEvent *)theEvent {
  [super keyDown:theEvent];
  self.native->OnKeyDown();
}
- (void)keyUp:(NSEvent *)theEvent {
  [super keyUp:theEvent];
  self.native->OnKeyUp();
}
@end

@implementation TintPopUpButton
- (BOOL)acceptsFirstResponder {
  return YES;
}
- (void)mouseDown:(NSEvent *)theEvent {
  [super mouseDown:theEvent];
  self.native->OnMouseDown();
}
- (void)mouseUp:(NSEvent *)theEvent {
  [super mouseUp:theEvent];
  self.native->OnMouseUp();
  self.native->OnClick();
}
- (void)mouseMoved:(NSEvent *)theEvent {
  [super mouseMoved:theEvent];
  self.native->OnMouseMove();
}
- (void)mouseEntered:(NSEvent *)theEvent {
  [super mouseEntered:theEvent];
  self.native->OnMouseEnter();
}
- (void)mouseExited:(NSEvent *)theEvent {
  [super mouseExited:theEvent];
  self.native->OnMouseExit();
}
- (void)keyDown:(NSEvent *)theEvent {
  [super keyDown:theEvent];
  self.native->OnKeyDown();
}
- (void)keyUp:(NSEvent *)theEvent {
  [super keyUp:theEvent];
  self.native->OnKeyUp();
}
@end

@implementation TintComboBox
- (id)initWithFrame:(NSRect)frame {
  NSTrackingArea *trackingArea;
  self = [super initWithFrame:frame];
  if (self) {
    trackingArea = [[NSTrackingArea alloc] initWithRect:frame
                                                options: (NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow )
                                                  owner:self userInfo:nil];
    [self addTrackingArea:trackingArea];
  }
  return self;
}
- (BOOL)acceptsFirstResponder {
  return YES;
}
- (void)mouseDown:(NSEvent *)theEvent {
  [super mouseDown:theEvent];
  self.native->OnMouseDown();
}
- (void)mouseUp:(NSEvent *)theEvent {
  [super mouseUp:theEvent];
  self.native->OnMouseUp();
  self.native->OnClick();
}
- (void)mouseMoved:(NSEvent *)theEvent {
  [super mouseMoved:theEvent];
  self.native->OnMouseMove();
}
- (void)mouseEntered:(NSEvent *)theEvent {
  [super mouseEntered:theEvent];
  self.native->OnMouseEnter();
}
- (void)mouseExited:(NSEvent *)theEvent {
  [super mouseExited:theEvent];
  self.native->OnMouseExit();
}
- (void)keyDown:(NSEvent *)theEvent {
  [super keyDown:theEvent];
  self.native->OnKeyDown();
}
- (void)keyUp:(NSEvent *)theEvent {
  [super keyUp:theEvent];
  self.native->OnKeyUp();
}
@end
