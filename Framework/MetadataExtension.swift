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
