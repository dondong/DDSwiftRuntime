//
//  SwiftProtocol.swift
//  DDSwiftRuntime
//
//  Created by dondong on 2022/3/8.
//

import Foundation

protocol SwiftProtocol {
    func myProcotolFunction();
}

protocol SwiftClassProtocol {
    func myClassProcotolFunction();
}

extension SwiftProtocol {
    func commonProcotolFunction() {
        print("SwiftProtocol.commonProcotolFunction");
    }
}

class SwiftProtocolClass : SwiftProtocol, SwiftClassProtocol {
    func myProcotolFunction() {
        print("SwiftProtocolClass.myProcotolFunction");
    }
    func myClassProcotolFunction() {
        print("SwiftProtocolClass.myClassProcotolFunction");
    }
}

struct SwiftProtocolStruct : SwiftProtocol {
    var val: Int;
    
    func myProcotolFunction() {
        print("SwiftProtocolStruct.myProcotolFunction");
    }
}

enum SwiftProtocolEnum : SwiftProtocol {
    case value1;
    case value2;
    case value3;
    
    func myProcotolFunction() {
        print("SwiftProtocolEnum.myProcotolFunction");
    }
}
