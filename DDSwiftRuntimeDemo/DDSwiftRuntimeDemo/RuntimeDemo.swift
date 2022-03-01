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
        print("type index:", i);
        printDescriptor(list[i]);
        print("");
    }
}

func printClass() {
    if let metadata = DDSwiftRuntime.getSwiftClass(Test.self) {
        printSwift(metadata, "Test");
        let witnesses = ClassMetadata.getValueWitnesses(metadata);
        print(witnesses);
        let existential = ClassMetadata.getExistentialTypeMetadata(metadata);
        print(existential);
    }
//    if let metadata = DDSwiftRuntime.getSwiftClass(SwiftBaseClass.self) {
//        printSwift(metadata, "SwiftBaseClass");
//    }
//    if let metadata = DDSwiftRuntime.getSwiftClass(SwiftClass.self) {
//        printSwift(metadata, "SwiftClass");
//    }
//    if let metadata = DDSwiftRuntime.getSwiftClass(SwiftChildClass.self) {
//        printSwift(metadata, "SwiftChildClass");
//    }
}

func printGenericClass() {
    if let metadata = DDSwiftRuntime.getSwiftClass(SwiftGenericBaseClass<String>.self) {
        printSwift(metadata, "SwiftGenericBaseClass");
    }
    if let metadata = DDSwiftRuntime.getSwiftClass(SwiftGenericClass<Float, Int>.self) {
        printSwift(metadata, "SwiftGenericClass");
    }
    if let metadata = DDSwiftRuntime.getSwiftClass(SwiftGenericChildClass.self) {
        printSwift(metadata, "SwiftGenericChildClass");
    }
}

fileprivate func printSwift(_ ptr: UnsafePointer<ClassMetadata>, _ clsName: String) {
    let metadata = UnsafeMutablePointer<ClassMetadata>(OpaquePointer(ptr));
    print("***********************************************");
    print("class name: ", clsName);
    print("***** ClassMetadata *****");
    print("address:", metadata);
    print("objc name:", metadata.pointee.name);
    print("objc isa:", metadata.pointee.isa);
    print("objc supper:", metadata.pointee.superclass);
    print("flags:", metadata.pointee.flags);
    print("instanceAddressPoint:", metadata.pointee.instanceAddressPoint);
    print("instanceSize:", metadata.pointee.instanceSize);
    print("instanceAlignMask:", String(format:"%x", metadata.pointee.instanceAlignMask));
    print("reserved:", metadata.pointee.reserved);
    print("classSize:", metadata.pointee.classSize);
    print("classAddressPoint:", metadata.pointee.classAddressPoint);
    print("description:", metadata.pointee.description);
    print("ivarDestroyer:", metadata.pointee.ivarDestroyer);
    print("function table:")
    let virtualMethods = metadata.pointee.virtualMethods;
    for i in 0..<virtualMethods.count {
        var info = dl_info();
        dladdr(UnsafeRawPointer(virtualMethods[i]), &info);
        print("\(i).  name:", String(cString:info.dli_sname));
        print("    address:", virtualMethods[i]);
    }
    
    print("***** ClassDescriptor *****");
    printClassDescriptor(metadata.pointee.description);
    print("***********************************************");
    print("");
}

fileprivate func printDescriptor(_ des: UnsafePointer<ContextDescriptor>) {
    switch(des.pointee.flag.kind) {
    case .Class:
        printClassDescriptor(UnsafePointer<ClassDescriptor>(OpaquePointer(des)));
    case .Enum:
        printEnumDescriptor(UnsafePointer<EnumDescriptor>(OpaquePointer(des)));
    case .Struct:
        printStructDescriptor(UnsafePointer<StructDescriptor>(OpaquePointer(des)));
    case .Protocol:
        printProtocolDescriptor(UnsafePointer<ProtocolDescriptor>(OpaquePointer(des)));
    case .Extension:
        printExtensionContextDescriptor(UnsafePointer<ExtensionContextDescriptor>(OpaquePointer(des)));
    case .Anonymous:
        printAnonymousContextDescriptor(UnsafePointer<AnonymousContextDescriptor>(OpaquePointer(des)));
    case .OpaqueType:
        printOpaqueTypeDescriptor(UnsafePointer<OpaqueTypeDescriptor>(OpaquePointer(des)));
    default:
        break;
    }
}

fileprivate func printContextDescriptor(_ d: UnsafePointer<ContextDescriptor>) {
    let des = UnsafeMutablePointer<ContextDescriptor>(OpaquePointer(d));
    print("kind:", des.pointee.flag.kind);
    print("address:", des);
    print("parent:", String(describing:des.pointee.parent));
    print("version:", des.pointee.flag.version);
    print("isGeneric:", des.pointee.flag.isGeneric);
    print("isUnique:", des.pointee.flag.isUnique);
    print("metadataInitialization:", des.pointee.flag.metadataInitialization);
    print("hasResilientSuperclass:", des.pointee.flag.hasResilientSuperclass);
    print("hasVTable:", des.pointee.flag.hasVTable);
}

fileprivate func printTypeContextDescriptor(_ d: UnsafePointer<TypeContextDescriptor>) {
    printContextDescriptor(UnsafePointer<ContextDescriptor>(OpaquePointer(d)));
    let des = UnsafeMutablePointer<TypeContextDescriptor>(OpaquePointer(d));
    print("name:", des.pointee.name);
    print("accessFunction:", String(describing:des.pointee.accessFunction));
    print("fieldDescriptor:", String(describing:des.pointee.fieldDescriptor));
}

fileprivate func printClassDescriptor(_ d: UnsafePointer<ClassDescriptor>) {
    printTypeContextDescriptor(UnsafePointer<TypeContextDescriptor>(OpaquePointer(d)));
    let des = UnsafeMutablePointer<ClassDescriptor>(OpaquePointer(d));
    print("numImmediateMembers:", des.pointee.numImmediateMembers);
    print("numFields:", des.pointee.numFields);
    print("fieldOffsetVectorOffset:", des.pointee.fieldOffsetVectorOffset);
    if let g = des.pointee.typeGenericContextDescriptorHeader {
        let gen = UnsafeMutablePointer<TypeGenericContextDescriptorHeader>(OpaquePointer(g));
        if let i = gen.pointee.instantiationCache {
            let ins = UnsafeMutablePointer<GenericMetadataInstantiationCache>(OpaquePointer(i));
            print("typeGenericContextDescriptorHeader instantiationCache  privateData:", ins.pointee.privateData);
        }
        if let d = gen.pointee.defaultInstantiationPattern {
            let def = UnsafeMutablePointer<GenericMetadataPattern>(OpaquePointer(d));
            print("typeGenericContextDescriptorHeader defaultInstantiationPattern  instantiationFunction:", String(describing:def.pointee.instantiationFunction));
            print("typeGenericContextDescriptorHeader defaultInstantiationPattern  completionFunction:", String(describing:def.pointee.completionFunction));
            print("typeGenericContextDescriptorHeader defaultInstantiationPattern  hasExtraDataPattern:", def.pointee.hasExtraDataPattern);
        }
        if let param = des.pointee.genericParamDescriptors {
            for i in 0..<param.count {
                print("\(i).  typeGenericContextDescriptorHeader genericParamDescriptor:", param[i].kind);
            }
        }
    }
    if let r = des.pointee.resilientSuperclass {
        let res = UnsafeMutablePointer<ResilientSuperclass>(OpaquePointer(r));
        print("resilientSuperclass superclass:", String(describing:res.pointee.superclass));
    }
    if let f = des.pointee.foreignMetadataInitialization {
        let fore = UnsafeMutablePointer<ForeignMetadataInitialization>(OpaquePointer(f));
        print("foreignMetadataInitialization completionFunction:", String(describing:fore.pointee.completionFunction));
    }
    if let s = des.pointee.singletonMetadataInitialization {
        let sin = UnsafeMutablePointer<SingletonMetadataInitialization>(OpaquePointer(s));
        print("singletonMetadataInitialization initializationCache:", String(describing:sin.pointee.initializationCache));
        print("singletonMetadataInitialization incompleteMetadata:", String(describing:sin.pointee.incompleteMetadata));
        print("singletonMetadataInitialization completionFunction:", String(describing:sin.pointee.completionFunction));
    }
    if let table = des.pointee.vtable {
        print("vtable:");
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
    if let table = des.pointee.overridetable {
        print("overridetable:");
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
}

fileprivate func printEnumDescriptor(_ d: UnsafePointer<EnumDescriptor>) {
    printTypeContextDescriptor(UnsafePointer<TypeContextDescriptor>(OpaquePointer(d)));
    let des = UnsafeMutablePointer<EnumDescriptor>(OpaquePointer(d));
    print("numPayloadCasesAndPayloadSizeOffset:", des.pointee.numPayloadCasesAndPayloadSizeOffset);
    print("numEmptyCases:", des.pointee.numEmptyCases);
}

fileprivate func printStructDescriptor(_ d: UnsafePointer<StructDescriptor>) {
    printTypeContextDescriptor(UnsafePointer<TypeContextDescriptor>(OpaquePointer(d)));
    let des = UnsafeMutablePointer<StructDescriptor>(OpaquePointer(d));
    print("numFields:", des.pointee.numFields);
    print("fieldOffsetVectorOffset:", des.pointee.fieldOffsetVectorOffset);
}

fileprivate func printProtocolDescriptor(_ d: UnsafePointer<ProtocolDescriptor>) {
    printContextDescriptor(UnsafePointer<ContextDescriptor>(OpaquePointer(d)));
    let des = UnsafeMutablePointer<ProtocolDescriptor>(OpaquePointer(d));
    print("name:", des.pointee.name);
    print("numRequirementsInSignature:", des.pointee.numRequirementsInSignature);
    print("numRequirements:", des.pointee.numRequirements);
    print("associatedTypeNames:", des.pointee.associatedTypeNames);
}

fileprivate func printExtensionContextDescriptor(_ d: UnsafePointer<ExtensionContextDescriptor>) {
    printContextDescriptor(UnsafePointer<ContextDescriptor>(OpaquePointer(d)));
    let des = UnsafeMutablePointer<ExtensionContextDescriptor>(OpaquePointer(d));
    print("mangledExtendedContext:", des.pointee.mangledExtendedContext);
}

fileprivate func printAnonymousContextDescriptor(_ d: UnsafePointer<AnonymousContextDescriptor>) {
    printContextDescriptor(UnsafePointer<ContextDescriptor>(OpaquePointer(d)));
}

fileprivate func printOpaqueTypeDescriptor(_ d: UnsafePointer<OpaqueTypeDescriptor>) {
    printContextDescriptor(UnsafePointer<ContextDescriptor>(OpaquePointer(d)));
}
