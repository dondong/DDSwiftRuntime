//
//  Metadata.swift
//  DDSwiftRuntime
//
//  Created by dondong on 2022/2/21.
//

import Foundation
import UIKit

// MARK: -
// MARK: HeapObject
/***
 * MetadataKind
 ***/
let MetadataKindIsNonType: UInt32 = 0x400;
let MetadataKindIsNonHeap: UInt32 = 0x200;
let MetadataKindIsRuntimePrivate: UInt32 = 0x100;
enum MetadataKind : UInt32 {
    case Unknown = 1;  // not include by source code
    case Class = 0;
    case Struct = 0x200;  //  0 | MetadataKindIsNonHeap
    case Enum = 0x201;  // 1 | MetadataKindIsNonHeap
    case Optional = 0x202;  // 2 | MetadataKindIsNonHeap)
    case ForeignClass = 0x203;  // 3 | MetadataKindIsNonHeap)
    case Opaque = 0x300;   // 0 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap
    case Tuple = 0x301;  // 1 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap
    case Function = 0x302;  // 2 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap
    case Existential = 0x303;  // 3 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap
    case Metatype = 0x304;   // 4 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap
    case ObjCClassWrapper = 0x305;  // 5 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap
    case ExistentialMetatype = 0x306;  // 6 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap
    case HeapLocalVariable = 0x400;   // 0 | MetadataKindIsNonType
    case HeapGenericLocalVariable = 0x500;  // 0 | MetadataKindIsNonType | MetadataKindIsRuntimePrivate
    case ErrorObject = 0x501;  // 1 | MetadataKindIsNonType | MetadataKindIsRuntimePrivate
    case Task = 0x502;  // 2 | MetadataKindIsNonType | MetadataKindIsRuntimePrivate
    case Job = 0x503;  // 3 | MetadataKindIsNonType | MetadataKindIsRuntimePrivate
}

extension MetadataKind {
    var isHeapMetadataKind: Bool { get { return (self.rawValue & MetadataKindIsNonHeap) == 0; } }
    var isTypeMetadataKind: Bool { get { return (self.rawValue & MetadataKindIsNonType) == 0; } }
    var isRuntimePrivateMetadataKind: Bool { get { return (self.rawValue & MetadataKindIsRuntimePrivate) != 0; } }
}

/***
 * Metadata
 ***/
struct Metadata : MetadataInterface {
    let kindRawValue: UInt;
}

extension Metadata {
    static func classof(_ data: UnsafePointer<Metadata>) -> Bool {
        return true;
    }
}

protocol MetadataInterface {
    var kindRawValue: UInt { get }
    static func classof(_ data: UnsafePointer<Metadata>) -> Bool;
}
fileprivate let MetadataInterface_LastEnumerated: UInt = 0x7FF;
extension MetadataInterface {
    // kind
    var kind: MetadataKind {
        get {
            if (self.kindRawValue > MetadataInterface_LastEnumerated) {
                return .Class;
            }
            return MetadataKind(rawValue:UInt32(self.kindRawValue)) ?? .Unknown;
        }
    }
    var isClassObject: Bool { mutating get { return self.kind == .Class; } }
    var isAnyKindOfClass: Bool {
        get {
            switch(self.kind) {
            case .Class, .ObjCClassWrapper, .ForeignClass:
                return true;
            default:
                return false;
            }
        }
    }
}

/***
 * ValueWitnessFlags
 ***/
struct ValueWitnessFlags {
    fileprivate let _value: UInt32;
}

extension ValueWitnessFlags {
    fileprivate static let AlignmentMask: UInt32       = 0x000000FF;
    fileprivate static let IsNonPOD: UInt32            = 0x00010000;
    fileprivate static let IsNonInline: UInt32         = 0x00020000;
    fileprivate static let HasSpareBits: UInt32        = 0x00080000;
    fileprivate static let IsNonBitwiseTakable: UInt32 = 0x00100000;
    fileprivate static let HasEnumWitnesses: UInt32    = 0x00200000;
    fileprivate static let Incomplete: UInt32          = 0x00400000;
    
    var alignmentMask: UInt32 { get { return self._value & ValueWitnessFlags.AlignmentMask; } }
    var alignment: UInt32 { get { return self.alignmentMask + 1; } }
    var isInlineStorage: Bool { get { return (self._value & ValueWitnessFlags.IsNonBitwiseTakable) == 0; } }
    var isPOD: Bool { get { return (self._value & ValueWitnessFlags.IsNonPOD) == 0; } }
    var isBitwiseTakable: Bool { get { return (self._value & ValueWitnessFlags.IsNonBitwiseTakable) == 0; } }
    var hasEnumWitnesses: Bool { get { return (self._value & ValueWitnessFlags.HasEnumWitnesses) != 0; } }
    var isIncomplete: Bool { get { return (self._value & ValueWitnessFlags.Incomplete) == 0; } }
}

/***
 * ValueWitnessTable
 ***/
struct ValueWitnessTable {
    let initializeBufferWithCopyOfBuffer: OpaquePointer;
    let destroy: OpaquePointer;
    let initializeWithCopy: OpaquePointer;
    let assignWithCopy: OpaquePointer;
    let initializeWithTake: OpaquePointer;
    let assignWithTake: OpaquePointer;
    let getEnumTagSinglePayload: OpaquePointer;
    let storeEnumTagSinglePayload: OpaquePointer;
    let size: size_t;
    let stride: size_t;
    let flags: ValueWitnessFlags;
    let extraInhabitantCount: UInt32;
    let getEnumTag: UInt;
    let destructiveProjectEnumData: OpaquePointer;
    let destructiveInjectEnumTag: OpaquePointer;
}

extension ValueWitnessTable {
    var isIncomplete: Bool { get { self.flags.isIncomplete; } }
    var isValueInline: Bool { get { self.flags.isInlineStorage; } }
    var isPOD: Bool { get { self.flags.isPOD; } }
    var isBitwiseTakable: Bool { get { self.flags.isBitwiseTakable; } }
    var alignment: UInt32 { get { self.flags.alignment; } }
    var alignmentMask: UInt32 { get { self.flags.alignmentMask; } }
}

/***
 * ExistentialTypeMetadata
 ***/
struct ExistentialTypeFlags {
    fileprivate let _value: UInt32;
}

extension ExistentialTypeFlags {
    fileprivate static let numWitnessTablesMask: UInt32 = 0x00FFFFFF;
    fileprivate static let classConstraintMask: UInt32 = 0x80000000;
    fileprivate static let hasSuperclassMask: UInt32 = 0x40000000;
    fileprivate static let specialProtocolMask: UInt32 = 0x3F000000;
    fileprivate static let specialProtocolShift: UInt32 = 24;
    var numWitnessTables: UInt32 { get { return self._value & Self.numWitnessTablesMask; } }
    var classConstraint: ProtocolClassConstraint { get { return ProtocolClassConstraint(rawValue:(self._value & Self.classConstraintMask) != 0 ? 1 : 0) ?? .Any; } }
    var hasSuperclassConstraint: Bool { get { return (self._value & Self.hasSuperclassMask) != 0; } }
    var specialProtocol: SpecialProtocol { get { return SpecialProtocol(rawValue:UInt8((self._value & Self.specialProtocolMask) >> Self.specialProtocolShift)) ?? .Error; } }
}

struct ExistentialTypeMetadata : MetadataInterface {
    let kindRawValue: UInt;
    let flags: ExistentialTypeFlags;
    let numProtocols: UInt32;
    // ConstTargetMetadataPointer
    // ProtocolDescriptorRef
}

extension ExistentialTypeMetadata {
    static func classof(_ data: UnsafePointer<Metadata>) -> Bool {
        return data.pointee.kind == .Existential;
    }
}

/***
 * HeapMetadata
 ***/
struct HeapMetadata : HeapMetadataInterface {
    let kindRawValue: UInt;
}

extension HeapMetadata {
    static func classof(_ data: UnsafePointer<Metadata>) -> Bool {
        return (data.pointee.kind == .Class || data.pointee.kind == .ObjCClassWrapper);
    }
}

/***
 *TupleTypeMetadata
 ***/
struct TupleTypeMetadata : MetadataInterface {
    let kindRawValue: UInt;
    let numElements: Int;
    fileprivate let _labels: UnsafePointer<CChar>;
    struct Element {
        let type: UnsafePointer<Metadata>;
        let offset: Int;
    }
}

extension TupleTypeMetadata {
    var labels: String { get { return String(cString:self._labels); } }
    // Element
    var elements: UnsafeBufferPointer<Element> { mutating get { return Self.getElements(&self); } }
    static func getElements( _ data: UnsafePointer<TupleTypeMetadata>) -> UnsafeBufferPointer<Element> {
        return UnsafeBufferPointer<Element>(start:UnsafeRawPointer(data.advanced(by:1)).assumingMemoryBound(to:Element.self), count:data.pointee.numElements);
    }
    static func classof(_ data: UnsafePointer<Metadata>) -> Bool {
        return data.pointee.kind == .Tuple;
    }
}

struct TupleTypeMetadata_Element {
    
}

protocol HeapMetadataInterface : MetadataInterface {
}

extension HeapMetadataInterface {
    // valueWitnesses
    var valueWitnesses: UnsafePointer<ValueWitnessTable> { mutating get { return Self.getValueWitnesses(&self); } }
    static func getValueWitnesses<T : HeapMetadataInterface>(_ data: UnsafePointer<T>) -> UnsafePointer<ValueWitnessTable> {
        let ptr = UnsafePointer<OpaquePointer>(OpaquePointer(data)).advanced(by:-1);
        return UnsafePointer<ValueWitnessTable>(ptr.pointee);
    }
    // destroy
    var destroy: UnsafePointer<FunctionPointer> { mutating get { return Self.getDestroy(&self); } }
    static func getDestroy<T : HeapMetadataInterface>(_ cls: UnsafePointer<T>) -> UnsafePointer<FunctionPointer> {
        let ptr = UnsafePointer<OpaquePointer>(OpaquePointer(cls)).advanced(by:-2);
        return UnsafePointer<FunctionPointer>(ptr.pointee);
    }
}

/***
 * HeapObject
 ***/
struct HeapObject {
    let metadata: UnsafePointer<HeapMetadata>;
    let refCounts: size_t;
}

struct MetadataTrailingFlags {
    fileprivate let _value: UInt64;
    init(_ val: UInt64) {
        self._value = val;
    }
}

extension MetadataTrailingFlags {
    fileprivate static let IsStaticSpecialization: UInt64 = 0;
    fileprivate static let IsCanonicalStaticSpecialization: UInt64 = 1;
    var isStaticSpecialization: Bool { get { return (self._value & (1 << Self.IsStaticSpecialization)) != 0; } }
    var isCanonicalStaticSpecialization: Bool { get { return (self._value & (1 << Self.IsCanonicalStaticSpecialization)) != 0; } }
}

/***
 * StructMetadata
 ***/
struct StructMetadata : MetadataInterface {
    let kindRawValue: UInt;
    let description: UnsafePointer<StructDescriptor>;
}

extension StructMetadata {
    // fieldOffsets
    var fieldOffsets: UnsafePointer<UInt32>? { mutating get { return Self.getFieldOffsets(&self); } };
    static func getFieldOffsets(_ data: UnsafePointer<StructMetadata>) -> UnsafePointer<UInt32>? {
        if (0 != data.pointee.description.pointee.fieldOffsetVectorOffset) {
            return UnsafeRawPointer(data).advanced(by:Int(data.pointee.description.pointee.fieldOffsetVectorOffset) * MemoryLayout<OpaquePointer>.size).assumingMemoryBound(to:UInt32.self);
        } else {
            return nil;
        }
    }
    // isStaticallySpecializedGenericMetadata
    var isStaticallySpecializedGenericMetadata: Bool { mutating get { return Self.getIsStaticallySpecializedGenericMetadata(&self); } }
    static func getIsStaticallySpecializedGenericMetadata(_ data: UnsafePointer<StructMetadata>) -> Bool {
        if (false == data.pointee.description.pointee.flags.isGeneric) {
            return false;
        }
        if let trailingFlags = Self.getTrailingFlags(data) {
            return trailingFlags.pointee.isStaticSpecialization;
        } else {
            return false;
        }
    }
    // isCanonicalStaticallySpecializedGenericMetadata
    var isCanonicalStaticallySpecializedGenericMetadata: Bool { mutating get { return Self.getIsCanonicalStaticallySpecializedGenericMetadata(&self); } }
    static func getIsCanonicalStaticallySpecializedGenericMetadata(_ data: UnsafePointer<StructMetadata>) -> Bool {
        if (false == data.pointee.description.pointee.flags.isGeneric) {
            return false;
        }
        if let trailingFlags = Self.getTrailingFlags(data) {
            return trailingFlags.pointee.isCanonicalStaticSpecialization;
        } else {
            return false;
        }
    }
    // trailingFlags
    var trailingFlags: UnsafePointer<MetadataTrailingFlags>? { mutating get { return Self.getTrailingFlags(&self); } }
    static func getTrailingFlags(_ data: UnsafePointer<StructMetadata>) -> UnsafePointer<MetadataTrailingFlags>? {
        let des = UnsafeMutablePointer<StructDescriptor>(mutating:data.pointee.description);
        if let header = des.pointee.typeGenericContextDescriptorHeader {
            if let flags = TypeGenericContextDescriptorHeader.getDefaultInstantiationPattern(header)?.pointee.patternFlags {
                if (!flags.hasTrailingFlags) {
                    return nil;
                }
                let offset = Int(des.pointee.fieldOffsetVectorOffset) + (Int(des.pointee.numFields) * MemoryLayout<UInt32>.size + MemoryLayout<OpaquePointer>.size - 1) / MemoryLayout<OpaquePointer>.size;
                return Optional(UnsafeRawPointer(data).advanced(by:offset * MemoryLayout<OpaquePointer>.size).assumingMemoryBound(to:MetadataTrailingFlags.self));
            } else {
                return nil;
            }
        } else {
            return nil;
        }
    }
    static func classof(_ data: UnsafePointer<Metadata>) -> Bool {
        return data.pointee.kind == .Struct;
    }
}

/***
 * EnumMetadata
 ***/
struct EnumMetadata : MetadataInterface {
    let kindRawValue: UInt;
    let description: UnsafePointer<EnumDescriptor>;
}

extension EnumMetadata {
    var hasPayloadSize: Bool { get { return self.description.pointee.hasPayloadSizeOffset; } }
    // payloadSize
    var payloadSize: UnsafePointer<Int>? { mutating get { return Self.getPayloadSize(&self); } }
    static func getPayloadSize(_ data: UnsafePointer<EnumMetadata>) -> UnsafePointer<Int>? {
        if (data.pointee.hasPayloadSize) {
            let offset = data.pointee.description.pointee.payloadSizeOffset;
            return UnsafePointer<Int>(OpaquePointer(data)).advanced(by:Int(offset));
        } else {
            return nil;
        }
    }
    // isStaticallySpecializedGenericMetadata
    var isStaticallySpecializedGenericMetadata: Bool { mutating get { return Self.getIsStaticallySpecializedGenericMetadata(&self); } }
    static func getIsStaticallySpecializedGenericMetadata(_ data: UnsafePointer<EnumMetadata>) -> Bool {
        if (false == data.pointee.description.pointee.flags.isGeneric) {
            return false;
        }
        if let trailingFlags = Self.getTrailingFlags(data) {
            return trailingFlags.pointee.isStaticSpecialization;
        } else {
            return false;
        }
    }
    // isCanonicalStaticallySpecializedGenericMetadata
    var isCanonicalStaticallySpecializedGenericMetadata: Bool { mutating get { return Self.getIsCanonicalStaticallySpecializedGenericMetadata(&self); } }
    static func getIsCanonicalStaticallySpecializedGenericMetadata(_ data: UnsafePointer<EnumMetadata>) -> Bool {
        if (false == data.pointee.description.pointee.flags.isGeneric) {
            return false;
        }
        if let trailingFlags = Self.getTrailingFlags(data) {
            return trailingFlags.pointee.isCanonicalStaticSpecialization;
        } else {
            return false;
        }
    }
    // trailingFlags
    var trailingFlags: UnsafePointer<MetadataTrailingFlags>? { mutating get { return Self.getTrailingFlags(&self); } }
    static func getTrailingFlags(_ data: UnsafePointer<EnumMetadata>) -> UnsafePointer<MetadataTrailingFlags>? {
        let des = UnsafeMutablePointer<EnumDescriptor>(mutating:data.pointee.description);
        if let header = des.pointee.typeGenericContextDescriptorHeader {
            if let flags = TypeGenericContextDescriptorHeader.getDefaultInstantiationPattern(header)?.pointee.patternFlags {
                if (!flags.hasTrailingFlags) {
                    return nil;
                }
                let offset = MemoryLayout<EnumMetadata>.size / MemoryLayout<OpaquePointer>.size + Int(header.pointee.base.numArguments) + (data.pointee.hasPayloadSize ? 1 : 0);
                return Optional(UnsafeRawPointer(data).advanced(by:offset * MemoryLayout<OpaquePointer>.size).assumingMemoryBound(to:MetadataTrailingFlags.self));
            } else {
                return nil;
            }
        } else {
            return nil;
        }
    }
    static func classof(_ data: UnsafePointer<Metadata>) -> Bool {
        return (data.pointee.kind == .Enum || data.pointee.kind == .Optional);
    }
}

// MARK: -
// MARK: ClassMetadata
protocol AnyClassMetadataInterface : HeapMetadataInterface {
    var superclass: OpaquePointer { get };
    var cache0: UInt { get };
    var cache1: UInt { get };
    var data: UInt { get };
}
extension AnyClassMetadataInterface {
    // name
    var name: String { mutating get { Self.getName(&self); } }
    static func getName<T : AnyClassMetadataInterface>(_ cls: UnsafePointer<T>) -> String {
        return String.init(cString:class_getName(unsafeBitCast(cls, to:AnyClass.self)));
    }
    
    var isTypeMetadata: Bool { get { return self.data & 2 != 0; } }
    var isPureObjC: Bool { get { return !self.isTypeMetadata; } }
}

/***
 * AnyClassMetadata
 ***/
struct AnyClassMetadata : AnyClassMetadataInterface {
    let kindRawValue: UInt;
    let superclass: OpaquePointer;
    let cache0: uintptr_t;
    let cache1: uintptr_t;
    let data: UInt;
};

extension AnyClassMetadata {
    static func classof(_ data: UnsafePointer<Metadata>) -> Bool {
        return (data.pointee.kind == .Class || data.pointee.kind == .ObjCClassWrapper);
    }
}

/***
 * ClassMetadata
 ***/
enum ClassFlags : UInt32 {
    case IsSwiftPreStableABI = 0x1;
    case UsesSwiftRefcounting = 0x2;
    case HasCustomObjCName = 0x4;
    case IsStaticSpecialization = 0x8;
    case IsCanonicalStaticSpecialization = 0x10;
}

struct ClassMetadata : AnyClassMetadataInterface {
    let kindRawValue: UInt;
    let superclass: OpaquePointer;
    let cache0: UInt;
    let cache1: UInt;
    let data: UInt;
    fileprivate let _flags: UInt32;
    let instanceAddressPoint: UInt32;
    let instanceSize: UInt32;
    let instanceAlignMask: UInt16;
    let reserved: UInt16;
    let classSize: UInt32;
    let classAddressPoint: UInt32;
    let description: UnsafePointer<ClassDescriptor>;
    let ivarDestroyer: OpaquePointer;
    // After this come the class members, laid out as follows:
    //   - class members for the superclass (recursively)
    //   - metadata reference for the parent, if applicable
    //   - generic parameters for this class
    //   - class variables (if we choose to support these)
    //   - "tabulated" virtual methods
};

extension ClassMetadata {
    // flags
    var flags: [ClassFlags] {
        get {
            var list = [ClassFlags]();
            if ((self._flags & ClassFlags.IsSwiftPreStableABI.rawValue) != 0) {
                list.append(.IsSwiftPreStableABI);
            }
            if ((self._flags & ClassFlags.UsesSwiftRefcounting.rawValue) != 0) {
                list.append(.UsesSwiftRefcounting);
            }
            if ((self._flags & ClassFlags.HasCustomObjCName.rawValue) != 0) {
                list.append(.HasCustomObjCName);
            }
            if ((self._flags & ClassFlags.IsStaticSpecialization.rawValue) != 0) {
                list.append(.IsStaticSpecialization);
            }
            if ((self._flags & ClassFlags.IsCanonicalStaticSpecialization.rawValue) != 0) {
                list.append(.IsCanonicalStaticSpecialization);
            }
            return list;
        }
    }
    // genericParams
    var genericParams: UnsafeBufferPointer<UnsafePointer<Metadata>>? { mutating get { return Self.getGenericParams(&self); } }
    static func getGenericParams(_ cls: UnsafePointer<ClassMetadata>) -> UnsafeBufferPointer<UnsafePointer<Metadata>>? {
        let numParams = Int(ClassDescriptor.getNumParams(cls.pointee.description));
        if (numParams > 0) {
            var offset = 0;
            if (numParams > 1) {
                offset = Int(cls.pointee.classSize - cls.pointee.classAddressPoint) - (numParams + 1) * MemoryLayout<OpaquePointer>.size;
            } else {
                offset = MemoryLayout<ClassMetadata>.size;
            }
            return Optional(UnsafeBufferPointer<UnsafePointer<Metadata>>(start:UnsafeRawPointer(cls).advanced(by:offset).assumingMemoryBound(to:UnsafePointer<Metadata>.self), count:numParams));
        } else {
            return nil;
        }
    }
    // virtual methods
    var virtualMethods: UnsafeBufferPointer<FunctionPointer> { mutating get { return Self.getVirtualMethods(&self); } }
    static func getVirtualMethods(_ cls: UnsafePointer<ClassMetadata>) -> UnsafeBufferPointer<FunctionPointer> {
        let numParams = Int(ClassDescriptor.getNumParams(cls.pointee.description));
        var offset = 0;
        var size = 0;
        if (numParams > 1) {
            offset = MemoryLayout<ClassMetadata>.size;
            size = (Int(cls.pointee.classSize) - Int(cls.pointee.classAddressPoint) - offset - numParams * MemoryLayout<OpaquePointer>.size) / MemoryLayout<uintptr_t>.size - 1/*init function*/;
        } else {
            offset = MemoryLayout<ClassMetadata>.size + MemoryLayout<OpaquePointer>.size;
            size = (Int(cls.pointee.classSize) - Int(cls.pointee.classAddressPoint) - offset) / MemoryLayout<uintptr_t>.size;
        }
        let bastPtr = UnsafeRawPointer(OpaquePointer(cls)).advanced(by:offset);
        return UnsafeBufferPointer(start:UnsafePointer<FunctionPointer>(OpaquePointer(bastPtr)), count:size);
    }
    static func classof(_ data: UnsafePointer<Metadata>) -> Bool {
        return data.pointee.kind == .Class;
    }
}
