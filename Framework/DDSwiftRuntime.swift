//
//  DDSwiftRuntime.swift
//  DDSwiftRuntime
//
//  Created by dondong on 2022/2/22.
//

import Foundation
import MachO
import Darwin

public class DDSwiftRuntime {
    // MARK: -
    // MARK: macho list
    // type
    public static func getAllSwiftTypeList() -> [UnsafePointer<ContextDescriptor>] { return Self._getAllSwiftList("__swift5_types"); }
    public static func getMainSwiftTypeList() -> [UnsafePointer<ContextDescriptor>] { return Self._getMainSwiftList("__swift5_types"); }
    public static func getSwiftTypeList(_ imageIndex: UInt32) -> [UnsafePointer<ContextDescriptor>] { return Self._getSwiftList(imageIndex, "__swift5_types"); }
    // protocol conformance
    public static func getAllSwiftProtocolConformanceList() -> [UnsafePointer<ProtocolConformanceDescriptor>] { return Self._getAllSwiftList("__swift5_proto"); }
    public static func getMainSwiftProtocolConformanceList() -> [UnsafePointer<ProtocolConformanceDescriptor>] { return Self._getMainSwiftList("__swift5_proto"); }
    public static func getSwiftProtocolConformanceList(_ imageIndex: UInt32) -> [UnsafePointer<ProtocolConformanceDescriptor>] { return Self._getSwiftList(imageIndex, "__swift5_proto"); }
    // protocol
    public static func getAllSwiftProtocolList() -> [UnsafePointer<ProtocolDescriptor>] { return Self._getAllSwiftList("__swift5_protos"); }
    public static func getMainSwiftProtocolList() -> [UnsafePointer<ProtocolDescriptor>] { return Self._getMainSwiftList("__swift5_protos"); }
    public static func getSwiftProtocolList(_ imageIndex: UInt32) -> [UnsafePointer<ProtocolDescriptor>] { return Self._getSwiftList(imageIndex, "__swift5_protos"); }
    
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
    // MARK: -
    // MARK: Metadata
    public static func getMetadata(classObject: AnyObject) -> UnsafePointer<Metadata> {
        let heapObject = unsafeBitCast(classObject, to:UnsafePointer<HeapObject>.self);
        return UnsafePointer<Metadata>(OpaquePointer(heapObject.pointee.metadata));
    }
    public static func getMetadata(anyValue: Any) -> UnsafePointer<Metadata> {
        var tmpVal = anyValue;
        let tmpValPtr = withUnsafePointer(to: &tmpVal) { $0 };
        let ptr = UnsafeRawPointer(tmpValPtr).advanced(by:MemoryLayout<OpaquePointer>.size * 3).load(as:OpaquePointer.self);
        return UnsafePointer<Metadata>(ptr);
    }
    public static func getObjcClassMetadata(_ type: AnyClass) -> UnsafePointer<AnyClassMetadata>? { return getMetadata(type); }
    public static func getSwiftClassMetadata(_ type: AnyClass) -> UnsafePointer<ClassMetadata>? { return getMetadata(type); }
    public static func getStructMetadata(_ type: Any.Type) -> UnsafePointer<StructMetadata>? { return getMetadata(type); }
    public static func getEnumMetadata(_ type: Any.Type) -> UnsafePointer<EnumMetadata>? { return getMetadata(type); }
    public static func getFunctionTypeMetadata(_ type: Any.Type) -> UnsafePointer<FunctionTypeMetadata>? { return getMetadata(type); }
    public static func getExistentialTypeMetadata(_ type: Any.Type) -> UnsafePointer<ExistentialTypeMetadata>? { return getMetadata(type); }
    public static func getMetatypeMetadata(_ type: Any.Type) -> UnsafePointer<MetatypeMetadata>? { return getMetadata(type); }
    public static func getObjCClassWrapperMetadata(_ type: Any.Type) -> UnsafePointer<ObjCClassWrapperMetadata>? { return getMetadata(type); }
    public static func getExistentialMetatypeMetadata(_ type: Any.Type) -> UnsafePointer<ExistentialMetatypeMetadata>? { return getMetadata(type); }
    public static func getMetadata<T : MetadataInterface>(_ type: Any.Type) -> UnsafePointer<T>? {
        var tmpType = type;
        let tmpTypePtr = withUnsafePointer(to: &tmpType) { $0 };
        let ptr = UnsafeRawPointer(tmpTypePtr).load(as:OpaquePointer.self);
        return Metadata.getFullMetadata(UnsafePointer<Metadata>(ptr));
    }
    
    // MARK: -
    // MARK: protocol
    public static func getSwiftProtocolConformances(_ meta: Any) -> [UnsafePointer<ProtocolConformanceDescriptor>] {
        var tmpVal = meta;
        let tmpValPtr = withUnsafePointer(to: &tmpVal) { $0 };
        let metaPtr = UnsafeRawPointer(tmpValPtr).load(as:UnsafePointer<Metadata>.self);
        var type: UnsafePointer<ContextDescriptor>! = nil;
        if (metaPtr.pointee.kind == .Class) {
            type = UnsafePointer<ContextDescriptor>(OpaquePointer(UnsafePointer<ClassMetadata>(OpaquePointer(metaPtr)).pointee.description));
        } else if (metaPtr.pointee.kind == .Struct) {
            type = UnsafePointer<ContextDescriptor>(OpaquePointer(UnsafePointer<StructMetadata>(OpaquePointer(metaPtr)).pointee.description));
        } else if (metaPtr.pointee.kind == .Enum) {
            type = UnsafePointer<ContextDescriptor>(OpaquePointer(UnsafePointer<EnumMetadata>(OpaquePointer(metaPtr)).pointee.description));
        } else {
            return [UnsafePointer<ProtocolConformanceDescriptor>]();
        }
        var list = [UnsafePointer<ProtocolConformanceDescriptor>]();
        let ptr = Self.getAllSwiftProtocolConformanceList();
        for i in 0..<ptr.count {
            if (ProtocolConformanceDescriptor.getTypeDescriptor(ptr[i]) == type) {
                list.append(ptr[i]);
            }
        }
        return list;
    }
    // MARK: -
    // MARK: private
}
//
//class DDInvocation {
//    var target: AnyObject;
//    var parameters: [Any];
//    var functionPtr: FunctionPointer;
//    var returnVal: Any?;
//    init?(target: AnyObject, parameters: [Any], functionName: String) {
//        let ptr = unsafeBitCast(target, to:UnsafePointer<HeapObject>.self);
//        let metadata = UnsafePointer<ClassMetadata>(OpaquePointer(ptr.pointee.metadata));
//        if let fun = metadata.pointee.getFunction(functionName) {
//            self.target = target;
//            self.parameters = parameters;
//            self.functionPtr = fun;
//        } else {
//            return nil;
//        }
//    }
//    
//    func invoke() {
//        
//    }
//}
