//
//  MetadataExtension.swift
//  DDSwiftRuntime
//
//  Created by dondong on 2022/3/4.
//

import Foundation

extension Metadata {
    static func getFullMetadata<T : MetadataInterface>(_ data: UnsafePointer<Metadata>) -> UnsafePointer<T>? {
        if (T.classof(data)) {
            return UnsafePointer<T>(OpaquePointer(data));
        } else {
            return nil;
        }
    }
}
