//
//  MetadataExtension.swift
//  DDSwiftRuntime
//
//  Created by dondong on 2022/3/4.
//

import Foundation
import UIKit

extension Metadata {
    public static func getFullMetadata<T : MetadataInterface>(_ data: UnsafePointer<Metadata>) -> UnsafePointer<T>? {
        if (T.classof(data)) {
            return UnsafePointer<T>(OpaquePointer(data));
        } else {
            return nil;
        }
    }
}

fileprivate let RO_META: UInt32 = 1<<0;
fileprivate let RO_ROOT: UInt32 = 1<<1;
fileprivate let RO_HAS_CXX_STRUCTORS: UInt32 = 1<<2;
fileprivate let RO_HIDDEN: UInt32 = 1<<4;
fileprivate let RO_EXCEPTION: UInt32 = 1<<5;
fileprivate let RO_HAS_SWIFT_INITIALIZER: UInt32 = 1<<6;
fileprivate let RO_IS_ARC: UInt32 = 1<<7;
fileprivate let RO_HAS_CXX_DTOR_ONLY: UInt32 = 1<<8;
fileprivate let RO_HAS_WEAK_WITHOUT_ARC: UInt32 = 1<<9;
fileprivate let RO_FORBIDS_ASSOCIATED_OBJECTS: UInt32 = 1<<10;
fileprivate let RO_FROM_BUNDLE: UInt32 = 1<<29;
fileprivate let RO_FUTURE: UInt32 = 1<<30;
fileprivate let RO_REALIZED: UInt32 = 1<<31;
fileprivate let RW_REALIZED: UInt32 = 1<<31;
fileprivate let RW_FUTURE: UInt32 = 1<<30;
fileprivate let RW_INITIALIZED: UInt32 = 1<<29;
fileprivate let RW_INITIALIZING: UInt32 = 1<<28;
fileprivate let RW_COPIED_RO: UInt32 = 1<<27;
fileprivate let RW_CONSTRUCTING: UInt32 = 1<<26;
fileprivate let RW_CONSTRUCTED: UInt32 = 1<<25;
fileprivate let RW_LOADED: UInt32 = 1<<23;
fileprivate let RW_HAS_INSTANCE_SPECIFIC_LAYOUT: UInt32 = 1<<21;
fileprivate let RW_FORBIDS_ASSOCIATED_OBJECTS: UInt32 = 1<<20;
fileprivate let RW_REALIZING: UInt32 = 1<<19;
fileprivate let FAST_DATA_MASK: UInt = 0x00007ffffffffff8;
fileprivate let FlagMask: UInt32 = 0xffff0003;
fileprivate let smallMethodListFlag: UInt32 = 0x80000000;

public struct entsize_list_tt {
    public let entsizeAndFlags: UInt32;
    public let count: UInt32;
    public let first: uintptr_t;
};

public struct protocol_list_t {
    public let count: UInt64;
    public let first: uintptr_t;
};

public struct class_ro_t {
    public let flags: UInt32;
    public let instanceStart: UInt32;
    public let instacneSize: UInt32;
    public let reserved: UInt32;
    public let ivarLayout: UnsafePointer<UInt8>;
    public let name: UnsafePointer<CChar>;
    public let baseMethodList: UnsafePointer<entsize_list_tt>;
    public let baseProtocols: UnsafePointer<protocol_list_t>;
    public let ivars: UnsafePointer<entsize_list_tt>;
    public let weakIvarLayout: UnsafePointer<uintptr_t>;
    public let baseProperties: UnsafePointer<entsize_list_tt>;
}

extension class_ro_t {
    public var methodArray: [Method] {
        get {
            var ret = [Method]();
            let entsize = self.baseMethodList.pointee.entsizeAndFlags & ~FlagMask;
            let flags = self.baseMethodList.pointee.entsizeAndFlags & FlagMask;
            let fixOffset: Int = (flags & smallMethodListFlag) > 0 ? 1 : 0;   // no idea about this offset
            let ptr = UnsafeRawPointer(self.baseMethodList).advanced(by:MemoryLayout<UInt32>.size * 2 + fixOffset);
            print(self.baseMethodList)
            print(ptr)
            for i in 0..<self.baseMethodList.pointee.count {
                ret.append(Method(ptr.advanced(by:Int(i * entsize))));
            }
            return ret;
        }
    }
}

public struct class_rw_t {
    public let flags: UInt32;
    public let witness: UInt32;
//    public let index: UInt16;
    public let ro: uintptr_t;
}

extension AnyClassMetadataInterface {
    public var ro: UnsafePointer<class_ro_t> {
        get {
            let ptr = UnsafePointer<UInt32>(bitPattern:self.data & FAST_DATA_MASK)!;
            if ((ptr.pointee & RW_REALIZED) > 0) {
                let rw = UnsafePointer<class_rw_t>(OpaquePointer(ptr));
                if ((rw.pointee.ro & 1) > 0) {
                    return UnsafePointer<class_ro_t>(UnsafePointer<OpaquePointer>(bitPattern:rw.pointee.ro ^ 1)!.pointee);
                } else {
                    return UnsafePointer<class_ro_t>(bitPattern:rw.pointee.ro)!;
                }
            } else {
                return UnsafePointer<class_ro_t>(OpaquePointer(ptr));
            }
        }
    }
}

//extension ClassMetadata {
//    public func getFunction(_ name: String) -> (functionName: String, parameters: [String], returnVal: String, impl: OpaquePointer)? {
//        let des = UnsafeMutablePointer<ClassDescriptor>(mutating:self.description);
//        if let vtable = des.pointee.vtable {
//            var preName = "$s";
//            let desName = des.pointee.fullName;
//            desName.components(separatedBy:".").forEach { str in
//                preName = preName.appendingFormat("%d%@", str.count, str);
//            };
//            preName.append("C");
//            for i in 0..<vtable.count {
//                let fullFuncName = MethodDescriptor.getImpl(vtable.baseAddress!.advanced(by:i)).functionName;
//                print(fullFuncName);
//                if (fullFuncName.hasPrefix("$s")) {
//                    var tmpStr = String(fullFuncName[fullFuncName.index(fullFuncName.startIndex, offsetBy:2)..<fullFuncName.endIndex]);
//                    let getNameCompnent: () -> String = {
//                        if (tmpStr[tmpStr.startIndex].isNumber) {
//                            var offset = 0
//                            var index = 0;
//                            while tmpStr[tmpStr.index(tmpStr.startIndex, offsetBy:index)].isNumber {
//                                offset = offset * 10 + tmpStr[tmpStr.index(tmpStr.startIndex, offsetBy:index)].wholeNumberValue!;
//                                index += 1;
//                            }
//                            let retVal = String(tmpStr[tmpStr.index(tmpStr.startIndex, offsetBy:index)..<tmpStr.index(tmpStr.startIndex, offsetBy:index + offset)]);
//                            tmpStr = String(tmpStr[tmpStr.index(tmpStr.startIndex, offsetBy:index + offset)..<tmpStr.endIndex]);
//                            return retVal;
//                        }
//                        return "";
//                    };
//                    while (tmpStr[tmpStr.startIndex].isNumber) {
//                        _ = getNameCompnent();
//                    }
//                    tmpStr = String(tmpStr[tmpStr.index(tmpStr.startIndex, offsetBy:1)..<tmpStr.endIndex]);
//                    // function name
//                    var funcName = getNameCompnent();
//                    if (tmpStr[tmpStr.startIndex].isNumber) {
//                        funcName.append("(");
//                        while (tmpStr[tmpStr.startIndex].isNumber) {
//                            funcName.append(getNameCompnent() + ":");
//                        }
//                        funcName.append(")");
//                    } else {
//                        funcName.append("()");
//                    }
//                    // type
//                    let getType: () -> String = {
//                        if (tmpStr.hasPrefix("y")) {
//                            tmpStr = String(tmpStr[tmpStr.index(tmpStr.startIndex, offsetBy:1)..<tmpStr.endIndex]);
//                            return "Void";
//                        } else if (tmpStr.hasPrefix("Sf")) {
//                            tmpStr = String(tmpStr[tmpStr.index(tmpStr.startIndex, offsetBy:2)..<tmpStr.endIndex]);
//                            return "Float";
//                        } else if (tmpStr.hasPrefix("Si")) {
//                            tmpStr = String(tmpStr[tmpStr.index(tmpStr.startIndex, offsetBy:2)..<tmpStr.endIndex]);
//                            return "Int";
//                        } else {
//                            return "";
//                        }
//                    };
//                    // return value
//                    let returnValue = getType();
//                    // parameters
//                    var parameters = [String]();
//                    while (tmpStr.count > 0) {
//                        let val = getType();
//                        if (val.count > 0 && val != "Void") {
//                            parameters.append(val);
//                        } else {
//                            break;
//                        }
//                    }
//                    print(funcName);
//                    print(returnValue);
//                    print(parameters);
//                }
////                funcName.removeSubrange(funcName.startIndex..<funcName.index(funcName.startIndex, offsetBy:preName.count));
////                var num = 0;
////                var index = 0;
////                for j in 0..<funcName.count {
////                    let c = funcName[funcName.index(funcName.startIndex, offsetBy:j)];
////                    if (c.isNumber) {
////                        num = num * 10 + c.wholeNumberValue!;
////                        index += 1;
////                    } else {
////                        break;
////                    }
////                }
////                funcName = String(funcName[funcName.index(funcName.startIndex, offsetBy:index)..<funcName.index(funcName.startIndex, offsetBy:index + num)]);
////                print(funcName);
//            }
//        }
//        return nil;
//    }
//}
