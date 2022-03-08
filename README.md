## Example

```swift
protocol Myprotocol {
    func myTest();
}
class Test<T> : Myprotocol {
  var val: T?;
  func myTest() {
  }
}

if let metadata = DDSwiftRuntime.getSwiftClassMetadata(Test<Int>.self) {
  if let args = metadata.pointee.genericArgs {
    for i in 0..<args.count {
      print(args[i].pointee.kind);
    }
  }
  let vtable = metadata.pointee.vtable;
  for i in 0..<vtable.count {
    print(vtable[i].functionName);
  }
}

let protocols = DDSwiftRuntime.getSwiftProtocolConformances(Test<Int>.self);
for i in 0..<protocols.count {
  let p = ProtocolConformanceDescriptor.getProtocolDescriptor(protocols[i]);
  print(i, ProtocolDescriptor.getName(p));
  if let table = ProtocolConformanceDescriptor.getWitnessTable(protocols[i]) {
    for j in 0..<table.count {
      print(table[j].functionName);
    }
  }
}

```

## Author

dondong, the-last-choice@qq.com

## License

DDSwiftRuntime is available under the MIT license. See the LICENSE file for more info.
