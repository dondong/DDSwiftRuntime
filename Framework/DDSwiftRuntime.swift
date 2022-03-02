//
//  DDSwiftRuntime.swift
//  DDSwiftRuntime
//
//  Created by dondong on 2022/2/22.
//

import Foundation
import MachO
import Darwin
import UIKit


class DDSwiftRuntime {
    static func getAllSwiftList<T>() -> [UnsafePointer<T>] {
        var list = [UnsafePointer<T>]();
        for i in 0..<_dyld_image_count() {
            list.append(contentsOf:Self.getSwiftList(i));
        }
        return list;
    }
    
    static func getMainSwiftList<T>() -> [UnsafePointer<T>] {
        for i in 0..<_dyld_image_count() {
            let header = _dyld_get_image_header(i);
            if (header!.pointee.filetype == MH_EXECUTE) {
                return Self.getSwiftList(i);
            }
        }
        return [UnsafePointer<T>]();
    }
    
    static func getSwiftList<T>(_ imageIndex: UInt32) -> [UnsafePointer<T>] {
        var segname = "";
        var sectname = "";
        if (T.self == ContextDescriptor.self) {
            segname = "__TEXT";
            sectname = "__swift5_types";
        } else if (T.self == ProtocolConformanceDescriptor.self) {
            segname = "__TEXT";
            sectname = "__swift5_proto";
        } else if (T.self == ProtocolDescriptor.self) {
            segname = "__TEXT";
            sectname = "__swift5_protos";
        } else {
            return [UnsafePointer<T>]();
        }
        var list = [UnsafePointer<T>]();
        if (imageIndex < _dyld_image_count()) {
            let header = unsafeBitCast(_dyld_get_image_header(imageIndex), to:UnsafePointer<mach_header_64>.self);
            var size: UInt = 0;
            guard let sect = getsectiondata(header, segname, sectname, &size) else { return list; }
            let ptr = UnsafePointer<RelativeDirectPointer>(OpaquePointer(sect));
            size = size / UInt(MemoryLayout<RelativeDirectPointer>.size);
            for i in 0..<size {
                guard let p = RelativeDirectPointer.getPointer(ptr.advanced(by:Int(i))) else { continue; }
                let type = UnsafeMutablePointer<T>(p);
                list.append(type);
            }
        }
        return list;
    }
    // type
    static func getAllSwiftTypeList() -> [UnsafePointer<ContextDescriptor>] { return Self.getAllSwiftList(); }
    static func getMainSwiftTypeList() -> [UnsafePointer<ContextDescriptor>] { return Self.getMainSwiftList(); }
    static func getSwiftTypeList(_ imageIndex: UInt32) -> [UnsafePointer<ContextDescriptor>] { return Self.getSwiftList(imageIndex); }
    // protocol conformance
    static func getAllSwiftProtocolConformanceList() -> [UnsafePointer<ProtocolConformanceDescriptor>] { return Self.getAllSwiftList(); }
    static func getMainSwiftProtocolConformanceList() -> [UnsafePointer<ProtocolConformanceDescriptor>] { return Self.getMainSwiftList(); }
    static func getSwiftProtocolConformanceList(_ imageIndex: UInt32) -> [UnsafePointer<ProtocolConformanceDescriptor>] { return Self.getSwiftList(imageIndex); }
    // protocol
    static func getAllSwiftProtocolList() -> [UnsafePointer<ProtocolDescriptor>] { return Self.getAllSwiftList(); }
    static func getMainSwiftProtocolList() -> [UnsafePointer<ProtocolDescriptor>] { return Self.getMainSwiftList(); }
    static func getSwiftProtocolList(_ imageIndex: UInt32) -> [UnsafePointer<ProtocolDescriptor>] { return Self.getSwiftList(imageIndex); }
    
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
}
