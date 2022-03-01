//
//  SwiftGenericClass.swift
//  DDSwiftRuntimeDemo
//
//  Created by dondong on 2022/3/1.
//

import Foundation

class SwiftGenericBaseClass<T> {
    func test(v: T) {
        print("SwiftGenericBaseClass test", v);
    }
    
    func testA() {
        print("SwiftGenericBaseClass testA");
    }
    
    func testB() {
        print("SwiftGenericBaseClass testB");
    }
    
    func testC() {
        print("SwiftGenericBaseClass testC");
    }
    
}

class SwiftGenericClass<T, T2> : SwiftGenericBaseClass<T> {
    override func test(v: T) {
        super.test(v:v);
        print("SwiftGenericClass test", v);
    }
    
    override func testB() {
        super.testB();
        print("SwiftGenericClass testB");
    }
    
    func testD(v: T2) {
        print("SwiftGenericClass testD", v);
    }
}

class SwiftGenericChildClass : SwiftGenericClass<Int, String> {
    override func test(v: Int) {
        super.test(v:v);
        print("SwiftChildClass test");
    }
    
    override func testC() {
        super.testC();
        print("SwiftChildClass testC");
    }
    
    override func testD(v: String) {
        testD(v:v)
        print("SwiftGenericClass testD", v);
    }
}
