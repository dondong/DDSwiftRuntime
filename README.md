## Example

```swift
class Test<T> {
  var val: T?;
}

if let metadata = DDSwiftRuntime.getSwiftClass(Test<Int>.self) {
  if let params = metadata.pointee.genericParams {
    for i in 0..<params.count {
      print(params[i].pointee.kind);
    }
  }
  let virtualMethods = metadata.pointee.virtualMethods;
  for i in 0..<virtualMethods.count {
    print(virtualMethods[i].functionName);
  }
}

```

## Author

dondong, the-last-choice@qq.com

## License

DDSwiftRuntime is available under the MIT license. See the LICENSE file for more info.
