// EventDispatcher.swift
// The MIT License (MIT)
// Copyright (c) 2016 Posh Development, LLC
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject
// to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
// ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
// CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import Foundation

private class WeakRef {
    private weak var _value: AnyObject?
    var value: AnyObject? { return _value }

    init(_ object: AnyObject) {
        self._value = object
    }
}

class EventManager {
    private var listeners: [WeakRef] = []
    private let listenerQueue = dispatch_queue_create("posh.winedefined.LockQueue", nil) // Lock when using listeners
    
    func startListening(listener: AnyObject) {
        dispatch_barrier_async(listenerQueue) { [weak self] in
            self?.listeners.append(WeakRef(listener))
        }
    }

    func stopListening(listener: AnyObject) {
        dispatch_barrier_async(listenerQueue) { [weak self] in
            if self == nil {
                return
            }
            self!.listeners = self!.listeners.filter{$0.value != nil}
        }
    }

    func forEachListener(action: (AnyObject)->Void, done: (()->Void)?) {
        dispatch_async(listenerQueue) { [weak self] in
            if self == nil {
                return
            }
            for listener in self!.listeners {
                if let existingListener = listener.value {
                    action(existingListener)
                }
            }
            if done != nil {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), done!)
            }
        }
    }
}
