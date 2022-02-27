//
//  SwiftClass.swift
//  DDSwiftRuntimeDemo
//
//  Created by dondong on 2022/2/27.
//

import Foundation


class SwiftBaseClass {
    func test() {
        print("SwiftBaseClass test");
    }
    
    func testA() {
        print("SwiftBaseClass testA");
    }
    
    func testB() {
        print("SwiftBaseClass testB");
    }
    
    func testC() {
        print("SwiftBaseClass testC");
    }
    
}

class SwiftClass : SwiftBaseClass {
    override func test() {
        super.test();
        print("SwiftClass test");
    }
    
    override func testB() {
        super.testB();
        print("SwiftClass testB");
    }
}

class SwiftChildClass : SwiftBaseClass {
    override func test() {
        super.test();
        print("SwiftChildClass test");
    }
    
    override func testC() {
        super.testC();
        print("SwiftChildClass testC");
    }
}

class Test<T> {
    var t: T?;
}
