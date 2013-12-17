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

#ifndef CONTENT_NW_SRC_API_CONTROL_CONTROL_H_
#define CONTENT_NW_SRC_API_CONTROL_CONTROL_H_ 


#include "base/memory/scoped_ptr.h"
#include "base/memory/weak_ptr.h"
#include "base/compiler_specific.h"
#include "content/nw/src/api/base/base.h"
#include <string>
#include <vector>

#if defined(OS_MACOSX)
#if __OBJC__
#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#include "base/mac/scoped_nsobject.h"
#include "content/nw/src/api/control/control_delegate_mac.h"

namespace nwapi {
class Control;
}
#else
class ControlDelegate;
#endif  // __OBJC__

namespace nw {
class NativeWindowCocoa;
}
#elif defined(OS_WIN)
namespace nw {
class NativeWindowWin;
}
#endif

namespace content {
class Shell;
}

namespace nwapi {
class Control : public Base {
 public:
  Control(int id,
       DispatcherHost* dispatcher_host,
       const base::DictionaryValue& option);
  virtual ~Control();

  virtual void Call(const std::string& method,
                    const base::ListValue& arguments) OVERRIDE;
  virtual void CallSync(const std::string& method,
                        const base::ListValue& arguments,
                        base::ListValue* result) OVERRIDE;

  // Configuring a control.
  void Create(const base::DictionaryValue& option);
  void Destroy();
  void Append(Control* control);
  void Insert(Control* control, int pos);
  void Remove(Control* control, int pos);
  void SetOptions(const base::DictionaryValue& options);
  base::DictionaryValue *GetOptions();
  void SetValue(const base::ListValue& value);
  base::ListValue *GetValue();

  // All control possible events
  void OnClick();
  void OnFocus();
  void OnBlur();
  void OnMouseDown();
  void OnMouseUp();
  void OnKeyDown();
  void OnKeyUp();
  void OnValueChange();
  void OnMouseEnter();
  void OnMouseExit();
  void OnMouseMove();

  std::string GetName();
  std::string GetType();
#if __OBJC__
  NSObject *GetNSObject();
#endif
 private:
#if defined(OS_MACOSX)
  friend class nw::NativeWindowCocoa;
#if __OBJC__
  ControlDelegateMac *control_delegate_;
#endif
#elif defined(OS_WIN)
  friend class nw::NativeWindowWin;
#endif

  DISALLOW_COPY_AND_ASSIGN(Control);
};

}  // namespace nwapi

#endif  // CONTENT_NW_SRC_API_CONTROL_CONTROL_H_
