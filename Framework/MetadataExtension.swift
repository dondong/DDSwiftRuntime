//
//  MetadataExtension.swift
//  DDSwiftRuntime
//
//  Created by dondong on 2022/3/4.
//

import Foundation

extension Metadata {
    public static func getFullMetadata<T : MetadataInterface>(_ data: UnsafePointer<Metadata>) -> UnsafePointer<T>? {
        if (T.classof(data)) {
            return UnsafePointer<T>(OpaquePointer(data));
        } else {
            return nil;
        }
    }
}

//extension ClassMetadata {
//    public func getFunction(_ name: String) -> OpaquePointer? {
//        let des = UnsafeMutablePointer<ClassDescriptor>(mutating:self.description);
//        if let vtable = des.pointee.vtable {
//            var preName = "$s";
//            let desName = des.pointee.fullName;
//            desName.components(separatedBy:".").forEach { str in
//                preName = preName.appendingFormat("%d%@", str.count, str);
//            };
//            preName.append("C");
//            for i in 0..<vtable.count {
//                var funcName = MethodDescriptor.getImpl(vtable.baseAddress!.advanced(by:i)).functionName;
//                print(funcName);
//                funcName.removeSubrange(funcName.startIndex..<funcName.index(funcName.startIndex, offsetBy:preName.count));
//                var num = 0;
//                var index = 0;
//                for j in 0..<funcName.count {
//                    let c = funcName[funcName.index(funcName.startIndex, offsetBy:j)];
//                    if (c.isNumber) {
//                        num = num * 10 + c.wholeNumberValue!;
//                        index += 1;
//                    } else {
//                        break;
//                    }
//                }
//                funcName = String(funcName[funcName.index(funcName.startIndex, offsetBy:index)..<funcName.index(funcName.startIndex, offsetBy:index + num)]);
//                print(funcName);
//            }
//        }
//        return nil;
//    }
//}
