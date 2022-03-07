## Example

```swift
class Test<T> {
  var val: T?;
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

```

## Author

dondong, the-last-choice@qq.com

## License

DDSwiftRuntime is available under the MIT license. See the LICENSE file for more info.
