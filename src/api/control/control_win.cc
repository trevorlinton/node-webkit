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

#include "content/nw/src/api/control/control.h"

#include "base/values.h"
#include "content/nw/src/api/dispatcher_host.h"
#include "content/nw/src/browser/native_window_win.h"
#include "content/nw/src/nw_shell.h"
#include "content/public/browser/web_contents.h"
#include "content/public/browser/web_contents_view.h"
#include "skia/ext/image_operations.h"
#include "ui/gfx/gdi_util.h"
#include "ui/gfx/icon_util.h"
#include "ui/views/widget/widget.h"


namespace nwapi {

void Control::Create(const base::DictionaryValue& option) {
}

void Control::Destroy() {
}

void Control::Append(Control* control_item) {
}

void Control::Insert(Control* control_item, int pos) {
}

void Control::Remove(Control* control_item, int pos) {
}

void Control::SetOptions(const base::DictionaryValue& options) {
}

base::DictionaryValue *Control::GetOptions() {
  return NULL;
}

void Control::SetValue(const base::ListValue& value) {
}

base::ListValue *Control::GetValue() {
  return NULL;
} 
}
// namespace nwapi
