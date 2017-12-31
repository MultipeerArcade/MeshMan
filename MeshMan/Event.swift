//
//  WeakArray.swift
//  Rave
//
//  Created by Stefan Vasiljevic on 2017-10-31.
//  Copyright © 2017 WeMesh. All rights reserved.
//

import Foundation


/// Repesents an Event.
class Event<ArgT> {
	
	// This queue is used to do any operations that involve modification of the eventHandles array so that it is thread safe.
	private let eventQueue = DispatchQueue(label: "io.rave.EventHandlerArrayQueue")
	
	internal typealias Handler = (Any, ArgType)->() // Sender, Arguments
	typealias ArgType = ArgT
	
	internal class Handle {
		
		var handler: Handler
		var handleQueue: DispatchQueue
		
		init(_ handler: @escaping Handler, _ handleQueue: DispatchQueue) {
			self.handler = handler
			self.handleQueue = handleQueue
		}
		
	}
	
	/// Stores event handles that are used to track all subscribers to this event.
	private var eventHandles: [WeakReference<Handle>] = []
	
	
	/**
	Use to subscribe to this event. The closure you pass will be executed when the event is raised.
	You can also specify a queue for handler to be executed on.
	- Important:
	When the returned `Event<ArgT>.Handle` is deinited, handler you have subscribed to the event will stop being executed when event is raised.
	Also, make sure you always pass `self` as `[weak self]` to the handler to avoid memory leaks and allow subscriber class to deinit.
	
	- Parameters:
	   - handler: Closure to execute when event is raised.
	   - queue: Prefered DispatchQueue for handler to be executed on. Default is <code>DispatchQueue.main<code>
	- Returns: Event handle that you have to keep a reference to in order to keep getting the event
	
	Example of usage:
	``` Swift
	class ObservableClass {
		var propertyChangedEvent = Event<String>()
	
		var property: String = "" {
			didSet {
				propertyChangedEvent(sender: self, arguments: self.property)
			}
		}
	}
	
	class SubscriberClass {
		private let observableClass: ObservableClass
		private var handle: Event<String>.Handle? = nil
		private var newObservableValue: String? = nil
	
		init(_ newObservableClass: ObservableClass) {
			self.observableClass = newObservableClass
			self.handle = self.observableClass.propertyChangedEvent.subscribe(queue: DispatchQueue.main) { [weak self] sender, arg in
				self?.newObservableValue = arg // This is where you should add your code to react to the Event
			}
		}
	}
	
	let observableClass = ObservableClass()
	let subscriberClass = SubscriberClass(observableClass)
	```
	*/
	internal func subscribe(queue: DispatchQueue, withHandler handler: @escaping Handler) -> Handle {
		let handle = Handle(handler, queue)
		
		self.eventQueue.async {
			self.eventHandles.append(WeakReference(handle))
		}
		
		return handle
	}

	/**
	Use to subscribe to this event. The closure you pass will be executed when the event is raised and it will be called on the Main queue
	You can also specify a queue for handler to be executed on.
	- Important:
	When the returned `Event<ArgT>.Handle` is deinited, handler you have subscribed to the event will stop being executed when event is raised.
	Also, make sure you always pass `self` as `[weak self]` to the handler to avoid memory leaks and allow subscriber class to deinit.
	
	- Parameters:
		- handler: Closure to execute when event is raised.
		- Returns: Event handle that you have to keep a reference to in order to keep getting the event
	
	Example of usage:
	``` Swift
	class ObservableClass {
		var propertyChangedEvent = Event<String>()
	
		var property: String = "" {
			didSet {
				propertyChangedEvent(sender: self, arguments: self.property)
			}
		}
	}
	
	class SubscriberClass {
		private let observableClass: ObservableClass
		private var handle: Event<String>.Handle? = nil
		private var newObservableValue: String? = nil
	
		init(_ newObservableClass: ObservableClass) {
			self.observableClass = newObservableClass
			self.handle = self.observableClass.propertyChangedEvent.subscribe() { [weak self] sender, arg in
				self?.newObservableValue = arg // This is where you should add your code to react to the Event
			}
		}
	}
	
	let observableClass = ObservableClass()
	let subscriberClass = SubscriberClass(observableClass)
	```
	*/
	internal func subscribe(_ handler: @escaping Handler) -> Handle {
		return self.subscribe(queue: DispatchQueue.main, withHandler: handler)
	}
	
	internal func raise(sender: Any, arguments: ArgType, whileTrimmingHandlers trimHandlers: Bool = true) {
		self.eventQueue.async {
			if trimHandlers {
				self.trimHandlers()
			}
			
			for weakHandle in self.eventHandles {
				weakHandle.value?.handleQueue.async {
					weakHandle.value?.handler(sender, arguments)
				}
			}
		}
	}
	
	private func trimHandlers() {
		self.eventHandles = self.eventHandles.filter {$0.value != nil }
	}
	
	/// Removes all handlers that are no longer referenced by the subscriber
	internal func trim(completion: (()->())? = nil) {
		self.eventQueue.async {
			self.trimHandlers()
			if let completion = completion {
				DispatchQueue.main.async {
					completion()
				}
			}
		}
	}
	
	/// Current handler count including handlers that are no longer referenced by the subscriber. If you want to get the number of actual subscribers call the <code>trim()<code> function first.
	internal var handlerCount: Int {
		var count = 0
		self.eventQueue.sync {
			 count = self.eventHandles.count
		}
		
		return count
	}
	
}


/// Stores a weak reference to an object passed into in during initilization.
class WeakReference<T: AnyObject> {
	
	private(set) weak var value: T?
	
	init(_ value: T?) {
		self.value = value
	}
	
}

