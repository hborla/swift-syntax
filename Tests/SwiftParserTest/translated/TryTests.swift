//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

// This test file has been translated from swift/test/Parse/try.swift

import XCTest

final class TryTests: XCTestCase {
  func testTry1() {
    AssertParse(
      """
      // Intentionally has lower precedence than assignments and ?:
      infix operator %%%% : LowPrecedence
      precedencegroup LowPrecedence {
        associativity: none
        lowerThan: AssignmentPrecedence
      }
      func %%%%<T, U>(x: T, y: U) -> Int { return 0 }
      """
    )
  }

  func testTry2() {
    AssertParse(
      """
      // Intentionally has lower precedence between assignments and ?:
      infix operator %%% : MiddlingPrecedence
      precedencegroup MiddlingPrecedence {
        associativity: none
        higherThan: AssignmentPrecedence
        lowerThan: TernaryPrecedence
      }
      func %%%<T, U>(x: T, y: U) -> Int { return 1 }
      """
    )
  }

  func testTry3() {
    AssertParse(
      """
      func foo() throws -> Int { return 0 }
      func bar() throws -> Int { return 0 }
      """
    )
  }

  func testTry4() {
    AssertParse(
      """
      var x = try foo() + bar()
      x = try foo() + bar()
      x += try foo() + bar()
      x += try foo() %%%% bar() 
      x += try foo() %%% bar()
      x = foo() + try bar()
      """
    )
  }

  func testTry5() {
    AssertParse(
      """
      var y = true ? try foo() : try bar() + 0
      var z = true ? try foo() : try bar() %%% 0
      """
    )
  }

  func testTry6() {
    AssertParse(
      """
      var a = try! foo() + bar()
      a = try! foo() + bar()
      a += try! foo() + bar()
      a += try! foo() %%%% bar() 
      a += try! foo() %%% bar()
      a = foo() + try! bar()
      """
    )
  }

  func testTry7() {
    AssertParse(
      """
      var b = true ? try! foo() : try! bar() + 0
      var c = true ? try! foo() : try! bar() %%% 0
      """
    )
  }

  func testTry8() {
    AssertParse(
      """
      infix operator ?+= : AssignmentPrecedence
      func ?+=(lhs: inout Int?, rhs: Int?) {
        lhs = lhs! + rhs!
      }
      """
    )
  }

  func testTry9() {
    AssertParse(
      """
      var i = try? foo() + bar()
      let _: Double = i 
      i = try? foo() + bar()
      i ?+= try? foo() + bar()
      i ?+= try? foo() %%%% bar() 
      i ?+= try? foo() %%% bar()
      _ = foo() == try? bar() 
      _ = (try? foo()) == bar() 
      _ = foo() == (try? bar()) 
      _ = (try? foo()) == (try? bar())
      """
    )
  }

  func testTry10() {
    AssertParse(
      """
      let j = true ? try? foo() : try? bar() + 0
      let k = true ? try? foo() : try? bar() %%% 0
      """
    )
  }

  func testTry11() {
    AssertParse(
      """
      1️⃣try let singleLet = try foo()
      """,
      diagnostics: [
        DiagnosticSpec(message: "'try' must be placed on the initial value expression", fixIts: ["remove redundant 'try'"]),
      ], fixedSource: "let singleLet = try foo()"
    )
  }

  func testTry11a() {
    AssertParse(
      """
      1️⃣try let singleLet = foo()
      """,
      diagnostics: [
        DiagnosticSpec(message: "'try' must be placed on the initial value expression", fixIts: ["move 'try' after '='"]),
      ], fixedSource: "let singleLet = try foo()"
    )
  }

  func testTry11b() {
    AssertParse(
      """
      1️⃣try var singleVar = foo()
      """,
      diagnostics: [
        DiagnosticSpec(message: "'try' must be placed on the initial value expression", fixIts: ["move 'try' after '='"]),
      ], fixedSource: "var singleVar = try foo()"
    )
  }

  func testTry11c() {
    AssertParse(
      """
      1️⃣try let uninit: Int
      """,
      diagnostics: [
        DiagnosticSpec(message: "'try' must be placed on the initial value expression", fixIts: []),
      ]
    )
  }

  func testTry11d() {
    AssertParse(
      """
      1️⃣try let (destructure1, destructure2) = (foo(), bar())
      """,
      diagnostics: [
        DiagnosticSpec(message: "'try' must be placed on the initial value expression", fixIts: ["move 'try' after '='"]),
      ], fixedSource: "let (destructure1, destructure2) = try (foo(), bar())"
    )
  }

  func testTry11e() {
    AssertParse(
      """
      1️⃣try let multi1 = foo(), multi2 = bar()
      """,
      diagnostics: [
        DiagnosticSpec(message: "'try' must be placed on the initial value expression", fixIts: ["move 'try' after '='"]),
      ], fixedSource: "let multi1 = try foo(), multi2 = try bar()"
    )
  }

  func testTry11f() {
    AssertParse(
      """
      class TryDecl {
        1️⃣try let singleLet = foo()
      }
      """,
      diagnostics: [
        DiagnosticSpec(message: "'try' must be placed on the initial value expression", fixIts: ["move 'try' after '='"]),
      ], fixedSource: """
      class TryDecl {
        let singleLet = try foo()
      }
      """
    )
  }

  func testTry11g() {
    AssertParse(
      """
      class TryDecl {
        1️⃣try var singleVar = foo()
      }
      """,
      diagnostics: [
        DiagnosticSpec(message: "'try' must be placed on the initial value expression", fixIts: ["move 'try' after '='"]),
      ], fixedSource: """
      class TryDecl {
        var singleVar = try foo()
      }
      """
    )
  }

  func testTry11h() {
    AssertParse(
      """
      try1️⃣
      func method() {}
      """,
      diagnostics: [
        DiagnosticSpec(message: "expected expression after 'try'"),
      ]
    )
  }

  func testTry11i() {
    AssertParse(
      """
      1️⃣try func method() {}
      """,
      diagnostics: [
        DiagnosticSpec(message: "'try' cannot be used with 'func'"),
      ]
    )
  }

  func testTry12a() {
    AssertParse(
      """
      1️⃣try while true {
        2️⃣try break
      }
      """,
      diagnostics: [
        DiagnosticSpec(locationMarker: "1️⃣", message: "'try' cannot be used with 'while'"),
        DiagnosticSpec(locationMarker: "2️⃣", message: "'try' cannot be used with 'break'"),
      ]
    )
  }

  func testTry12b() {
    AssertParse(
      """
      1️⃣try throw 2️⃣
      """,
      diagnostics: [
        DiagnosticSpec(locationMarker: "1️⃣", message: "'try' must be placed on the thrown expression", fixIts: ["move 'try' after 'throw'"]),
        DiagnosticSpec(locationMarker: "2️⃣", message: "expected expression after 'try'", fixIts: ["insert expression"]),
      ], fixedSource: "throw try <#expression#>"
    )
  }

  func testTry12c() {
    AssertParse(
      """
      1️⃣try return
      """,
      diagnostics: [
        DiagnosticSpec(message: "'try' cannot be used with 'return'"),
      ]
    )
  }

  func testTry12d() {
    AssertParse(
      """
      1️⃣try throw foo()
      """,
      diagnostics: [
        DiagnosticSpec(message: "'try' must be placed on the thrown expression", fixIts: ["move 'try' after 'throw'"]),
      ], fixedSource: "throw try foo()"
    )
  }

  func testTry12e() {
    AssertParse(
      """
      1️⃣try return foo()
      """,
      diagnostics: [
        DiagnosticSpec(message: "'try' must be placed on the returned expression", fixIts: ["move 'try' after 'return'"]),
      ], fixedSource: "return try foo()"
    )
  }

  func testTry13() {
    AssertParse(
      #"""
      // Test operators.
      func *(a : String, b : String) throws -> Int { return 42 }
      let _ = "foo"
              *  
              "bar"
      let _ = try! "foo"*"bar"
      let _ = try? "foo"*"bar"
      let _ = (try? "foo"*"bar") ?? 0
      """#
    )
  }

  func testTry14() {
    AssertParse(
      """
      // <rdar://problem/21414023> Assertion failure when compiling function that takes throwing functions and rethrows
      func rethrowsDispatchError(handleError: ((Error) throws -> ()), body: () throws -> ()) rethrows {
        do {
          body()   
        } catch {
        }
      }
      """
    )
  }

  func testTry15() {
    AssertParse(
      """
      // <rdar://problem/21432429> Calling rethrows from rethrows crashes Swift compiler
      struct r21432429 {
        func x(_ f: () throws -> ()) rethrows {}
        func y(_ f: () throws -> ()) rethrows {
          x(f)  
        }
      }
      """
    )
  }

  func testTry16() {
    AssertParse(
      """
      // <rdar://problem/21427855> Swift 2: Omitting try from call to throwing closure in rethrowing function crashes compiler
      func callThrowingClosureWithoutTry(closure: (Int) throws -> Int) rethrows {
        closure(0)  
      }
      """
    )
  }

  func testTry17() {
    AssertParse(
      """
      func producesOptional() throws -> Int? { return nil }
      let _: String = try? producesOptional()
      """
    )
  }

  func testTry18() {
    AssertParse(
      """
      let _ = (try? foo())!!
      """
    )
  }

  func testTry19() {
    AssertParse(
      """
      func producesDoubleOptional() throws -> Int?? { return 3 }
      let _: String = try? producesDoubleOptional()
      """
    )
  }

  func testTry20() {
    AssertParse(
      """
      func maybeThrow() throws {}
      try maybeThrow() // okay
      try! maybeThrow() // okay
      try? maybeThrow() // okay since return type of maybeThrow is Void
      _ = try? maybeThrow() // okay
      """
    )
  }

  func testTry21() {
    AssertParse(
      """
      let _: () -> Void = { try! maybeThrow() } // okay
      let _: () -> Void = { try? maybeThrow() } // okay since return type of maybeThrow is Void
      """
    )
  }

  func testTry22() {
    AssertParse(
      """
      if try? maybeThrow() { 
      }
      let _: Int = try? foo()
      """
    )
  }

  func testTry23() {
    AssertParse(
      """
      class X {}
      func test(_: X) {}
      func producesObject() throws -> AnyObject { return X() }
      test(try producesObject())
      """
    )
  }

  func testTry24() {
    AssertParse(
      #"""
      _ = "a\(try maybeThrow())b"
      _ = try "a\(maybeThrow())b"
      _ = "a\(maybeThrow())"
      """#
    )
  }

  func testTry25() {
    AssertParse(
      """
      extension DefaultStringInterpolation {
        mutating func appendInterpolation() throws {}
      }
      """
    )
  }

  func testTry26() {
    AssertParse(
      #"""
      _ = try "a\()b"
      _ = "a\()b" 
      _ = try "\() \(1)"
      """#
    )
  }

  func testTry27() {
    AssertParse(
      """
      func testGenericOptionalTry<T>(_ call: () throws -> T ) {
        let _: String = try? call() 
      }
      """
    )
  }

  func testTry28() {
    AssertParse(
      """
      func genericOptionalTry<T>(_ call: () throws -> T ) -> T? {
        let x = try? call() // no error expected
        return x
      }
      """
    )
  }

  func testTry29() {
    AssertParse(
      """
      // Test with a non-optional type
      let _: String = genericOptionalTry({ () throws -> Int in return 3 })
      """
    )
  }

  func testTry30() {
    AssertParse(
      """
      // Test with an optional type
      let _: String = genericOptionalTry({ () throws -> Int? in return nil })
      """
    )
  }

  func testTry31() {
    AssertParse(
      """
      func produceAny() throws -> Any {
        return 3
      }
      """
    )
  }

  func testTry32() {
    AssertParse(
      """
      let _: Int? = try? produceAny() as? Int 
      let _: Int?? = (try? produceAny()) as? Int // good
      let _: String = try? produceAny() as? Int 
      let _: String = (try? produceAny()) as? Int
      """
    )
  }

  func testTry33() {
    AssertParse(
      """
      struct ThingProducer {
        func produceInt() throws -> Int { return 3 }
        func produceIntNoThrowing() -> Int { return 3 }
        func produceAny() throws -> Any { return 3 }
        func produceOptionalAny() throws -> Any? { return 3 }
        func produceDoubleOptionalInt() throws -> Int?? { return 3 }
      }
      """
    )
  }

  func testTry34() {
    AssertParse(
      """
      let optProducer: ThingProducer? = ThingProducer()
      let _: Int? = try? optProducer?.produceInt() 
      let _: Int = try? optProducer?.produceInt() 
      let _: String = try? optProducer?.produceInt() 
      let _: Int?? = try? optProducer?.produceInt() // good
      """
    )
  }

  func testTry35() {
    AssertParse(
      """
      let _: Int? = try? optProducer?.produceIntNoThrowing() 
      let _: Int?? = try? optProducer?.produceIntNoThrowing()
      """
    )
  }

  func testTry36() {
    AssertParse(
      """
      let _: Int? = (try? optProducer?.produceAny()) as? Int // good
      let _: Int? = try? optProducer?.produceAny() as? Int 
      let _: Int?? = try? optProducer?.produceAny() as? Int // good
      let _: String = try? optProducer?.produceAny() as? Int
      """
    )
  }

  func testTry37() {
    AssertParse(
      """
      let _: String = try? optProducer?.produceDoubleOptionalInt()
      """
    )
  }

  func testTry38() {
    AssertParse(
      """
      let producer = ThingProducer()
      """
    )
  }

  func testTry39() {
    AssertParse(
      """
      let _: Int = try? producer.produceDoubleOptionalInt() 
      let _: Int? = try? producer.produceDoubleOptionalInt() 
      let _: Int?? = try? producer.produceDoubleOptionalInt() 
      let _: Int??? = try? producer.produceDoubleOptionalInt() // good
      let _: String = try? producer.produceDoubleOptionalInt()
      """
    )
  }

  func testTry40() {
    AssertParse(
      """
      // rdar://problem/46742002
      protocol Dummy : class {}
      """
    )
  }

  func testTry41() {
    AssertParse(
      """
      class F<T> {
        func wait() throws -> T { fatalError() }
      }
      """
    )
  }

  func testTry42() {
    AssertParse(
      """
      func bar(_ a: F<Dummy>, _ b: F<Dummy>) {
        _ = (try? a.wait()) === (try? b.wait())
      }
      """
    )
  }
}
