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
public enum MetadataKind : UInt32 {
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
    public var isHeapMetadataKind: Bool { get { return (self.rawValue & MetadataKindIsNonHeap) == 0; } }
    public var isTypeMetadataKind: Bool { get { return (self.rawValue & MetadataKindIsNonType) == 0; } }
    public var isRuntimePrivateMetadataKind: Bool { get { return (self.rawValue & MetadataKindIsRuntimePrivate) != 0; } }
}

/***
 * Metadata
 ***/
public struct Metadata : MetadataInterface {
    public let kindRawValue: UInt;
}

extension Metadata {
    public static func classof(_ data: UnsafePointer<Metadata>) -> Bool {
        return true;
    }
}

public protocol MetadataInterface {
    var kindRawValue: UInt { get }
    static func classof(_ data: UnsafePointer<Metadata>) -> Bool;
}
fileprivate let MetadataInterface_LastEnumerated: UInt = 0x7FF;
extension MetadataInterface {
    // kind
    public var kind: MetadataKind {
        get {
            if (self.kindRawValue > MetadataInterface_LastEnumerated) {
                return .Class;
            }
            return MetadataKind(rawValue:UInt32(self.kindRawValue)) ?? .Unknown;
        }
    }
    public var isClassObject: Bool { mutating get { return self.kind == .Class; } }
    public var isAnyKindOfClass: Bool {
        get {
            switch(self.kind) {
            case .Class, .ObjCClassWrapper, .ForeignClass:
                return true;
            default:
                return false;
            }
        }
    }
    // genericArgs
    public var genericArgs: UnsafeBufferPointer<UnsafePointer<Metadata>>? { mutating get { return nil; } }
}

/***
 * ValueWitnessFlags
 ***/
public struct ValueWitnessFlags {
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
    
    public var alignmentMask: UInt32 { get { return self._value & ValueWitnessFlags.AlignmentMask; } }
    public var alignment: UInt32 { get { return self.alignmentMask + 1; } }
    public var isInlineStorage: Bool { get { return (self._value & ValueWitnessFlags.IsNonBitwiseTakable) == 0; } }
    public var isPOD: Bool { get { return (self._value & ValueWitnessFlags.IsNonPOD) == 0; } }
    public var isBitwiseTakable: Bool { get { return (self._value & ValueWitnessFlags.IsNonBitwiseTakable) == 0; } }
    public var hasEnumWitnesses: Bool { get { return (self._value & ValueWitnessFlags.HasEnumWitnesses) != 0; } }
    public var isIncomplete: Bool { get { return (self._value & ValueWitnessFlags.Incomplete) == 0; } }
}

/***
 * ValueWitnessTable
 ***/
public struct ValueWitnessTable {
    public let initializeBufferWithCopyOfBuffer: OpaquePointer;
    public let destroy: OpaquePointer;
    public let initializeWithCopy: OpaquePointer;
    public let assignWithCopy: OpaquePointer;
    public let initializeWithTake: OpaquePointer;
    public let assignWithTake: OpaquePointer;
    public let getEnumTagSinglePayload: OpaquePointer;
    public let storeEnumTagSinglePayload: OpaquePointer;
    public let size: size_t;
    public let stride: size_t;
    public let flags: ValueWitnessFlags;
    public let extraInhabitantCount: UInt32;
    public let getEnumTag: UInt;
    public let destructiveProjectEnumData: OpaquePointer;
    public let destructiveInjectEnumTag: OpaquePointer;
}

extension ValueWitnessTable {
    public var isIncomplete: Bool { get { self.flags.isIncomplete; } }
    public var isValueInline: Bool { get { self.flags.isInlineStorage; } }
    public var isPOD: Bool { get { self.flags.isPOD; } }
    public var isBitwiseTakable: Bool { get { self.flags.isBitwiseTakable; } }
    public var alignment: UInt32 { get { self.flags.alignment; } }
    public var alignmentMask: UInt32 { get { self.flags.alignmentMask; } }
}

/***
 * ExistentialTypeMetadata
 ***/
public struct ExistentialTypeFlags {
    fileprivate let _value: UInt32;
}

extension ExistentialTypeFlags {
    fileprivate static let numWitnessTablesMask: UInt32 = 0x00FFFFFF;
    fileprivate static let classConstraintMask: UInt32 = 0x80000000;
    fileprivate static let hasSuperclassMask: UInt32 = 0x40000000;
    fileprivate static let specialProtocolMask: UInt32 = 0x3F000000;
    fileprivate static let specialProtocolShift: UInt32 = 24;
    public var numWitnessTables: UInt32 { get { return self._value & Self.numWitnessTablesMask; } }
    public var classConstraint: ProtocolClassConstraint { get { return ProtocolClassConstraint(rawValue:(self._value & Self.classConstraintMask) != 0 ? 1 : 0) ?? .Any; } }
    public var hasSuperclassConstraint: Bool { get { return (self._value & Self.hasSuperclassMask) != 0; } }
    public var specialProtocol: SpecialProtocol { get { return SpecialProtocol(rawValue:UInt8((self._value & Self.specialProtocolMask) >> Self.specialProtocolShift)) ?? .Error; } }
}

public struct ExistentialTypeMetadata : MetadataInterface {
    public let kindRawValue: UInt;
    public let flags: ExistentialTypeFlags;
    public let numProtocols: UInt32;
    // ConstTargetMetadataPointer
    // ProtocolDescriptorRef
}

extension ExistentialTypeMetadata {
    public static func classof(_ data: UnsafePointer<Metadata>) -> Bool {
        return data.pointee.kind == .Existential;
    }
}

/***
 * HeapMetadata
 ***/
public struct HeapMetadata : HeapMetadataInterface {
    public let kindRawValue: UInt;
}

extension HeapMetadata {
    public static func classof(_ data: UnsafePointer<Metadata>) -> Bool {
        return (data.pointee.kind == .Class || data.pointee.kind == .ObjCClassWrapper);
    }
}

/***
 *TupleTypeMetadata
 ***/
public struct TupleTypeMetadata : MetadataInterface {
    public let kindRawValue: UInt;
    public let numElements: Int;
    fileprivate let _labels: UnsafePointer<CChar>;
    public struct Element {
        let type: UnsafePointer<Metadata>;
        let offset: Int;
    }
}

extension TupleTypeMetadata {
    public var labels: String { get { return String(cString:self._labels); } }
    // Element
    public var elements: UnsafeBufferPointer<Element> { mutating get { return Self.getElements(&self); } }
    public static func getElements( _ data: UnsafePointer<TupleTypeMetadata>) -> UnsafeBufferPointer<Element> {
        return UnsafeBufferPointer<Element>(start:UnsafeRawPointer(data.advanced(by:1)).assumingMemoryBound(to:Element.self), count:data.pointee.numElements);
    }
    public static func classof(_ data: UnsafePointer<Metadata>) -> Bool {
        return data.pointee.kind == .Tuple;
    }
}

public struct TupleTypeMetadata_Element {
    
}

public protocol HeapMetadataInterface : MetadataInterface {
}

extension HeapMetadataInterface {
    // valueWitnesses
    public var valueWitnesses: UnsafePointer<ValueWitnessTable> { mutating get { return Self.getValueWitnesses(&self); } }
    public static func getValueWitnesses<T : HeapMetadataInterface>(_ data: UnsafePointer<T>) -> UnsafePointer<ValueWitnessTable> {
        let ptr = UnsafePointer<OpaquePointer>(OpaquePointer(data)).advanced(by:-1);
        return UnsafePointer<ValueWitnessTable>(ptr.pointee);
    }
    // destroy
    public var destroy: UnsafePointer<FunctionPointer> { mutating get { return Self.getDestroy(&self); } }
    public static func getDestroy<T : HeapMetadataInterface>(_ cls: UnsafePointer<T>) -> UnsafePointer<FunctionPointer> {
        let ptr = UnsafePointer<OpaquePointer>(OpaquePointer(cls)).advanced(by:-2);
        return UnsafePointer<FunctionPointer>(ptr.pointee);
    }
}

/***
 * HeapObject
 ***/
public struct HeapObject {
    public let metadata: UnsafePointer<HeapMetadata>;
    public let refCounts: size_t;
}

public struct MetadataTrailingFlags {
    fileprivate let _value: UInt64;
    public init(_ val: UInt64) {
        self._value = val;
    }
}

extension MetadataTrailingFlags {
    fileprivate static let IsStaticSpecialization: UInt64 = 0;
    fileprivate static let IsCanonicalStaticSpecialization: UInt64 = 1;
    public var isStaticSpecialization: Bool { get { return (self._value & (1 << Self.IsStaticSpecialization)) != 0; } }
    public var isCanonicalStaticSpecialization: Bool { get { return (self._value & (1 << Self.IsCanonicalStaticSpecialization)) != 0; } }
}

/***
 * StructMetadata
 ***/
public struct StructMetadata : MetadataInterface {
    public let kindRawValue: UInt;
    public let description: UnsafePointer<StructDescriptor>;
}

extension StructMetadata {
    // fieldOffsets
    public var fieldOffsets: UnsafePointer<UInt32>? { mutating get { return Self.getFieldOffsets(&self); } };
    public static func getFieldOffsets(_ data: UnsafePointer<StructMetadata>) -> UnsafePointer<UInt32>? {
        if (0 != data.pointee.description.pointee.fieldOffsetVectorOffset) {
            return UnsafeRawPointer(data).advanced(by:Int(data.pointee.description.pointee.fieldOffsetVectorOffset) * MemoryLayout<OpaquePointer>.size).assumingMemoryBound(to:UInt32.self);
        } else {
            return nil;
        }
    }
    // isStaticallySpecializedGenericMetadata
    public var isStaticallySpecializedGenericMetadata: Bool { mutating get { return Self.getIsStaticallySpecializedGenericMetadata(&self); } }
    public static func getIsStaticallySpecializedGenericMetadata(_ data: UnsafePointer<StructMetadata>) -> Bool {
        if (false == data.pointee.description.pointee.isGeneric) {
            return false;
        }
        if let trailingFlags = Self.getTrailingFlags(data) {
            return trailingFlags.pointee.isStaticSpecialization;
        } else {
            return false;
        }
    }
    // isCanonicalStaticallySpecializedGenericMetadata
    public var isCanonicalStaticallySpecializedGenericMetadata: Bool { mutating get { return Self.getIsCanonicalStaticallySpecializedGenericMetadata(&self); } }
    public static func getIsCanonicalStaticallySpecializedGenericMetadata(_ data: UnsafePointer<StructMetadata>) -> Bool {
        if (false == data.pointee.description.pointee.isGeneric) {
            return false;
        }
        if let trailingFlags = Self.getTrailingFlags(data) {
            return trailingFlags.pointee.isCanonicalStaticSpecialization;
        } else {
            return false;
        }
    }
    // trailingFlags
    public var trailingFlags: UnsafePointer<MetadataTrailingFlags>? { mutating get { return Self.getTrailingFlags(&self); } }
    public static func getTrailingFlags(_ data: UnsafePointer<StructMetadata>) -> UnsafePointer<MetadataTrailingFlags>? {
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
    public static func classof(_ data: UnsafePointer<Metadata>) -> Bool {
        return data.pointee.kind == .Struct;
    }
    // genericArgs
    public var genericArgs: UnsafeBufferPointer<UnsafePointer<Metadata>>? { mutating get { return Self.getGenericArgs(&self); } }
    public static func getGenericArgs(_ data: UnsafePointer<StructMetadata>) -> UnsafeBufferPointer<UnsafePointer<Metadata>>? {
        if (data.pointee.description.pointee.isGeneric) {
            let offset = Int(UnsafeMutablePointer<StructDescriptor>(mutating:data.pointee.description).pointee.genericArgumentOffset) * MemoryLayout<OpaquePointer>.size;
            let num = Int(StructDescriptor.getTypeGenericContextDescriptorHeader(data.pointee.description)!.pointee.base.numArguments);
            return Optional(UnsafeBufferPointer<UnsafePointer<Metadata>>(start:UnsafeRawPointer(data).advanced(by:offset).assumingMemoryBound(to:UnsafePointer<Metadata>.self), count:num));
        } else {
            return nil;
        }
    }
}

/***
 * EnumMetadata
 ***/
public struct EnumMetadata : MetadataInterface {
    public let kindRawValue: UInt;
    public let description: UnsafePointer<EnumDescriptor>;
}

extension EnumMetadata {
    public var hasPayloadSize: Bool { get { return self.description.pointee.hasPayloadSizeOffset; } }
    // payloadSize
    public var payloadSize: UnsafePointer<Int>? { mutating get { return Self.getPayloadSize(&self); } }
    public static func getPayloadSize(_ data: UnsafePointer<EnumMetadata>) -> UnsafePointer<Int>? {
        if (data.pointee.hasPayloadSize) {
            let offset = data.pointee.description.pointee.payloadSizeOffset;
            return UnsafePointer<Int>(OpaquePointer(data)).advanced(by:Int(offset));
        } else {
            return nil;
        }
    }
    // isStaticallySpecializedGenericMetadata
    public var isStaticallySpecializedGenericMetadata: Bool { mutating get { return Self.getIsStaticallySpecializedGenericMetadata(&self); } }
    public static func getIsStaticallySpecializedGenericMetadata(_ data: UnsafePointer<EnumMetadata>) -> Bool {
        if (false == data.pointee.description.pointee.isGeneric) {
            return false;
        }
        if let trailingFlags = Self.getTrailingFlags(data) {
            return trailingFlags.pointee.isStaticSpecialization;
        } else {
            return false;
        }
    }
    // isCanonicalStaticallySpecializedGenericMetadata
    public var isCanonicalStaticallySpecializedGenericMetadata: Bool { mutating get { return Self.getIsCanonicalStaticallySpecializedGenericMetadata(&self); } }
    public static func getIsCanonicalStaticallySpecializedGenericMetadata(_ data: UnsafePointer<EnumMetadata>) -> Bool {
        if (false == data.pointee.description.pointee.isGeneric) {
            return false;
        }
        if let trailingFlags = Self.getTrailingFlags(data) {
            return trailingFlags.pointee.isCanonicalStaticSpecialization;
        } else {
            return false;
        }
    }
    // trailingFlags
    public var trailingFlags: UnsafePointer<MetadataTrailingFlags>? { mutating get { return Self.getTrailingFlags(&self); } }
    public static func getTrailingFlags(_ data: UnsafePointer<EnumMetadata>) -> UnsafePointer<MetadataTrailingFlags>? {
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
    public static func classof(_ data: UnsafePointer<Metadata>) -> Bool {
        return (data.pointee.kind == .Enum || data.pointee.kind == .Optional);
    }
    // genericArgs
    public var genericArgs: UnsafeBufferPointer<UnsafePointer<Metadata>>? { mutating get { return Self.getGenericArgs(&self); } }
    public static func getGenericArgs(_ data: UnsafePointer<EnumMetadata>) -> UnsafeBufferPointer<UnsafePointer<Metadata>>? {
        if (data.pointee.description.pointee.isGeneric) {
            let offset = Int(UnsafeMutablePointer<EnumDescriptor>(mutating:data.pointee.description).pointee.genericArgumentOffset) * MemoryLayout<OpaquePointer>.size;
            let num = Int(EnumDescriptor.getTypeGenericContextDescriptorHeader(data.pointee.description)!.pointee.base.numArguments);
            return Optional(UnsafeBufferPointer<UnsafePointer<Metadata>>(start:UnsafeRawPointer(data).advanced(by:offset).assumingMemoryBound(to:UnsafePointer<Metadata>.self), count:num));
        } else {
            return nil;
        }
    }
}

// MARK: -
// MARK: ClassMetadata
public protocol AnyClassMetadataInterface : HeapMetadataInterface {
    var superclass: UnsafePointer<AnyClassMetadata> { get };
    var cache0: UInt { get };
    var cache1: UInt { get };
    var data: UInt { get };
}
extension AnyClassMetadataInterface {
    // name
    public var name: String { mutating get { return Self.getName(&self); } }
    public static func getName<T : AnyClassMetadataInterface>(_ cls: UnsafePointer<T>) -> String {
        return String.init(cString:class_getName(unsafeBitCast(cls, to:AnyClass.self)));
    }
    // isa
    public var isa: UnsafePointer<AnyClassMetadata> { get { return UnsafePointer<AnyClassMetadata>(OpaquePointer(bitPattern:self.kindRawValue)!); } }
    public var isTypeMetadata: Bool { get { return self.data & 2 != 0; } }
    public var isPureObjC: Bool { get { return !self.isTypeMetadata; } }
}

/***
 * AnyClassMetadata
 ***/
public struct AnyClassMetadata : AnyClassMetadataInterface {
    public let kindRawValue: UInt;
    public let superclass: UnsafePointer<AnyClassMetadata>;
    public let cache0: uintptr_t;
    public let cache1: uintptr_t;
    public let data: UInt;
};

extension AnyClassMetadata {
    public static func classof(_ data: UnsafePointer<Metadata>) -> Bool {
        return (data.pointee.kind == .Class || data.pointee.kind == .ObjCClassWrapper);
    }
}

/***
 * ClassMetadata
 ***/
public enum ClassFlags : UInt32 {
    case IsSwiftPreStableABI = 0x1;
    case UsesSwiftRefcounting = 0x2;
    case HasCustomObjCName = 0x4;
    case IsStaticSpecialization = 0x8;
    case IsCanonicalStaticSpecialization = 0x10;
}

public struct ClassMetadata : AnyClassMetadataInterface {
    public let kindRawValue: UInt;
    public let superclass: UnsafePointer<AnyClassMetadata>;
    public let cache0: UInt;
    public let cache1: UInt;
    public let data: UInt;
    fileprivate let _flags: UInt32;
    public let instanceAddressPoint: UInt32;
    public let instanceSize: UInt32;
    public let instanceAlignMask: UInt16;
    public let reserved: UInt16;
    public let classSize: UInt32;
    public let classAddressPoint: UInt32;
    public let description: UnsafePointer<ClassDescriptor>;
    public let ivarDestroyer: OpaquePointer;
    // After this come the class members, laid out as follows:
    //   - class members for the superclass (recursively)
    //   - metadata reference for the parent, if applicable
    //   - generic parameters for this class
    //   - class variables (if we choose to support these)
    //   - "tabulated" virtual methods
};

extension ClassMetadata {
    // flags
    public var flags: [ClassFlags] {
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
    // genericArgs
    public var genericArgs: UnsafeBufferPointer<UnsafePointer<Metadata>>? { mutating get { return Self.getGenericArgs(&self); } }
    public static func getGenericArgs(_ data: UnsafePointer<ClassMetadata>) -> UnsafeBufferPointer<UnsafePointer<Metadata>>? {
        if (data.pointee.description.pointee.isGeneric) {
            let offset = Int(UnsafeMutablePointer<ClassDescriptor>(mutating:data.pointee.description).pointee.genericArgumentOffset) * MemoryLayout<OpaquePointer>.size;
            let num = Int(ClassDescriptor.getTypeGenericContextDescriptorHeader(data.pointee.description)!.pointee.base.numArguments);
            return Optional(UnsafeBufferPointer<UnsafePointer<Metadata>>(start:UnsafeRawPointer(data).advanced(by:offset).assumingMemoryBound(to:UnsafePointer<Metadata>.self), count:num));
        } else {
            return nil;
        }
    }
    // virtual methods
    public var vtable: [FunctionPointer] { mutating get { return Self.getVtable(&self); } }
    public static func getVtable(_ data: UnsafePointer<ClassMetadata>) -> [FunctionPointer] {
        var list = [FunctionPointer]();
        var ptr = UnsafePointer<AnyClassMetadata>(OpaquePointer(data));
        while (ptr.pointee.isTypeMetadata) {
            let des = UnsafeMutablePointer<ClassDescriptor>(mutating:UnsafePointer<ClassMetadata>(OpaquePointer(ptr)).pointee.description);
            if (des.pointee.hasVTable) {
                let offset = Int(des.pointee.vTableOffset) * MemoryLayout<OpaquePointer>.size;
                let ptr = UnsafeRawPointer(data).advanced(by:offset).assumingMemoryBound(to:FunctionPointer.self);
                list.insert(contentsOf:UnsafeBufferPointer<FunctionPointer>(start:ptr, count:Int(des.pointee.vTableSize)), at:0);
            }
            ptr = ptr.pointee.superclass;
        }
        return list;
    }
    public static func classof(_ data: UnsafePointer<Metadata>) -> Bool {
        return data.pointee.kind == .Class;
    }
}

/***
 * MetadataBounds
 ***/
internal struct MetadataBounds {
    internal var negativeSizeInWords: UInt32;
    internal var positiveSizeInWords: UInt32;
}

extension MetadataBounds {
    public var totalSizeInBytes: Int { get { return Int(self.negativeSizeInWords) + Int(self.positiveSizeInWords) * MemoryLayout<OpaquePointer>.size; } }
    public var addressPointInBytes: Int { get { return Int(self.negativeSizeInWords) * MemoryLayout<OpaquePointer>.size; } }
}

/***
 * StoredClassMetadataBounds
 ***/
internal struct StoredClassMetadataBounds {
    internal var immediateMembersOffset: Int
    internal var bounds: MetadataBounds;
}

extension StoredClassMetadataBounds {
    internal func tryGetImmediateMembersOffset(_ output: inout Int) -> Bool {
//        output = self.immediateMembersOffset.load(std::memory_order_relaxed);
        output = self.immediateMembersOffset;
        return (output != 0);
    }
    internal func tryGet(_ output : inout ClassMetadataBounds) -> Bool {
        let offset = self.immediateMembersOffset;
        if (offset == 0) { return false; }

        output.immediateMembersOffset = offset;
        output.negativeSizeInWords = self.bounds.negativeSizeInWords;
        output.positiveSizeInWords = self.bounds.positiveSizeInWords;
        return true;
    }
    internal mutating func initialize(_ value: ClassMetadataBounds) {
        if (value.immediateMembersOffset != 0) {
            self.bounds.negativeSizeInWords = value.negativeSizeInWords;
            self.bounds.positiveSizeInWords = value.positiveSizeInWords;
            self.immediateMembersOffset = value.immediateMembersOffset;
        }
    }
}


/***
 * ClassMetadataBounds
 ***/
internal struct ClassMetadataBounds {
    internal var negativeSizeInWords: UInt32;
    internal var positiveSizeInWords: UInt32;
    internal var immediateMembersOffset: Int;
    internal init(_ immediateMembersOffset: Int, _ negativeSizeInWords: UInt32, _ positiveSizeInWords: UInt32) {
        self.immediateMembersOffset = immediateMembersOffset;
        self.negativeSizeInWords = negativeSizeInWords;
        self.positiveSizeInWords = positiveSizeInWords;
    }
}

extension ClassMetadataBounds {
    internal mutating func adjustForSubclass(_ areImmediateMembersNegative: Bool, _ numImmediateMembers: UInt32) {
      if (areImmediateMembersNegative) {
          self.negativeSizeInWords += UInt32(numImmediateMembers);
          self.immediateMembersOffset = -Int(self.negativeSizeInWords) * MemoryLayout<OpaquePointer>.size;
      } else {
          self.immediateMembersOffset = Int(self.positiveSizeInWords) * MemoryLayout<OpaquePointer>.size;
          self.positiveSizeInWords += UInt32(numImmediateMembers);
      }
    }
    internal static func forSwiftRootClass() -> ClassMetadataBounds {
        let addressPoint: Int = 16;
        let totoalSize: Int = MemoryLayout<ClassMetadata>.size;
        return ClassMetadataBounds(totoalSize - addressPoint,
                                   UInt32(addressPoint / MemoryLayout<OpaquePointer>.size),
                                   UInt32((totoalSize - addressPoint) / MemoryLayout<OpaquePointer>.size));
    }
}
