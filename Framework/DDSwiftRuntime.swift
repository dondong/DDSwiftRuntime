//
//  DDSwiftRuntime.swift
//  DDSwiftRuntime
//
//  Created by dondong on 2022/2/22.
//

import Foundation
import MachO

class DDSwiftRuntime {
    static func getAllSwiftTypeList() -> [UnsafePointer<ContextDescriptor>] {
        var list = [UnsafePointer<ContextDescriptor>]();
        for i in 0..<_dyld_image_count() {
            list.append(contentsOf:Self.getSwiftTypeList(i));
        }
        return list;
    }
    
    static func getMainSwiftTypeList() -> [UnsafePointer<ContextDescriptor>] {
        for i in 0..<_dyld_image_count() {
            let header = _dyld_get_image_header(i);
            if (header!.pointee.filetype == MH_EXECUTE) {
                return Self.getSwiftTypeList(i);
            }
        }
        return [UnsafePointer<ContextDescriptor>]();
    }
    
    static func getSwiftTypeList(_ imageIndex: UInt32) -> [UnsafePointer<ContextDescriptor>] {
        var list = [UnsafePointer<ContextDescriptor>]();
        if (imageIndex < _dyld_image_count()) {
            let header = unsafeBitCast(_dyld_get_image_header(imageIndex), to:UnsafePointer<mach_header_64>.self);
            var size: UInt = 0;
            guard let sect = getsectiondata(header, "__TEXT", "__swift5_types", &size) else { return list; }
            let ptr = UnsafePointer<RelativeDirectPointer>(OpaquePointer(sect));
            size = size / UInt(MemoryLayout<RelativeDirectPointer>.size);
            for i in 0..<size {
                guard let p = Self.getPointerFromRelativeDirectPointer(ptr.advanced(by:Int(i))) else { continue; }
                let type = UnsafeMutablePointer<ContextDescriptor>(p);
                list.append(type);
            }
        }
        return list;
    }
    
    static func getObjcClass(_ cls: AnyClass) -> UnsafePointer<AnyClassMetadata> {
        let ptr = Unmanaged.passUnretained(cls as AnyObject).toOpaque();
        return UnsafePointer<AnyClassMetadata>.init(OpaquePointer(ptr));
    }
    
    static func getSwiftClass(_ cls: AnyClass) -> UnsafePointer<ClassMetadata>? {
        let opaquePtr = Unmanaged.passUnretained(cls as AnyObject).toOpaque();
        let ptr = UnsafePointer<AnyClassMetadata>.init(OpaquePointer(opaquePtr));
        if (ptr.pointee.isSwiftMetadata) {
            return Optional(UnsafePointer<ClassMetadata>.init(OpaquePointer(opaquePtr)));
        } else {
            return nil;
        }
    }
    
    static func covert<T>(_ val: Any) -> T {
        var tmpVal = val;
        let tmpValPtr = withUnsafePointer(to: &tmpVal) { $0 };
        return UnsafeRawPointer.init(tmpValPtr).load(as:T.self);
    }
    
    static func getPointerFromRelativeContextPointer(_ ptr: UnsafePointer<RelativeContextPointer>) -> OpaquePointer? {
        if (0 != ptr.pointee) {
            if ((ptr.pointee & 1) != 0) {
                return UnsafePointer<OpaquePointer>(OpaquePointer(bitPattern:Int(bitPattern:ptr) + Int(ptr.pointee & ~1)))?.pointee;
            } else {
                return OpaquePointer(bitPattern:Int(bitPattern:ptr) + Int(ptr.pointee & ~1));
            }
        } else {
            return nil;
        }
    }
    
    static func getPointerFromRelativeDirectPointer(_ ptr: UnsafePointer<RelativeDirectPointer>) -> OpaquePointer? {
        if (0 != ptr.pointee) {
            return OpaquePointer(bitPattern:Int(bitPattern:ptr) + Int(ptr.pointee));
        } else {
            return nil;
        }
    }
}
