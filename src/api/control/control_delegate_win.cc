// Copyright (c) 2012 Intel Corp
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

#include "content/nw/src/api/control/control_delegate_win.h"

#include "base/logging.h"
#include "base/strings/string16.h"
#include "content/nw/src/api/dispatcher_host.h"
#include "content/nw/src/api/controlitem/controlitem.h"

namespace nwapi {

ControlDelegate::ControlDelegate(DispatcherHost* dispatcher_host)
    : dispatcher_host_(dispatcher_host) {
}

ControlDelegate::~ControlDelegate() {
}

bool ControlDelegate::IsCommandIdChecked(int command_id) const {
  if (command_id < 0)
    return false;

  ControlItem* item = dispatcher_host_->GetApiObject<ControlItem>(command_id);
  return item->is_checked_;
}

bool ControlDelegate::IsCommandIdEnabled(int command_id) const {
  if (command_id < 0)
    return false;

  ControlItem* item = dispatcher_host_->GetApiObject<ControlItem>(command_id);
  if (!item)
    return false;
  return item->is_enabled_;
}

bool ControlDelegate::IsItemForCommandIdDynamic(int command_id) const {
  if (command_id < 0)
    return false;

  ControlItem* item = dispatcher_host_->GetApiObject<ControlItem>(command_id);
  if (!item)
    return false;
  return item->is_modified_;
}

string16 ControlDelegate::GetLabelForCommandId(int command_id) const {
  ControlItem* item = dispatcher_host_->GetApiObject<ControlItem>(command_id);
  return item->label_;
}

bool ControlDelegate::GetIconForCommandId(int command_id,
                                       gfx::Image* icon) const {
  ControlItem* item = dispatcher_host_->GetApiObject<ControlItem>(command_id);
  if (!item)
    return false;
  if (item->icon_.IsEmpty())
    return false;

  *icon = item->icon_;
  return true;
}

void ControlDelegate::ExecuteCommand(int command_id, int event_flags) {
  if (command_id < 0)
    return;

  ControlItem* item = dispatcher_host_->GetApiObject<ControlItem>(command_id);
  if (!item)
    return;
  item->OnClick();
}

bool ControlDelegate::HasIcon(int command_id) {
  if (command_id < 0)
    return false;

  ControlItem* item = dispatcher_host_->GetApiObject<ControlItem>(command_id);
  if (!item)
    return false;
  return !item->icon_.IsEmpty();
}

}  // namespace nwapi
