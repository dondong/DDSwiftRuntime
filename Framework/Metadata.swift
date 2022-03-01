//
//  Metadata.swift
//  DDSwiftRuntime
//
//  Created by dondong on 2022/2/21.
//

import Foundation

typealias RelativeContextPointer=Int32
typealias RelativeDirectPointer=Int32
typealias Pointer=uintptr_t
// MARK: -
// MARK: HeapObject
/***
 * MetadataKind
 ***/
let MetadataKindIsNonType: UInt32 = 0x400;
let MetadataKindIsNonHeap: UInt32 = 0x200;
let MetadataKindIsRuntimePrivate: UInt32 = 0x100;
enum MetadataKind : UInt32 {
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
    let getEnumTag: Pointer;
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
enum ProtocolClassConstraint : UInt8 {
    case Class = 0;
    case `Any` = 1;
}

enum SpecialProtocol : UInt8 {
    case None = 0;
    case Error = 1;
}

struct ExistentialTypeFlags{
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

struct ExistentialTypeMetadata {
    let kind: OpaquePointer;
    let flags: ExistentialTypeFlags;
    let numProtocols: UInt32;
    // ConstTargetMetadataPointer
    // ProtocolDescriptorRef
}

/***
 * HeapMetadata
 ***/
struct HeapMetadata {
    let kind: Pointer;
    private let _valueWitnesses: UnsafePointer<ValueWitnessTable>;
}

extension HeapMetadata {
    fileprivate static let LastEnumerated: UInt = 0x7FF;
    var metadataKind: MetadataKind {
        get {
            if (self.kind > HeapMetadata.LastEnumerated) {
                return .Class;
            }
            return MetadataKind(rawValue:UInt32(self.kind & HeapMetadata.LastEnumerated)) ?? .Class;
        }
    }
    var isClassObject: Bool { get { return self.metadataKind == .Class; } }
    var isAnyExistentialType: Bool {
        get {
            switch (self.metadataKind) {
            case .ExistentialMetatype, .Existential:
                return true;
            default:
                return false;
            }
        }
    }
    var isAnyClass: Bool {
        get {
            switch (self.metadataKind) {
            case .Class, .ObjCClassWrapper, .ForeignClass:
                return true;
            default:
                return false;
            }
        }
    }
    
    // valueWitnesses
    var valueWitnesses: UnsafePointer<ValueWitnessTable> { mutating get { return Self.getValueWitnesses(&self); } }
    static func getValueWitnesses(_ data: UnsafePointer<HeapMetadata>) -> UnsafePointer<ValueWitnessTable> {
        return data.advanced(by:-1).pointee._valueWitnesses;
    }
}

/***
 * HeapObject
 ***/
struct HeapObject {
    let metadata: UnsafePointer<HeapMetadata>;
    let refCounts: size_t;
}

// MARK: -
// MARK: ClassMetadata
protocol ObjcClassInterface {
}
extension ObjcClassInterface {
    // name
    var name: String { mutating get { Self.getName(&self); } }
    static func getName<T : ObjcClassInterface>(_ cls: UnsafePointer<T>) -> String {
        return String.init(cString:class_getName(unsafeBitCast(cls, to:AnyClass.self)));
    }
}

/***
 * AnyClassMetadata
 ***/
struct AnyClassMetadata : ObjcClassInterface {
    let isa: OpaquePointer;
    let superclass: OpaquePointer;
    let cache0: uintptr_t;
    let cache1: uintptr_t;
    let ro: uintptr_t;
};

extension AnyClassMetadata {
    var isSwiftMetadata: Bool {
        get {
            if (self.ro & (1<<1) > 0) {
                return true;
            } else {
                return false;
            }
        }
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

struct ClassMetadata : ObjcClassInterface {
    let isa: OpaquePointer;
    let superclass: OpaquePointer;
    let cache0: uintptr_t;
    let cache1: uintptr_t;
    let ro: uintptr_t;
    fileprivate let _flags: UInt32;
    let instanceAddressPoint: UInt32;
    let instanceSize: UInt32;
    let instanceAlignMask: UInt16;
    let reserved: UInt16;
    let classSize: UInt32;
    let classAddressPoint: UInt32;
    let description: UnsafePointer<ClassDescriptor>;
    let ivarDestroyer: Pointer;
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
    // virtual methods
    var virtualMethods: UnsafeBufferPointer<OpaquePointer> { mutating get { return Self.getVirtualMethods(&self); } }
    static func getVirtualMethods(_ cls: UnsafePointer<ClassMetadata>) -> UnsafeBufferPointer<OpaquePointer> {
        let offset = MemoryLayout<ClassMetadata>.size + Int(ClassDescriptor.getNumParams(cls.pointee.description)) * 8;
        let size = (Int(cls.pointee.classSize) - Int(cls.pointee.classAddressPoint) - offset) / MemoryLayout<uintptr_t>.size;
        let bastPtr = UnsafeRawPointer(OpaquePointer(cls)).advanced(by:offset);
        return UnsafeBufferPointer(start:UnsafePointer<OpaquePointer>(OpaquePointer(bastPtr)), count:size);
    }
    // valueWitnesses
    var valueWitnesses: UnsafePointer<ValueWitnessTable> { mutating get { return Self.getValueWitnesses(&self); } }
    static func getValueWitnesses(_ cls: UnsafePointer<ClassMetadata>) -> UnsafePointer<ValueWitnessTable> {
        let ptr = UnsafePointer<OpaquePointer>(OpaquePointer(cls)).advanced(by:-1);
        return UnsafePointer<ValueWitnessTable>(ptr.pointee);
    }
    // existentialTypeMetadata
    var existentialTypeMetadata: UnsafePointer<ExistentialTypeMetadata> { mutating get { return Self.getExistentialTypeMetadata(&self); } }
    static func getExistentialTypeMetadata(_ cls: UnsafePointer<ClassMetadata>) -> UnsafePointer<ExistentialTypeMetadata> {
        let ptr = UnsafePointer<OpaquePointer>(OpaquePointer(cls)).advanced(by:-2);
        return UnsafePointer<ExistentialTypeMetadata>(ptr.pointee);
    }
}
