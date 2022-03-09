//
//  Value.swift
//  DDSwiftRuntime
//
//  Created by dondong on 2022/3/2.
//

import Foundation

public struct RelativeContextPointer {
    fileprivate let _value: Int32;
    var rawvalue: Int32 { get { return self._value; } }
    var pointer: OpaquePointer? { mutating get { return Self.getPointer(&self); } }
    static func getPointer(_ ptr: UnsafePointer<RelativeContextPointer>) -> OpaquePointer? {
        if (0 != ptr.pointee._value) {
            if ((ptr.pointee._value & 1) != 0) {
                return UnsafePointer<OpaquePointer>(OpaquePointer(bitPattern:Int(bitPattern:ptr) + Int(ptr.pointee._value & ~1)))?.pointee;
            } else {
                return OpaquePointer(bitPattern:Int(bitPattern:ptr) + Int(ptr.pointee._value & ~1));
            }
        } else {
            return nil;
        }
    }
}

public struct RelativeDirectPointer {
    fileprivate let _value: Int32;
    var rawvalue: Int32 { get { return self._value; } }
    var pointer: OpaquePointer? { mutating get { return Self.getPointer(&self); } }
    static func getPointer(_ ptr: UnsafePointer<RelativeDirectPointer>) -> OpaquePointer? {
        if (0 != ptr.pointee._value) {
            return OpaquePointer(bitPattern:Int(bitPattern:ptr) + Int(ptr.pointee._value));
        } else {
            return nil;
        }
    }
}
public struct FunctionPointer {
    fileprivate let _value: OpaquePointer;
    init(_ val: OpaquePointer) {
        self._value = val;
    }
    var functionName: String {
        get {
            if (Int(bitPattern:self._value) != 0) {
                var info = dl_info();
                dladdr(UnsafeRawPointer(self._value), &info);
                return String(cString:info.dli_sname);
            } else {
                return "";
            }
        }
    }
}
