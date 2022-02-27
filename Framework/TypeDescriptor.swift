//
//  TypeDescriptor.swift
//  DDSwiftRuntime
//
//  Created by dondong on 2022/2/25.
//

import Foundation

/***
 * ContextDescriptorKind
 ***/
enum ContextDescriptorKind : UInt8 {
    /// This context descriptor represents a module.
    case Module = 0;
    /// This context descriptor represents an extension.
    case Extension = 1;
    /// This context descriptor represents an anonymous possibly-generic context
    /// such as a function body.
    case Anonymous = 2;
    /// This context descriptor represents a protocol context.
    case ProtocolType = 3;
    /// This context descriptor represents an opaque type alias.
    case OpaqueType = 4;
    /// First kind that represents a type of any sort.
    /// case Type_First = 16
    /// This context descriptor represents a class.
    case Class = 16;   // .Type_First
    /// This context descriptor represents a struct.
    case Struct = 17;  // .Type_First + 1
    /// This context descriptor represents an enum.
    case Enum = 18;    // .Type_First + 2
    /// Last kind that represents a type of any sort.
    case Type_Last = 31;
};

/***
 * MetadataInitializationKind
 ***/
enum MetadataInitializationKind : UInt8 {
    case NoMetadataInitialization = 0;
    case SingletonMetadataInitialization = 1;
    case ForeignMetadataInitialization = 2;
}

/***
 * MethodDescriptorKind
 ***/
enum MethodDescriptorKind : UInt8 {
    case Method = 0;
    case Init = 1;
    case Getter = 2;
    case Setter = 3;
    case ModifyCoroutine = 4;
    case ReadCoroutine = 5;
}

/***
 * ContextDescriptorFlags
 ***/
struct ContextDescriptorFlags {
    fileprivate let value: UInt32;
}

extension ContextDescriptorFlags {
    var kind: ContextDescriptorKind { get { return ContextDescriptorKind(rawValue:UInt8(self.value & 0x1F)) ?? .Module; } }
    var isGeneric: Bool { get { return (self.value & 0x80) != 0; } }
    var isUnique: Bool { get { return (self.value & 0x40) != 0; } }
    var version: UInt8 { get { return UInt8((self.value >> 8) & 0xFF); } }
    var kindSpecificFlags: UInt16 { get { return UInt16((self.value >> 16) & 0xFFFF); } }
    var metadataInitialization: MetadataInitializationKind { get { return MetadataInitializationKind(rawValue:UInt8(self.kindSpecificFlags & 0x3)) ?? .NoMetadataInitialization } }
    var hasResilientSuperclass: Bool { get { return (self.kindSpecificFlags & 0x2000) != 0; } }
    var hasVTable: Bool { get { return (self.kindSpecificFlags & 0x8000) != 0; } }
    var hasOverrideTable: Bool { get { return (self.kindSpecificFlags & 0x4000) != 0; } }
}

/***
 * ContextDescriptor
 ***/
protocol ContextDescriptorInterface {
    var flag: ContextDescriptorFlags { get };
}

extension ContextDescriptorInterface {
    // parent
    var parent: UnsafePointer<ContextDescriptor>? { mutating get { return Self.getParent(&self); } }
    static func getParent<T : ContextDescriptorInterface>(_ data: UnsafePointer<T>) -> UnsafePointer<ContextDescriptor>? {
        let ptr = DDSwiftRuntime.getPointerFromRelativeDirectPointer(UnsafePointer<RelativeDirectPointer>(OpaquePointer(data)).advanced(by:1));
        return UnsafePointer<ContextDescriptor>(ptr);
    }
}

struct ContextDescriptor : ContextDescriptorInterface {
    let flag: ContextDescriptorFlags;
    fileprivate let _parent: RelativeDirectPointer;
}

/***
 * Protocol
 ***/
struct ProtocolDescriptor : ContextDescriptorInterface {
    let flag: ContextDescriptorFlags;
    fileprivate let _parent: RelativeDirectPointer;
    fileprivate let _name: RelativeDirectPointer;
    let numRequirementsInSignature: UInt32;
    let numRequirements: UInt32;
    let associatedTypeNames: RelativeDirectPointer
    // GenericRequirementDescriptor
    // ProtocolRequirement
}

extension ProtocolDescriptor {
    var name: String { mutating get { return Self.getName(&self); } }
    static func getName(_ data: UnsafePointer<ProtocolDescriptor>) -> String {
        let ptr = DDSwiftRuntime.getPointerFromRelativeDirectPointer(UnsafePointer<RelativeDirectPointer>(OpaquePointer(data)).advanced(by:2))!;
        let namePtr = UnsafePointer<CChar>(ptr);
        guard let parent = self.getParent(data) else { return String(cString:namePtr) }
        let preName = self.getName(UnsafePointer<ProtocolDescriptor>(OpaquePointer(parent)));
        return String(preName + "." + String(cString:namePtr));
    }
}
enum ProtocolRequirementKind : UInt32 {
    case BaseProtocol = 0;
    case Method = 1;
    case Init = 2;
    case Getter = 3;
    case Setter = 4;
    case ReadCoroutine = 5;
    case ModifyCoroutine = 6;
    case AssociatedTypeAccessFunction = 7;
    case AssociatedConformanceAccessFunction = 8;
  }

struct ProtocolRequirementFlags {
    fileprivate let value: UInt32;
}

extension ProtocolRequirementFlags {
    fileprivate static let KindMask: UInt32 = 0x0F;
    fileprivate static let IsInstanceMask: UInt32 = 0x10;
    fileprivate static let IsAsyncMask: UInt32 = 0x20;
    fileprivate static let ExtraDiscriminatorShift: UInt32 = 16;
    fileprivate static let ExtraDiscriminatorMask: UInt32 = 0xFFFF0000;
    var kind: ProtocolRequirementKind { get { return ProtocolRequirementKind(rawValue: (self.value & ProtocolRequirementFlags.KindMask)) ?? .BaseProtocol; } }
    var isInstance: Bool { get { return (self.value & ProtocolRequirementFlags.IsInstanceMask) != 0; } }
    var isAsync: Bool { get { return (self.value & ProtocolRequirementFlags.IsAsyncMask) != 0; } }
    var isSignedWithAddress: Bool { get { return self.kind != .BaseProtocol; } }
    var extraDiscriminator: UInt16 { get { return UInt16(self.value >> ProtocolRequirementFlags.ExtraDiscriminatorShift); } }
}

struct ProtocolRequirement {
    let flags: ProtocolRequirementFlags;
    let defaultImplementation: RelativeDirectPointer;
}

// MARK: -
// MARK: TypeContext
/***
 * TypeContextDescriptor
 ***/
protocol TypeContextDescriptorInterface : ContextDescriptorInterface {
}

extension TypeContextDescriptorInterface {
    // name
    var name: String { mutating get { return Self.getName(&self); } }
    static func getName<T : TypeContextDescriptorInterface>(_ data: UnsafePointer<T>) -> String {
        let ptr = DDSwiftRuntime.getPointerFromRelativeDirectPointer(UnsafePointer<RelativeDirectPointer>(OpaquePointer(data)).advanced(by:2))!;
        let namePtr = UnsafePointer<CChar>(ptr);
        guard let parent = self.getParent(data) else { return String(cString:namePtr) }
        let preName = self.getName(UnsafePointer<TypeContextDescriptor>(OpaquePointer(parent)));
        return String(preName + "." + String(cString:namePtr));
    }
    // accessFunction
    var accessFunction: OpaquePointer? { mutating get { Self.getAccessFunction(&self); } }
    static func getAccessFunction<T : TypeContextDescriptorInterface>(_ data: UnsafePointer<T>) -> OpaquePointer? {
        return DDSwiftRuntime.getPointerFromRelativeDirectPointer(UnsafePointer<RelativeDirectPointer>(OpaquePointer(data)).advanced(by:3));
    }
    // fieldDescriptor
    var fieldDescriptor: OpaquePointer? { mutating get { return Self.getFieldDescriptor(&self); } }
    static func getFieldDescriptor<T : TypeContextDescriptorInterface>(_ data: UnsafePointer<T>) -> OpaquePointer? {
        return DDSwiftRuntime.getPointerFromRelativeDirectPointer(UnsafePointer<RelativeDirectPointer>(OpaquePointer(data)).advanced(by:4));
    }
}

struct TypeContextDescriptor : TypeContextDescriptorInterface {
    let flag: ContextDescriptorFlags;
    fileprivate let _parent: RelativeDirectPointer;
    fileprivate let _name: RelativeDirectPointer;
    fileprivate let _accessFunction: RelativeDirectPointer;
    fileprivate let _fieldDescriptor: RelativeDirectPointer;
};

// MARK: -
// MARK: Extension
struct ExtensionContextDescriptor {
    let flag: ContextDescriptorFlags;
    fileprivate let _parent: RelativeDirectPointer;
    fileprivate let _name: RelativeDirectPointer;
    fileprivate let _accessFunction: RelativeDirectPointer;
    fileprivate let _fieldDescriptor: RelativeDirectPointer;
    let extendedContext: RelativeDirectPointer;
}

extension ExtensionContextDescriptor {
    var mangledExtendedContext: String { mutating get { return Self.getMangledExtendedContext(&self); } }
    static func getMangledExtendedContext(_ data: UnsafePointer<ExtensionContextDescriptor>) -> String {
        let ptr = DDSwiftRuntime.getPointerFromRelativeDirectPointer(UnsafePointer<RelativeDirectPointer>(OpaquePointer(data)).advanced(by:5));
        return String(cString:UnsafePointer<CChar>(ptr!));
    }
}

// MARK: -
// MARK: Anonymous
struct AnonymousContextDescriptor {
    let flag: ContextDescriptorFlags;
    fileprivate let _parent: RelativeDirectPointer;
    fileprivate let _name: RelativeDirectPointer;
    fileprivate let _accessFunction: RelativeDirectPointer;
    fileprivate let _fieldDescriptor: RelativeDirectPointer;
    // GenericContextDescriptorHeader
    // MangledContextName
}

// MARK: -
// MARK: OpaqueType
struct OpaqueTypeDescriptor {
    let flag: ContextDescriptorFlags;
    fileprivate let _parent: RelativeDirectPointer;
    fileprivate let _name: RelativeDirectPointer;
    fileprivate let _accessFunction: RelativeDirectPointer;
    fileprivate let _fieldDescriptor: RelativeDirectPointer;
    // GenericContextDescriptorHeader
    // RelativeDirectPointer<const char>
}

// MARK: -
// MARK: Struct
protocol ValueTypeDescriptorInterface : TypeContextDescriptorInterface {
}

extension ValueTypeDescriptorInterface {
    static func classof(descriptor: TypeContextDescriptor) -> Bool {
        return (descriptor.flag.kind == .Struct || descriptor.flag.kind == .Enum);
    }
    static func classof(descriptor: UnsafePointer<TypeContextDescriptor>) -> Bool {
        return (descriptor.pointee.flag.kind == .Struct || descriptor.pointee.flag.kind == .Enum);
    }
}
/***
 * StructDescriptor
 ***/
struct StructDescriptor : ValueTypeDescriptorInterface {
    let flag: ContextDescriptorFlags;
    fileprivate let _parent: RelativeDirectPointer;
    fileprivate let _name: RelativeDirectPointer;
    fileprivate let _accessFunction: RelativeDirectPointer;
    fileprivate let _fieldDescriptor: RelativeDirectPointer;
    let numFields: UInt32;
    let fieldOffsetVectorOffset: UInt32;
    // TypeGenericContextDescriptorHeader
    // ForeignMetadataInitialization
    // SingletonMetadataInitialization
    // CanonicalSpecializedMetadatasListCount
    // CanonicalSpecializedMetadatasListEntry
    // CanonicalSpecializedMetadatasCachingOnceToken
}

extension StructDescriptor {
    var hasFieldOffsetVector: Bool { get { return self.fieldOffsetVectorOffset != 0; } }
}

// MARK: -
// MARK: Enum
/***
 * EnumDescriptor
 ***/
struct EnumDescriptor : ValueTypeDescriptorInterface {
    let flag: ContextDescriptorFlags;
    fileprivate let _parent: RelativeDirectPointer;
    fileprivate let _name: RelativeDirectPointer;
    fileprivate let _accessFunction: RelativeDirectPointer;
    fileprivate let _fieldDescriptor: RelativeDirectPointer;
    let numPayloadCasesAndPayloadSizeOffset: UInt32;
    let numEmptyCases: UInt32;
    // ForeignMetadataInitialization
    // SingletonMetadataInitialization
    // CanonicalSpecializedMetadatasListCount
    // CanonicalSpecializedMetadatasListEntry
    // CanonicalSpecializedMetadatasCachingOnceToken
}

extension EnumDescriptor {
    var numPayloadCases: UInt32 { get { return self.numPayloadCasesAndPayloadSizeOffset & 0x00FFFFFF; } }
    var numCases: UInt32 { get { return self.numPayloadCases + self.numEmptyCases; } }
    var payloadSizeOffset: UInt32 { get { return ((self.numPayloadCasesAndPayloadSizeOffset & 0xFF000000) >> 24); } }
}

// MARK: -
// MARK: Class
/***
 * ClassDescriptor
 ***/
struct ClassDescriptor : TypeContextDescriptorInterface {
    let flag: ContextDescriptorFlags;
    fileprivate let _parent: RelativeDirectPointer;
    fileprivate let _name: RelativeDirectPointer;
    fileprivate let _accessFunction: RelativeDirectPointer;
    fileprivate let _fieldDescriptor: RelativeDirectPointer;
    let superclassType: RelativeDirectPointer;
    let metadataNegativeSizeInWords: UInt32;  // resilientMetadataBounds: RelativeDirectPointer
    let metadataPositiveSizeInWords: UInt32;  // extraClassFlags: UInt32
    let numImmediateMembers: UInt32;
    let numFields: UInt32;
    let fieldOffsetVectorOffset: UInt32;
    // TypeGenericContextDescriptorHeader
    // ResilientSuperclass
    // ForeignMetadataInitialization
    // SingletonMetadataInitialization
    // VTableDescriptorHeader
    // MethodDescriptor
    // OverrideTableHeader
    // MethodOverrideDescriptor
    // ObjCResilientClassStubInfo
    // CanonicalSpecializedMetadatasListCount
    // CanonicalSpecializedMetadatasListEntry
    // CanonicalSpecializedMetadataAccessorsListEntry
    // CanonicalSpecializedMetadatasCachingOnceToken
};

extension ClassDescriptor {
    fileprivate static func _getVtableOffset(_ data: UnsafePointer<ClassDescriptor>) -> Int {
        var offset = 0;
        if (data.pointee.flag.isGeneric) {
            let ptr = UnsafePointer<TypeGenericContextDescriptorHeader>(OpaquePointer(data.advanced(by:1)));
            offset = MemoryLayout<TypeGenericContextDescriptorHeader>.size + Int((ptr.pointee.base.numParams + 3) & ~UInt16(3)) + MemoryLayout<GenericRequirementDescriptor>.size * Int(ptr.pointee.base.numRequirements);
        }
        if (data.pointee.flag.hasResilientSuperclass) {
            offset += MemoryLayout<ResilientSuperclass>.size;
        }
        switch(data.pointee.flag.metadataInitialization) {
        case .ForeignMetadataInitialization:
            offset += MemoryLayout<ForeignMetadataInitialization>.size;
        case .SingletonMetadataInitialization:
            offset += MemoryLayout<SingletonMetadataInitialization>.size;
        case .NoMetadataInitialization:
            offset += 0;
        }
        return offset;
    }
    // vtable
    var vtable: UnsafeBufferPointer<MethodDescriptor>? { mutating get { Self.getVTable(&self); } }
    static func getVTable(_ data: UnsafePointer<ClassDescriptor>) -> UnsafeBufferPointer<MethodDescriptor>? {
        if (data.pointee.flag.hasVTable) {
            let ptr = UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:self._getVtableOffset(data)).assumingMemoryBound(to:VTableDescriptorHeader.self);
            let buffer = UnsafeBufferPointer(start:UnsafePointer<MethodDescriptor>(OpaquePointer(ptr.advanced(by:1))), count:Int(ptr.pointee.vTableSize));
            return Optional(buffer);
        } else {
            return nil;
        }
    }
    
    fileprivate static func _getOverridetableOffset(_ data: UnsafePointer<ClassDescriptor>) -> Int {
        var offset = self._getVtableOffset(data);
        if (data.pointee.flag.hasVTable) {
            let ptr = UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:offset).assumingMemoryBound(to:VTableDescriptorHeader.self);
            offset += MemoryLayout<VTableDescriptorHeader>.size;
            offset += MemoryLayout<MethodDescriptor>.size * Int(ptr.pointee.vTableSize);
        }
        return offset;
    }
    // overridetable
    var overridetable: UnsafeBufferPointer<MethodOverrideDescriptor>? { mutating get { return Self.getOverridetable(&self); } }
    static func getOverridetable(_ data: UnsafePointer<ClassDescriptor>) -> UnsafeBufferPointer<MethodOverrideDescriptor>? {
        if (data.pointee.flag.hasOverrideTable) {
            let ptr = UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:self._getOverridetableOffset(data)).assumingMemoryBound(to:OverrideTableHeader.self);
            let buffer = UnsafeBufferPointer(start:UnsafePointer<MethodOverrideDescriptor>(OpaquePointer(ptr.advanced(by:1))), count:Int(ptr.pointee.numEntries));
            return Optional(buffer);
        } else {
            return nil;
        }
    }
}


// MARK: -
// MARK: GenericContext
/***
 * GenericContextDescriptorHeader
 ***/
struct GenericContextDescriptorHeader {
    let numParams: UInt16;
    let numRequirements: UInt16;
    let numKeyArguments: UInt16;
    let numExtraArguments: UInt16;
};

/***
 * TypeGenericContextDescriptorHeader
 ***/
struct TypeGenericContextDescriptorHeader {
    let instantiationCache: RelativeDirectPointer;
    let defaultInstantiationPattern: RelativeDirectPointer;
    let base: GenericContextDescriptorHeader;
};

// MARK: -
// MARK: Append
enum GenericRequirementKind : UInt8 {
    case ProtocolDescriptor = 0;
    case SameType = 1;
    case BaseClass = 2;
    case SameConformance = 3;
    case Unknown = 0x1E;
    case Layout = 0x1F;
};

struct GenericRequirementFlags {
    fileprivate let value: UInt32;
}

extension GenericRequirementFlags {
    var hasKeyArgument: Bool { get { return (self.value & 0x80) != 0; } }
    var hasExtraArgument: Bool { get { return (self.value & 0x40) != 0; } }
    var kind: GenericRequirementKind { get { return GenericRequirementKind(rawValue:UInt8(self.value & 0x1F)) ?? .Unknown; } }
}

/***
 * GenericRequirementDescriptor
 ***/
struct GenericRequirementDescriptor {
    let flags: GenericRequirementFlags;
    let param: RelativeDirectPointer;
    fileprivate let _layout: Int32;
}

struct RelativeTargetProtocolDescriptorPointer {
    fileprivate let _pointer : RelativeDirectPointer;
}

extension RelativeTargetProtocolDescriptorPointer {
    fileprivate static func mask() -> Int32 {
        return Int32(MemoryLayout<RelativeDirectPointer>.alignment - 1);
    }
    fileprivate static func pointer(_ ptr: UnsafePointer<RelativeTargetProtocolDescriptorPointer>, _ offset: Int32) -> OpaquePointer? {
        return OpaquePointer(bitPattern:Int(bitPattern:ptr) + Int(offset));
    }
    var pointer: OpaquePointer? {
        mutating get {
            let offset = (self._pointer & ~RelativeTargetProtocolDescriptorPointer.mask());
            if (self._pointer == 0) { return nil; }
            return RelativeTargetProtocolDescriptorPointer.pointer(&self, offset);
        }
    }
    var isObjC: Bool {
        return (self._pointer & RelativeTargetProtocolDescriptorPointer.mask()) != 0;
    }
}

typealias GenericRequirementLayoutKind = RelativeDirectPointer;
extension GenericRequirementDescriptor {
    var kind: GenericRequirementKind { get { return self.flags.kind; } }
    // param
    var getParam: String { mutating get { return Self.getName(&self); } }
    static func getName(_ data: UnsafePointer<GenericRequirementDescriptor>) -> String {
        let ptr = DDSwiftRuntime.getPointerFromRelativeDirectPointer(UnsafePointer<RelativeDirectPointer>(OpaquePointer(data)).advanced(by:1))!;
        return String(cString:UnsafePointer<CChar>(ptr));
    }
    // protocol
//    var protocolDescriptor: UnsafePointer<ProtocolDescriptor>? { mutating get { return Self.getProtocolDescriptor(&self); } }
//    static func getProtocolDescriptor(_ data: UnsafePointer<GenericRequirementDescriptor>) -> UnsafePointer<ProtocolDescriptor>? {
//        if (data.pointee.kind == .ProtocolDescriptor) {
//            let ptr = DDSwiftRuntime.getPointerFromRelativeDirectPointer(UnsafePointer<RelativeDirectPointer>(OpaquePointer(data)).advanced(by:2))!;
//            return Optional(UnsafePointer<ProtocolDescriptor>(ptr));
//        } else {
//            return nil;
//        }
//    }
    // mangledTypeName
    var mangledTypeName: String? { mutating get { return Self.getMangledTypeName(&self); } }
    static func getMangledTypeName(_ data: UnsafePointer<GenericRequirementDescriptor>) -> String? {
        if (data.pointee.kind == .SameType || data.pointee.kind == .BaseClass) {
            let ptr = DDSwiftRuntime.getPointerFromRelativeDirectPointer(UnsafePointer<RelativeDirectPointer>(OpaquePointer(data)).advanced(by:2))!;
            return Optional(String(cString:UnsafePointer<CChar>(ptr)));
        } else {
            return nil;
        }
    }
    // conformance
    var conformance: UnsafePointer<ProtocolConformanceDescriptor>? { mutating get { return Self.getConformance(&self); } }
    static func getConformance(_ data: UnsafePointer<GenericRequirementDescriptor>) -> UnsafePointer<ProtocolConformanceDescriptor>? {
        if (data.pointee.kind == .SameConformance) {
            let ptr = DDSwiftRuntime.getPointerFromRelativeContextPointer(UnsafePointer<RelativeContextPointer>(OpaquePointer(data)).advanced(by:2))!;
            return Optional(UnsafePointer<ProtocolConformanceDescriptor>(ptr));
        } else {
            return nil;
        }
    }
    // layout
    var layout: GenericRequirementLayoutKind? {
        get {
            if (self.kind == .Layout) {
                return Optional(self._layout);
            } else {
                return nil;
            }
        }
    }
    var hasKnownKind: Bool {
        get {
            var ret: Bool = false;
            switch(self.kind) {
            case .BaseClass, .Layout, .ProtocolDescriptor, .SameConformance, .SameType:
                ret = true;
            default:
                ret = false;
            }
            return ret;
        }
    }
}

/***
 * ConformanceFlags
 ***
 */
enum TypeReferenceKind : UInt16 {
    case DirectTypeDescriptor = 0x00;
    case IndirectTypeDescriptor = 0x01;
    case DirectObjCClassName = 0x02;
    case IndirectObjCClass = 0x03;
//    First_Kind = DirectTypeDescriptor,
//    Last_Kind = IndirectObjCClass,
};

struct ConformanceFlags {
    fileprivate let _value: UInt32;
}

extension ConformanceFlags {
    fileprivate static let TypeMetadataKindMask: UInt32 = 0x7 << 3;
    fileprivate static let TypeMetadataKindShift: UInt32 = 3;
    var typeReferenceKind: TypeReferenceKind { get { return TypeReferenceKind(rawValue:UInt16((self._value & Self.TypeMetadataKindMask) >> Self.TypeMetadataKindShift)) ?? .DirectTypeDescriptor; } }
}

/***
 * TypeReference
 ***/
struct TypeReference {
    fileprivate let _value: RelativeDirectPointer;
}

extension TypeReference {
    fileprivate static func getPointer(_ ptr: UnsafePointer<TypeReference>) -> OpaquePointer {
        return DDSwiftRuntime.getPointerFromRelativeDirectPointer(UnsafePointer<RelativeDirectPointer>(OpaquePointer(ptr)))!;
    }
    // TypeDescriptor
    mutating func getTypeDescriptor(_ kind: TypeReferenceKind) -> UnsafePointer<ContextDescriptor>? {
        if (kind == .DirectTypeDescriptor) {
            return Optional(UnsafePointer<ContextDescriptor>(Self.getPointer(&self)));
        } else if (kind == .IndirectTypeDescriptor) {
            return Optional(UnsafePointer<UnsafePointer<ContextDescriptor>>(Self.getPointer(&self)).pointee);
        } else {
            return nil;
        }
    }
    // IndirectObjCClass
    mutating func getIndirectObjCClass(_ kind: TypeReferenceKind) -> UnsafePointer<ClassMetadata>? {
        if (kind == .IndirectObjCClass) {
            return Optional(UnsafePointer<ClassMetadata>(Self.getPointer(&self)));
        } else {
            return nil;
        }
    }
    // DirectObjCClassName
    mutating func getDirectObjCClassName(_ kind: TypeReferenceKind) -> String? {
        if (kind == .DirectObjCClassName) {
            return Optional(String(cString:UnsafePointer<CChar>(Self.getPointer(&self))));
        } else {
            return nil;
        }
    }
}

/***
 * WitnessTable
 ***/
struct WitnessTable {
    let description: UnsafePointer<ProtocolConformanceDescriptor>;
}

/***
 * ProtocolConformanceDescriptor
 ***/
struct ProtocolConformanceDescriptor {
    fileprivate let _protocol: RelativeContextPointer;
    let typeRef: TypeReference;
    fileprivate let _witnessTablePattern : RelativeDirectPointer;
    let flags: ConformanceFlags;
}

extension ProtocolConformanceDescriptor {
    // protocol
    var protocolDescriptor: UnsafePointer<ProtocolDescriptor> { mutating get { return Self.getProtocolDescriptor(&self); } }
    static func getProtocolDescriptor(_ data: UnsafePointer<ProtocolConformanceDescriptor>) -> UnsafePointer<ProtocolDescriptor> {
        let ptr = DDSwiftRuntime.getPointerFromRelativeContextPointer(UnsafePointer<RelativeDirectPointer>(OpaquePointer(data)))!;
        return UnsafePointer<ProtocolDescriptor>(ptr);
    }
    // witnessTablePattern
    var witnessTablePattern: UnsafePointer<WitnessTable> { mutating get { return Self.getWitnessTablePattern(&self); } }
    static func getWitnessTablePattern(_ data: UnsafePointer<ProtocolConformanceDescriptor>) -> UnsafePointer<WitnessTable> {
        let ptr = DDSwiftRuntime.getPointerFromRelativeDirectPointer(UnsafePointer<RelativeDirectPointer>(OpaquePointer(data)).advanced(by:2))!;
        return UnsafePointer<WitnessTable>(ptr);
    }
}

/***
 * ResilientSuperclass
 ***/
struct ResilientSuperclass {
    let superclass: RelativeDirectPointer;
};

/***
 * ForeignMetadataInitialization
 ***/
struct ForeignMetadataInitialization {
  /// The completion function.  The pattern will always be null.
    let completionFunction: RelativeDirectPointer;
};

/***
 * SingletonMetadataInitialization
 ***/
struct SingletonMetadataInitialization {
    let initializationCache: RelativeDirectPointer;
    let incompleteMetadata: RelativeDirectPointer;  // resilientPattern: RelativeDirectPointer;
    let completionFunction: RelativeDirectPointer;
}

/***
 * VTableDescriptorHeader
 ***/
struct VTableDescriptorHeader {
    let vTableOffset: UInt32;
    let vTableSize: UInt32;
};

/***
 * MethodDescriptorFlags
 ***/
struct MethodDescriptorFlags {
    fileprivate let value: UInt32;
}

extension MethodDescriptorFlags {
    var kind: MethodDescriptorKind { get { return MethodDescriptorKind(rawValue:UInt8(self.value & 0x0F)) ?? .Method; } }
    var isDynamic: Bool { get { return (self.value & 0x20) != 0; } }
    var isInstance: Bool { get { return (self.value & 0x10) != 0; } }
    var isAsync: Bool { get { return (self.value & 0x40) != 0; } }
}

/***
 * MethodDescriptor
 ***/
struct MethodDescriptor {
    let flags: MethodDescriptorFlags;
    fileprivate let _impl: RelativeDirectPointer;
}

extension MethodDescriptor {
    // impl
    var impl: OpaquePointer { mutating get { MethodDescriptor.getImpl(&self); } }
    static func getImpl(_ data: UnsafePointer<MethodDescriptor>) -> OpaquePointer {
        return DDSwiftRuntime.getPointerFromRelativeDirectPointer(UnsafePointer<RelativeDirectPointer>(OpaquePointer(data)).advanced(by:1))!;
    }
}

/***
 * OverrideTableHeader
 ***/
struct OverrideTableHeader {
    let numEntries: UInt32;
};

/***
 * MethodOverrideDescriptor
 ***/
struct MethodOverrideDescriptor {
    fileprivate let _cls: RelativeContextPointer;
    fileprivate let _method: RelativeContextPointer;  // base
    fileprivate let _impl: RelativeDirectPointer;    // override
}

extension MethodOverrideDescriptor {
    // cls
    var cls: OpaquePointer { mutating get { Self.getClass(&self); } }
    static func getClass(_ data: UnsafePointer<MethodOverrideDescriptor>) -> OpaquePointer {
        return DDSwiftRuntime.getPointerFromRelativeContextPointer(UnsafePointer<RelativeDirectPointer>(OpaquePointer(data)))!;
    }
    // method
    var method: OpaquePointer { mutating get { Self.getMethod(&self); } }
    static func getMethod(_ data: UnsafePointer<MethodOverrideDescriptor>) -> OpaquePointer {
        return DDSwiftRuntime.getPointerFromRelativeContextPointer(UnsafePointer<RelativeDirectPointer>(OpaquePointer(data)).advanced(by:1))!;
    }
    // impl
    var impl: OpaquePointer { mutating get { Self.getImpl(&self); } }
    static func getImpl(_ data: UnsafePointer<MethodOverrideDescriptor>) -> OpaquePointer {
        return DDSwiftRuntime.getPointerFromRelativeDirectPointer(UnsafePointer<RelativeDirectPointer>(OpaquePointer(data)).advanced(by:2))!;
    }
}

/***
 * ObjCResilientClassStubInfo
 ***/
struct ObjCResilientClassStubInfo {
    let stub: RelativeDirectPointer;
};

/***
 * CanonicalSpecializedMetadatasListCount
 ***/
struct CanonicalSpecializedMetadatasListCount {
    let count: UInt32;
}

/***
 * CanonicalSpecializedMetadatasListEntry
 ***/
struct CanonicalSpecializedMetadatasListEntry {
    let metadata: RelativeDirectPointer;
}

/***
 * CanonicalSpecializedMetadataAccessorsListEntry
 ***/
struct CanonicalSpecializedMetadataAccessorsListEntry {
    let accessor: RelativeDirectPointer;
};

/***
 * CanonicalSpecializedMetadatasCachingOnceToken
 ***/
struct CanonicalSpecializedMetadatasCachingOnceToken {
    let token: RelativeDirectPointer;
};
