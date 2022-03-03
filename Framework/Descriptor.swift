//
//  Descriptor.swift
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
    case `Protocol` = 3;
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
    fileprivate let _value: UInt32;
}

extension ContextDescriptorFlags {
    var kind: ContextDescriptorKind { get { return ContextDescriptorKind(rawValue:UInt8(self._value & 0x1F)) ?? .Module; } }
    var isGeneric: Bool { get { return (self._value & 0x80) != 0; } }
    var isUnique: Bool { get { return (self._value & 0x40) != 0; } }
    var version: UInt8 { get { return UInt8((self._value >> 8) & 0xFF); } }
    var kindSpecificFlags: UInt16 { get { return UInt16((self._value >> 16) & 0xFFFF); } }
    var metadataInitialization: MetadataInitializationKind { get { return MetadataInitializationKind(rawValue:UInt8(self.kindSpecificFlags & 0x3)) ?? .NoMetadataInitialization } }
    var hasResilientSuperclass: Bool { get { return (self.kindSpecificFlags & 0x2000) != 0; } }
    var hasVTable: Bool { get { return (self.kindSpecificFlags & 0x8000) != 0; } }
    var hasOverrideTable: Bool { get { return (self.kindSpecificFlags & 0x4000) != 0; } }
}

/***
 * ContextDescriptor
 ***/
protocol ContextDescriptorInterface {
    var flags: ContextDescriptorFlags { get };
}

extension ContextDescriptorInterface {
    // parent
    var parent: UnsafePointer<ContextDescriptor>? { mutating get { return Self.getParent(&self); } }
    static func getParent<T : ContextDescriptorInterface>(_ data: UnsafePointer<T>) -> UnsafePointer<ContextDescriptor>? {
        let ptr = UnsafeMutablePointer<RelativeDirectPointer>(OpaquePointer(data)).advanced(by:1).pointee.pointer;
        return UnsafePointer<ContextDescriptor>(ptr);
    }
}

struct ContextDescriptor : ContextDescriptorInterface {
    let flags: ContextDescriptorFlags;
    fileprivate var _parent: RelativeDirectPointer;
}

/***
 * Protocol
 ***/
enum ProtocolClassConstraint : UInt8 {
    case Class = 0;
    case `Any` = 1;
}

enum SpecialProtocol : UInt8 {
    case None = 0;
    case Error = 1;
}

struct ProtocolContextDescriptorFlags {
    fileprivate var _value: UInt16;
    init(_ val: UInt16) {
        self._value = val;
    }
}

extension ProtocolContextDescriptorFlags {
    fileprivate static let HasClassConstraint: UInt16 = 0;
    fileprivate static let HasClassConstraint_width: UInt16 = 1;
    fileprivate static let IsResilient: UInt16 = 1;
    fileprivate static let SpecialProtocolKind: UInt16 = 2;
    fileprivate static let SpecialProtocolKind_width: UInt16 = 6;
    var classConstraint: ProtocolClassConstraint { get { return ProtocolClassConstraint(rawValue:UInt8((self._value >> Self.HasClassConstraint) & ((1 << Self.HasClassConstraint_width) - 1))) ?? .Class; } }
    var specialProtocol: SpecialProtocol { get { return SpecialProtocol(rawValue:UInt8((self._value >> Self.SpecialProtocolKind) & ((1 << Self.SpecialProtocolKind_width) - 1))) ?? .None; } }
}

struct ProtocolDescriptor : ContextDescriptorInterface {
    let flags: ContextDescriptorFlags;
    fileprivate let _parent: RelativeDirectPointer;
    fileprivate var _name: RelativeDirectPointer;
    let numRequirementsInSignature: UInt32;
    let numRequirements: UInt32;
    fileprivate let _associatedTypeNames: RelativeDirectPointer
    // GenericRequirementDescriptor
    // ProtocolRequirement
}

extension ProtocolDescriptor {
    // protocolContextDescriptorFlags
    var protocolContextDescriptorFlags: ProtocolContextDescriptorFlags { get { return ProtocolContextDescriptorFlags(self.flags.kindSpecificFlags); } }
    // name
    var name: String { mutating get { return Self.getName(&self); } }
    static func getName(_ data: UnsafePointer<ProtocolDescriptor>) -> String {
        let ptr = UnsafeMutablePointer<ProtocolDescriptor>(mutating:data).pointee._name.pointer!;
        let namePtr = UnsafePointer<CChar>(ptr);
        guard let parent = self.getParent(data) else { return String(cString:namePtr) }
        let preName = self.getName(UnsafePointer<ProtocolDescriptor>(OpaquePointer(parent)));
        return String(preName + "." + String(cString:namePtr));
    }
    var associatedTypeNames: String? { mutating get { return Self.getAssociatedTypeNames(&self); } }
    static func getAssociatedTypeNames(_ data: UnsafePointer<ProtocolDescriptor>) -> String? {
        if let ptr = UnsafeMutablePointer<ProtocolDescriptor>(mutating:data).pointee._name.pointer {
            return String(cString:UnsafePointer<CChar>(ptr))
        } else {
            return nil;
        }
    }
    // requirementSignature
    var requirementSignature: UnsafeBufferPointer<GenericRequirementDescriptor> { mutating get { return Self.getRequirementSignature(&self); } }
    static func getRequirementSignature(_ data: UnsafePointer<ProtocolDescriptor>) -> UnsafeBufferPointer<GenericRequirementDescriptor> {
        let ptr = UnsafePointer<GenericRequirementDescriptor>(OpaquePointer(data.advanced(by:1)));
        return UnsafeBufferPointer<GenericRequirementDescriptor>(start:ptr, count:Int(data.pointee.numRequirementsInSignature));
    }
    // requirements
    fileprivate static func _getRequirementsOffset(_ data: UnsafePointer<ProtocolDescriptor>) -> Int {
        return MemoryLayout<GenericRequirementDescriptor>.size * Int(data.pointee.numRequirementsInSignature);
    }
    var requirements: UnsafeBufferPointer<ProtocolRequirement> { mutating get { return Self.getRequirements(&self); } }
    static func getRequirements(_ data: UnsafePointer<ProtocolDescriptor>) -> UnsafeBufferPointer<ProtocolRequirement> {
        let offset = Self._getRequirementsOffset(data);
        let ptr = UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:offset).assumingMemoryBound(to:ProtocolRequirement.self);
        return UnsafeBufferPointer<ProtocolRequirement>(start:ptr, count:Int(data.pointee.numRequirements));
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
    fileprivate var _defaultImplementation: RelativeDirectPointer;
}

extension ProtocolRequirement {
    var defaultImplementation: FunctionPointer? { mutating get { return Self.getDefaultImplementation(&self); } }
    static func getDefaultImplementation(_ data: UnsafePointer<ProtocolRequirement>) -> FunctionPointer? {
        if let ptr = UnsafeMutablePointer<ProtocolRequirement>(mutating:data).pointee._defaultImplementation.pointer {
            return Optional(FunctionPointer(ptr));
        } else {
            return nil;
        }
    }
}

// MARK: -
// MARK: TypeContext
/***
 * TypeContextDescriptor
 ***/
struct TypeContextDescriptorFlags {
    fileprivate let _value: UInt16;
    init(_ val: UInt16) {
        self._value = val;
    }
}

extension TypeContextDescriptorFlags {
    fileprivate static let MetadataInitialization: UInt16 = 0;
    fileprivate static let MetadataInitialization_width: UInt16 = 2;
    fileprivate static let HasImportInfo: UInt16 = 2;
    fileprivate static let HasCanonicalMetadataPrespecializations: UInt16 = 3;
    fileprivate static let Class_IsActor: UInt16 = 7;
    fileprivate static let Class_IsDefaultActor: UInt16 = 8;
    fileprivate static let Class_ResilientSuperclassReferenceKind: UInt16 = 9;
    fileprivate static let Class_ResilientSuperclassReferenceKind_width: UInt16 = 3;
    fileprivate static let Class_AreImmediateMembersNegative: UInt16 = 12;
    fileprivate static let Class_HasResilientSuperclass: UInt16 = 13;
    fileprivate static let Class_HasOverrideTable: UInt16 = 14;
    fileprivate static let Class_HasVTable: UInt16 = 15;
    var metadataInitialization: MetadataInitializationKind { get { return MetadataInitializationKind(rawValue:UInt8((self._value >> Self.MetadataInitialization) & ((1 << Self.MetadataInitialization_width) - 1))) ?? .NoMetadataInitialization; } }
    var hasSingletonMetadataInitialization: Bool { get { return self.metadataInitialization == .SingletonMetadataInitialization; } }
    var hasForeignMetadataInitialization: Bool { get { return self.metadataInitialization == .ForeignMetadataInitialization; } }
    var hasImportInfo: Bool { get { return (self._value & (1 << Self.HasImportInfo)) != 0; } }
    var hasCanonicalMetadataPrespecializations: Bool { get { return (self._value & (1 << Self.HasCanonicalMetadataPrespecializations)) != 0; } }
    var class_hasVTable: Bool { get { return (self._value & (1 << Self.Class_HasVTable)) != 0; } }
    var class_hasOverrideTable: Bool { get { return (self._value & (1 << Self.Class_HasOverrideTable)) != 0; } }
    var class_areImmediateMembersNegative: Bool { get { return (self._value & (1 << Self.Class_AreImmediateMembersNegative)) != 0; } }
    var class_isDefaultActor: Bool { get { return (self._value & (1 << Self.Class_IsDefaultActor)) != 0; } }
    var class_isActor: Bool { get { return (self._value & (1 << Self.Class_IsActor)) != 0; } }
    var class_ResilientSuperclassReferenceKind: TypeReferenceKind { get { return TypeReferenceKind(rawValue:UInt16((self._value >> Self.Class_ResilientSuperclassReferenceKind) & ((1 << Self.Class_ResilientSuperclassReferenceKind_width) - 1))) ?? .DirectTypeDescriptor; } }
}

protocol TypeContextDescriptorInterface : ContextDescriptorInterface {
}

extension TypeContextDescriptorInterface {
    // name
    var name: String { mutating get { return Self.getName(&self); } }
    static func getName<T : TypeContextDescriptorInterface>(_ data: UnsafePointer<T>) -> String {
        let ptr = UnsafeMutablePointer<RelativeDirectPointer>(OpaquePointer(data)).advanced(by:2).pointee.pointer!;
        let namePtr = UnsafePointer<CChar>(ptr);
        guard let parent = self.getParent(data) else { return String(cString:namePtr) }
        let preName = self.getName(UnsafePointer<TypeContextDescriptor>(OpaquePointer(parent)));
        return String(preName + "." + String(cString:namePtr));
    }
    // accessFunction
    var accessFunction: FunctionPointer? { mutating get { Self.getAccessFunction(&self); } }
    static func getAccessFunction<T : TypeContextDescriptorInterface>(_ data: UnsafePointer<T>) -> FunctionPointer? {
        if let ptr = UnsafeMutablePointer<RelativeDirectPointer>(OpaquePointer(data)).advanced(by:3).pointee.pointer {
            return Optional(FunctionPointer(ptr));
        } else {
            return nil;
        }
    }
    // fieldDescriptor
    var fieldDescriptor: FunctionPointer? { mutating get { return Self.getFieldDescriptor(&self); } }
    static func getFieldDescriptor<T : TypeContextDescriptorInterface>(_ data: UnsafePointer<T>) -> FunctionPointer? {
        if let ptr = UnsafeMutablePointer<RelativeDirectPointer>(OpaquePointer(data)).advanced(by:4).pointee.pointer {
            return Optional(FunctionPointer(ptr));
        } else {
            return nil;
        }
    }
    
    var typgetTypeContextDescriptorFlags: TypeContextDescriptorFlags { get { return TypeContextDescriptorFlags(self.flags.kindSpecificFlags) } }
    var metadataInitialization: MetadataInitializationKind { get { return self.typgetTypeContextDescriptorFlags.metadataInitialization; } }
    var hasSingletonMetadataInitialization: Bool { get { return self.typgetTypeContextDescriptorFlags.hasSingletonMetadataInitialization; } }
    var hasForeignMetadataInitialization: Bool { get { return self.typgetTypeContextDescriptorFlags.hasForeignMetadataInitialization; } }
    var hasCanonicicalMetadataPrespecializations: Bool { get { return self.typgetTypeContextDescriptorFlags.hasCanonicalMetadataPrespecializations; } }
}

struct TypeContextDescriptor : TypeContextDescriptorInterface {
    let flags: ContextDescriptorFlags;
    fileprivate let _parent: RelativeDirectPointer;
    fileprivate let _name: RelativeDirectPointer;
    fileprivate let _accessFunction: RelativeDirectPointer;
    fileprivate let _fieldDescriptor: RelativeDirectPointer;
};

// MARK: -
// MARK: Extension
struct ExtensionContextDescriptor : ContextDescriptorInterface {
    let flags: ContextDescriptorFlags;
    fileprivate let _parent: RelativeDirectPointer;
    fileprivate var _extendedContext: RelativeDirectPointer;
}

extension ExtensionContextDescriptor {
    var mangledExtendedContext: String { mutating get { return Self.getMangledExtendedContext(&self); } }
    static func getMangledExtendedContext(_ data: UnsafePointer<ExtensionContextDescriptor>) -> String {
        let ptr = UnsafeMutablePointer<ExtensionContextDescriptor>(mutating:data).pointee._extendedContext.pointer!;
        return String(cString:UnsafePointer<CChar>(ptr));
    }
}

// MARK: -
// MARK: Anonymous
struct AnonymousContextDescriptorFlags {
    fileprivate let _value: UInt16;
    init(_ val: UInt16) {
        self._value = val;
    }
}

extension AnonymousContextDescriptorFlags {
    fileprivate static let HasMangledName: UInt16 = 0;
    var hasMangledName: Bool { get { return (self._value & (1 << Self.HasMangledName)) != 0; } }
}

struct AnonymousContextDescriptor {
    let flags: ContextDescriptorFlags;
    fileprivate let _parent: RelativeDirectPointer;
    fileprivate let _name: RelativeDirectPointer;
    fileprivate let _accessFunction: RelativeDirectPointer;
    fileprivate let _fieldDescriptor: RelativeDirectPointer;
    // GenericContextDescriptorHeader
    // MangledContextName
}

extension AnonymousContextDescriptor {
    var anonymousContextDescriptorFlags: AnonymousContextDescriptorFlags { get { return AnonymousContextDescriptorFlags(self.flags.kindSpecificFlags); } }
    var hasMangledName: Bool { get { return self.anonymousContextDescriptorFlags.hasMangledName; } }
    // mangledName
    var mangledName: String? { mutating get { return Self.getMangledName(&self); } }
    static func getMangledName(_ data: UnsafePointer<AnonymousContextDescriptor>) -> String? {
        if (data.pointee.hasMangledName) {
            let ptr = OpaquePointer(UnsafePointer<GenericContextDescriptorHeader>(OpaquePointer(data.advanced(by:1))).advanced(by:1));
            return Optional(UnsafeMutablePointer<MangledContextName>(ptr).pointee.name);
        } else {
            return nil;
        }
    }
}

struct MangledContextName {
    fileprivate var _name: RelativeDirectPointer;
}

extension MangledContextName {
    var name: String { mutating get { return Self.getName(&self); } }
    static func getName(_ data: UnsafePointer<MangledContextName>) -> String {
        let ptr = UnsafeMutablePointer<MangledContextName>(mutating:data).pointee._name.pointer!;
        return String(cString:UnsafePointer<CChar>(ptr));
    }
}

// MARK: -
// MARK: OpaqueType
struct OpaqueTypeDescriptor {
    let flags: ContextDescriptorFlags;
    fileprivate let _parent: RelativeDirectPointer;
    // GenericContextDescriptorHeader
    // RelativeDirectPointer<const char>
}

extension OpaqueTypeDescriptor {
    var numUnderlyingTypeArguments: UInt16 { get { return self.flags.kindSpecificFlags; } }
}

// MARK: -
// MARK: Struct
protocol ValueTypeDescriptorInterface : TypeContextDescriptorInterface {
}

extension ValueTypeDescriptorInterface {
    static func classof(descriptor: TypeContextDescriptor) -> Bool {
        return (descriptor.flags.kind == .Struct || descriptor.flags.kind == .Enum);
    }
    static func classof(descriptor: UnsafePointer<TypeContextDescriptor>) -> Bool {
        return (descriptor.pointee.flags.kind == .Struct || descriptor.pointee.flags.kind == .Enum);
    }
}
/***
 * StructDescriptor
 ***/
struct StructDescriptor : ValueTypeDescriptorInterface {
    let flags: ContextDescriptorFlags;
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
    // foreignMetadataInitialization
    fileprivate static func _getForeignMetadataInitializationOffset(_ data: UnsafePointer<StructDescriptor>) -> Int {
        if (data.pointee.flags.isGeneric) {
            let ptr = UnsafePointer<TypeGenericContextDescriptorHeader>(OpaquePointer(data.advanced(by:1)));
            return TypeGenericContextDescriptorHeader.getTypeGenericContextDataSize(ptr);
        }
        return 0;
    }
    var foreignMetadataInitialization: UnsafePointer<ForeignMetadataInitialization>? { mutating get { return Self.getForeignMetadataInitialization(&self); } }
    static func getForeignMetadataInitialization(_ data: UnsafePointer<StructDescriptor>) -> UnsafePointer<ForeignMetadataInitialization>? {
        if (data.pointee.hasForeignMetadataInitialization) {
            let offset = Self._getForeignMetadataInitializationOffset(data);
            return Optional(UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:offset).assumingMemoryBound(to:ForeignMetadataInitialization.self));
        } else {
            return nil;
        }
    }
    // singletonMetadataInitialization
    fileprivate static func _getSingletonMetadataInitializationOffset(_ data: UnsafePointer<StructDescriptor>) -> Int {
        var offset = Self._getForeignMetadataInitializationOffset(data);
        if (data.pointee.hasForeignMetadataInitialization) {
            offset += MemoryLayout<ForeignMetadataInitialization>.size;
        }
        return offset;
    }
    var singletonMetadataInitialization: UnsafePointer<SingletonMetadataInitialization>? { mutating get { return Self.getSingletonMetadataInitialization(&self); } }
    static func getSingletonMetadataInitialization(_ data: UnsafePointer<StructDescriptor>) -> UnsafePointer<SingletonMetadataInitialization>? {
        if (data.pointee.hasSingletonMetadataInitialization) {
            let offset = Self._getSingletonMetadataInitializationOffset(data);
            return Optional(UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:offset).assumingMemoryBound(to:SingletonMetadataInitialization.self));
        } else {
            return nil;
        }
    }
    // canonicicalMetadataPrespecializations
    fileprivate static func _getCanonicicalMetadataPrespecializationsOffset(_ data: UnsafePointer<StructDescriptor>) -> Int {
        var offset = Self._getSingletonMetadataInitializationOffset(data);
        if (data.pointee.hasSingletonMetadataInitialization) {
            offset += MemoryLayout<SingletonMetadataInitialization>.size;
        }
        return offset;
    }
    var canonicicalMetadataPrespecializations: UnsafeBufferPointer<CanonicalSpecializedMetadatasListEntry>? { mutating get { return Self.getCanonicicalMetadataPrespecializations(&self); } }
    static func getCanonicicalMetadataPrespecializations(_ data: UnsafePointer<StructDescriptor>) -> UnsafeBufferPointer<CanonicalSpecializedMetadatasListEntry>? {
        if (data.pointee.hasCanonicicalMetadataPrespecializations) {
            let offset = Self._getCanonicicalMetadataPrespecializationsOffset(data);
            let countPtr = UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:offset).assumingMemoryBound(to:CanonicalSpecializedMetadatasListCount.self);
            let listPtr = UnsafePointer<CanonicalSpecializedMetadatasListEntry>(OpaquePointer(countPtr.advanced(by:1)));
            return UnsafeBufferPointer<CanonicalSpecializedMetadatasListEntry>(start:listPtr, count:Int(countPtr.pointee.count));
        } else {
            return nil;
        }
    }
    // canonicalMetadataPrespecializationCachingOnceToken
    fileprivate static func _getCanonicalMetadataPrespecializationCachingOnceToken(_ data: UnsafePointer<StructDescriptor>) -> Int {
        var offset = Self._getCanonicicalMetadataPrespecializationsOffset(data);
        if (data.pointee.hasCanonicicalMetadataPrespecializations) {
            let countPtr = UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:offset).assumingMemoryBound(to:CanonicalSpecializedMetadatasListCount.self);
            offset += MemoryLayout<CanonicalSpecializedMetadatasListCount>.size + MemoryLayout<SingletonMetadataInitialization>.size * Int(countPtr.pointee.count);
        }
        return offset;
    }
    var canonicalMetadataPrespecializationCachingOnceToken: CLong { mutating get { return Self.getCanonicalMetadataPrespecializationCachingOnceToken(&self); } }
    static func getCanonicalMetadataPrespecializationCachingOnceToken(_ data: UnsafePointer<StructDescriptor>) -> CLong {
        if (data.pointee.hasCanonicicalMetadataPrespecializations) {
            let offset = Self._getCanonicalMetadataPrespecializationCachingOnceToken(data);
            let ptr = UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:offset).assumingMemoryBound(to:CanonicalSpecializedMetadatasCachingOnceToken.self);
            return CanonicalSpecializedMetadatasCachingOnceToken.getToken(ptr);
        } else {
            return 0;
        }
    }
    
}

// MARK: -
// MARK: Enum
/***
 * EnumDescriptor
 ***/
struct EnumDescriptor : ValueTypeDescriptorInterface {
    let flags: ContextDescriptorFlags;
    fileprivate let _parent: RelativeDirectPointer;
    fileprivate let _name: RelativeDirectPointer;
    fileprivate let _accessFunction: RelativeDirectPointer;
    fileprivate let _fieldDescriptor: RelativeDirectPointer;
    fileprivate let _numPayloadCasesAndPayloadSizeOffset: UInt32;
    let numEmptyCases: UInt32;
    // ForeignMetadataInitialization
    // SingletonMetadataInitialization
    // CanonicalSpecializedMetadatasListCount
    // CanonicalSpecializedMetadatasListEntry
    // CanonicalSpecializedMetadatasCachingOnceToken
}

extension EnumDescriptor {
    var numPayloadCases: UInt32 { get { return self._numPayloadCasesAndPayloadSizeOffset & 0x00FFFFFF; } }
    var numCases: UInt32 { get { return self.numPayloadCases + self.numEmptyCases; } }
    var payloadSizeOffset: UInt32 { get { return ((self._numPayloadCasesAndPayloadSizeOffset & 0xFF000000) >> 24); } }
    var hasPayloadSizeOffset: Bool { get { return self.payloadSizeOffset != 0; } }
    // foreignMetadataInitialization
    var foreignMetadataInitialization: UnsafePointer<ForeignMetadataInitialization>? { mutating get { return Self.getForeignMetadataInitialization(&self); } }
    static func getForeignMetadataInitialization(_ data: UnsafePointer<EnumDescriptor>) -> UnsafePointer<ForeignMetadataInitialization>? {
        if (data.pointee.hasSingletonMetadataInitialization) {
            return UnsafePointer<ForeignMetadataInitialization>(OpaquePointer(data.advanced(by:1)));
        } else {
            return nil;
        }
    }
    // singletonMetadataInitialization
    fileprivate static func _getSingletonMetadataInitializationOffset(_ data: UnsafePointer<EnumDescriptor>) -> Int {
        if (data.pointee.hasSingletonMetadataInitialization) {
            return MemoryLayout<ForeignMetadataInitialization>.size;
        }
        return 0;
    }
    var singletonMetadataInitialization: UnsafePointer<SingletonMetadataInitialization>? { mutating get { return Self.getSingletonMetadataInitialization(&self); } }
    static func getSingletonMetadataInitialization(_ data: UnsafePointer<EnumDescriptor>) -> UnsafePointer<SingletonMetadataInitialization>? {
        if (data.pointee.hasSingletonMetadataInitialization) {
            let offset = Self._getSingletonMetadataInitializationOffset(data);
            return UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:offset).assumingMemoryBound(to:SingletonMetadataInitialization.self);
        } else {
            return nil;
        }
    }
    // canonicicalMetadataPrespecializations
    fileprivate static func _getCanonicicalMetadataPrespecializationsOffset(_ data: UnsafePointer<EnumDescriptor>) -> Int {
        var offset = Self._getSingletonMetadataInitializationOffset(data);
        if (data.pointee.hasSingletonMetadataInitialization) {
            offset += MemoryLayout<SingletonMetadataInitialization>.size;
        }
        return offset;
    }
    var canonicicalMetadataPrespecializations: UnsafeBufferPointer<CanonicalSpecializedMetadatasListEntry>? { mutating get { return Self.getCanonicicalMetadataPrespecializations(&self); } }
    static func getCanonicicalMetadataPrespecializations(_ data: UnsafePointer<EnumDescriptor>) -> UnsafeBufferPointer<CanonicalSpecializedMetadatasListEntry>? {
        if (data.pointee.hasCanonicicalMetadataPrespecializations) {
            let offset = Self._getCanonicicalMetadataPrespecializationsOffset(data);
            let countPtr = UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:offset).assumingMemoryBound(to:CanonicalSpecializedMetadatasListCount.self);
            let listPtr = UnsafePointer<CanonicalSpecializedMetadatasListEntry>(OpaquePointer(countPtr.advanced(by:1)));
            return UnsafeBufferPointer<CanonicalSpecializedMetadatasListEntry>(start:listPtr, count:Int(countPtr.pointee.count));
        } else {
            return nil;
        }
    }
    // canonicalMetadataPrespecializationCachingOnceToken
    fileprivate static func _getCanonicalMetadataPrespecializationCachingOnceToken(_ data: UnsafePointer<EnumDescriptor>) -> Int {
        var offset = Self._getCanonicicalMetadataPrespecializationsOffset(data);
        if (data.pointee.hasCanonicicalMetadataPrespecializations) {
            let countPtr = UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:offset).assumingMemoryBound(to:CanonicalSpecializedMetadatasListCount.self);
            offset += MemoryLayout<CanonicalSpecializedMetadatasListCount>.size + MemoryLayout<SingletonMetadataInitialization>.size * Int(countPtr.pointee.count);
        }
        return offset;
    }
    var canonicalMetadataPrespecializationCachingOnceToken: CLong { mutating get { return Self.getCanonicalMetadataPrespecializationCachingOnceToken(&self); } }
    static func getCanonicalMetadataPrespecializationCachingOnceToken(_ data: UnsafePointer<EnumDescriptor>) -> CLong {
        if (data.pointee.hasCanonicicalMetadataPrespecializations) {
            let offset = Self._getCanonicalMetadataPrespecializationCachingOnceToken(data);
            let ptr = UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:offset).assumingMemoryBound(to:CanonicalSpecializedMetadatasCachingOnceToken.self);
            return CanonicalSpecializedMetadatasCachingOnceToken.getToken(ptr);
        } else {
            return 0;
        }
    }
}

// MARK: -
// MARK: Class
/***
 * ClassDescriptor
 ***/
struct ClassDescriptor : TypeContextDescriptorInterface {
    let flags: ContextDescriptorFlags;
    fileprivate let _parent: RelativeDirectPointer;
    fileprivate let _name: RelativeDirectPointer;
    fileprivate let _accessFunction: RelativeDirectPointer;
    fileprivate let _fieldDescriptor: RelativeDirectPointer;
    fileprivate var _superclassType: RelativeDirectPointer;
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
    // superclassType
    var superclassType: String? { mutating get { return Self.getSuperclassType(&self); } }
    static func getSuperclassType(_ data: UnsafePointer<ClassDescriptor>) -> String? {
        if let ptr = UnsafeMutablePointer<ClassDescriptor>(mutating:data).pointee._superclassType.pointer {
            return Optional(String(cString:UnsafePointer<CChar>(ptr)));
        } else {
            return nil;
        }
    }
    // typeGenericContextDescriptorHeader
    var typeGenericContextDescriptorHeader: UnsafePointer<TypeGenericContextDescriptorHeader>? { mutating get { return Self.getTypeGenericContextDescriptorHeader(&self); } }
    static func getTypeGenericContextDescriptorHeader(_ data: UnsafePointer<ClassDescriptor>) -> UnsafePointer<TypeGenericContextDescriptorHeader>? {
        if (data.pointee.flags.isGeneric) {
            return UnsafePointer<TypeGenericContextDescriptorHeader>(OpaquePointer(data.advanced(by:1)));
        } else {
            return nil;
        }
    }
    // genericParamDescriptors
    var numParams: UInt32 { mutating get { return Self.getNumParams(&self); } }
    static func getNumParams(_ data: UnsafePointer<ClassDescriptor>) -> UInt32 {
        if (data.pointee.flags.isGeneric) {
            return UInt32(UnsafePointer<TypeGenericContextDescriptorHeader>(OpaquePointer(data.advanced(by:1))).pointee.base.numParams);
        } else {
            return 0;
        }
    }
    var genericParamDescriptors: UnsafeBufferPointer<GenericParamDescriptor>? { mutating get { return Self.getGenericParamDescriptors(&self); } }
    static func getGenericParamDescriptors(_ data: UnsafePointer<ClassDescriptor>) -> UnsafeBufferPointer<GenericParamDescriptor>? {
        if (data.pointee.flags.isGeneric) {
            let ptr = UnsafePointer<TypeGenericContextDescriptorHeader>(OpaquePointer(data.advanced(by:1)));
            if (ptr.pointee.base.numParams > 0) {
                return Optional(UnsafeBufferPointer(start:UnsafePointer<GenericParamDescriptor>(OpaquePointer(ptr.advanced(by:1))), count:Int(ptr.pointee.base.numParams)));
            } else {
                return nil;
            }
        } else {
            return nil;
        }
    }
    // ResilientSuperclass
    fileprivate static func _getResilientSuperclassOffset(_ data: UnsafePointer<ClassDescriptor>) -> Int {
        var offset = 0;
        if (data.pointee.flags.isGeneric) {
            let ptr = UnsafePointer<TypeGenericContextDescriptorHeader>(OpaquePointer(data.advanced(by:1)));
            offset = TypeGenericContextDescriptorHeader.getTypeGenericContextDataSize(ptr);
        }
        return offset;
    }
    var resilientSuperclass: UnsafePointer<ResilientSuperclass>? { mutating get { return Self.getResilientSuperclass(&self); } }
    static func getResilientSuperclass(_ data: UnsafePointer<ClassDescriptor>) -> UnsafePointer<ResilientSuperclass>? {
        if (data.pointee.flags.hasResilientSuperclass) {
            return UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:self._getResilientSuperclassOffset(data)).assumingMemoryBound(to:ResilientSuperclass.self);
        } else {
            return nil;
        }
    }
    // ForeignMetadataInitialization
    fileprivate static func _getMetadataInitializationOffset(_ data: UnsafePointer<ClassDescriptor>) -> Int {
        var offset = Self._getResilientSuperclassOffset(data);
        if (data.pointee.flags.hasResilientSuperclass) {
            offset += MemoryLayout<ResilientSuperclass>.size;
        }
        return offset;
    }
    var foreignMetadataInitialization: UnsafePointer<ForeignMetadataInitialization>? { mutating get { return Self.getForeignMetadataInitialization(&self); } }
    static func getForeignMetadataInitialization(_ data: UnsafePointer<ClassDescriptor>) -> UnsafePointer<ForeignMetadataInitialization>? {
        if (data.pointee.flags.metadataInitialization == .ForeignMetadataInitialization) {
            return UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:self._getMetadataInitializationOffset(data)).assumingMemoryBound(to:ForeignMetadataInitialization.self);
        } else {
            return nil;
        }
    }
    // SingletonMetadataInitialization
    var singletonMetadataInitialization: UnsafePointer<SingletonMetadataInitialization>? { mutating get { return Self.getSingletonMetadataInitialization(&self); } }
    static func getSingletonMetadataInitialization(_ data: UnsafePointer<ClassDescriptor>) -> UnsafePointer<SingletonMetadataInitialization>? {
        if (data.pointee.flags.metadataInitialization == .SingletonMetadataInitialization) {
            return UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:self._getMetadataInitializationOffset(data)).assumingMemoryBound(to:SingletonMetadataInitialization.self);
        } else {
            return nil;
        }
    }
    // vtable
    fileprivate static func _getVtableOffset(_ data: UnsafePointer<ClassDescriptor>) -> Int {
        var offset = Self._getMetadataInitializationOffset(data);
        switch(data.pointee.flags.metadataInitialization) {
        case .ForeignMetadataInitialization:
            offset += MemoryLayout<ForeignMetadataInitialization>.size;
        case .SingletonMetadataInitialization:
            offset += MemoryLayout<SingletonMetadataInitialization>.size;
        case .NoMetadataInitialization:
            offset += 0;
        }
        return offset;
    }
    var vTableSize: UInt32 { mutating get { return Self.getVTableSize(&self); } }
    static func getVTableSize(_ data: UnsafePointer<ClassDescriptor>) -> UInt32 {
        if (data.pointee.flags.hasVTable) {
            let ptr = UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:self._getVtableOffset(data)).assumingMemoryBound(to:VTableDescriptorHeader.self);
            return ptr.pointee.vTableSize;
        } else {
            return 0;
        }
    }
    var vtable: UnsafeBufferPointer<MethodDescriptor>? { mutating get { Self.getVTable(&self); } }
    static func getVTable(_ data: UnsafePointer<ClassDescriptor>) -> UnsafeBufferPointer<MethodDescriptor>? {
        if (data.pointee.flags.hasVTable) {
            let ptr = UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:self._getVtableOffset(data)).assumingMemoryBound(to:VTableDescriptorHeader.self);
            let buffer = UnsafeBufferPointer(start:UnsafePointer<MethodDescriptor>(OpaquePointer(ptr.advanced(by:1))), count:Int(ptr.pointee.vTableSize));
            return Optional(buffer);
        } else {
            return nil;
        }
    }
    
    // overridetable
    fileprivate static func _getOverridetableOffset(_ data: UnsafePointer<ClassDescriptor>) -> Int {
        var offset = self._getVtableOffset(data);
        if (data.pointee.flags.hasVTable) {
            let ptr = UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:offset).assumingMemoryBound(to:VTableDescriptorHeader.self);
            offset += MemoryLayout<VTableDescriptorHeader>.size;
            offset += MemoryLayout<MethodDescriptor>.size * Int(ptr.pointee.vTableSize);
        }
        return offset;
    }
    var overridetableSize: UInt32 { mutating get { return Self.getOverridetableSize(&self); } }
    static func getOverridetableSize(_ data: UnsafePointer<ClassDescriptor>) -> UInt32 {
        if (data.pointee.flags.hasOverrideTable) {
            let ptr = UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:self._getOverridetableOffset(data)).assumingMemoryBound(to:OverrideTableHeader.self);
            return ptr.pointee.numEntries;
        } else {
            return 0;
        }
    }
    var overridetable: UnsafeBufferPointer<MethodOverrideDescriptor>? { mutating get { return Self.getOverridetable(&self); } }
    static func getOverridetable(_ data: UnsafePointer<ClassDescriptor>) -> UnsafeBufferPointer<MethodOverrideDescriptor>? {
        if (data.pointee.flags.hasOverrideTable) {
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

extension GenericContextDescriptorHeader {
    var numArguments: UInt32 { get { return UInt32(self.numKeyArguments + self.numExtraArguments); } }
    var hasArguments: Bool { get { return self.numArguments > 0; } }
}

enum GenericParamKind : UInt8 {
    case `Type` = 0;
    case Max = 0x3F;
}

struct GenericParamDescriptor {
    let value: UInt8;
}

extension GenericParamDescriptor {
    var hasKeyArgument: Bool { get { return (self.value & 0x80) != 0; } }
    var hasExtraArgument: Bool { get { return (self.value & 0x40) != 0; } }
    var kind: GenericParamKind { get { return GenericParamKind(rawValue:self.value & 0x3F) ?? .Max; } }
}

/***
 * TypeGenericContextDescriptorHeader
 ***/
struct TypeGenericContextDescriptorHeader {
    fileprivate var _instantiationCache: RelativeDirectPointer;
    fileprivate var _defaultInstantiationPattern: RelativeDirectPointer;
    let base: GenericContextDescriptorHeader;
};

extension TypeGenericContextDescriptorHeader {
    // instantiationCache
    var instantiationCache: UnsafePointer<GenericMetadataInstantiationCache>? { mutating get { Self.getInstantiationCache(&self); } }
    static func getInstantiationCache(_ data: UnsafePointer<TypeGenericContextDescriptorHeader>) -> UnsafePointer<GenericMetadataInstantiationCache>? {
        if let ptr = UnsafeMutablePointer<TypeGenericContextDescriptorHeader>(mutating:data).pointee._instantiationCache.pointer {
            return Optional(UnsafePointer<GenericMetadataInstantiationCache>(ptr))
        } else {
            return nil;
        }
    }
    // defaultInstantiationPattern
    var defaultInstantiationPattern: UnsafePointer<GenericMetadataPattern>? { mutating get { return Self.getDefaultInstantiationPattern(&self); } }
    static func getDefaultInstantiationPattern(_ data: UnsafePointer<TypeGenericContextDescriptorHeader>) -> UnsafePointer<GenericMetadataPattern>? {
        if let ptr = UnsafeMutablePointer<TypeGenericContextDescriptorHeader>(mutating:data).pointee._defaultInstantiationPattern.pointer {
            return Optional(UnsafePointer<GenericMetadataPattern>(ptr))
        } else {
            return nil;
        }
    }
    //
    fileprivate static func getTypeGenericContextDataSize(_ data: UnsafePointer<TypeGenericContextDescriptorHeader>) ->Int {
        return MemoryLayout<TypeGenericContextDescriptorHeader>.size + Int((data.pointee.base.numParams + 3) & ~UInt16(3)) + MemoryLayout<GenericRequirementDescriptor>.size * Int(data.pointee.base.numRequirements);
    }
}

struct GenericMetadataInstantiationCache {
    fileprivate let _privateData: OpaquePointer;
}

extension GenericMetadataInstantiationCache {
    fileprivate static let NumGenericMetadataPrivateDataWords: Int = 16;
    var privateData: UnsafeBufferPointer<OpaquePointer> { mutating get { return Self.getPrivateData(&self); } }
    static func getPrivateData(_ data: UnsafePointer<GenericMetadataInstantiationCache>) -> UnsafeBufferPointer<OpaquePointer> {
        return UnsafeBufferPointer(start:UnsafePointer<OpaquePointer>(OpaquePointer(data)), count:Self.NumGenericMetadataPrivateDataWords);
    }
}

struct GenericMetadataPatternFlags {
    fileprivate let _value: UInt32;
}

extension GenericMetadataPatternFlags {
    fileprivate static let HasExtraDataPattern: UInt32 = 0;
    fileprivate static let HasTrailingFlags: UInt32 = 1;
    fileprivate static let Class_HasImmediateMembersPattern: UInt32 = 31;
    fileprivate static let Value_MetadataKind: UInt32 = 21;
    fileprivate static let Value_MetadataKind_width: UInt32 = 11;
    var class_hasImmediateMembersPattern: Bool { get { return (self._value & (1 << Self.Class_HasImmediateMembersPattern)) != 0; } }
    var hasExtraDataPattern: Bool { get { return (self._value & (1 << Self.HasExtraDataPattern)) != 0; } }
    var hasTrailingFlags: Bool { get { return (self._value & (1 << Self.HasTrailingFlags)) != 0; } }
    var value_getMetadataKind: MetadataKind { get { return MetadataKind(rawValue:(((1 << Self.Value_MetadataKind_width) - 1) & (self._value >> Self.Value_MetadataKind))) ?? .Class; } }
}

struct GenericMetadataPattern {
    fileprivate var _instantiationFunction: RelativeDirectPointer;
    fileprivate var _completionFunction: RelativeDirectPointer;
    let patternFlags: GenericMetadataPatternFlags;
}

extension GenericMetadataPattern {
    // instantiationFunction
    var instantiationFunction: FunctionPointer? { mutating get { return Self.getDefaultInstantiationPattern(&self); } }
    static func getDefaultInstantiationPattern(_ data: UnsafePointer<GenericMetadataPattern>) -> FunctionPointer? {
        if let ptr = UnsafeMutablePointer<GenericMetadataPattern>(mutating:data).pointee._instantiationFunction.pointer {
            return Optional(FunctionPointer(ptr));
        } else {
            return nil;
        }
    }
    // completionFunction
    var completionFunction: FunctionPointer? { mutating get { return Self.getCompletionFunction(&self); } }
    static func getCompletionFunction(_ data: UnsafePointer<GenericMetadataPattern>) -> FunctionPointer? {
        if let ptr = UnsafeMutablePointer<GenericMetadataPattern>(mutating:data).pointee._completionFunction.pointer {
            return Optional(FunctionPointer(ptr));
        } else {
            return nil;
        }
    }
    var hasExtraDataPattern: Bool { get { return self.patternFlags.hasExtraDataPattern; } }
}

// MARK: -
// MARK: Append
enum GenericRequirementKind : UInt8 {
    case `Protocol` = 0;
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
    fileprivate var _param: RelativeDirectPointer;
    fileprivate let _layout: Int32;
}

struct RelativeTargetProtocolDescriptorPointer {
    fileprivate var _pointer : RelativeDirectPointer;
}

extension RelativeTargetProtocolDescriptorPointer {
//    fileprivate static func mask() -> Int32 {
//        return Int32(MemoryLayout<RelativeDirectPointer>.alignment - 1);
//    }
//    fileprivate static func pointer(_ ptr: UnsafePointer<RelativeTargetProtocolDescriptorPointer>, _ offset: Int32) -> OpaquePointer? {
//        return OpaquePointer(bitPattern:Int(bitPattern:ptr) + Int(offset));
//    }
//    var pointer: OpaquePointer? {
//        mutating get {
//            let offset = (self._pointer & ~RelativeTargetProtocolDescriptorPointer.mask());
//            if (self._pointer == 0) { return nil; }
//            return RelativeTargetProtocolDescriptorPointer.pointer(&self, offset);
//        }
//    }
//    var isObjC: Bool {
//        return (self._pointer & RelativeTargetProtocolDescriptorPointer.mask()) != 0;
//    }
}

typealias GenericRequirementLayoutKind = Int32;
extension GenericRequirementDescriptor {
    var kind: GenericRequirementKind { get { return self.flags.kind; } }
    // param
    var param: String { mutating get { return Self.getParam(&self); } }
    static func getParam(_ data: UnsafePointer<GenericRequirementDescriptor>) -> String {
        let ptr = UnsafeMutablePointer<GenericRequirementDescriptor>(mutating:data).pointee._param.pointer!;
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
            let ptr = UnsafeMutablePointer<RelativeDirectPointer>(mutating:UnsafePointer<RelativeDirectPointer>(OpaquePointer(data)).advanced(by:2)).pointee.pointer!;
            return Optional(String(cString:UnsafePointer<CChar>(ptr)));
        } else {
            return nil;
        }
    }
    // conformance
    var conformance: UnsafePointer<ProtocolConformanceDescriptor>? { mutating get { return Self.getConformance(&self); } }
    static func getConformance(_ data: UnsafePointer<GenericRequirementDescriptor>) -> UnsafePointer<ProtocolConformanceDescriptor>? {
        if (data.pointee.kind == .SameConformance) {
            let ptr = UnsafeMutablePointer<RelativeContextPointer>(mutating:UnsafePointer<RelativeContextPointer>(OpaquePointer(data)).advanced(by:2)).pointee.pointer!;
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
            case .BaseClass, .Layout, .Protocol, .SameConformance, .SameType:
                ret = true;
            default:
                ret = false;
            }
            return ret;
        }
    }
}

/***
 * ResilientWitness
 ***/
struct ResilientWitnessesHeader {
    let numWitnesses: UInt32;
}

struct ResilientWitness {
    fileprivate var _requirement: RelativeContextPointer;
    fileprivate var _witness: RelativeDirectPointer;
}

extension ResilientWitness {
    // requirement
    var requirement: UnsafePointer<ProtocolRequirement> { mutating get { return Self.getRequirement(&self); } }
    static func getRequirement(_ data: UnsafePointer<ResilientWitness>) -> UnsafePointer<ProtocolRequirement> {
        let ptr = UnsafeMutablePointer<ResilientWitness>(mutating:data).pointee._requirement.pointer!;
        return UnsafePointer<ProtocolRequirement>(ptr);
    }
    //witness
    var witness: OpaquePointer { mutating get { return Self.getWitness(&self); } }
    static func getWitness(_ data: UnsafePointer<ResilientWitness>) -> OpaquePointer {
        return UnsafeMutablePointer<ResilientWitness>(mutating:data).pointee._witness.pointer!;
    }
}

/***
 * GenericWitnessTable
 ***/
struct GenericWitnessTable {
    let witnessTableSizeInWords: UInt16;
    let witnessTablePrivateSizeInWordsAndRequiresInstantiation: UInt16;
    fileprivate var _instantiator: RelativeDirectPointer;
    fileprivate var _privateData: RelativeDirectPointer;
}

extension GenericWitnessTable {
    fileprivate static let NumGenericMetadataPrivateDataWords: UInt32 = 16;
    var witnessTablePrivateSizeInWords: UInt16 { get { return self.witnessTablePrivateSizeInWordsAndRequiresInstantiation >> 0x01; } }
    var requiresInstantiation: UInt16 { get { return self.witnessTablePrivateSizeInWordsAndRequiresInstantiation & 0x01; } }
    // instantiator
    var instantiator: FunctionPointer { mutating get { return Self.getInstantiator(&self); } }
    static func getInstantiator(_ data: UnsafePointer<GenericWitnessTable>) -> FunctionPointer {
        return FunctionPointer(UnsafeMutablePointer<GenericWitnessTable>(mutating:data).pointee._instantiator.pointer!);
    }
    // privateData
    var privateData: UnsafeBufferPointer<FunctionPointer> { mutating get { return Self.getPrivateData(&self); } }
    static func getPrivateData(_ data: UnsafePointer<GenericWitnessTable>) -> UnsafeBufferPointer<FunctionPointer> {
        let ptr = UnsafeMutablePointer<GenericWitnessTable>(mutating:data).pointee._privateData.pointer!;
        let size = data.pointee.witnessTablePrivateSizeInWords;  // not sure
        return UnsafeBufferPointer<FunctionPointer>(start:UnsafePointer<FunctionPointer>(ptr), count:Int(size));
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
    fileprivate static let IsRetroactiveMask: UInt32 = 0x01 << 6;
    fileprivate static let IsSynthesizedNonUniqueMask: UInt32 = 0x01 << 7;
    fileprivate static let NumConditionalRequirementsMask: UInt32 = 0xFF << 8;
    fileprivate static let NumConditionalRequirementsShift: UInt32 = 8;
    fileprivate static let HasResilientWitnessesMask: UInt32 = 0x01 << 16;
    fileprivate static let HasGenericWitnessTableMask: UInt32 = 0x01 << 17;
    var typeReferenceKind: TypeReferenceKind { get { return TypeReferenceKind(rawValue:UInt16((self._value & Self.TypeMetadataKindMask) >> Self.TypeMetadataKindShift)) ?? .DirectTypeDescriptor; } }
    var isRetroactive: Bool { get { return (self._value & Self.IsRetroactiveMask) != 0; } }
    var isSynthesizedNonUnique: Bool { get { return (self._value & Self.IsSynthesizedNonUniqueMask) != 0; } }
    var numConditionalRequirements: UInt32 { get { return (self._value & Self.NumConditionalRequirementsMask) >> Self.NumConditionalRequirementsShift; } }
    var hasResilientWitnesses: Bool { get { return (self._value & Self.HasResilientWitnessesMask) != 0; } }
    var hasGenericWitnessTable: Bool { get { return (self._value & Self.HasGenericWitnessTableMask) != 0; } }
}

/***
 * TypeReference
 ***/
struct TypeReference {
    fileprivate var _value: RelativeDirectPointer;
}

extension TypeReference {
    fileprivate static func getPointer(_ ptr: UnsafePointer<TypeReference>) -> OpaquePointer {
        return UnsafeMutablePointer<TypeReference>(mutating:ptr).pointee._value.pointer!;
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
    fileprivate var _protocol: RelativeContextPointer;
    fileprivate var _typeRef: TypeReference;
    fileprivate var _witnessTablePattern : RelativeDirectPointer;
    let flags: ConformanceFlags;
    // RelativeContextPointer
    // GenericRequirementDescriptor
    // ResilientWitnessesHeader
    // ResilientWitness
    // GenericWitnessTable
}

extension ProtocolConformanceDescriptor {
    // protocol
    var protocolDescriptor: UnsafePointer<ProtocolDescriptor> { mutating get { return Self.getProtocolDescriptor(&self); } }
    static func getProtocolDescriptor(_ data: UnsafePointer<ProtocolConformanceDescriptor>) -> UnsafePointer<ProtocolDescriptor> {
        let ptr = UnsafeMutablePointer<ProtocolConformanceDescriptor>(mutating:data).pointee._protocol.pointer!;
        return UnsafePointer<ProtocolDescriptor>(ptr);
    }
    // witnessTablePattern
    var witnessTablePattern: UnsafePointer<WitnessTable>? { mutating get { return Self.getWitnessTablePattern(&self); } }
    static func getWitnessTablePattern(_ data: UnsafePointer<ProtocolConformanceDescriptor>) -> UnsafePointer<WitnessTable>? {
        if let ptr = UnsafeMutablePointer<ProtocolConformanceDescriptor>(mutating:data).pointee._witnessTablePattern.pointer {
            return Optional(UnsafePointer<WitnessTable>(ptr));
        } else {
            return nil;
        }
    }
    var witnessTable: UnsafeBufferPointer<FunctionPointer>? { mutating get { return Self.getWitnessTable(&self); } }
    static func getWitnessTable(_ data: UnsafePointer<ProtocolConformanceDescriptor>) -> UnsafeBufferPointer<FunctionPointer>? {
        if let ptr = UnsafePointer<FunctionPointer>(OpaquePointer(Self.getWitnessTablePattern(data)?.advanced(by:1))) {
            let size = Self.getProtocolDescriptor(data).pointee.numRequirements; // not sure
            return UnsafeBufferPointer<FunctionPointer>(start:ptr, count:Int(size));
        } else {
            return nil;
        }
    }
    // directObjCClassName
    var directObjCClassName: String? { mutating get { return Self.getDirectObjCClassName(&self); } }
    static func getDirectObjCClassName(_ data: UnsafePointer<ProtocolConformanceDescriptor>) -> String? {
        let ptr = UnsafeMutablePointer<ProtocolConformanceDescriptor>(mutating:data);
        return ptr.pointee._typeRef.getDirectObjCClassName(data.pointee.flags.typeReferenceKind);
    }
    // indirectObjCClass
    var indirectObjCClass: UnsafePointer<ClassMetadata>? { mutating get { return Self.getIndirectObjCClass(&self); } }
    static func getIndirectObjCClass(_ data: UnsafePointer<ProtocolConformanceDescriptor>) -> UnsafePointer<ClassMetadata>? {
        let ptr = UnsafeMutablePointer<ProtocolConformanceDescriptor>(mutating:data);
        return ptr.pointee._typeRef.getIndirectObjCClass(data.pointee.flags.typeReferenceKind);
    }
    // typeDescriptor
    var typeDescriptor: UnsafePointer<ContextDescriptor>? { mutating get { return Self.getTypeDescriptor(&self); } }
    static func getTypeDescriptor(_ data: UnsafePointer<ProtocolConformanceDescriptor>) -> UnsafePointer<ContextDescriptor>? {
        let ptr = UnsafeMutablePointer<ProtocolConformanceDescriptor>(mutating:data);
        return ptr.pointee._typeRef.getTypeDescriptor(data.pointee.flags.typeReferenceKind);
    }
    // retroactiveContext
    var retroactiveContext: UnsafePointer<ContextDescriptor>? { mutating get { return Self.getRetroactiveContext(&self); } }
    static func getRetroactiveContext(_ data: UnsafePointer<ProtocolConformanceDescriptor>) -> UnsafePointer<ContextDescriptor>? {
        if (data.pointee.flags.isRetroactive) {
            let ptr = UnsafeMutablePointer<RelativeContextPointer>(OpaquePointer(data.advanced(by:1)));
            return UnsafePointer<ContextDescriptor>(ptr.pointee.pointer);
        } else {
            return nil;
        }
    }
    // conditionalRequirements
    fileprivate static func _getConditionalRequirementsOffset(_ data: UnsafePointer<ProtocolConformanceDescriptor>) -> Int {
        if (data.pointee.flags.isRetroactive) {
            return MemoryLayout<RelativeContextPointer>.size;
        }
        return 0;
    }
    var hasConditionalRequirements: Bool { get { return self.flags.numConditionalRequirements > 0; } }
    var conditionalRequirements: UnsafeBufferPointer<GenericRequirementDescriptor>? { mutating get { return Self.getConditionalRequirements(&self); } }
    static func getConditionalRequirements(_ data: UnsafePointer<ProtocolConformanceDescriptor>) -> UnsafeBufferPointer<GenericRequirementDescriptor>? {
        let size = data.pointee.flags.numConditionalRequirements;
        if (size > 0) {
            let offset = Self._getConditionalRequirementsOffset(data);
            let ptr = OpaquePointer(UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:offset));
            return Optional(UnsafeBufferPointer(start:UnsafePointer<GenericRequirementDescriptor>(ptr), count:Int(size)));
        } else {
            return nil;
        }
    }
    // resilientWitnesses
    fileprivate static func _getResilientWitnessesOffset(_ data: UnsafePointer<ProtocolConformanceDescriptor>) -> Int {
        var offset = Self._getConditionalRequirementsOffset(data);
        if (data.pointee.flags.numConditionalRequirements > 0) {
            offset += Int(data.pointee.flags.numConditionalRequirements) * MemoryLayout<GenericRequirementDescriptor>.size;
        }
        return offset;
    }
    var resilientWitnesses: UnsafeBufferPointer<ResilientWitness>? { mutating get { return Self.getResilientWitnesses(&self); } }
    static func getResilientWitnesses(_ data: UnsafePointer<ProtocolConformanceDescriptor>) -> UnsafeBufferPointer<ResilientWitness>? {
        if (data.pointee.flags.hasResilientWitnesses) {
            let offset = Self._getResilientWitnessesOffset(data);
            let headerPtr = UnsafePointer<ResilientWitnessesHeader>(OpaquePointer(UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:offset)));
            let ptr = UnsafePointer<ResilientWitness>(OpaquePointer(headerPtr.advanced(by:1)));
            return Optional(UnsafeBufferPointer(start:ptr, count:Int(headerPtr.pointee.numWitnesses)));
        } else {
            return nil;
        }
    }
    // genericWitnessTable
    fileprivate static func _getGenericWitnessTableOffset(_ data: UnsafePointer<ProtocolConformanceDescriptor>) -> Int {
        var offset = Self._getResilientWitnessesOffset(data);
        if (data.pointee.flags.hasResilientWitnesses) {
            let headerPtr = UnsafePointer<ResilientWitnessesHeader>(OpaquePointer(UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:offset)));
            offset += MemoryLayout<ResilientWitnessesHeader>.size + Int(headerPtr.pointee.numWitnesses) * MemoryLayout<ResilientWitness>.size;
        }
        return offset;
    }
    var genericWitnessTable: UnsafePointer<GenericWitnessTable>? { mutating get { return Self.getGenericWitnessTable(&self); } }
    static func getGenericWitnessTable(_ data: UnsafePointer<ProtocolConformanceDescriptor>) -> UnsafePointer<GenericWitnessTable>? {
        if (data.pointee.flags.hasGenericWitnessTable) {
            let offset = Self._getGenericWitnessTableOffset(data);
            return UnsafePointer<GenericWitnessTable>(OpaquePointer(UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:offset)));
        } else {
            return nil;
        }
    }
}

/***
 * ResilientSuperclass
 ***/
struct ResilientSuperclass {
    fileprivate var _superclass: RelativeDirectPointer;
};

extension ResilientSuperclass {
    var superclass: OpaquePointer? { mutating get { return Self.getSuperclass(&self); } }
    static func getSuperclass(_ data: UnsafePointer<ResilientSuperclass>) -> OpaquePointer? {
        return UnsafeMutablePointer<ResilientSuperclass>(mutating:data).pointee._superclass.pointer;
    }
}

/***
 * ForeignMetadataInitialization
 ***/
struct ForeignMetadataInitialization {
  /// The completion function.  The pattern will always be null.
    fileprivate var _completionFunction: RelativeDirectPointer;
};

extension ForeignMetadataInitialization {
    var completionFunction: OpaquePointer? { mutating get { return Self.getCompletionFunction(&self); } }
    static func getCompletionFunction(_ data: UnsafePointer<ForeignMetadataInitialization>) -> OpaquePointer? {
        return UnsafeMutablePointer<ForeignMetadataInitialization>(mutating:data).pointee._completionFunction.pointer;
    }
}

/***
 * SingletonMetadataCache
 ***/
struct SingletonMetadataCache {
    let metadata: UnsafePointer<Metadata>;
    let `private`: OpaquePointer;
}

/***
 * ResilientClassMetadataPattern
 ***/
struct ResilientClassMetadataPattern {
    fileprivate var _relocationFunction: RelativeDirectPointer;
    fileprivate var _destroy: RelativeDirectPointer;
    fileprivate var _iVarDestroyer: RelativeDirectPointer;
    let flags: ClassFlags;
    fileprivate var _data: RelativeDirectPointer;
    fileprivate var _metaclass: RelativeDirectPointer;
}

extension ResilientClassMetadataPattern {
    // relocationFunction
    var relocationFunction: FunctionPointer? { mutating get { return Self.getRelocationFunction(&self); } }
    static func getRelocationFunction(_ data: UnsafePointer<ResilientClassMetadataPattern>) -> FunctionPointer? {
        if let ptr = UnsafeMutablePointer<ResilientClassMetadataPattern>(mutating:data).pointee._relocationFunction.pointer {
            return FunctionPointer(ptr);
        } else {
            return nil;
        }
    }
    // destroy
    var destroy: FunctionPointer? { mutating get { return Self.getDestroy(&self); } }
    static func getDestroy(_ data: UnsafePointer<ResilientClassMetadataPattern>) -> FunctionPointer? {
        if let ptr = UnsafeMutablePointer<ResilientClassMetadataPattern>(mutating:data).pointee._destroy.pointer {
            return FunctionPointer(ptr);
        } else {
            return nil;
        }
    }
    // iVarDestroyer
    var iVarDestroyer: FunctionPointer? { mutating get { return Self.getIVarDestroyer(&self); } }
    static func getIVarDestroyer(_ data: UnsafePointer<ResilientClassMetadataPattern>) -> FunctionPointer? {
        if let ptr = UnsafeMutablePointer<ResilientClassMetadataPattern>(mutating:data).pointee._iVarDestroyer.pointer {
            return FunctionPointer(ptr);
        } else {
            return nil;
        }
    }
    // data
    var data: OpaquePointer? { mutating get { return Self.getData(&self); } }
    static func getData(_ data: UnsafePointer<ResilientClassMetadataPattern>) -> OpaquePointer? {
        return UnsafeMutablePointer<ResilientClassMetadataPattern>(mutating:data).pointee._data.pointer;
    }
    // metaclass
    var metaclass: UnsafePointer<AnyClassMetadata>? { mutating get { return Self.getMetaclass(&self); } }
    static func getMetaclass(_ data: UnsafePointer<ResilientClassMetadataPattern>) -> UnsafePointer<AnyClassMetadata>? {
        let ptr = UnsafeMutablePointer<ResilientClassMetadataPattern>(mutating:data).pointee._data.pointer;
        return UnsafePointer<AnyClassMetadata>(ptr);
    }
}

/***
 * SingletonMetadataInitialization
 ***/
struct SingletonMetadataInitialization {
    fileprivate var _initializationCache: RelativeDirectPointer;
    fileprivate var _incompleteMetadata: RelativeDirectPointer;  // resilientPattern: RelativeDirectPointer;
    fileprivate var _completionFunction: RelativeDirectPointer;
}

extension SingletonMetadataInitialization {
    // initializationCache
    var initializationCache: UnsafePointer<SingletonMetadataCache>? { mutating get { return Self.getInitializationCache(&self); } }
    static func getInitializationCache(_ data: UnsafePointer<SingletonMetadataInitialization>) -> UnsafePointer<SingletonMetadataCache>? {
        let ptr = UnsafeMutablePointer<SingletonMetadataInitialization>(mutating:data).pointee._initializationCache.pointer;
        return UnsafePointer<SingletonMetadataCache>(ptr);
    }
    // incompleteMetadata
    var incompleteMetadata: OpaquePointer? { mutating get { return Self.getIncompleteMetadata(&self); } }
    static func getIncompleteMetadata(_ data: UnsafePointer<SingletonMetadataInitialization>) -> OpaquePointer? {
        return UnsafeMutablePointer<SingletonMetadataInitialization>(mutating:data).pointee._incompleteMetadata.pointer;
    }
    // resilientPattern
    var resilientPattern: UnsafePointer<ResilientClassMetadataPattern>? { mutating get { return Self.getResilientPattern(&self); } }
    static func getResilientPattern(_ data: UnsafePointer<SingletonMetadataInitialization>) -> UnsafePointer<ResilientClassMetadataPattern>? {
        let ptr = UnsafeMutablePointer<SingletonMetadataInitialization>(mutating:data).pointee._incompleteMetadata.pointer;
        return UnsafePointer<ResilientClassMetadataPattern>(ptr);
    }
    // completionFunction
    var completionFunction: FunctionPointer? { mutating get { return Self.getCompletionFunction(&self); } }
    static func getCompletionFunction(_ data: UnsafePointer<SingletonMetadataInitialization>) -> FunctionPointer? {
        if let ptr = UnsafeMutablePointer<SingletonMetadataInitialization>(mutating:data).pointee._completionFunction.pointer {
            return Optional(FunctionPointer(ptr));
        } else {
            return nil;
        }
    }
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
    fileprivate var _impl: RelativeDirectPointer;
}

extension MethodDescriptor {
    // impl
    var impl: FunctionPointer { mutating get { MethodDescriptor.getImpl(&self); } }
    static func getImpl(_ data: UnsafePointer<MethodDescriptor>) -> FunctionPointer {
        return FunctionPointer(UnsafeMutablePointer<MethodDescriptor>(mutating:data).pointee._impl.pointer!);
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
    fileprivate var _cls: RelativeContextPointer;
    fileprivate var _method: RelativeContextPointer;  // base
    fileprivate var _impl: RelativeDirectPointer;    // override
}

extension MethodOverrideDescriptor {
    // cls
    var cls: OpaquePointer { mutating get { Self.getClass(&self); } }
    static func getClass(_ data: UnsafePointer<MethodOverrideDescriptor>) -> OpaquePointer {
        return UnsafeMutablePointer<MethodOverrideDescriptor>(mutating:data).pointee._cls.pointer!;
    }
    // method
    var method: FunctionPointer { mutating get { Self.getMethod(&self); } }
    static func getMethod(_ data: UnsafePointer<MethodOverrideDescriptor>) -> FunctionPointer {
        return FunctionPointer(UnsafeMutablePointer<MethodOverrideDescriptor>(mutating:data).pointee._method.pointer!);
    }
    // impl
    var impl: FunctionPointer { mutating get { Self.getImpl(&self); } }
    static func getImpl(_ data: UnsafePointer<MethodOverrideDescriptor>) -> FunctionPointer {
        return FunctionPointer(UnsafeMutablePointer<MethodOverrideDescriptor>(mutating:data).pointee._impl.pointer!);
    }
}

/***
 * ObjCResilientClassStubInfo
 ***/
struct ObjCResilientClassStubInfo {
    fileprivate var _stub: RelativeDirectPointer;
};

extension ObjCResilientClassStubInfo {
    var sub: OpaquePointer { mutating get { return Self.getSub(&self); } }
    static func getSub(_ data: UnsafePointer<ObjCResilientClassStubInfo>) -> OpaquePointer {
        return UnsafeMutablePointer<ObjCResilientClassStubInfo>(mutating:data).pointee._stub.pointer!;
    }
}

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
    fileprivate var _metadata: RelativeDirectPointer;
}

extension CanonicalSpecializedMetadatasListEntry {
    var metadata: UnsafePointer<Metadata> { mutating get { return Self.getMetadata(&self); } }
    static func getMetadata(_ data: UnsafePointer<CanonicalSpecializedMetadatasListEntry>) -> UnsafePointer<Metadata> {
        return UnsafePointer<Metadata>(UnsafeMutablePointer<CanonicalSpecializedMetadatasListEntry>(mutating:data).pointee._metadata.pointer!);
    }
}

/***
 * CanonicalSpecializedMetadataAccessorsListEntry
 ***/
struct CanonicalSpecializedMetadataAccessorsListEntry {
    fileprivate var _accessor: RelativeDirectPointer;
};

extension CanonicalSpecializedMetadataAccessorsListEntry {
    var accessor: OpaquePointer { mutating get { return Self.getAccessor(&self); } }
    static func getAccessor(_ data: UnsafePointer<CanonicalSpecializedMetadataAccessorsListEntry>) -> OpaquePointer {
        return UnsafeMutablePointer<CanonicalSpecializedMetadataAccessorsListEntry>(mutating:data).pointee._accessor.pointer!
    }
}

/***
 * CanonicalSpecializedMetadatasCachingOnceToken
 ***/
struct CanonicalSpecializedMetadatasCachingOnceToken {
    fileprivate var _token: RelativeDirectPointer;
};

extension CanonicalSpecializedMetadatasCachingOnceToken {
    var token: CLong { mutating get { return Self.getToken(&self); } }
    static func getToken(_ data: UnsafePointer<CanonicalSpecializedMetadatasCachingOnceToken>) -> CLong {
        let ptr = UnsafeMutablePointer<CanonicalSpecializedMetadatasCachingOnceToken>(mutating:data).pointee._token.pointer!
        return UnsafePointer<CLong>(ptr).pointee;
    }
}
