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
    // genericArgs
    var genericArgs: UnsafeBufferPointer<UnsafePointer<Metadata>>? { mutating get { return nil; } }
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
    var isCanonicalStaticallySpecializedGenericMetadata: Bool { mutating get { return Self.getIsCanonicalStaticallySpecializedGenericMetadata(&self); } }
    static func getIsCanonicalStaticallySpecializedGenericMetadata(_ data: UnsafePointer<StructMetadata>) -> Bool {
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
    // genericArgs
    var genericArgs: UnsafeBufferPointer<UnsafePointer<Metadata>>? { mutating get { return Self.getGenericArgs(&self); } }
    static func getGenericArgs(_ data: UnsafePointer<StructMetadata>) -> UnsafeBufferPointer<UnsafePointer<Metadata>>? {
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
    var isCanonicalStaticallySpecializedGenericMetadata: Bool { mutating get { return Self.getIsCanonicalStaticallySpecializedGenericMetadata(&self); } }
    static func getIsCanonicalStaticallySpecializedGenericMetadata(_ data: UnsafePointer<EnumMetadata>) -> Bool {
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
    // genericArgs
    var genericArgs: UnsafeBufferPointer<UnsafePointer<Metadata>>? { mutating get { return Self.getGenericArgs(&self); } }
    static func getGenericArgs(_ data: UnsafePointer<EnumMetadata>) -> UnsafeBufferPointer<UnsafePointer<Metadata>>? {
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
protocol AnyClassMetadataInterface : HeapMetadataInterface {
    var superclass: UnsafePointer<AnyClassMetadata> { get };
    var cache0: UInt { get };
    var cache1: UInt { get };
    var data: UInt { get };
}
extension AnyClassMetadataInterface {
    // name
    var name: String { mutating get { return Self.getName(&self); } }
    static func getName<T : AnyClassMetadataInterface>(_ cls: UnsafePointer<T>) -> String {
        return String.init(cString:class_getName(unsafeBitCast(cls, to:AnyClass.self)));
    }
    // isa
    var isa: UnsafePointer<AnyClassMetadata> { get { return UnsafePointer<AnyClassMetadata>(OpaquePointer(bitPattern:self.kindRawValue)!); } }
    var isTypeMetadata: Bool { get { return self.data & 2 != 0; } }
    var isPureObjC: Bool { get { return !self.isTypeMetadata; } }
}

/***
 * AnyClassMetadata
 ***/
struct AnyClassMetadata : AnyClassMetadataInterface {
    let kindRawValue: UInt;
    let superclass: UnsafePointer<AnyClassMetadata>;
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
    let superclass: UnsafePointer<AnyClassMetadata>;
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
    // genericArgs
    var genericArgs: UnsafeBufferPointer<UnsafePointer<Metadata>>? { mutating get { return Self.getGenericArgs(&self); } }
    static func getGenericArgs(_ data: UnsafePointer<ClassMetadata>) -> UnsafeBufferPointer<UnsafePointer<Metadata>>? {
        if (data.pointee.description.pointee.isGeneric) {
            let offset = Int(UnsafeMutablePointer<ClassDescriptor>(mutating:data.pointee.description).pointee.genericArgumentOffset) * MemoryLayout<OpaquePointer>.size;
            let num = Int(ClassDescriptor.getTypeGenericContextDescriptorHeader(data.pointee.description)!.pointee.base.numArguments);
            return Optional(UnsafeBufferPointer<UnsafePointer<Metadata>>(start:UnsafeRawPointer(data).advanced(by:offset).assumingMemoryBound(to:UnsafePointer<Metadata>.self), count:num));
        } else {
            return nil;
        }
    }
    // virtual methods
    var vtable: [FunctionPointer] { mutating get { return Self.getVtable(&self); } }
    static func getVtable(_ data: UnsafePointer<ClassMetadata>) -> [FunctionPointer] {
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
    static func classof(_ data: UnsafePointer<Metadata>) -> Bool {
        return data.pointee.kind == .Class;
    }
}

/***
 * MetadataBounds
 ***/
struct MetadataBounds {
    var negativeSizeInWords: UInt32;
    var positiveSizeInWords: UInt32;
}

extension MetadataBounds {
    var totalSizeInBytes: Int { get { return Int(self.negativeSizeInWords) + Int(self.positiveSizeInWords) * MemoryLayout<OpaquePointer>.size; } }
    var addressPointInBytes: Int { get { return Int(self.negativeSizeInWords) * MemoryLayout<OpaquePointer>.size; } }
}

/***
 * StoredClassMetadataBounds
 ***/
struct StoredClassMetadataBounds {
    var immediateMembersOffset: Int
    var bounds: MetadataBounds;
}

extension StoredClassMetadataBounds {
    func tryGetImmediateMembersOffset(_ output: inout Int) -> Bool {
//        output = self.immediateMembersOffset.load(std::memory_order_relaxed);
        output = self.immediateMembersOffset;
        return (output != 0);
    }
    func tryGet(_ output : inout ClassMetadataBounds) -> Bool {
        let offset = self.immediateMembersOffset;
        if (offset == 0) { return false; }

        output.immediateMembersOffset = offset;
        output.negativeSizeInWords = self.bounds.negativeSizeInWords;
        output.positiveSizeInWords = self.bounds.positiveSizeInWords;
        return true;
    }
    mutating func initialize(_ value: ClassMetadataBounds) {
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
struct ClassMetadataBounds {
    var negativeSizeInWords: UInt32;
    var positiveSizeInWords: UInt32;
    var immediateMembersOffset: Int;
    init(_ immediateMembersOffset: Int, _ negativeSizeInWords: UInt32, _ positiveSizeInWords: UInt32) {
        self.immediateMembersOffset = immediateMembersOffset;
        self.negativeSizeInWords = negativeSizeInWords;
        self.positiveSizeInWords = positiveSizeInWords;
    }
}

extension ClassMetadataBounds {
    mutating func adjustForSubclass(_ areImmediateMembersNegative: Bool, _ numImmediateMembers: UInt32) {
      if (areImmediateMembersNegative) {
          self.negativeSizeInWords += UInt32(numImmediateMembers);
          self.immediateMembersOffset = -Int(self.negativeSizeInWords) * MemoryLayout<OpaquePointer>.size;
      } else {
          self.immediateMembersOffset = Int(self.positiveSizeInWords) * MemoryLayout<OpaquePointer>.size;
          self.positiveSizeInWords += UInt32(numImmediateMembers);
      }
    }
    static func forSwiftRootClass() -> ClassMetadataBounds {
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
enum FunctionMetadataConvention: UInt8 {
    case Swift = 0;
    case Block = 1;
    case Thin = 2;
    case CFunctionPointer = 3;
}

struct FunctionTypeFlags {
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
    var numParameters: UInt { get { return self._value & Self.NumParametersMask; } }
    var convention: FunctionMetadataConvention { get { return FunctionMetadataConvention(rawValue:UInt8((self._value & Self.ConventionMask) >> Self.ConventionShift)) ?? .Swift; } }
    var isAsync: Bool { get { return (self._value & Self.AsyncMask) != 0; } }
    var isThrowing: Bool { get { return (self._value & Self.ThrowsMask) != 0; } }
    var isEscaping: Bool { get { return (self._value & Self.EscapingMask) != 0; } }
    var isSendable: Bool { get { return (self._value & Self.SendableMask) != 0; } }
    var hasParameterFlags: Bool { get { return (self._value & Self.ParamFlagsMask) != 0; } }
    var isDifferentiable: Bool { get { return (self._value & Self.DifferentiableMask) != 0; } }
    var hasGlobalActor: Bool { get { return (self._value & Self.GlobalActorMask) != 0; } }
}

enum ValueOwnership : UInt8 {
    case Default = 0;
    case InOut = 1;
    case Shared = 2;
    case Owned = 3;
//    case Last_Kind = Owned;
};

struct ParameterTypeFlags {
    fileprivate let _value: UInt32;
}

extension ParameterTypeFlags {
    fileprivate static let ValueOwnershipMask: UInt32 = 0x7F;
    fileprivate static let VariadicMask: UInt32 = 0x80;
    fileprivate static let AutoClosureMask: UInt32 = 0x100;
    fileprivate static let NoDerivativeMask: UInt32 = 0x200;
    fileprivate static let IsolatedMask: UInt32 = 0x400;
    var isNone: Bool { get { return self._value == 0; } }
    var isVariadic: Bool { get { return (self._value & Self.VariadicMask) != 0; } }
    var isAutoClosure: Bool { get { return (self._value & Self.AutoClosureMask) != 0; } }
    var isNoDerivative: Bool { get { return (self._value & Self.NoDerivativeMask) != 0; } }
    var isIsolated: Bool { get { return (self._value & Self.IsolatedMask) != 0; } }
    var valueOwnership: ValueOwnership { get { return ValueOwnership(rawValue:UInt8(self._value & Self.ValueOwnershipMask)) ?? .Default; } }
}

struct FunctionTypeMetadata : MetadataInterface {
    let kindRawValue: UInt;
    let flags: FunctionTypeFlags;
    let resultType: UnsafePointer<Metadata>;
}

extension FunctionTypeMetadata {
    var numParameters: UInt { get { return self.flags.numParameters; } }
    var convention: FunctionMetadataConvention { get { return self.flags.convention; } }
    var isAsync: Bool { get { return self.flags.isAsync; } }
    var isThrowing: Bool { get { return self.flags.isThrowing; } }
    var isSendable: Bool { get { return self.flags.isSendable; } }
    var isDifferentiable: Bool { get { return self.flags.isDifferentiable; } }
    var hasParameterFlags: Bool { get { return self.flags.hasParameterFlags; } }
    var isEscaping: Bool { get { return self.flags.isEscaping; } }
    var hasGlobalActor: Bool { get { return self.flags.hasGlobalActor; } }
    // parameters
    var parameters: UnsafeBufferPointer<UnsafePointer<Metadata>> { mutating get { return Self.getParameters(&self); } }
    static func getParameters(_ data: UnsafePointer<FunctionTypeMetadata>) -> UnsafeBufferPointer<UnsafePointer<Metadata>> {
        return UnsafeBufferPointer<UnsafePointer<Metadata>>(start:UnsafePointer<UnsafePointer<Metadata>>(OpaquePointer(data.advanced(by:1))), count:Int(data.pointee.numParameters));
    }
    // parameterFlags
    var parameterFlags: UnsafeBufferPointer<ParameterTypeFlags> { mutating get { return Self.getParameterFlags(&self); } }
    static func getParameterFlags(_ data: UnsafePointer<FunctionTypeMetadata>) -> UnsafeBufferPointer<ParameterTypeFlags> {
        let ptr = UnsafeRawPointer(data.advanced(by:1)).advanced(by:Int(data.pointee.numParameters) * MemoryLayout<OpaquePointer>.size).assumingMemoryBound(to:ParameterTypeFlags.self);
        return UnsafeBufferPointer(start:ptr, count:Int(data.pointee.numParameters));
    }
    static func classof(_ data: UnsafePointer<Metadata>) -> Bool {
        return data.pointee.kind == .Function;
    }
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
 * MetatypeMetadata
 ***/
struct MetatypeMetadata : MetadataInterface {
    let kindRawValue: UInt;
    let instanceType: UnsafePointer<Metadata>;
}

extension MetatypeMetadata {
    static func classof(_ data: UnsafePointer<Metadata>) -> Bool {
        return data.pointee.kind == .Metatype;
    }
}

/***
 * ObjCClassWrapperMetadata
 ***/
struct ObjCClassWrapperMetadata : MetadataInterface {
    let kindRawValue: UInt;
    let `class`: UnsafePointer<ClassMetadata>;
}

extension ObjCClassWrapperMetadata {
    static func classof(_ data: UnsafePointer<Metadata>) -> Bool {
        return data.pointee.kind == .ObjCClassWrapper;
    }
}

/***
 * ExistentialMetatypeMetadata
 ***/
struct ExistentialMetatypeMetadata : MetadataInterface {
    let kindRawValue: UInt;
    let instanceType: UnsafePointer<ClassMetadata>;
    let flags: ExistentialTypeFlags;
}

extension ExistentialMetatypeMetadata {
    var isObjC: Bool { get { return self.isClassBounded && self.flags.numWitnessTables == 0; } }
    var isClassBounded: Bool { get { return self.flags.classConstraint == .Class; } }
    static func classof(_ data: UnsafePointer<Metadata>) -> Bool {
        return data.pointee.kind == .ExistentialMetatype;
    }
}
