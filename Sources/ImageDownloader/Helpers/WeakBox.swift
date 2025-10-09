//
//  WeakBox.swift
//  ImageDownloader
//
//  Weak reference wrapper to prevent retain cycles
//

import Foundation

/// Weak reference wrapper
internal final class WeakBox<T: AnyObject> {
    weak var value: T?

    init(_ value: T?) {
        self.value = value
    }
}
