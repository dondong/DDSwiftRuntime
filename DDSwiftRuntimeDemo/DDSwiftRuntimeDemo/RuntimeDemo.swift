//
//  RuntimeDemo.swift
//  DDSwiftRuntimeDemo
//
//  Created by dondong on 2022/2/27.
//

import Foundation
import Darwin

func printAllType() {
    let list = DDSwiftRuntime.getMainSwiftTypeList();
    for i in 0..<list.count {
        print("***********************************************");
        let ptr = UnsafeMutablePointer<TypeContextDescriptor>(OpaquePointer(list[i]));
        print("\(i).  kind:", ptr.pointee.flag.kind);
        print("    name:", ptr.pointee.name);
        print("    accessFunction:", String(format:"%p", ptr.pointee.accessFunction!));
        print("    fieldDescriptor:", String(format:"%p", ptr.pointee.fieldDescriptor!));
        print("    version:", ptr.pointee.flag.version);
        print("    isGeneric:", ptr.pointee.flag.isGeneric);
        print("    isUnique:", ptr.pointee.flag.isUnique);
        print("    metadataInitialization:", ptr.pointee.flag.metadataInitialization);
        print("    hasResilientSuperclass:", ptr.pointee.flag.hasResilientSuperclass);
        print("    hasVTable:", ptr.pointee.flag.hasVTable);
        print("    hasOverrideTable:", ptr.pointee.flag.hasOverrideTable);
    }
}

func printClass() {
    if let metadata = DDSwiftRuntime.getSwiftClass(SwiftBaseClass.self) {
        printSwift(metadata, "SwiftBaseClass");
    }
    if let metadata = DDSwiftRuntime.getSwiftClass(SwiftClass.self) {
        printSwift(metadata, "SwiftClass");
    }
    if let metadata = DDSwiftRuntime.getSwiftClass(SwiftChildClass.self) {
        printSwift(metadata, "SwiftChildClass");
    }
}

fileprivate func printSwift(_ ptr: UnsafePointer<ClassMetadata>, _ clsName: String) {
    let metadata = UnsafeMutablePointer<ClassMetadata>(OpaquePointer(ptr));
    print("***********************************************");
    print("class name: ", clsName);
    print("***** ClassMetadata *****");
    print("address:", metadata);
    print("objc name: ", metadata.pointee.name);
    print("flags: ", metadata.pointee.flags);
    print("instanceAddressPoint: ", metadata.pointee.instanceAddressPoint);
    print("instanceSize: ", metadata.pointee.instanceSize);
    print("instanceAlignMask: ", String(format:"%x", metadata.pointee.instanceAlignMask));
    print("reserved: ", metadata.pointee.reserved);
    print("classSize: ", metadata.pointee.classSize);
    print("classAddressPoint: ", metadata.pointee.classAddressPoint);
    print("description: ", metadata.pointee.description);
    print("ivarDestroyer: ", metadata.pointee.ivarDestroyer);
    print("function table:")
    let functionTable = metadata.pointee.functionTable;
    for i in 0..<functionTable.count {
        var info = dl_info();
        dladdr(UnsafeRawPointer(functionTable[i]), &info);
        print("\(i).  name:", String(cString:info.dli_sname));
        print("    address:", functionTable[i]);
    }
    
    print("***** ClassDescriptor *****");
    let type = UnsafeMutablePointer<ClassDescriptor>(OpaquePointer(metadata.pointee.description));
    print("address:", type);
    print("parent:", String(describing:type.pointee.parent));
    print("name:", type.pointee.name);
    print("accessFunction:", String(describing:type.pointee.accessFunction));
    print("fieldDescriptor:", String(describing:type.pointee.fieldDescriptor));
    print("numImmediateMembers:", type.pointee.numImmediateMembers);
    print("numFields:", type.pointee.numFields);
    print("fieldOffsetVectorOffset:", type.pointee.fieldOffsetVectorOffset);
    if let table = type.pointee.vtable {
        print("type vtable:");
        for i in 0..<table.count {
            let item = UnsafeMutablePointer<MethodDescriptor>(OpaquePointer(table.baseAddress!.advanced(by:i)));
            var info = dl_info();
            dladdr(UnsafeRawPointer(item), &info);
            print("\(i).  kind:", item.pointee.flags.kind);
            print("    isAsync:", item.pointee.flags.isAsync);
            print("    isDynamic:", item.pointee.flags.isDynamic);
            print("    isInstance:", item.pointee.flags.isInstance);
            print("    name:", String(cString:info.dli_sname));
            print("    address:", item.pointee.impl);
        }
    }
    if let table = type.pointee.overridetable {
        print("type overridetable:");
        for i in 0..<table.count {
            let item = UnsafeMutablePointer<MethodOverrideDescriptor>(OpaquePointer(table.baseAddress!.advanced(by:i)));
            var methodInfo = dl_info();
            dladdr(UnsafeRawPointer(item.pointee.method), &methodInfo);
            var implInfo = dl_info();
            dladdr(UnsafeRawPointer(item.pointee.impl), &implInfo);
            print("\(i).  type_name:", TypeContextDescriptor.getName(UnsafePointer<TypeContextDescriptor>(item.pointee.cls)));
            print("    type_address:", item.pointee.cls);
            print("    base_name:", String(cString:methodInfo.dli_sname));
            print("    base_address:", item.pointee.method);
            print("    override_name:", String(cString:implInfo.dli_sname));
            print("    override_address:", item.pointee.impl);
        }
    }
    print("***********************************************");
    print("");
}
