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
    // type
    static func getAllSwiftTypeList() -> [UnsafePointer<ContextDescriptor>] { return Self._getAllSwiftList("__swift5_types"); }
    static func getMainSwiftTypeList() -> [UnsafePointer<ContextDescriptor>] { return Self._getMainSwiftList("__swift5_types"); }
    static func getSwiftTypeList(_ imageIndex: UInt32) -> [UnsafePointer<ContextDescriptor>] { return Self._getSwiftList(imageIndex, "__swift5_types"); }
    // protocol conformance
    static func getAllSwiftProtocolConformanceList() -> [UnsafePointer<ProtocolConformanceDescriptor>] { return Self._getAllSwiftList("__swift5_proto"); }
    static func getMainSwiftProtocolConformanceList() -> [UnsafePointer<ProtocolConformanceDescriptor>] { return Self._getMainSwiftList("__swift5_proto"); }
    static func getSwiftProtocolConformanceList(_ imageIndex: UInt32) -> [UnsafePointer<ProtocolConformanceDescriptor>] { return Self._getSwiftList(imageIndex, "__swift5_proto"); }
    // protocol
    static func getAllSwiftProtocolList() -> [UnsafePointer<ProtocolDescriptor>] { return Self._getAllSwiftList("__swift5_protos"); }
    static func getMainSwiftProtocolList() -> [UnsafePointer<ProtocolDescriptor>] { return Self._getMainSwiftList("__swift5_protos"); }
    static func getSwiftProtocolList(_ imageIndex: UInt32) -> [UnsafePointer<ProtocolDescriptor>] { return Self._getSwiftList(imageIndex, "__swift5_protos"); }
    
    fileprivate static func _getAllSwiftList<T>(_ sectname: String) -> [UnsafePointer<T>] {
        var list = [UnsafePointer<T>]();
        for i in 0..<_dyld_image_count() {
            list.append(contentsOf:Self._getSwiftList(i, sectname));
        }
        return list;
    }
    
    fileprivate static func _getMainSwiftList<T>(_ sectname: String) -> [UnsafePointer<T>] {
        for i in 0..<_dyld_image_count() {
            let header = _dyld_get_image_header(i);
            if (header!.pointee.filetype == MH_EXECUTE) {
                return Self._getSwiftList(i, sectname);
            }
        }
        return [UnsafePointer<T>]();
    }
    
    fileprivate static func _getSwiftList<T>(_ imageIndex: UInt32, _ sectname: String) -> [UnsafePointer<T>] {
        var list = [UnsafePointer<T>]();
        if (imageIndex < _dyld_image_count()) {
            let header = unsafeBitCast(_dyld_get_image_header(imageIndex), to:UnsafePointer<mach_header_64>.self);
            var size: UInt = 0;
            guard let sect = getsectiondata(header, "__TEXT", sectname, &size) else { return list; }
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
    
    static func getObjcClass(_ cls: AnyClass) -> UnsafePointer<AnyClassMetadata> {
        let ptr = Unmanaged.passUnretained(cls as AnyObject).toOpaque();
        return UnsafePointer<AnyClassMetadata>.init(OpaquePointer(ptr));
    }
    
    static func getSwiftClass(_ cls: AnyClass) -> UnsafePointer<ClassMetadata>? {
        let opaquePtr = Unmanaged.passUnretained(cls as AnyObject).toOpaque();
        let ptr = UnsafePointer<AnyClassMetadata>(OpaquePointer(opaquePtr));
        if (ptr.pointee.isTypeMetadata) {
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
