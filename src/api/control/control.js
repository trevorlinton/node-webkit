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

var v8_util = process.binding('v8_util');

function Control(option) {
  if(typeof(option.customizable) == undefined) option.customizable = true;
  v8_util.setHiddenValue(this, 'items', []);
  nw.allocateObject(this, option);
}
require('util').inherits(Control, exports.Base);

Control.prototype.__defineGetter__('items', function() {
  return v8_util.getHiddenValue(this, 'items');
});

Control.prototype.__defineSetter__('items', function(val) {
  throw new String('Control.items is immutable');
});

Control.prototype.append = function(control_item) {
  //if (v8_util.getConstructorName(control_item) != 'Control')
  //  throw new String("Control.append() requires a valid Control");
    
  this.items.push(control_item);
  nw.callObjectMethod(this, 'Append', [ control_item.id ]);
};

Control.prototype.insert = function(control_item, i) {
  this.items.splice(i, 0, control_item);
  nw.callObjectMethod(this, 'Insert', [ control_item.id, i ]);
}

Control.prototype.remove = function(control_item) {
  var pos_hint = this.items.indexOf(control_item);
  nw.callObjectMethod(this, 'Remove', [ control_item.id, pos_hint ]);
  this.items.splice(pos_hint, 1);
}

Control.prototype.removeAt = function(i) {
  nw.callObjectMethod(this, 'Remove', [ this.items[i].id, i ]);
  this.items.splice(i, 1);
}

Control.prototype.handleEvent = function(ev) {
  if (ev == 'click') {
    // Emit click handler
    if (typeof this.click == 'function')
      this.click();
  }
  if (ev == 'focus') {
    // Emit click handler
    if (typeof this.focus == 'function')
      this.focus();
  }
  if (ev == 'blur') {
    // Emit click handler
    if (typeof this.blur == 'function')
      this.blur();
  }
  if (ev == 'mousedown') {
    // Emit click handler
    if (typeof this.mousedown == 'function')
      this.mousedown();
  }
  if (ev == 'mouseup') {
    // Emit click handler
    if (typeof this.mouseup == 'function')
      this.mouseup();
  }
  if (ev == 'keydown') {
    // Emit click handler
    if (typeof this.keydown == 'function')
      this.keydown();
  }
  if (ev == 'keyup') {
    // Emit click handler
    if (typeof this.keyup == 'function')
      this.keyup();
  }
  if (ev == 'valuechange') {
    // Emit click handler
    if (typeof this.valuechange == 'function')
      this.valuechange();
  }
  if (ev == 'mouseenter') {
    // Emit click handler
    if (typeof this.mouseenter == 'function')
      this.mouseenter();
  }
  if (ev == 'mouseexit') {
    // Emit click handler
    if (typeof this.mouseexit == 'function')
      this.mouseexit();
  }
  if (ev == 'mousemove') {
    // Emit click handler
    if (typeof this.mousemove == 'function')
      this.mousemove();
  }
  // Emit generate event handler
  exports.Base.prototype.handleEvent.apply(this, arguments);
}

exports.Control = Control;
