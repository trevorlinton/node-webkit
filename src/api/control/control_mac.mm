// Copyright (c) 2013 True Interactions
// Copyright (c) 2012 The Chromium Authors
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy 
// of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell co
// pies of the Software, and to permit persons to whom the Software is furnished
//  to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in al
// l copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IM
// PLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNES
// S FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
//  OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WH
// ETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <Cocoa/Cocoa.h>

#include "base/message_loop/message_loop.h"
#include "base/mac/scoped_sending_event.h"
#include "base/values.h"
#include "content/public/browser/web_contents.h"
#include "content/public/browser/web_contents_view.h"
#include "content/nw/src/api/control/control.h"
#include "content/nw/src/browser/native_window_mac.h"
#include "content/nw/src/nw_shell.h"

namespace nwapi {

void Control::Create(const base::DictionaryValue& option) {
  control_delegate_ = [[ControlDelegateMac alloc] initWithOptions:option];
}

void Control::Destroy() {
  [control_delegate_ release];
}

void Control::Append(Control* control) {
  if([[control_delegate_ type] isEqualToString:@"toolbar"]) {
    [control_delegate_ append:control];
  }
}

void Control::Insert(Control* control, int pos) {
  if([[control_delegate_ type]  isEqualToString:@"toolbar"]) {
    [control_delegate_ insert:control atIndex:pos];
  }
}

void Control::Remove(Control* control, int pos) {
  if([[control_delegate_ type]  isEqualToString:@"toolbar"]) {
    [control_delegate_ removeAtIndex:pos];
  }
}

void Control::ProcessOptions(const base::DictionaryValue& option) {
  [control_delegate_ processOptions:option];
}

std::string Control::GetName() {
  return std::string([[control_delegate_ name] UTF8String]);
}

std::string Control::GetType() {
  return std::string([[control_delegate_ type] UTF8String]);
}

base::DictionaryValue *Control::GetOptions() {
  return [control_delegate_ options];
}

NSObject *Control::GetNSObject() {
  return [control_delegate_ getBackObj];
}

}  // namespace nwapi
