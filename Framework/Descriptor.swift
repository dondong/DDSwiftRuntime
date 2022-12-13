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
public enum ContextDescriptorKind : UInt8 {
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
public enum MetadataInitializationKind : UInt8 {
    case NoMetadataInitialization = 0;
    case SingletonMetadataInitialization = 1;
    case ForeignMetadataInitialization = 2;
}

/***
 * MethodDescriptorKind
 ***/
public enum MethodDescriptorKind : UInt8 {
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
public struct ContextDescriptorFlags {
    fileprivate let _value: UInt32;
}

extension ContextDescriptorFlags {
    public var kind: ContextDescriptorKind { get { return ContextDescriptorKind(rawValue:UInt8(self._value & 0x1F)) ?? .Module; } }
    public var isGeneric: Bool { get { return (self._value & 0x80) != 0; } }
    public var isUnique: Bool { get { return (self._value & 0x40) != 0; } }
    public var version: UInt8 { get { return UInt8((self._value >> 8) & 0xFF); } }
    public var kindSpecificFlags: UInt16 { get { return UInt16((self._value >> 16) & 0xFFFF); } }
    public var metadataInitialization: MetadataInitializationKind { get { return MetadataInitializationKind(rawValue:UInt8(self.kindSpecificFlags & 0x3)) ?? .NoMetadataInitialization } }
    public var hasResilientSuperclass: Bool { get { return (self.kindSpecificFlags & 0x2000) != 0; } }
    public var hasVTable: Bool { get { return (self.kindSpecificFlags & 0x8000) != 0; } }
    public var hasOverrideTable: Bool { get { return (self.kindSpecificFlags & 0x4000) != 0; } }
}

/***
 * ContextDescriptor
 ***/
public protocol ContextDescriptorInterface {
    var flags: ContextDescriptorFlags { get };
}

extension ContextDescriptorInterface {
    public var kind: ContextDescriptorKind { get { return self.flags.kind; } }
    public var isGeneric: Bool { get { return self.flags.isGeneric; } }
    public var isUnique: Bool { get { return self.flags.isUnique; } }
    public var version: UInt8 { get { return self.flags.version; } }
    public var metadataInitialization: MetadataInitializationKind { get { return self.flags.metadataInitialization; } }
    public var hasResilientSuperclass: Bool { get { return self.flags.hasResilientSuperclass; } }
    public var hasVTable: Bool { get { return self.flags.hasVTable; } }
    public var hasOverrideTable: Bool { get { return self.flags.hasOverrideTable; } }
    // parent
    public var parent: UnsafePointer<ContextDescriptor>? { mutating get { return Self.getParent(&self); } }
    public static func getParent<T : ContextDescriptorInterface>(_ data: UnsafePointer<T>) -> UnsafePointer<ContextDescriptor>? {
        let ptr = UnsafeMutablePointer<RelativeDirectPointer>(OpaquePointer(data)).advanced(by:1).pointee.pointer;
        return UnsafePointer<ContextDescriptor>(ptr);
    }
}

public struct ContextDescriptor : ContextDescriptorInterface {
    public let flags: ContextDescriptorFlags;
    fileprivate var _parent: RelativeDirectPointer;
}

/***
 * Protocol
 ***/
public enum ProtocolClassConstraint : UInt8 {
    case Class = 0;
    case `Any` = 1;
}

public enum SpecialProtocol : UInt8 {
    case None = 0;
    case Error = 1;
}

public struct ProtocolContextDescriptorFlags {
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
    public var classConstraint: ProtocolClassConstraint { get { return ProtocolClassConstraint(rawValue:UInt8((self._value >> Self.HasClassConstraint) & ((1 << Self.HasClassConstraint_width) - 1))) ?? .Class; } }
    public var specialProtocol: SpecialProtocol { get { return SpecialProtocol(rawValue:UInt8((self._value >> Self.SpecialProtocolKind) & ((1 << Self.SpecialProtocolKind_width) - 1))) ?? .None; } }
}

public struct ProtocolDescriptor : ContextDescriptorInterface {
    public let flags: ContextDescriptorFlags;
    fileprivate let _parent: RelativeDirectPointer;
    fileprivate var _name: RelativeDirectPointer;
    public let numRequirementsInSignature: UInt32;
    public let numRequirements: UInt32;
    fileprivate let _associatedTypeNames: RelativeDirectPointer
    // GenericRequirementDescriptor
    // ProtocolRequirement
}

extension ProtocolDescriptor {
    // protocolContextDescriptorFlags
    public var protocolContextDescriptorFlags: ProtocolContextDescriptorFlags { get { return ProtocolContextDescriptorFlags(self.flags.kindSpecificFlags); } }
    // name
    public var name: String { mutating get { return Self.getName(&self); } }
    public static func getName(_ data: UnsafePointer<ProtocolDescriptor>) -> String {
        let ptr = UnsafeMutablePointer<ProtocolDescriptor>(mutating:data).pointee._name.pointer!;
        let namePtr = UnsafePointer<CChar>(ptr);
        guard let parent = self.getParent(data) else { return String(cString:namePtr) }
        let preName = self.getName(UnsafePointer<ProtocolDescriptor>(OpaquePointer(parent)));
        return String(preName + "." + String(cString:namePtr));
    }
    public var associatedTypeNames: String? { mutating get { return Self.getAssociatedTypeNames(&self); } }
    public static func getAssociatedTypeNames(_ data: UnsafePointer<ProtocolDescriptor>) -> String? {
        if let ptr = UnsafeMutablePointer<ProtocolDescriptor>(mutating:data).pointee._name.pointer {
            return String(cString:UnsafePointer<CChar>(ptr))
        } else {
            return nil;
        }
    }
    // requirementSignature
    public var requirementSignature: UnsafeBufferPointer<GenericRequirementDescriptor> { mutating get { return Self.getRequirementSignature(&self); } }
    public static func getRequirementSignature(_ data: UnsafePointer<ProtocolDescriptor>) -> UnsafeBufferPointer<GenericRequirementDescriptor> {
        let ptr = UnsafePointer<GenericRequirementDescriptor>(OpaquePointer(data.advanced(by:1)));
        return UnsafeBufferPointer<GenericRequirementDescriptor>(start:ptr, count:Int(data.pointee.numRequirementsInSignature));
    }
    // requirements
    fileprivate static func _getRequirementsOffset(_ data: UnsafePointer<ProtocolDescriptor>) -> Int {
        return MemoryLayout<GenericRequirementDescriptor>.size * Int(data.pointee.numRequirementsInSignature);
    }
    public var requirements: UnsafeBufferPointer<ProtocolRequirement> { mutating get { return Self.getRequirements(&self); } }
    public static func getRequirements(_ data: UnsafePointer<ProtocolDescriptor>) -> UnsafeBufferPointer<ProtocolRequirement> {
        let offset = Self._getRequirementsOffset(data);
        let ptr = UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:offset).assumingMemoryBound(to:ProtocolRequirement.self);
        return UnsafeBufferPointer<ProtocolRequirement>(start:ptr, count:Int(data.pointee.numRequirements));
    }
}
public enum ProtocolRequirementKind : UInt32 {
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

public struct ProtocolRequirementFlags {
    fileprivate let value: UInt32;
}

extension ProtocolRequirementFlags {
    fileprivate static let KindMask: UInt32 = 0x0F;
    fileprivate static let IsInstanceMask: UInt32 = 0x10;
    fileprivate static let IsAsyncMask: UInt32 = 0x20;
    fileprivate static let ExtraDiscriminatorShift: UInt32 = 16;
    fileprivate static let ExtraDiscriminatorMask: UInt32 = 0xFFFF0000;
    public var kind: ProtocolRequirementKind { get { return ProtocolRequirementKind(rawValue: (self.value & ProtocolRequirementFlags.KindMask)) ?? .BaseProtocol; } }
    public var isInstance: Bool { get { return (self.value & ProtocolRequirementFlags.IsInstanceMask) != 0; } }
    public var isAsync: Bool { get { return (self.value & ProtocolRequirementFlags.IsAsyncMask) != 0; } }
    public var isSignedWithAddress: Bool { get { return self.kind != .BaseProtocol; } }
    public var extraDiscriminator: UInt16 { get { return UInt16(self.value >> ProtocolRequirementFlags.ExtraDiscriminatorShift); } }
}

public struct ProtocolRequirement {
    public let flags: ProtocolRequirementFlags;
    fileprivate var _defaultImplementation: RelativeDirectPointer;
}

extension ProtocolRequirement {
    public var defaultImplementation: FunctionPointer? { mutating get { return Self.getDefaultImplementation(&self); } }
    public static func getDefaultImplementation(_ data: UnsafePointer<ProtocolRequirement>) -> FunctionPointer? {
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
public struct TypeContextDescriptorFlags {
    fileprivate let _value: UInt16;
    internal init(_ val: UInt16) {
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
    public var metadataInitialization: MetadataInitializationKind { get { return MetadataInitializationKind(rawValue:UInt8((self._value >> Self.MetadataInitialization) & ((1 << Self.MetadataInitialization_width) - 1))) ?? .NoMetadataInitialization; } }
    public var hasSingletonMetadataInitialization: Bool { get { return self.metadataInitialization == .SingletonMetadataInitialization; } }
    public var hasForeignMetadataInitialization: Bool { get { return self.metadataInitialization == .ForeignMetadataInitialization; } }
    public var hasImportInfo: Bool { get { return (self._value & (1 << Self.HasImportInfo)) != 0; } }
    public var hasCanonicalMetadataPrespecializations: Bool { get { return (self._value & (1 << Self.HasCanonicalMetadataPrespecializations)) != 0; } }
    public var class_hasVTable: Bool { get { return (self._value & (1 << Self.Class_HasVTable)) != 0; } }
    public var class_hasOverrideTable: Bool { get { return (self._value & (1 << Self.Class_HasOverrideTable)) != 0; } }
    public var class_areImmediateMembersNegative: Bool { get { return (self._value & (1 << Self.Class_AreImmediateMembersNegative)) != 0; } }
    public var class_isDefaultActor: Bool { get { return (self._value & (1 << Self.Class_IsDefaultActor)) != 0; } }
    public var class_isActor: Bool { get { return (self._value & (1 << Self.Class_IsActor)) != 0; } }
    public var class_ResilientSuperclassReferenceKind: TypeReferenceKind { get { return TypeReferenceKind(rawValue:UInt16((self._value >> Self.Class_ResilientSuperclassReferenceKind) & ((1 << Self.Class_ResilientSuperclassReferenceKind_width) - 1))) ?? .DirectTypeDescriptor; } }
}

public protocol TypeContextDescriptorInterface : ContextDescriptorInterface {
    var genericArgumentOffset: Int32 { mutating get };
}

extension TypeContextDescriptorInterface {
    // name
    public var name: String { mutating get { return Self.getName(&self); } }
    public static func getName<T : TypeContextDescriptorInterface>(_ data: UnsafePointer<T>) -> String {
        let ptr = UnsafeMutablePointer<RelativeDirectPointer>(OpaquePointer(data)).advanced(by:2).pointee.pointer!;
        return String(cString:UnsafePointer<CChar>(ptr));
    }
    public var fullName: String  { mutating get { return Self.getFullName(&self); } }
    public static func getFullName<T : TypeContextDescriptorInterface>(_ data: UnsafePointer<T>) -> String {
        let ptr = UnsafeMutablePointer<RelativeDirectPointer>(OpaquePointer(data)).advanced(by:2).pointee.pointer!;
        let namePtr = UnsafePointer<CChar>(ptr);
        guard let parent = self.getParent(data) else { return String(cString:namePtr) }
        let preName = self.getName(UnsafePointer<TypeContextDescriptor>(OpaquePointer(parent)));
        return String(preName + "." + String(cString:namePtr));
    }
    // accessFunction
    public var accessFunction: FunctionPointer? { mutating get { Self.getAccessFunction(&self); } }
    public static func getAccessFunction<T : TypeContextDescriptorInterface>(_ data: UnsafePointer<T>) -> FunctionPointer? {
        if let ptr = UnsafeMutablePointer<RelativeDirectPointer>(OpaquePointer(data)).advanced(by:3).pointee.pointer {
            return Optional(FunctionPointer(ptr));
        } else {
            return nil;
        }
    }
    // fieldDescriptor
    public var fieldDescriptor: UnsafePointer<FieldDescriptor>? { mutating get { return Self.getFieldDescriptor(&self); } }
    public static func getFieldDescriptor<T : TypeContextDescriptorInterface>(_ data: UnsafePointer<T>) -> UnsafePointer<FieldDescriptor>? {
        if let ptr = UnsafeMutablePointer<RelativeDirectPointer>(OpaquePointer(data)).advanced(by:4).pointee.pointer {
            return Optional(UnsafePointer<FieldDescriptor>(ptr));
        } else {
            return nil;
        }
    }
    
    public var typeContextDescriptorFlags: TypeContextDescriptorFlags { get { return TypeContextDescriptorFlags(self.flags.kindSpecificFlags) } }
    public var metadataInitialization: MetadataInitializationKind { get { return self.typeContextDescriptorFlags.metadataInitialization; } }
    public var hasSingletonMetadataInitialization: Bool { get { return self.typeContextDescriptorFlags.hasSingletonMetadataInitialization; } }
    public var hasForeignMetadataInitialization: Bool { get { return self.typeContextDescriptorFlags.hasForeignMetadataInitialization; } }
    public var hasCanonicicalMetadataPrespecializations: Bool { get { return self.typeContextDescriptorFlags.hasCanonicalMetadataPrespecializations; } }
    
    // typeGenericContextDescriptorHeader
    public var typeGenericContextDescriptorHeader: UnsafePointer<TypeGenericContextDescriptorHeader>? { mutating get { return Self.getTypeGenericContextDescriptorHeader(&self); } }
    public static func getTypeGenericContextDescriptorHeader<T : TypeContextDescriptorInterface>(_ data: UnsafePointer<T>) -> UnsafePointer<TypeGenericContextDescriptorHeader>? {
        if (data.pointee.isGeneric) {
            return UnsafePointer<TypeGenericContextDescriptorHeader>(OpaquePointer(data.advanced(by:1)));
        } else {
            return nil;
        }
    }
    // genericParamDescriptors
    public var numParams: UInt32 { mutating get { return Self.getNumParams(&self); } }
    public static func getNumParams<T : TypeContextDescriptorInterface>(_ data: UnsafePointer<T>) -> UInt32 {
        if (data.pointee.isGeneric) {
            return UInt32(UnsafePointer<TypeGenericContextDescriptorHeader>(OpaquePointer(data.advanced(by:1))).pointee.base.numParams);
        } else {
            return 0;
        }
    }
    public var genericParamDescriptors: UnsafeBufferPointer<GenericParamDescriptor>? { mutating get { return Self.getGenericParamDescriptors(&self); } }
    public static func getGenericParamDescriptors<T : TypeContextDescriptorInterface>(_ data: UnsafePointer<T>) -> UnsafeBufferPointer<GenericParamDescriptor>? {
        if (data.pointee.isGeneric) {
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
}

public struct FieldRecordFlags {
    fileprivate static let IsIndirectCase: UInt32 = 0x1;  // Is this an indirect enum case?
    fileprivate static let IsVar: UInt32 = 0x2;   // Is this a mutable `var` property?
    fileprivate static let IsArtificial: UInt32 = 0x4;  // Is this an artificial field?
    fileprivate let _data: UInt32;
}

extension FieldRecordFlags {
    public var isIndirectCase: Bool { get { return (self._data & Self.IsIndirectCase) == Self.IsIndirectCase; } }
    public var isVar: Bool { get { return (self._data & Self.IsVar) == Self.IsVar; } }
    public var isArtificial: Bool { get { return (self._data & Self.IsArtificial) == Self.IsArtificial; } }
}

public struct FieldRecord {
    public let flags: FieldRecordFlags;
    fileprivate var _mangledTypeName: RelativeDirectPointer;
    fileprivate var _fieldName: RelativeDirectPointer;
}

extension FieldRecord {
    public var mangledTypeName: String? { mutating get { return Self.getMangledTypeName(&self); } }
    public static func getMangledTypeName(_ data: UnsafePointer<FieldRecord>) -> String? {
        if let ptr = UnsafeMutablePointer<RelativeDirectPointer>(OpaquePointer(data)).advanced(by:1).pointee.pointer {
            return String(cString:UnsafePointer<CChar>(ptr));
        } else {
            return nil;
        }
    }
    // fieldName
    public var fieldName: String? { mutating get { return Self.getFieldName(&self); } }
    public static func getFieldName(_ data: UnsafePointer<FieldRecord>) -> String? {
        if let ptr = UnsafeMutablePointer<RelativeDirectPointer>(OpaquePointer(data)).advanced(by:2).pointee.pointer {
            return String(cString:UnsafePointer<CChar>(ptr));
        } else {
            return nil;
        }
    }
}

public struct FieldDescriptorKind {
    fileprivate let value: UInt16;
}

extension FieldDescriptorKind {
    fileprivate static let Struct: UInt16 = 0;
    fileprivate static let Class: UInt16 = 1;
    fileprivate static let Enum: UInt16 = 2;
    fileprivate static let MultiPayloadEnum: UInt16 = 3;
    fileprivate static let ProtocolValue: UInt16 = 4;
    fileprivate static let ClassProtocol: UInt16 = 5;
    fileprivate static let ObjCProtocol: UInt16 = 6;
    fileprivate static let ObjCClass: UInt16 = 7;
    public var isEnum: Bool { get { return self.value == Self.Enum || self.value == Self.MultiPayloadEnum; } }
    public var isClass: Bool { get { return self.value == Self.Class || self.value == Self.ObjCClass; } }
    public var isProtocol: Bool { get { return self.value == Self.ProtocolValue || self.value == Self.ClassProtocol || self.value == Self.ObjCProtocol; } }
    public var isStruct: Bool { get { return self.value == Self.Struct; } }
}

public struct FieldDescriptor {
    fileprivate var _mangledTypeName: RelativeDirectPointer;
    fileprivate var _superclass: RelativeDirectPointer;
    public let fieldDescriptorKind: FieldDescriptorKind;
    public let fieldRecordSize: UInt16;
    public let numFields: UInt32;
}

extension FieldDescriptor {
    // mangledTypeName
    public var mangledTypeName: String? { mutating get { return Self.getMangledTypeName(&self); } }
    public static func getMangledTypeName(_ data: UnsafePointer<FieldDescriptor>) -> String? {
        if let ptr = UnsafeMutablePointer<RelativeDirectPointer>(OpaquePointer(data)).pointee.pointer {
            return String(cString:UnsafePointer<CChar>(ptr));
        } else {
            return nil;
        }
    }
    // superclass
    public var superclass: String? { mutating get { return Self.getSuperclass(&self); } }
    public static func getSuperclass(_ data: UnsafePointer<FieldDescriptor>) -> String? {
        if let ptr = UnsafeMutablePointer<RelativeDirectPointer>(OpaquePointer(data)).advanced(by:1).pointee.pointer {
            return String(cString:UnsafePointer<CChar>(ptr));
        } else {
            return nil;
        }
    }
    // fields
    public var fields: UnsafeBufferPointer<FieldRecord>? { mutating get { return Self.getFields(&self); } }
    public static func getFields(_ data: UnsafePointer<FieldDescriptor>) -> UnsafeBufferPointer<FieldRecord>? {
        if (data.pointee.numFields > 0) {
            return UnsafeBufferPointer<FieldRecord>(start:UnsafePointer<FieldRecord>(OpaquePointer(data.advanced(by:1))), count:Int(data.pointee.numFields));
        } else {
            return nil;
        }
    }
}

public struct TypeContextDescriptor : TypeContextDescriptorInterface {
    public let flags: ContextDescriptorFlags;
    fileprivate let _parent: RelativeDirectPointer;
    fileprivate let _name: RelativeDirectPointer;
    fileprivate let _accessFunction: RelativeDirectPointer;
    fileprivate let _fieldDescriptor: RelativeDirectPointer;
};

extension TypeContextDescriptor {
    public var genericArgumentOffset: Int32 { get { assert(false); return 0; } }
}

// MARK: -
// MARK: Extension
public struct ExtensionContextDescriptor : ContextDescriptorInterface {
    public let flags: ContextDescriptorFlags;
    fileprivate let _parent: RelativeDirectPointer;
    fileprivate var _extendedContext: RelativeDirectPointer;
}

extension ExtensionContextDescriptor {
    public var mangledExtendedContext: String { mutating get { return Self.getMangledExtendedContext(&self); } }
    public static func getMangledExtendedContext(_ data: UnsafePointer<ExtensionContextDescriptor>) -> String {
        let ptr = UnsafeMutablePointer<ExtensionContextDescriptor>(mutating:data).pointee._extendedContext.pointer!;
        return String(cString:UnsafePointer<CChar>(ptr));
    }
}

// MARK: -
// MARK: Anonymous
public struct AnonymousContextDescriptorFlags {
    fileprivate let _value: UInt16;
    internal init(_ val: UInt16) {
        self._value = val;
    }
}

extension AnonymousContextDescriptorFlags {
    fileprivate static let HasMangledName: UInt16 = 0;
    public var hasMangledName: Bool { get { return (self._value & (1 << Self.HasMangledName)) != 0; } }
}

public struct AnonymousContextDescriptor {
    public let flags: ContextDescriptorFlags;
    fileprivate let _parent: RelativeDirectPointer;
    fileprivate let _name: RelativeDirectPointer;
    fileprivate let _accessFunction: RelativeDirectPointer;
    fileprivate let _fieldDescriptor: RelativeDirectPointer;
    // GenericContextDescriptorHeader
    // MangledContextName
}

extension AnonymousContextDescriptor {
    public var anonymousContextDescriptorFlags: AnonymousContextDescriptorFlags { get { return AnonymousContextDescriptorFlags(self.flags.kindSpecificFlags); } }
    public var hasMangledName: Bool { get { return self.anonymousContextDescriptorFlags.hasMangledName; } }
    // mangledName
    public var mangledName: String? { mutating get { return Self.getMangledName(&self); } }
    public static func getMangledName(_ data: UnsafePointer<AnonymousContextDescriptor>) -> String? {
        if (data.pointee.hasMangledName) {
            let ptr = OpaquePointer(UnsafePointer<GenericContextDescriptorHeader>(OpaquePointer(data.advanced(by:1))).advanced(by:1));
            return Optional(UnsafeMutablePointer<MangledContextName>(ptr).pointee.name);
        } else {
            return nil;
        }
    }
}

public struct MangledContextName {
    fileprivate var _name: RelativeDirectPointer;
}

extension MangledContextName {
    public var name: String { mutating get { return Self.getName(&self); } }
    public static func getName(_ data: UnsafePointer<MangledContextName>) -> String {
        let ptr = UnsafeMutablePointer<MangledContextName>(mutating:data).pointee._name.pointer!;
        return String(cString:UnsafePointer<CChar>(ptr));
    }
}

// MARK: -
// MARK: OpaqueType
public struct OpaqueTypeDescriptor {
    public let flags: ContextDescriptorFlags;
    fileprivate let _parent: RelativeDirectPointer;
    // GenericContextDescriptorHeader
    // RelativeDirectPointer<const char>
}

extension OpaqueTypeDescriptor {
    public var numUnderlyingTypeArguments: UInt16 { get { return self.flags.kindSpecificFlags; } }
}

// MARK: -
// MARK: Struct
public protocol ValueTypeDescriptorInterface : TypeContextDescriptorInterface {
}

extension ValueTypeDescriptorInterface {
    public static func classof(descriptor: TypeContextDescriptor) -> Bool {
        return (descriptor.flags.kind == .Struct || descriptor.flags.kind == .Enum);
    }
    public static func classof(descriptor: UnsafePointer<TypeContextDescriptor>) -> Bool {
        return (descriptor.pointee.flags.kind == .Struct || descriptor.pointee.flags.kind == .Enum);
    }
}
/***
 * StructDescriptor
 ***/
public struct StructDescriptor : ValueTypeDescriptorInterface {
    public let flags: ContextDescriptorFlags;
    fileprivate let _parent: RelativeDirectPointer;
    fileprivate let _name: RelativeDirectPointer;
    fileprivate let _accessFunction: RelativeDirectPointer;
    fileprivate let _fieldDescriptor: RelativeDirectPointer;
    public let numFields: UInt32;
    public let fieldOffsetVectorOffset: UInt32;
    // TypeGenericContextDescriptorHeader
    // ForeignMetadataInitialization
    // SingletonMetadataInitialization
    // CanonicalSpecializedMetadatasListCount
    // CanonicalSpecializedMetadatasListEntry
    // CanonicalSpecializedMetadatasCachingOnceToken
}

extension StructDescriptor {
    public var hasFieldOffsetVector: Bool { get { return self.fieldOffsetVectorOffset != 0; } }
    // foreignMetadataInitialization
    fileprivate static func _getForeignMetadataInitializationOffset(_ data: UnsafePointer<StructDescriptor>) -> Int {
        if (data.pointee.isGeneric) {
            let ptr = UnsafePointer<TypeGenericContextDescriptorHeader>(OpaquePointer(data.advanced(by:1)));
            return TypeGenericContextDescriptorHeader.getTypeGenericContextDataSize(ptr);
        }
        return 0;
    }
    public var foreignMetadataInitialization: UnsafePointer<ForeignMetadataInitialization>? { mutating get { return Self.getForeignMetadataInitialization(&self); } }
    public static func getForeignMetadataInitialization(_ data: UnsafePointer<StructDescriptor>) -> UnsafePointer<ForeignMetadataInitialization>? {
        if (data.pointee.hasForeignMetadataInitialization) {
            let offset = Self._getForeignMetadataInitializationOffset(data);
            return Optional(UnsafeRawPointer(data.advanced(by:1)).advanced(by:offset).assumingMemoryBound(to:ForeignMetadataInitialization.self));
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
    public var singletonMetadataInitialization: UnsafePointer<SingletonMetadataInitialization>? { mutating get { return Self.getSingletonMetadataInitialization(&self); } }
    public static func getSingletonMetadataInitialization(_ data: UnsafePointer<StructDescriptor>) -> UnsafePointer<SingletonMetadataInitialization>? {
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
    public var canonicicalMetadataPrespecializations: UnsafeBufferPointer<CanonicalSpecializedMetadatasListEntry>? { mutating get { return Self.getCanonicicalMetadataPrespecializations(&self); } }
    public static func getCanonicicalMetadataPrespecializations(_ data: UnsafePointer<StructDescriptor>) -> UnsafeBufferPointer<CanonicalSpecializedMetadatasListEntry>? {
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
    public var canonicalMetadataPrespecializationCachingOnceToken: CLong { mutating get { return Self.getCanonicalMetadataPrespecializationCachingOnceToken(&self); } }
    public static func getCanonicalMetadataPrespecializationCachingOnceToken(_ data: UnsafePointer<StructDescriptor>) -> CLong {
        if (data.pointee.hasCanonicicalMetadataPrespecializations) {
            let offset = Self._getCanonicalMetadataPrespecializationCachingOnceToken(data);
            let ptr = UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:offset).assumingMemoryBound(to:CanonicalSpecializedMetadatasCachingOnceToken.self);
            return CanonicalSpecializedMetadatasCachingOnceToken.getToken(ptr);
        } else {
            return 0;
        }
    }
    // genericArgumentOffset
    public var genericArgumentOffset: Int32 { get { return Int32(MemoryLayout<StructMetadata>.size / MemoryLayout<OpaquePointer>.size); } }
}

// MARK: -
// MARK: Enum
/***
 * EnumDescriptor
 ***/
public struct EnumDescriptor : ValueTypeDescriptorInterface {
    public let flags: ContextDescriptorFlags;
    fileprivate let _parent: RelativeDirectPointer;
    fileprivate let _name: RelativeDirectPointer;
    fileprivate let _accessFunction: RelativeDirectPointer;
    fileprivate let _fieldDescriptor: RelativeDirectPointer;
    fileprivate let _numPayloadCasesAndPayloadSizeOffset: UInt32;
    public let numEmptyCases: UInt32;
    // TypeGenericContextDescriptorHeader
    // ForeignMetadataInitialization
    // SingletonMetadataInitialization
    // CanonicalSpecializedMetadatasListCount
    // CanonicalSpecializedMetadatasListEntry
    // CanonicalSpecializedMetadatasCachingOnceToken
}

extension EnumDescriptor {
    public var numPayloadCases: UInt32 { get { return self._numPayloadCasesAndPayloadSizeOffset & 0x00FFFFFF; } }
    public var numCases: UInt32 { get { return self.numPayloadCases + self.numEmptyCases; } }
    public var payloadSizeOffset: UInt32 { get { return ((self._numPayloadCasesAndPayloadSizeOffset & 0xFF000000) >> 24); } }
    public var hasPayloadSizeOffset: Bool { get { return self.payloadSizeOffset != 0; } }
    // foreignMetadataInitialization
    fileprivate static func _getForeignMetadataInitializationOffset(_ data: UnsafePointer<EnumDescriptor>) -> Int {
        if (data.pointee.isGeneric) {
            let ptr = UnsafePointer<TypeGenericContextDescriptorHeader>(OpaquePointer(data.advanced(by:1)));
            return TypeGenericContextDescriptorHeader.getTypeGenericContextDataSize(ptr);
        }
        return 0;
    }
    public var foreignMetadataInitialization: UnsafePointer<ForeignMetadataInitialization>? { mutating get { return Self.getForeignMetadataInitialization(&self); } }
    public static func getForeignMetadataInitialization(_ data: UnsafePointer<EnumDescriptor>) -> UnsafePointer<ForeignMetadataInitialization>? {
        if (data.pointee.hasForeignMetadataInitialization) {
            let offset = Self._getForeignMetadataInitializationOffset(data);
            return Optional(UnsafeRawPointer(data.advanced(by:1)).advanced(by:offset).assumingMemoryBound(to:ForeignMetadataInitialization.self));
        } else {
            return nil;
        }
    }
    // singletonMetadataInitialization
    fileprivate static func _getSingletonMetadataInitializationOffset(_ data: UnsafePointer<EnumDescriptor>) -> Int {
        if (data.pointee.hasForeignMetadataInitialization) {
            return MemoryLayout<ForeignMetadataInitialization>.size;
        }
        return 0;
    }
    public var singletonMetadataInitialization: UnsafePointer<SingletonMetadataInitialization>? { mutating get { return Self.getSingletonMetadataInitialization(&self); } }
    public static func getSingletonMetadataInitialization(_ data: UnsafePointer<EnumDescriptor>) -> UnsafePointer<SingletonMetadataInitialization>? {
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
    public var canonicicalMetadataPrespecializations: UnsafeBufferPointer<CanonicalSpecializedMetadatasListEntry>? { mutating get { return Self.getCanonicicalMetadataPrespecializations(&self); } }
    public static func getCanonicicalMetadataPrespecializations(_ data: UnsafePointer<EnumDescriptor>) -> UnsafeBufferPointer<CanonicalSpecializedMetadatasListEntry>? {
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
    public var canonicalMetadataPrespecializationCachingOnceToken: CLong { mutating get { return Self.getCanonicalMetadataPrespecializationCachingOnceToken(&self); } }
    public static func getCanonicalMetadataPrespecializationCachingOnceToken(_ data: UnsafePointer<EnumDescriptor>) -> CLong {
        if (data.pointee.hasCanonicicalMetadataPrespecializations) {
            let offset = Self._getCanonicalMetadataPrespecializationCachingOnceToken(data);
            let ptr = UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:offset).assumingMemoryBound(to:CanonicalSpecializedMetadatasCachingOnceToken.self);
            return CanonicalSpecializedMetadatasCachingOnceToken.getToken(ptr);
        } else {
            return 0;
        }
    }
    // genericArgumentOffset
    public var genericArgumentOffset: Int32 { get { return Int32(MemoryLayout<EnumMetadata>.size / MemoryLayout<OpaquePointer>.size); } }
}

// MARK: -
// MARK: Class
/***
 * ClassDescriptor
 ***/
public struct ExtraClassDescriptorFlags {
    public let _value: UInt32;
    internal init(_ val: UInt32) {
        self._value = val;
    }
}

extension ExtraClassDescriptorFlags {
    fileprivate static let HasObjCResilientClassStub: UInt32 = 0;
    public var hasObjCResilientClassStub: Bool { get { return (self._value & (1 << Self.HasObjCResilientClassStub)) != 0; } }
}

public struct ClassDescriptor : TypeContextDescriptorInterface {
    public let flags: ContextDescriptorFlags;
    fileprivate let _parent: RelativeDirectPointer;
    fileprivate let _name: RelativeDirectPointer;
    fileprivate let _accessFunction: RelativeDirectPointer;
    fileprivate let _fieldDescriptor: RelativeDirectPointer;
    fileprivate var _superclassType: RelativeDirectPointer;
    fileprivate var _resilientMetadataBounds: RelativeDirectPointer;  // metadataNegativeSizeInWords : UInt32
    public let metadataPositiveSizeInWords: UInt32;  // extraClassFlags: ExtraClassDescriptorFlags
    public let numImmediateMembers: UInt32;
    public let numFields: UInt32;
    public let fieldOffsetVectorOffset: UInt32;
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
    public var metadataNegativeSizeInWords: UInt32 { get { return UInt32(self._resilientMetadataBounds.rawvalue); } }
    public var extraClassFlags: ExtraClassDescriptorFlags { get { return ExtraClassDescriptorFlags(self.metadataPositiveSizeInWords); } }
    public var areImmediateMembersNegative: Bool { get { return self.typeContextDescriptorFlags.class_areImmediateMembersNegative; } }
    public var resilientSuperclassReferenceKind: TypeReferenceKind { get { return self.typeContextDescriptorFlags.class_ResilientSuperclassReferenceKind; } }
    
    public var genericArgumentOffset: Int32 {
        mutating get {
            if (!self.hasResilientSuperclass) {
                return self.nonResilientImmediateMembersOffset;
            }
            return self.resilientImmediateMembersOffset;
        }
    }
    
    // metadataBounds
    internal var metadataBounds: ClassMetadataBounds { mutating get { return Self.getMetadataBounds(&self); } }
    internal static func getMetadataBounds(_ data: UnsafePointer<ClassDescriptor>) -> ClassMetadataBounds {
        if (data.pointee.hasResilientSuperclass) {
            return Self.getResilientMetadataBounds(data)!;
        } else {
            return data.pointee.nonResilientMetadataBounds;
        }
    }
    // nonResilientImmediateMembersOffset
    internal var nonResilientImmediateMembersOffset: Int32 {
        get {
            if (!self.hasResilientSuperclass) {
                return self.areImmediateMembersNegative ? -Int32(self.metadataNegativeSizeInWords) : Int32(self.metadataPositiveSizeInWords - self.numImmediateMembers);
            } else {
                return 0;
            }
        }
    }
    // nonResilientMetadataBounds
    internal var nonResilientMetadataBounds: ClassMetadataBounds { get { return ClassMetadataBounds(Int(self.nonResilientImmediateMembersOffset) * MemoryLayout<OpaquePointer>.size, self.metadataNegativeSizeInWords, self.metadataPositiveSizeInWords); } }
    // resilientImmediateMembersOffset
    internal var resilientImmediateMembersOffset: Int32 { mutating get { return Self.getResilientImmediateMembersOffset(&self); } }
    fileprivate static func _getResilientMetadataBounds(_ data: UnsafePointer<ClassDescriptor>) ->  UnsafePointer<StoredClassMetadataBounds>? {
        if (data.pointee.hasResilientSuperclass) {
            return UnsafePointer<StoredClassMetadataBounds>(UnsafeMutablePointer<ClassDescriptor>(mutating:data).pointee._resilientMetadataBounds.pointer);
        } else {
            return nil;
        }
    }
    internal static func getResilientImmediateMembersOffset(_ data: UnsafePointer<ClassDescriptor>) -> Int32 {
        if let storedBoundsPtr = Self._getResilientMetadataBounds(data) {
            var result = 0;
            if (storedBoundsPtr.pointee.tryGetImmediateMembersOffset(&result)) {
                return Int32(result / MemoryLayout<OpaquePointer>.size);
            }
            var storedBounds = storedBoundsPtr.pointee;
            let bounds = computeMetadataBoundsFromSuperclass(data, &storedBounds);
            return Int32(Int(bounds.immediateMembersOffset) / MemoryLayout<OpaquePointer>.size);
        } else {
            return 0;
        }
    }
    // resilientMetadataBounds
    internal var resilientMetadataBounds: ClassMetadataBounds? { mutating get { Self.getResilientMetadataBounds(&self); } }
    internal static func getResilientMetadataBounds(_ data: UnsafePointer<ClassDescriptor>) -> ClassMetadataBounds? {
        if let storedBoundsPtr = Self._getResilientMetadataBounds(data) {
            var bounds = ClassMetadataBounds(0, 0, 0);
            if (storedBoundsPtr.pointee.tryGet(&bounds)) {
                return bounds;
            }
            var storedBounds = storedBoundsPtr.pointee;
            return computeMetadataBoundsFromSuperclass(data, &storedBounds);
        } else {
            return nil;
        }
    }
    // superclassType
    public var superclassType: String? { mutating get { return Self.getSuperclassType(&self); } }
    public static func getSuperclassType(_ data: UnsafePointer<ClassDescriptor>) -> String? {
        if let ptr = UnsafeMutablePointer<ClassDescriptor>(mutating:data).pointee._superclassType.pointer {
            return Optional(String(cString:UnsafePointer<CChar>(ptr)));
        } else {
            return nil;
        }
    }
    // resilientSuperclass
    fileprivate static func _getResilientSuperclassOffset(_ data: UnsafePointer<ClassDescriptor>) -> Int {
        var offset = 0;
        if (data.pointee.isGeneric) {
            let ptr = UnsafePointer<TypeGenericContextDescriptorHeader>(OpaquePointer(data.advanced(by:1)));
            offset = TypeGenericContextDescriptorHeader.getTypeGenericContextDataSize(ptr);
        }
        return offset;
    }
    public var resilientSuperclass: UnsafePointer<ResilientSuperclass>? { mutating get { return Self.getResilientSuperclass(&self); } }
    public static func getResilientSuperclass(_ data: UnsafePointer<ClassDescriptor>) -> UnsafePointer<ResilientSuperclass>? {
        if (data.pointee.hasResilientSuperclass) {
            return UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:self._getResilientSuperclassOffset(data)).assumingMemoryBound(to:ResilientSuperclass.self);
        } else {
            return nil;
        }
    }
    // ForeignMetadataInitialization
    fileprivate static func _getMetadataInitializationOffset(_ data: UnsafePointer<ClassDescriptor>) -> Int {
        var offset = Self._getResilientSuperclassOffset(data);
        if (data.pointee.hasResilientSuperclass) {
            offset += MemoryLayout<ResilientSuperclass>.size;
        }
        return offset;
    }
    public var foreignMetadataInitialization: UnsafePointer<ForeignMetadataInitialization>? { mutating get { return Self.getForeignMetadataInitialization(&self); } }
    public static func getForeignMetadataInitialization(_ data: UnsafePointer<ClassDescriptor>) -> UnsafePointer<ForeignMetadataInitialization>? {
        if (data.pointee.metadataInitialization == .ForeignMetadataInitialization) {
            return UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:self._getMetadataInitializationOffset(data)).assumingMemoryBound(to:ForeignMetadataInitialization.self);
        } else {
            return nil;
        }
    }
    // SingletonMetadataInitialization
    public var singletonMetadataInitialization: UnsafePointer<SingletonMetadataInitialization>? { mutating get { return Self.getSingletonMetadataInitialization(&self); } }
    public static func getSingletonMetadataInitialization(_ data: UnsafePointer<ClassDescriptor>) -> UnsafePointer<SingletonMetadataInitialization>? {
        if (data.pointee.metadataInitialization == .SingletonMetadataInitialization) {
            return UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:self._getMetadataInitializationOffset(data)).assumingMemoryBound(to:SingletonMetadataInitialization.self);
        } else {
            return nil;
        }
    }
    // vtable
    fileprivate static func _getVtableOffset(_ data: UnsafePointer<ClassDescriptor>) -> Int {
        var offset = Self._getMetadataInitializationOffset(data);
        switch(data.pointee.metadataInitialization) {
        case .ForeignMetadataInitialization:
            offset += MemoryLayout<ForeignMetadataInitialization>.size;
        case .SingletonMetadataInitialization:
            offset += MemoryLayout<SingletonMetadataInitialization>.size;
        case .NoMetadataInitialization:
            offset += 0;
        }
        return offset;
    }
    public var vTableOffset: UInt32 { mutating get { return Self.getVTableOffset(&self); } }
    public static func getVTableOffset(_ data: UnsafePointer<ClassDescriptor>) -> UInt32 {
        if (data.pointee.hasVTable) {
            let ptr = UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:self._getVtableOffset(data)).assumingMemoryBound(to:VTableDescriptorHeader.self);
            return ptr.pointee.vTableOffset;
        } else {
            return 0;
        }
    }
    public var vTableSize: UInt32 { mutating get { return Self.getVTableSize(&self); } }
    public static func getVTableSize(_ data: UnsafePointer<ClassDescriptor>) -> UInt32 {
        if (data.pointee.hasVTable) {
            let ptr = UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:self._getVtableOffset(data)).assumingMemoryBound(to:VTableDescriptorHeader.self);
            return ptr.pointee.vTableSize;
        } else {
            return 0;
        }
    }
    public var vtable: UnsafeBufferPointer<MethodDescriptor>? { mutating get { Self.getVTable(&self); } }
    public static func getVTable(_ data: UnsafePointer<ClassDescriptor>) -> UnsafeBufferPointer<MethodDescriptor>? {
        if (data.pointee.hasVTable) {
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
        if (data.pointee.hasVTable) {
            let ptr = UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:offset).assumingMemoryBound(to:VTableDescriptorHeader.self);
            offset += MemoryLayout<VTableDescriptorHeader>.size;
            offset += MemoryLayout<MethodDescriptor>.size * Int(ptr.pointee.vTableSize);
        }
        return offset;
    }
    public var overridetableSize: UInt32 { mutating get { return Self.getOverridetableSize(&self); } }
    public static func getOverridetableSize(_ data: UnsafePointer<ClassDescriptor>) -> UInt32 {
        if (data.pointee.hasOverrideTable) {
            let ptr = UnsafeRawPointer(OpaquePointer(data.advanced(by:1))).advanced(by:self._getOverridetableOffset(data)).assumingMemoryBound(to:OverrideTableHeader.self);
            return ptr.pointee.numEntries;
        } else {
            return 0;
        }
    }
    public var overridetable: UnsafeBufferPointer<MethodOverrideDescriptor>? { mutating get { return Self.getOverridetable(&self); } }
    public static func getOverridetable(_ data: UnsafePointer<ClassDescriptor>) -> UnsafeBufferPointer<MethodOverrideDescriptor>? {
        if (data.pointee.hasOverrideTable) {
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
public struct GenericContextDescriptorHeader {
    public let numParams: UInt16;
    public let numRequirements: UInt16;
    public let numKeyArguments: UInt16;
    public let numExtraArguments: UInt16;
};

extension GenericContextDescriptorHeader {
    public var numArguments: UInt32 { get { return UInt32(self.numKeyArguments + self.numExtraArguments); } }
    public var hasArguments: Bool { get { return self.numArguments > 0; } }
}

public enum GenericParamKind : UInt8 {
    case `Type` = 0;
    case Max = 0x3F;
}

public struct GenericParamDescriptor {
    public let value: UInt8;
}

extension GenericParamDescriptor {
    public var hasKeyArgument: Bool { get { return (self.value & 0x80) != 0; } }
    public var hasExtraArgument: Bool { get { return (self.value & 0x40) != 0; } }
    public var kind: GenericParamKind { get { return GenericParamKind(rawValue:self.value & 0x3F) ?? .Max; } }
}

/***
 * TypeGenericContextDescriptorHeader
 ***/
public struct TypeGenericContextDescriptorHeader {
    fileprivate var _instantiationCache: RelativeDirectPointer;
    fileprivate var _defaultInstantiationPattern: RelativeDirectPointer;
    public let base: GenericContextDescriptorHeader;
};

extension TypeGenericContextDescriptorHeader {
    // instantiationCache
    public var instantiationCache: UnsafePointer<GenericMetadataInstantiationCache>? { mutating get { Self.getInstantiationCache(&self); } }
    public static func getInstantiationCache(_ data: UnsafePointer<TypeGenericContextDescriptorHeader>) -> UnsafePointer<GenericMetadataInstantiationCache>? {
        if let ptr = UnsafeMutablePointer<TypeGenericContextDescriptorHeader>(mutating:data).pointee._instantiationCache.pointer {
            return Optional(UnsafePointer<GenericMetadataInstantiationCache>(ptr))
        } else {
            return nil;
        }
    }
    // defaultInstantiationPattern
    public var defaultInstantiationPattern: UnsafePointer<GenericMetadataPattern>? { mutating get { return Self.getDefaultInstantiationPattern(&self); } }
    public static func getDefaultInstantiationPattern(_ data: UnsafePointer<TypeGenericContextDescriptorHeader>) -> UnsafePointer<GenericMetadataPattern>? {
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

public struct GenericMetadataInstantiationCache {
    fileprivate let _privateData: OpaquePointer;
}

extension GenericMetadataInstantiationCache {
    fileprivate static let NumGenericMetadataPrivateDataWords: Int = 16;
    public var privateData: UnsafeBufferPointer<OpaquePointer> { mutating get { return Self.getPrivateData(&self); } }
    public static func getPrivateData(_ data: UnsafePointer<GenericMetadataInstantiationCache>) -> UnsafeBufferPointer<OpaquePointer> {
        return UnsafeBufferPointer(start:UnsafePointer<OpaquePointer>(OpaquePointer(data)), count:Self.NumGenericMetadataPrivateDataWords);
    }
}

public struct GenericMetadataPatternFlags {
    fileprivate let _value: UInt32;
}

extension GenericMetadataPatternFlags {
    fileprivate static let HasExtraDataPattern: UInt32 = 0;
    fileprivate static let HasTrailingFlags: UInt32 = 1;
    fileprivate static let Class_HasImmediateMembersPattern: UInt32 = 31;
    fileprivate static let Value_MetadataKind: UInt32 = 21;
    fileprivate static let Value_MetadataKind_width: UInt32 = 11;
    public var class_hasImmediateMembersPattern: Bool { get { return (self._value & (1 << Self.Class_HasImmediateMembersPattern)) != 0; } }
    public var hasExtraDataPattern: Bool { get { return (self._value & (1 << Self.HasExtraDataPattern)) != 0; } }
    public var hasTrailingFlags: Bool { get { return (self._value & (1 << Self.HasTrailingFlags)) != 0; } }
    public var value_getMetadataKind: MetadataKind { get { return MetadataKind(rawValue:(((1 << Self.Value_MetadataKind_width) - 1) & (self._value >> Self.Value_MetadataKind))) ?? .Class; } }
}

public struct GenericMetadataPattern {
    fileprivate var _instantiationFunction: RelativeDirectPointer;
    fileprivate var _completionFunction: RelativeDirectPointer;
    public let patternFlags: GenericMetadataPatternFlags;
}

extension GenericMetadataPattern {
    // instantiationFunction
    public var instantiationFunction: FunctionPointer? { mutating get { return Self.getDefaultInstantiationPattern(&self); } }
    public static func getDefaultInstantiationPattern(_ data: UnsafePointer<GenericMetadataPattern>) -> FunctionPointer? {
        if let ptr = UnsafeMutablePointer<GenericMetadataPattern>(mutating:data).pointee._instantiationFunction.pointer {
            return Optional(FunctionPointer(ptr));
        } else {
            return nil;
        }
    }
    // completionFunction
    public var completionFunction: FunctionPointer? { mutating get { return Self.getCompletionFunction(&self); } }
    public static func getCompletionFunction(_ data: UnsafePointer<GenericMetadataPattern>) -> FunctionPointer? {
        if let ptr = UnsafeMutablePointer<GenericMetadataPattern>(mutating:data).pointee._completionFunction.pointer {
            return Optional(FunctionPointer(ptr));
        } else {
            return nil;
        }
    }
    public var hasExtraDataPattern: Bool { get { return self.patternFlags.hasExtraDataPattern; } }
}

// MARK: -
// MARK: Append
public enum GenericRequirementKind : UInt8 {
    case `Protocol` = 0;
    case SameType = 1;
    case BaseClass = 2;
    case SameConformance = 3;
    case Unknown = 0x1E;
    case Layout = 0x1F;
};

public struct GenericRequirementFlags {
    fileprivate let value: UInt32;
}

extension GenericRequirementFlags {
    public var hasKeyArgument: Bool { get { return (self.value & 0x80) != 0; } }
    public var hasExtraArgument: Bool { get { return (self.value & 0x40) != 0; } }
    public var kind: GenericRequirementKind { get { return GenericRequirementKind(rawValue:UInt8(self.value & 0x1F)) ?? .Unknown; } }
}

/***
 * GenericRequirementDescriptor
 ***/
public struct GenericRequirementDescriptor {
    public let flags: GenericRequirementFlags;
    fileprivate var _param: RelativeDirectPointer;
    fileprivate let _layout: Int32;
}

public struct RelativeProtocolDescriptorPointer {
    fileprivate var _pointer : Int32;
}

extension RelativeProtocolDescriptorPointer {
    fileprivate static func getMask() -> Int32 {
        return Int32(MemoryLayout<Int32>.alignment - 1) & ~Int32(0x01);
    }
    fileprivate static func _getPointer(_ data: UnsafePointer<RelativeProtocolDescriptorPointer>) -> OpaquePointer {
        let offset = (data.pointee._pointer & ~Self.getMask());
        let address = Int(bitPattern:data) + Int(offset & ~1);
        if ((offset & 1) != 0) {
            return UnsafePointer<OpaquePointer>(OpaquePointer(bitPattern:address))!.pointee;
        } else {
            return OpaquePointer(bitPattern:address)!;
        }
    }
    // isObjC
    public var isObjC: Bool { get { return ((self._pointer & Self.getMask()) >> 1) != 0; } }
    // swiftPointer
    public var swiftPointer: UnsafePointer<ProtocolDescriptor>? { mutating get { return Self.getSwiftPointer(&self); } }
    public static func getSwiftPointer(_ data: UnsafePointer<RelativeProtocolDescriptorPointer>) ->UnsafePointer<ProtocolDescriptor>? {
        if (!data.pointee.isObjC) {
            return Optional(UnsafePointer<ProtocolDescriptor>(Self._getPointer(data)));
        } else {
            return nil;
        }
    }
    // objcPointer
    public var objcPointer: UnsafePointer<ObjcProtocol>? { mutating get { return Self.getObjcPointer(&self); } }
    public static func getObjcPointer(_ data: UnsafePointer<RelativeProtocolDescriptorPointer>) ->UnsafePointer<ObjcProtocol>? {
        if (data.pointee.isObjC) {
            return Optional(UnsafePointer<ObjcProtocol>(Self._getPointer(data)));
        } else {
            return nil;
        }
    }
}

public struct ObjcProtocol {
    public let isa: UnsafePointer<AnyClassMetadata>;
}

public typealias GenericRequirementLayoutKind = Int32;
extension GenericRequirementDescriptor {
    public var kind: GenericRequirementKind { get { return self.flags.kind; } }
    // param
    public var param: String { mutating get { return Self.getParam(&self); } }
    public static func getParam(_ data: UnsafePointer<GenericRequirementDescriptor>) -> String {
        let ptr = UnsafeMutablePointer<GenericRequirementDescriptor>(mutating:data).pointee._param.pointer!;
        return String(cString:UnsafePointer<CChar>(ptr));
    }
    // protocol
    public var protocolDescriptor: UnsafePointer<RelativeProtocolDescriptorPointer>? { mutating get { return Self.getProtocolDescriptor(&self); } }
    public static func getProtocolDescriptor(_ data: UnsafePointer<GenericRequirementDescriptor>) -> UnsafePointer<RelativeProtocolDescriptorPointer>? {
        if (data.pointee.kind == .Protocol) {
            return Optional(UnsafePointer<RelativeProtocolDescriptorPointer>(OpaquePointer(UnsafePointer<RelativeDirectPointer>(OpaquePointer(data)).advanced(by:2))));
        } else {
            return nil;
        }
    }
    // mangledTypeName
    public var mangledTypeName: String? { mutating get { return Self.getMangledTypeName(&self); } }
    public static func getMangledTypeName(_ data: UnsafePointer<GenericRequirementDescriptor>) -> String? {
        if (data.pointee.kind == .SameType || data.pointee.kind == .BaseClass) {
            let ptr = UnsafeMutablePointer<RelativeDirectPointer>(mutating:UnsafePointer<RelativeDirectPointer>(OpaquePointer(data)).advanced(by:2)).pointee.pointer!;
            return Optional(String(cString:UnsafePointer<CChar>(ptr)));
        } else {
            return nil;
        }
    }
    // conformance
    public var conformance: UnsafePointer<ProtocolConformanceDescriptor>? { mutating get { return Self.getConformance(&self); } }
    public static func getConformance(_ data: UnsafePointer<GenericRequirementDescriptor>) -> UnsafePointer<ProtocolConformanceDescriptor>? {
        if (data.pointee.kind == .SameConformance) {
            let ptr = UnsafeMutablePointer<RelativeContextPointer>(mutating:UnsafePointer<RelativeContextPointer>(OpaquePointer(data)).advanced(by:2)).pointee.pointer!;
            return Optional(UnsafePointer<ProtocolConformanceDescriptor>(ptr));
        } else {
            return nil;
        }
    }
    // layout
    public var layout: GenericRequirementLayoutKind? {
        get {
            if (self.kind == .Layout) {
                return Optional(self._layout);
            } else {
                return nil;
            }
        }
    }
    public var hasKnownKind: Bool {
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
public struct ResilientWitnessesHeader {
    public let numWitnesses: UInt32;
}

public struct ResilientWitness {
    fileprivate var _requirement: RelativeContextPointer;
    fileprivate var _witness: RelativeDirectPointer;
}

extension ResilientWitness {
    // requirement
    public var requirement: UnsafePointer<ProtocolRequirement> { mutating get { return Self.getRequirement(&self); } }
    public static func getRequirement(_ data: UnsafePointer<ResilientWitness>) -> UnsafePointer<ProtocolRequirement> {
        let ptr = UnsafeMutablePointer<ResilientWitness>(mutating:data).pointee._requirement.pointer!;
        return UnsafePointer<ProtocolRequirement>(ptr);
    }
    //witness
    public var witness: OpaquePointer { mutating get { return Self.getWitness(&self); } }
    public static func getWitness(_ data: UnsafePointer<ResilientWitness>) -> OpaquePointer {
        return UnsafeMutablePointer<ResilientWitness>(mutating:data).pointee._witness.pointer!;
    }
}

/***
 * GenericWitnessTable
 ***/
public struct GenericWitnessTable {
    public let witnessTableSizeInWords: UInt16;
    public let witnessTablePrivateSizeInWordsAndRequiresInstantiation: UInt16;
    fileprivate var _instantiator: RelativeDirectPointer;
    fileprivate var _privateData: RelativeDirectPointer;
}

extension GenericWitnessTable {
    fileprivate static let NumGenericMetadataPrivateDataWords: UInt32 = 16;
    public var witnessTablePrivateSizeInWords: UInt16 { get { return self.witnessTablePrivateSizeInWordsAndRequiresInstantiation >> 0x01; } }
    public var requiresInstantiation: UInt16 { get { return self.witnessTablePrivateSizeInWordsAndRequiresInstantiation & 0x01; } }
    // instantiator
    public var instantiator: FunctionPointer { mutating get { return Self.getInstantiator(&self); } }
    public static func getInstantiator(_ data: UnsafePointer<GenericWitnessTable>) -> FunctionPointer {
        return FunctionPointer(UnsafeMutablePointer<GenericWitnessTable>(mutating:data).pointee._instantiator.pointer!);
    }
    // privateData
    public var privateData: UnsafeBufferPointer<FunctionPointer> { mutating get { return Self.getPrivateData(&self); } }
    public static func getPrivateData(_ data: UnsafePointer<GenericWitnessTable>) -> UnsafeBufferPointer<FunctionPointer> {
        let ptr = UnsafeMutablePointer<GenericWitnessTable>(mutating:data).pointee._privateData.pointer!;
        let size = data.pointee.witnessTablePrivateSizeInWords;  // not sure
        return UnsafeBufferPointer<FunctionPointer>(start:UnsafePointer<FunctionPointer>(ptr), count:Int(size));
    }
}

/***
 * ConformanceFlags
 ***
 */
public enum TypeReferenceKind : UInt16 {
    case DirectTypeDescriptor = 0x00;
    case IndirectTypeDescriptor = 0x01;
    case DirectObjCClassName = 0x02;
    case IndirectObjCClass = 0x03;
//    First_Kind = DirectTypeDescriptor,
//    Last_Kind = IndirectObjCClass,
};

public struct ConformanceFlags {
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
    public var typeReferenceKind: TypeReferenceKind { get { return TypeReferenceKind(rawValue:UInt16((self._value & Self.TypeMetadataKindMask) >> Self.TypeMetadataKindShift)) ?? .DirectTypeDescriptor; } }
    public var isRetroactive: Bool { get { return (self._value & Self.IsRetroactiveMask) != 0; } }
    public var isSynthesizedNonUnique: Bool { get { return (self._value & Self.IsSynthesizedNonUniqueMask) != 0; } }
    public var numConditionalRequirements: UInt32 { get { return (self._value & Self.NumConditionalRequirementsMask) >> Self.NumConditionalRequirementsShift; } }
    public var hasResilientWitnesses: Bool { get { return (self._value & Self.HasResilientWitnessesMask) != 0; } }
    public var hasGenericWitnessTable: Bool { get { return (self._value & Self.HasGenericWitnessTableMask) != 0; } }
}

/***
 * TypeReference
 ***/
internal struct TypeReference {
    fileprivate var _value: RelativeDirectPointer;
}

extension TypeReference {
    fileprivate static func getPointer(_ ptr: UnsafePointer<TypeReference>) -> OpaquePointer {
        return UnsafeMutablePointer<TypeReference>(mutating:ptr).pointee._value.pointer!;
    }
    // TypeDescriptor
    internal mutating func getTypeDescriptor(_ kind: TypeReferenceKind) -> UnsafePointer<ContextDescriptor>? {
        if (kind == .DirectTypeDescriptor) {
            return Optional(UnsafePointer<ContextDescriptor>(Self.getPointer(&self)));
        } else if (kind == .IndirectTypeDescriptor) {
            return Optional(UnsafePointer<UnsafePointer<ContextDescriptor>>(Self.getPointer(&self)).pointee);
        } else {
            return nil;
        }
    }
    // IndirectObjCClass
    internal mutating func getIndirectObjCClass(_ kind: TypeReferenceKind) -> UnsafePointer<ClassMetadata>? {
        if (kind == .IndirectObjCClass) {
            return Optional(UnsafePointer<ClassMetadata>(Self.getPointer(&self)));
        } else {
            return nil;
        }
    }
    // DirectObjCClassName
    internal  mutating func getDirectObjCClassName(_ kind: TypeReferenceKind) -> String? {
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
public struct WitnessTable {
    public let description: UnsafePointer<ProtocolConformanceDescriptor>;
}

/***
 * ProtocolConformanceDescriptor
 ***/
public struct ProtocolConformanceDescriptor {
    fileprivate var _protocol: RelativeContextPointer;
    fileprivate var _typeRef: TypeReference;
    fileprivate var _witnessTablePattern : RelativeDirectPointer;
    public let flags: ConformanceFlags;
    // RelativeContextPointer
    // GenericRequirementDescriptor
    // ResilientWitnessesHeader
    // ResilientWitness
    // GenericWitnessTable
}

extension ProtocolConformanceDescriptor {
    // protocol
    public var protocolDescriptor: UnsafePointer<ProtocolDescriptor> { mutating get { return Self.getProtocolDescriptor(&self); } }
    public static func getProtocolDescriptor(_ data: UnsafePointer<ProtocolConformanceDescriptor>) -> UnsafePointer<ProtocolDescriptor> {
        let ptr = UnsafeMutablePointer<ProtocolConformanceDescriptor>(mutating:data).pointee._protocol.pointer!;
        return UnsafePointer<ProtocolDescriptor>(ptr);
    }
    // witnessTablePattern
    public var witnessTablePattern: UnsafePointer<WitnessTable>? { mutating get { return Self.getWitnessTablePattern(&self); } }
    public static func getWitnessTablePattern(_ data: UnsafePointer<ProtocolConformanceDescriptor>) -> UnsafePointer<WitnessTable>? {
        if let ptr = UnsafeMutablePointer<ProtocolConformanceDescriptor>(mutating:data).pointee._witnessTablePattern.pointer {
            return Optional(UnsafePointer<WitnessTable>(ptr));
        } else {
            return nil;
        }
    }
    public var witnessTable: UnsafeBufferPointer<FunctionPointer>? { mutating get { return Self.getWitnessTable(&self); } }
    public static func getWitnessTable(_ data: UnsafePointer<ProtocolConformanceDescriptor>) -> UnsafeBufferPointer<FunctionPointer>? {
        if let ptr = UnsafePointer<FunctionPointer>(OpaquePointer(Self.getWitnessTablePattern(data)?.advanced(by:1))) {
            let size = Self.getProtocolDescriptor(data).pointee.numRequirements; // not sure
            return UnsafeBufferPointer<FunctionPointer>(start:ptr, count:Int(size));
        } else {
            return nil;
        }
    }
    // directObjCClassName
    public var directObjCClassName: String? { mutating get { return Self.getDirectObjCClassName(&self); } }
    public static func getDirectObjCClassName(_ data: UnsafePointer<ProtocolConformanceDescriptor>) -> String? {
        let ptr = UnsafeMutablePointer<ProtocolConformanceDescriptor>(mutating:data);
        return ptr.pointee._typeRef.getDirectObjCClassName(data.pointee.flags.typeReferenceKind);
    }
    // indirectObjCClass
    public var indirectObjCClass: UnsafePointer<ClassMetadata>? { mutating get { return Self.getIndirectObjCClass(&self); } }
    public static func getIndirectObjCClass(_ data: UnsafePointer<ProtocolConformanceDescriptor>) -> UnsafePointer<ClassMetadata>? {
        let ptr = UnsafeMutablePointer<ProtocolConformanceDescriptor>(mutating:data);
        return ptr.pointee._typeRef.getIndirectObjCClass(data.pointee.flags.typeReferenceKind);
    }
    // typeDescriptor
    public var typeDescriptor: UnsafePointer<ContextDescriptor>? { mutating get { return Self.getTypeDescriptor(&self); } }
    public static func getTypeDescriptor(_ data: UnsafePointer<ProtocolConformanceDescriptor>) -> UnsafePointer<ContextDescriptor>? {
        let ptr = UnsafeMutablePointer<ProtocolConformanceDescriptor>(mutating:data);
        return ptr.pointee._typeRef.getTypeDescriptor(data.pointee.flags.typeReferenceKind);
    }
    // retroactiveContext
    public var retroactiveContext: UnsafePointer<ContextDescriptor>? { mutating get { return Self.getRetroactiveContext(&self); } }
    public static func getRetroactiveContext(_ data: UnsafePointer<ProtocolConformanceDescriptor>) -> UnsafePointer<ContextDescriptor>? {
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
    public  var hasConditionalRequirements: Bool { get { return self.flags.numConditionalRequirements > 0; } }
    public var conditionalRequirements: UnsafeBufferPointer<GenericRequirementDescriptor>? { mutating get { return Self.getConditionalRequirements(&self); } }
    public static func getConditionalRequirements(_ data: UnsafePointer<ProtocolConformanceDescriptor>) -> UnsafeBufferPointer<GenericRequirementDescriptor>? {
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
    public static func getResilientWitnesses(_ data: UnsafePointer<ProtocolConformanceDescriptor>) -> UnsafeBufferPointer<ResilientWitness>? {
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
    public static func getGenericWitnessTable(_ data: UnsafePointer<ProtocolConformanceDescriptor>) -> UnsafePointer<GenericWitnessTable>? {
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
public struct ResilientSuperclass {
    fileprivate var _superclass: RelativeDirectPointer;
};

extension ResilientSuperclass {
    public var superclass: OpaquePointer? { mutating get { return Self.getSuperclass(&self); } }
    public static func getSuperclass(_ data: UnsafePointer<ResilientSuperclass>) -> OpaquePointer? {
        return UnsafeMutablePointer<ResilientSuperclass>(mutating:data).pointee._superclass.pointer;
    }
}

/***
 * ForeignMetadataInitialization
 ***/
public struct ForeignMetadataInitialization {
  /// The completion function.  The pattern will always be null.
    fileprivate var _completionFunction: RelativeDirectPointer;
};

extension ForeignMetadataInitialization {
    public var completionFunction: OpaquePointer? { mutating get { return Self.getCompletionFunction(&self); } }
    public static func getCompletionFunction(_ data: UnsafePointer<ForeignMetadataInitialization>) -> OpaquePointer? {
        return UnsafeMutablePointer<ForeignMetadataInitialization>(mutating:data).pointee._completionFunction.pointer;
    }
}

/***
 * SingletonMetadataCache
 ***/
public struct SingletonMetadataCache {
    public let metadata: UnsafePointer<Metadata>;
    public let `private`: OpaquePointer;
}

/***
 * ResilientClassMetadataPattern
 ***/
public struct ResilientClassMetadataPattern {
    fileprivate var _relocationFunction: RelativeDirectPointer;
    fileprivate var _destroy: RelativeDirectPointer;
    fileprivate var _iVarDestroyer: RelativeDirectPointer;
    public let flags: ClassFlags;
    fileprivate var _data: RelativeDirectPointer;
    fileprivate var _metaclass: RelativeDirectPointer;
}

extension ResilientClassMetadataPattern {
    // relocationFunction
    public var relocationFunction: FunctionPointer? { mutating get { return Self.getRelocationFunction(&self); } }
    public static func getRelocationFunction(_ data: UnsafePointer<ResilientClassMetadataPattern>) -> FunctionPointer? {
        if let ptr = UnsafeMutablePointer<ResilientClassMetadataPattern>(mutating:data).pointee._relocationFunction.pointer {
            return FunctionPointer(ptr);
        } else {
            return nil;
        }
    }
    // destroy
    public var destroy: FunctionPointer? { mutating get { return Self.getDestroy(&self); } }
    public static func getDestroy(_ data: UnsafePointer<ResilientClassMetadataPattern>) -> FunctionPointer? {
        if let ptr = UnsafeMutablePointer<ResilientClassMetadataPattern>(mutating:data).pointee._destroy.pointer {
            return FunctionPointer(ptr);
        } else {
            return nil;
        }
    }
    // iVarDestroyer
    public var iVarDestroyer: FunctionPointer? { mutating get { return Self.getIVarDestroyer(&self); } }
    public static func getIVarDestroyer(_ data: UnsafePointer<ResilientClassMetadataPattern>) -> FunctionPointer? {
        if let ptr = UnsafeMutablePointer<ResilientClassMetadataPattern>(mutating:data).pointee._iVarDestroyer.pointer {
            return FunctionPointer(ptr);
        } else {
            return nil;
        }
    }
    // data
    public var data: OpaquePointer? { mutating get { return Self.getData(&self); } }
    public static func getData(_ data: UnsafePointer<ResilientClassMetadataPattern>) -> OpaquePointer? {
        return UnsafeMutablePointer<ResilientClassMetadataPattern>(mutating:data).pointee._data.pointer;
    }
    // metaclass
    public var metaclass: UnsafePointer<AnyClassMetadata>? { mutating get { return Self.getMetaclass(&self); } }
    public static func getMetaclass(_ data: UnsafePointer<ResilientClassMetadataPattern>) -> UnsafePointer<AnyClassMetadata>? {
        let ptr = UnsafeMutablePointer<ResilientClassMetadataPattern>(mutating:data).pointee._data.pointer;
        return UnsafePointer<AnyClassMetadata>(ptr);
    }
}

/***
 * SingletonMetadataInitialization
 ***/
public struct SingletonMetadataInitialization {
    fileprivate var _initializationCache: RelativeDirectPointer;
    fileprivate var _incompleteMetadata: RelativeDirectPointer;  // resilientPattern: RelativeDirectPointer;
    fileprivate var _completionFunction: RelativeDirectPointer;
}

extension SingletonMetadataInitialization {
    // initializationCache
    public var initializationCache: UnsafePointer<SingletonMetadataCache>? { mutating get { return Self.getInitializationCache(&self); } }
    public static func getInitializationCache(_ data: UnsafePointer<SingletonMetadataInitialization>) -> UnsafePointer<SingletonMetadataCache>? {
        let ptr = UnsafeMutablePointer<SingletonMetadataInitialization>(mutating:data).pointee._initializationCache.pointer;
        return UnsafePointer<SingletonMetadataCache>(ptr);
    }
    // incompleteMetadata
    public var incompleteMetadata: OpaquePointer? { mutating get { return Self.getIncompleteMetadata(&self); } }
    public static func getIncompleteMetadata(_ data: UnsafePointer<SingletonMetadataInitialization>) -> OpaquePointer? {
        return UnsafeMutablePointer<SingletonMetadataInitialization>(mutating:data).pointee._incompleteMetadata.pointer;
    }
    // resilientPattern
    public var resilientPattern: UnsafePointer<ResilientClassMetadataPattern>? { mutating get { return Self.getResilientPattern(&self); } }
    public static func getResilientPattern(_ data: UnsafePointer<SingletonMetadataInitialization>) -> UnsafePointer<ResilientClassMetadataPattern>? {
        let ptr = UnsafeMutablePointer<SingletonMetadataInitialization>(mutating:data).pointee._incompleteMetadata.pointer;
        return UnsafePointer<ResilientClassMetadataPattern>(ptr);
    }
    // completionFunction
    public var completionFunction: FunctionPointer? { mutating get { return Self.getCompletionFunction(&self); } }
    public static func getCompletionFunction(_ data: UnsafePointer<SingletonMetadataInitialization>) -> FunctionPointer? {
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
public struct VTableDescriptorHeader {
    let vTableOffset: UInt32;
    let vTableSize: UInt32;
};

/***
 * MethodDescriptorFlags
 ***/
public struct MethodDescriptorFlags {
    fileprivate let value: UInt32;
}

extension MethodDescriptorFlags {
    public var kind: MethodDescriptorKind { get { return MethodDescriptorKind(rawValue:UInt8(self.value & 0x0F)) ?? .Method; } }
    public var isDynamic: Bool { get { return (self.value & 0x20) != 0; } }
    public var isInstance: Bool { get { return (self.value & 0x10) != 0; } }
    public var isAsync: Bool { get { return (self.value & 0x40) != 0; } }
}

/***
 * MethodDescriptor
 ***/
public struct MethodDescriptor {
    public let flags: MethodDescriptorFlags;
    fileprivate var _impl: RelativeDirectPointer;
}

extension MethodDescriptor {
    // impl
    public var impl: FunctionPointer { mutating get { MethodDescriptor.getImpl(&self); } }
    public static func getImpl(_ data: UnsafePointer<MethodDescriptor>) -> FunctionPointer {
        return FunctionPointer(UnsafeMutablePointer<MethodDescriptor>(mutating:data).pointee._impl.pointer!);
    }
}

/***
 * OverrideTableHeader
 ***/
public struct OverrideTableHeader {
    public let numEntries: UInt32;
};

/***
 * MethodOverrideDescriptor
 ***/
public struct MethodOverrideDescriptor {
    fileprivate var _cls: RelativeContextPointer;
    fileprivate var _method: RelativeContextPointer;  // base
    fileprivate var _impl: RelativeDirectPointer;    // override
}

extension MethodOverrideDescriptor {
    // cls
    public  var cls: OpaquePointer { mutating get { Self.getClass(&self); } }
    public static func getClass(_ data: UnsafePointer<MethodOverrideDescriptor>) -> OpaquePointer {
        return UnsafeMutablePointer<MethodOverrideDescriptor>(mutating:data).pointee._cls.pointer!;
    }
    // method
    public var method: FunctionPointer { mutating get { Self.getMethod(&self); } }
    public static func getMethod(_ data: UnsafePointer<MethodOverrideDescriptor>) -> FunctionPointer {
        return FunctionPointer(UnsafeMutablePointer<MethodOverrideDescriptor>(mutating:data).pointee._method.pointer!);
    }
    // impl
    public var impl: FunctionPointer { mutating get { Self.getImpl(&self); } }
    public static func getImpl(_ data: UnsafePointer<MethodOverrideDescriptor>) -> FunctionPointer {
        return FunctionPointer(UnsafeMutablePointer<MethodOverrideDescriptor>(mutating:data).pointee._impl.pointer!);
    }
}

/***
 * ObjCResilientClassStubInfo
 ***/
public struct ObjCResilientClassStubInfo {
    fileprivate var _stub: RelativeDirectPointer;
};

extension ObjCResilientClassStubInfo {
    public var sub: OpaquePointer { mutating get { return Self.getSub(&self); } }
    public static func getSub(_ data: UnsafePointer<ObjCResilientClassStubInfo>) -> OpaquePointer {
        return UnsafeMutablePointer<ObjCResilientClassStubInfo>(mutating:data).pointee._stub.pointer!;
    }
}

/***
 * CanonicalSpecializedMetadatasListCount
 ***/
public struct CanonicalSpecializedMetadatasListCount {
    public let count: UInt32;
}

/***
 * CanonicalSpecializedMetadatasListEntry
 ***/
public struct CanonicalSpecializedMetadatasListEntry {
    fileprivate var _metadata: RelativeDirectPointer;
}

extension CanonicalSpecializedMetadatasListEntry {
    public var metadata: UnsafePointer<Metadata> { mutating get { return Self.getMetadata(&self); } }
    public static func getMetadata(_ data: UnsafePointer<CanonicalSpecializedMetadatasListEntry>) -> UnsafePointer<Metadata> {
        return UnsafePointer<Metadata>(UnsafeMutablePointer<CanonicalSpecializedMetadatasListEntry>(mutating:data).pointee._metadata.pointer!);
    }
}

/***
 * CanonicalSpecializedMetadataAccessorsListEntry
 ***/
public struct CanonicalSpecializedMetadataAccessorsListEntry {
    fileprivate var _accessor: RelativeDirectPointer;
};

extension CanonicalSpecializedMetadataAccessorsListEntry {
    public var accessor: OpaquePointer { mutating get { return Self.getAccessor(&self); } }
    public static func getAccessor(_ data: UnsafePointer<CanonicalSpecializedMetadataAccessorsListEntry>) -> OpaquePointer {
        return UnsafeMutablePointer<CanonicalSpecializedMetadataAccessorsListEntry>(mutating:data).pointee._accessor.pointer!
    }
}

/***
 * CanonicalSpecializedMetadatasCachingOnceToken
 ***/
public struct CanonicalSpecializedMetadatasCachingOnceToken {
    fileprivate var _token: RelativeDirectPointer;
};

extension CanonicalSpecializedMetadatasCachingOnceToken {
    public var token: CLong { mutating get { return Self.getToken(&self); } }
    public static func getToken(_ data: UnsafePointer<CanonicalSpecializedMetadatasCachingOnceToken>) -> CLong {
        let ptr = UnsafeMutablePointer<CanonicalSpecializedMetadatasCachingOnceToken>(mutating:data).pointee._token.pointer!
        return UnsafePointer<CLong>(ptr).pointee;
    }
}


fileprivate func computeMetadataBoundsFromSuperclass(_ description: UnsafePointer<ClassDescriptor>, _ storedBounds: inout StoredClassMetadataBounds) -> ClassMetadataBounds {
    var bounds: ClassMetadataBounds;
    if let superRef = ClassDescriptor.getResilientSuperclass(description) {
        bounds = computeMetadataBoundsForSuperclass(OpaquePointer(superRef), description.pointee.resilientSuperclassReferenceKind) ?? ClassMetadataBounds.forSwiftRootClass();
    } else {
        bounds = ClassMetadataBounds.forSwiftRootClass();
    }
    bounds.adjustForSubclass(description.pointee.areImmediateMembersNegative,
                             description.pointee.numImmediateMembers);
    storedBounds.initialize(bounds);
    return bounds;
}

fileprivate func computeMetadataBoundsForSuperclass(_ ref: OpaquePointer, _ refKind: TypeReferenceKind) -> ClassMetadataBounds? {
    switch (refKind) {
    case .IndirectTypeDescriptor, .DirectTypeDescriptor:
        let description = UnsafePointer<ClassDescriptor>(ref);
        return Optional(ClassDescriptor.getMetadataBounds(description));
//    case .DirectObjCClassName: // to do
//    case .IndirectObjCClass: // to do
    default:
        return nil;
    }
}
