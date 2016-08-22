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

// Tracks listeners subscribed to an event stream and makes it easy to dispatch events to all subscribed listeners
class EventDispatcher {

    var serial = false  // If true, the listeners are dispatched serially

    // Subscribe to the events dispatched by the EventManager
    func startListening(listener: AnyObject) {
        dispatch_barrier_async(listenersListLockQueue) { [weak self] in
            if let this = self {
                this.listeners = this.listeners.filter{$0 !== listener}
                this.listeners.append(listener)
            }
        }
    }

    // Unsubscribe to the events dispatched by the EventManager
    func stopListening(listener: AnyObject) {
        dispatch_barrier_async(listenersListLockQueue) { [weak self] in
            if let this = self {
                this.listeners = this.listeners.filter{$0 !== listener}
            }
        }
    }

    // Called by the dispatcher to run action on each of the subscribed listeners
    func forEachListener(action: (AnyObject)->Void) {
        dispatch_async(listenersListLockQueue) { [weak self] in
            if let this = self {
                for listener in this.listeners {
                    this.scheduleAction(action, forListener: listener)
                }
            }
        }
    }

    private var listeners: [AnyObject] = []
    private let listenersListLockQueue = dispatch_queue_create("com.poshdevelopment.event_manager_lock", nil)  // Lock when using listeners
    private let dispatchQueue = dispatch_queue_create("com.poshdevelopment.event_manager_lock", nil)

    private func scheduleAction(action: (AnyObject)->Void, forListener listener: AnyObject) {
        let block = { () -> Void in
            action(listener)
        }
        if (serial) {
            dispatch_barrier_async(dispatchQueue, block)
        } else {
            dispatch_async(dispatchQueue, block)
        }
    }
}

private class WeakRef {
    private weak var _value: AnyObject?
    var value: AnyObject? { return _value }

    init(_ object: AnyObject) {
        self._value = object
    }
}