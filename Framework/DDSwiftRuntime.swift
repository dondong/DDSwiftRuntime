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
    
    static func getObjcClassMetadata(_ meta: AnyClass) -> UnsafePointer<AnyClassMetadata>? { return getMetadata(meta); }
    static func getSwiftClassMetadata(_ meta: AnyClass) -> UnsafePointer<ClassMetadata>? { return getMetadata(meta); }
    static func getStructMetadata(_ meta: Any) -> UnsafePointer<StructMetadata>? { return getMetadata(meta); }
    static func getEnumMetadata(_ meta: Any) -> UnsafePointer<EnumMetadata>? { return getMetadata(meta); }
    
    static func getMetadata<T : MetadataInterface>(_ meta: Any) -> UnsafePointer<T>? {
        let ptr : OpaquePointer = Self._covert(meta);
        return Metadata.getFullMetadata(UnsafePointer<Metadata>(ptr));
    }
    
    static func _covert<T>(_ val: Any) -> T {
        var tmpVal = val;
        let tmpValPtr = withUnsafePointer(to: &tmpVal) { $0 };
        return UnsafeRawPointer.init(tmpValPtr).load(as:T.self);
    }
}
