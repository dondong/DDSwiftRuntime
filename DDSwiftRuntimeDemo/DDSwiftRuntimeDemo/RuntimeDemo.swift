//
//  RuntimeDemo.swift
//  DDSwiftRuntimeDemo
//
//  Created by dondong on 2022/2/27.
//

import Foundation
import Darwin

func printMainTypes() {
    let list = DDSwiftRuntime.getMainSwiftTypeList();
    for i in 0..<list.count {
        print("***********************************************");
        print("type index:", i);
        printDescriptor(list[i]);
        print("");
    }
}

func printMainProtocolConformances() {
    let list = DDSwiftRuntime.getMainSwiftProtocolConformanceList();
    for i in 0..<list.count {
        print("***********************************************");
        print("protocol conformance index:", i);
        printProtocolConformanceDescriptor(list[i]);
        print("");
    }
}

func printProtocolConformances() {
    print("***********************************************");
    print("SwiftProtocolClass")
    _printProtocolConformance(SwiftProtocolClass.self);
    print("");
    print("***********************************************");
    print("SwiftGenericStruct")
    _printProtocolConformance(SwiftProtocolStruct.self);
    print("");
    print("***********************************************");
    print("SwiftProtocolEnum")
    _printProtocolConformance(SwiftProtocolEnum.self);
    print("");
}

fileprivate func _printProtocolConformance(_ pro: Any.Type) {
    let protocols = DDSwiftRuntime.getSwiftProtocolConformances(pro);
    for i in 0..<protocols.count {
        let p = ProtocolConformanceDescriptor.getProtocolDescriptor(protocols[i]);
        print(i, ProtocolDescriptor.getName(p));
        if let table = ProtocolConformanceDescriptor.getWitnessTable(protocols[i]) {
            print("wintess table");
            for j in 0..<table.count {
                print(j, "function:", table[j].functionName);
            }
        }
    }
}

func printClass() {
    if let metadata = DDSwiftRuntime.getSwiftClassMetadata(SwiftBaseClass.self) {
        printClassMetadata(metadata);
    }
    if let metadata = DDSwiftRuntime.getSwiftClassMetadata(SwiftClass.self) {
        printClassMetadata(metadata);
    }
    if let metadata = DDSwiftRuntime.getSwiftClassMetadata(SwiftChildClass.self) {
        printClassMetadata(metadata);
    }
    if let metadata = DDSwiftRuntime.getObjcClassMetadata(ObjClass.self) {
        printAnyClassMetadata(metadata);
    }
}

func printGeneric() {
    if let metadata = DDSwiftRuntime.getSwiftClassMetadata(SwiftGenericBaseClass<String>.self) {
        printClassMetadata(metadata);
    }
    if let metadata = DDSwiftRuntime.getSwiftClassMetadata(SwiftGenericClass<Int, NSString>.self) {
        printClassMetadata(metadata);
    }
    if let metadata = DDSwiftRuntime.getSwiftClassMetadata(SwiftGenericChildClass.self) {
        printClassMetadata(metadata);
    }
    if let metadata = DDSwiftRuntime.getStructMetadata(SwiftGenericStruct<Int>.self) {
        printStructMetadata(metadata)
    }
    if let metadata = DDSwiftRuntime.getEnumMetadata(SwiftGenericEnum<String, NSString>.self) {
        printEnumMetadata(metadata);
    }
}

fileprivate func printMetadata(_ data: UnsafePointer<Metadata>) {
    switch(data.pointee.kind) {
    case .Class:
        printClassMetadata(UnsafePointer<ClassMetadata>(OpaquePointer(data)));
    case .Enum, .Optional:
        printEnumMetadata(UnsafePointer<EnumMetadata>(OpaquePointer(data)));
    case .Struct:
        printStructMetadata(UnsafePointer<StructMetadata>(OpaquePointer(data)));
    default:
        break;
    }
}

fileprivate func printAnyClassMetadata(_ data: UnsafePointer<AnyClassMetadata>) {
    let metadata = UnsafeMutablePointer<AnyClassMetadata>(mutating:data);
    print("***********************************************");
    print("***** AnyClassMetadata *****");
    print("address:", metadata);
    print("objc name:", metadata.pointee.name);
    print("objc kind:", metadata.pointee.kind);
    print("objc supper:", metadata.pointee.superclass);
    print("***********************************************");
    print("");
}

fileprivate func printClassMetadata(_ data: UnsafePointer<ClassMetadata>) {
    let metadata = UnsafeMutablePointer<ClassMetadata>(mutating:data);
    print("***********************************************");
    print("***** ClassMetadata *****");
    print("address:", metadata);
    print("objc name:", metadata.pointee.name);
    print("objc kind:", metadata.pointee.kind);
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
    if let gens = metadata.pointee.genericArgs {
        print("genericArgs:")
        for i in 0..<gens.count {
            print("\(i).  kind:", gens[i].pointee.kind, gens[i]);
            if let enumGen: UnsafePointer<EnumMetadata> = Metadata.getFullMetadata(gens[i]) {
                print("    name:", EnumDescriptor.getName(enumGen.pointee.description));
            } else if let strGen: UnsafePointer<StructMetadata> = Metadata.getFullMetadata(gens[i]) {
                print("    name:", StructDescriptor.getName(strGen.pointee.description));
            } else if let clsGen: UnsafePointer<ClassMetadata> = Metadata.getFullMetadata(gens[i]) {
                print("    name:", ClassMetadata.getName(clsGen));
            } else if let clsGen: UnsafePointer<AnyClassMetadata> = Metadata.getFullMetadata(gens[i]) {
                print("    name:", AnyClassMetadata.getName(clsGen));
            }
        }
    }
    let vtable = metadata.pointee.vtable;
    if (vtable.count > 0) {
        print("vtable:");
        for i in 0..<vtable.count {
            print("\(i).  name:", vtable[i].functionName);
            print("    address:", vtable[i]);
        }
    }
    
    print("***** ClassDescriptor *****");
    printClassDescriptor(metadata.pointee.description);
    print("***********************************************");
    print("");
}

fileprivate func printStructMetadata(_ data: UnsafePointer<StructMetadata>) {
    let metadata = UnsafeMutablePointer<StructMetadata>(mutating:data);
    print("***********************************************");
    print("***** StructMetadata *****");
    print("address:", metadata);
    if let gens = metadata.pointee.genericArgs {
        print("genericArgs:")
        for i in 0..<gens.count {
            print("\(i).  kind:", gens[i].pointee.kind, gens[i]);
            if let enumGen: UnsafePointer<EnumMetadata> = Metadata.getFullMetadata(gens[i]) {
                print("    name:", EnumDescriptor.getName(enumGen.pointee.description));
            } else if let strGen: UnsafePointer<StructMetadata> = Metadata.getFullMetadata(gens[i]) {
                print("    name:", StructDescriptor.getName(strGen.pointee.description));
            } else if let clsGen: UnsafePointer<ClassMetadata> = Metadata.getFullMetadata(gens[i]) {
                print("    name:", ClassMetadata.getName(clsGen));
            } else if let clsGen: UnsafePointer<AnyClassMetadata> = Metadata.getFullMetadata(gens[i]) {
                print("    name:", AnyClassMetadata.getName(clsGen));
            }
        }
    }
    
    print("***** StructDescriptor *****");
    printStructDescriptor(metadata.pointee.description);
    print("***********************************************");
}

fileprivate func printEnumMetadata(_ data: UnsafePointer<EnumMetadata>) {
    let metadata = UnsafeMutablePointer<EnumMetadata>(mutating:data);
    print("***********************************************");
    print("***** EnumMetadata *****");
    print("address:", metadata);
    if let gens = metadata.pointee.genericArgs {
        print("genericArgs:")
        for i in 0..<gens.count {
            print("\(i).  kind:", gens[i].pointee.kind, gens[i]);
            if let enumGen: UnsafePointer<EnumMetadata> = Metadata.getFullMetadata(gens[i]) {
                print("    name:", EnumDescriptor.getName(enumGen.pointee.description));
            } else if let strGen: UnsafePointer<StructMetadata> = Metadata.getFullMetadata(gens[i]) {
                print("    name:", StructDescriptor.getName(strGen.pointee.description));
            } else if let clsGen: UnsafePointer<ClassMetadata> = Metadata.getFullMetadata(gens[i]) {
                print("    name:", ClassMetadata.getName(clsGen));
            } else if let clsGen: UnsafePointer<AnyClassMetadata> = Metadata.getFullMetadata(gens[i]) {
                print("    name:", AnyClassMetadata.getName(clsGen));
            }
        }
    }
    
    print("***** EnumDescriptor *****");
    printEnumDescriptor(metadata.pointee.description);
    print("***********************************************");
}

fileprivate func printDescriptor(_ des: UnsafePointer<ContextDescriptor>) {
    switch(des.pointee.flags.kind) {
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

fileprivate func printProtocolConformanceDescriptor(_ d: UnsafePointer<ProtocolConformanceDescriptor>) {
    let des = UnsafeMutablePointer<ProtocolConformanceDescriptor>(mutating:d);
    print("address:", des);
    print("flags kind:", des.pointee.flags.typeReferenceKind);
    print("protocolDescriptor:", des.pointee.protocolDescriptor, ProtocolDescriptor.getName(des.pointee.protocolDescriptor));
    print("witnessTablePattern:", des.pointee.witnessTablePattern ?? "");
    if let table = des.pointee.witnessTable {
        print("vtable");
        for i in 0..<table.count {
            print("\(i) ", table.baseAddress!.advanced(by:i), table[i].functionName);
        }
    }
    if let name = des.pointee.directObjCClassName {
        print("directObjCClassName:", name);
    }
    if let metadata = des.pointee.indirectObjCClass {
        print("indirectObjCClass");
        printClassMetadata(metadata);
    }
    if let type = des.pointee.typeDescriptor {
        print("typeDescriptor");
        printDescriptor(type);
    }
    if let ret = des.pointee.retroactiveContext {
        print("retroactiveContext");
        print("kind:", ret.pointee.flags.kind);
    }
    if let con = des.pointee.conditionalRequirements {
        print("conditionalRequirements");
        for i in 0..<con.count {
            print("\(i) kind:", con[i].flags.kind);
        }
    }
    if let res = des.pointee.resilientWitnesses {
        print("resilientWitnesses");
        for i in 0..<res.count {
            let p = UnsafeMutablePointer<ResilientWitness>(mutating:res.baseAddress!.advanced(by:i));
            print("\(i) requirement:", p.pointee.requirement, "witness:",  p.pointee.witness);
            print(FunctionPointer(p.pointee.witness).functionName)
        }
    }
    if let g = des.pointee.genericWitnessTable {
        print("genericWitnessTable");
        let gen = UnsafeMutablePointer<GenericWitnessTable>(mutating:g);
        print("witnessTablePrivateSizeInWords:", gen.pointee.privateData.count);
        let ptr = gen.pointee.privateData;
        for i in 0..<ptr.count {
            print("\(i) address:", ptr[i], "name:", ptr[i].functionName);
        }
    }
}

fileprivate func printContextDescriptor(_ d: UnsafePointer<ContextDescriptor>) {
    let des = UnsafeMutablePointer<ContextDescriptor>(OpaquePointer(d));
    print("kind:", des.pointee.flags.kind);
    print("address:", des);
    print("parent:", String(describing:des.pointee.parent));
    print("version:", des.pointee.version);
    print("isGeneric:", des.pointee.isGeneric);
    print("isUnique:", des.pointee.isUnique);
    print("metadataInitialization:", des.pointee.metadataInitialization);
    print("hasResilientSuperclass:", des.pointee.hasResilientSuperclass);
    print("hasVTable:", des.pointee.hasVTable);
}

fileprivate func printTypeContextDescriptor(_ d: UnsafePointer<TypeContextDescriptor>) {
    printContextDescriptor(UnsafePointer<ContextDescriptor>(OpaquePointer(d)));
    let des = UnsafeMutablePointer<TypeContextDescriptor>(OpaquePointer(d));
    print("name:", des.pointee.name);
    print("accessFunction:", String(describing:des.pointee.accessFunction?.functionName));
    print("fieldDescriptor:", FieldDescriptor.getMangledTypeName(des.pointee.fieldDescriptor!)!);
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
            print("\(i).  kind:", item.pointee.flags.kind);
            print("    isAsync:", item.pointee.flags.isAsync);
            print("    isDynamic:", item.pointee.flags.isDynamic);
            print("    isInstance:", item.pointee.flags.isInstance);
            print("    name:", item.pointee.impl.functionName);
            print("    address:", item.pointee.impl);
        }
    }
    if let table = des.pointee.overridetable {
        print("overridetable:");
        for i in 0..<table.count {
            let item = UnsafeMutablePointer<MethodOverrideDescriptor>(OpaquePointer(table.baseAddress!.advanced(by:i)));
            print("\(i).  type_name:", TypeContextDescriptor.getName(UnsafePointer<TypeContextDescriptor>(item.pointee.cls)));
            print("    type_address:", item.pointee.cls);
            print("    base_name:", item.pointee.method.functionName);
            print("    base_address:", item.pointee.method);
            print("    override_name:", item.pointee.impl.functionName);
            print("    override_address:", item.pointee.impl);
        }
    }
}

fileprivate func printEnumDescriptor(_ d: UnsafePointer<EnumDescriptor>) {
    printTypeContextDescriptor(UnsafePointer<TypeContextDescriptor>(OpaquePointer(d)));
    let des = UnsafeMutablePointer<EnumDescriptor>(OpaquePointer(d));
    print("numCases:", des.pointee.numCases);
    print("numPayloadCases:", des.pointee.numPayloadCases);
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
    let des = UnsafeMutablePointer<ProtocolDescriptor>(mutating:d);
    print("name:", des.pointee.name);
    print("numRequirementsInSignature:", des.pointee.numRequirementsInSignature);
    print("numRequirements:", des.pointee.numRequirements);
    print("associatedTypeNames:", des.pointee.associatedTypeNames ?? "");
    if (des.pointee.numRequirementsInSignature > 0) {
        print("numRequirementsInSignature");
        let req = des.pointee.requirementSignature;
        for i in 0..<req.count {
            print("\(i)  kind:", req[i].kind);
        }
    }
    if (des.pointee.numRequirements > 0) {
        print("numRequirements");
        let req = des.pointee.requirements;
        for i in 0..<req.count {
            let p = UnsafeMutablePointer<ProtocolRequirement>(mutating:req.baseAddress!.advanced(by:i));
            print("\(i)  defaultImplementation:", p.pointee.defaultImplementation?.functionName ?? "nil");
        }
    }
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
