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
public struct RefCounts {
    fileprivate let _value: UInt;
}

extension RefCounts {
    fileprivate static let PureSwiftDeallocShift: UInt = 0;
    fileprivate static let PureSwiftDeallocBitCount: UInt = 1;
    fileprivate static let PureSwiftDeallocMask: UInt = (((UInt(1)<<Self.PureSwiftDeallocBitCount) - 1) << Self.PureSwiftDeallocShift);
    fileprivate static let UnownedRefCountShift: UInt = Self.PureSwiftDeallocShift + Self.PureSwiftDeallocBitCount;
    fileprivate static let UnownedRefCountBitCount: UInt = 31;
    fileprivate static let UnownedRefCountMask = (((UInt(1)<<Self.UnownedRefCountBitCount) - 1) << Self.UnownedRefCountShift);
    fileprivate static let IsImmortalShift: UInt = 0;
    fileprivate static let IsImmortalBitCount: UInt = 32;
    fileprivate static let IsImmortalMask: UInt = (((UInt(1)<<Self.IsImmortalBitCount) - 1) << Self.IsImmortalShift);
    fileprivate static let IsDeinitingShift: UInt = Self.UnownedRefCountShift + Self.UnownedRefCountBitCount;
    fileprivate static let IsDeinitingBitCount: UInt = 1;
    fileprivate static let IsDeinitingMask: UInt =  (((UInt(1)<<Self.IsDeinitingBitCount) - 1) << Self.IsDeinitingShift);
    fileprivate static let StrongExtraRefCountShift: UInt = Self.IsDeinitingShift + Self.IsDeinitingBitCount;
    fileprivate static let StrongExtraRefCountBitCount: UInt = 30;
    fileprivate static let StrongExtraRefCountMask: UInt = (((UInt(1)<<Self.StrongExtraRefCountBitCount) - 1) << Self.StrongExtraRefCountShift);
    fileprivate static let UseSlowRCShift: UInt = Self.StrongExtraRefCountShift + Self.StrongExtraRefCountBitCount;
    fileprivate static let UseSlowRCBitCount: UInt = 1;
    fileprivate static let UseSlowRCMask: UInt = (((UInt(1)<<Self.UseSlowRCBitCount) - 1) << Self.UseSlowRCShift);
    fileprivate static let SideTableShift: UInt = 0;
    fileprivate static let SideTableBitCount: UInt = 62;
    fileprivate static let SideTableMask: UInt = (((UInt(1)<<Self.SideTableBitCount) - 1) << Self.SideTableShift);
    fileprivate static let SideTableUnusedLowBits: UInt = 3;
    fileprivate static let SideTableMarkShift: UInt = Self.SideTableBitCount;
    fileprivate static let SideTableMarkBitCount: UInt = 1;
    fileprivate static let SideTableMarkMask: UInt = (((UInt(1)<<Self.SideTableMarkBitCount) - 1) << Self.SideTableMarkShift);
    private var useSlowRC: Bool { get { return 0 != ((self._value & Self.UseSlowRCMask) >> Self.UseSlowRCShift); } }
    private func isImmortal(checkSlowRCBit: Bool) -> Bool {
        if (checkSlowRCBit) {
            return (((self._value & Self.IsImmortalMask) >> Self.IsImmortalShift) == Self.IsImmortalMask) && self.useSlowRC;
        } else {
            return (((self._value & Self.IsImmortalMask) >> Self.IsImmortalShift) == Self.IsImmortalMask);
        }
    }
    private var strongExtraRefCount: UInt32 { get { return UInt32((self._value & Self.StrongExtraRefCountMask) >> Self.StrongExtraRefCountShift); } }
    private var hasSideTable: Bool { get { return self.useSlowRC && !self.isImmortal(checkSlowRCBit:false); } }
    private var sideTable: UnsafePointer<HeapObjectSideTableEntry> {
        get {
            let addr: UInt = ((self._value & Self.SideTableMask) >> Self.SideTableShift) << Self.SideTableUnusedLowBits;
            return UnsafePointer<HeapObjectSideTableEntry>(OpaquePointer(bitPattern:addr)!);
        }
    }
    // public
    public var pureSwiftDeallocation: Bool { get { return (0 != ((self._value & Self.PureSwiftDeallocMask) >> Self.PureSwiftDeallocShift)) && (0 == ((self._value & Self.UseSlowRCMask) >> Self.UseSlowRCShift)); } }
    public var count: UInt32 {
        get {
            if (self.hasSideTable) {
                return self.sideTable.pointee.refCounts.count;
            } else {
                return self.strongExtraRefCount + 1;
            }
        }
    }
    public var isDeiniting: Bool {
        get {
            if (self.hasSideTable) {
                return self.sideTable.pointee.refCounts.isDeiniting;
            } else {
                return 0 != ((self._value & Self.IsDeinitingMask) >> Self.IsDeinitingShift);
            }
        }
    }
}

public struct HeapObject {
    public let metadata: UnsafePointer<HeapMetadata>;
    public let refCounts: RefCounts;
}

fileprivate struct HeapObjectSideTableEntry {
    public let object: UnsafePointer<HeapObject>;
    fileprivate let __alignas: UInt32;
    public let refCounts: RefCounts;
    public let weakBits: UInt32;
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

/***
 * FunctionTypeMetadata
 ***/
public enum FunctionMetadataConvention: UInt8 {
    case Swift = 0;
    case Block = 1;
    case Thin = 2;
    case CFunctionPointer = 3;
}

public struct FunctionTypeFlags {
    fileprivate let _value: UInt;
}

extension FunctionTypeFlags {
    fileprivate static let NumParametersMask: UInt = 0x0000FFFF;
    fileprivate static let ConventionMask: UInt = 0x00FF0000;
    fileprivate static let ConventionShift: UInt = 16;
    fileprivate static let ThrowsMask: UInt = 0x01000000;
    fileprivate static let ParamFlagsMask: UInt = 0x02000000;
    fileprivate static let EscapingMask: UInt = 0x04000000;
    fileprivate static let DifferentiableMask: UInt = 0x08000000;
    fileprivate static let GlobalActorMask: UInt = 0x10000000;
    fileprivate static let AsyncMask: UInt = 0x20000000;
    fileprivate static let SendableMask: UInt = 0x40000000;
    public var numParameters: UInt { get { return self._value & Self.NumParametersMask; } }
    public var convention: FunctionMetadataConvention { get { return FunctionMetadataConvention(rawValue:UInt8((self._value & Self.ConventionMask) >> Self.ConventionShift)) ?? .Swift; } }
    public var isAsync: Bool { get { return (self._value & Self.AsyncMask) != 0; } }
    public var isThrowing: Bool { get { return (self._value & Self.ThrowsMask) != 0; } }
    public var isEscaping: Bool { get { return (self._value & Self.EscapingMask) != 0; } }
    public var isSendable: Bool { get { return (self._value & Self.SendableMask) != 0; } }
    public var hasParameterFlags: Bool { get { return (self._value & Self.ParamFlagsMask) != 0; } }
    public var isDifferentiable: Bool { get { return (self._value & Self.DifferentiableMask) != 0; } }
    public var hasGlobalActor: Bool { get { return (self._value & Self.GlobalActorMask) != 0; } }
}

public enum ValueOwnership : UInt8 {
    case Default = 0;
    case InOut = 1;
    case Shared = 2;
    case Owned = 3;
//    case Last_Kind = Owned;
};

public struct ParameterTypeFlags {
    fileprivate let _value: UInt32;
}

extension ParameterTypeFlags {
    fileprivate static let ValueOwnershipMask: UInt32 = 0x7F;
    fileprivate static let VariadicMask: UInt32 = 0x80;
    fileprivate static let AutoClosureMask: UInt32 = 0x100;
    fileprivate static let NoDerivativeMask: UInt32 = 0x200;
    fileprivate static let IsolatedMask: UInt32 = 0x400;
    public var isNone: Bool { get { return self._value == 0; } }
    public var isVariadic: Bool { get { return (self._value & Self.VariadicMask) != 0; } }
    public var isAutoClosure: Bool { get { return (self._value & Self.AutoClosureMask) != 0; } }
    public var isNoDerivative: Bool { get { return (self._value & Self.NoDerivativeMask) != 0; } }
    public var isIsolated: Bool { get { return (self._value & Self.IsolatedMask) != 0; } }
    public var valueOwnership: ValueOwnership { get { return ValueOwnership(rawValue:UInt8(self._value & Self.ValueOwnershipMask)) ?? .Default; } }
}

public struct FunctionTypeMetadata : MetadataInterface {
    public let kindRawValue: UInt;
    public let flags: FunctionTypeFlags;
    public let resultType: UnsafePointer<Metadata>;
}

extension FunctionTypeMetadata {
    public var numParameters: UInt { get { return self.flags.numParameters; } }
    public var convention: FunctionMetadataConvention { get { return self.flags.convention; } }
    public var isAsync: Bool { get { return self.flags.isAsync; } }
    public var isThrowing: Bool { get { return self.flags.isThrowing; } }
    public var isSendable: Bool { get { return self.flags.isSendable; } }
    public var isDifferentiable: Bool { get { return self.flags.isDifferentiable; } }
    public var hasParameterFlags: Bool { get { return self.flags.hasParameterFlags; } }
    public var isEscaping: Bool { get { return self.flags.isEscaping; } }
    public var hasGlobalActor: Bool { get { return self.flags.hasGlobalActor; } }
    // parameters
    public var parameters: UnsafeBufferPointer<UnsafePointer<Metadata>> { mutating get { return Self.getParameters(&self); } }
    public static func getParameters(_ data: UnsafePointer<FunctionTypeMetadata>) -> UnsafeBufferPointer<UnsafePointer<Metadata>> {
        return UnsafeBufferPointer<UnsafePointer<Metadata>>(start:UnsafePointer<UnsafePointer<Metadata>>(OpaquePointer(data.advanced(by:1))), count:Int(data.pointee.numParameters));
    }
    // parameterFlags
    public var parameterFlags: UnsafeBufferPointer<ParameterTypeFlags> { mutating get { return Self.getParameterFlags(&self); } }
    public static func getParameterFlags(_ data: UnsafePointer<FunctionTypeMetadata>) -> UnsafeBufferPointer<ParameterTypeFlags> {
        let ptr = UnsafeRawPointer(data.advanced(by:1)).advanced(by:Int(data.pointee.numParameters) * MemoryLayout<OpaquePointer>.size).assumingMemoryBound(to:ParameterTypeFlags.self);
        return UnsafeBufferPointer(start:ptr, count:Int(data.pointee.numParameters));
    }
    public static func classof(_ data: UnsafePointer<Metadata>) -> Bool {
        return data.pointee.kind == .Function;
    }
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
 * MetatypeMetadata
 ***/
public struct MetatypeMetadata : MetadataInterface {
    public let kindRawValue: UInt;
    public let instanceType: UnsafePointer<Metadata>;
}

extension MetatypeMetadata {
    public static func classof(_ data: UnsafePointer<Metadata>) -> Bool {
        return data.pointee.kind == .Metatype;
    }
}

/***
 * ObjCClassWrapperMetadata
 ***/
public struct ObjCClassWrapperMetadata : MetadataInterface {
    public let kindRawValue: UInt;
    public let `class`: UnsafePointer<ClassMetadata>;
}

extension ObjCClassWrapperMetadata {
    public static func classof(_ data: UnsafePointer<Metadata>) -> Bool {
        return data.pointee.kind == .ObjCClassWrapper;
    }
}

/***
 * ExistentialMetatypeMetadata
 ***/
public struct ExistentialMetatypeMetadata : MetadataInterface {
    public let kindRawValue: UInt;
    public let instanceType: UnsafePointer<ClassMetadata>;
    public let flags: ExistentialTypeFlags;
}

extension ExistentialMetatypeMetadata {
    public var isObjC: Bool { get { return self.isClassBounded && self.flags.numWitnessTables == 0; } }
    public var isClassBounded: Bool { get { return self.flags.classConstraint == .Class; } }
    public static func classof(_ data: UnsafePointer<Metadata>) -> Bool {
        return data.pointee.kind == .ExistentialMetatype;
    }
}
