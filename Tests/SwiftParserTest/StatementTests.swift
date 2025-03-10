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

@_spi(RawSyntax) import SwiftSyntax
@_spi(RawSyntax) import SwiftParser
import XCTest

final class StatementTests: XCTestCase {
  func testIf() {
    AssertParse("""
                if let baz {}
                """,
                substructure: Syntax(IfStmtSyntax(ifKeyword: .ifKeyword(),
                                                  conditions: ConditionElementListSyntax([
                                                    ConditionElementSyntax(condition: .init(OptionalBindingConditionSyntax(
                                                      letOrVarKeyword: .letKeyword(),
                                                      pattern: PatternSyntax(IdentifierPatternSyntax(identifier: .identifier("baz"))),
                                                      typeAnnotation: nil,
                                                      initializer: nil)), trailingComma: nil)
                                                  ]),
                                                  body: .init(leftBrace: .leftBraceToken(),
                                                              statements: .init([]),
                                                              rightBrace: .rightBraceToken()),
                                                  elseKeyword: nil, elseBody: nil)))

    AssertParse("""
                if let self = self {}
                """,
                substructure: Syntax(IfStmtSyntax(ifKeyword: .ifKeyword(),
                                                  conditions: ConditionElementListSyntax([
                                                    ConditionElementSyntax(condition: .init(OptionalBindingConditionSyntax(
                                                      letOrVarKeyword: .letKeyword(),
                                                      pattern: PatternSyntax(IdentifierPatternSyntax(identifier: .selfKeyword())),
                                                      typeAnnotation: nil,
                                                      initializer: InitializerClauseSyntax(equal: .equalToken(), value: ExprSyntax(IdentifierExprSyntax(identifier: .selfKeyword(), declNameArguments: nil))))), trailingComma: nil)
                                                  ]),
                                                  body: .init(leftBrace: .leftBraceToken(),
                                                              statements: .init([]),
                                                              rightBrace: .rightBraceToken()),
                                                  elseKeyword: nil, elseBody: nil)))

    AssertParse("if let x { }")

    AssertParse(
      """
      if case1️⃣* ! = x {
        bar()
      }
      """,
      diagnostics: [
        DiagnosticSpec(message: "expected expression, '=', and expression in pattern matching"),
        DiagnosticSpec(message: "unexpected code '* ! = x' in 'if' statement"),
      ]
    )

    AssertParse(
      """
      if includeSavedHints { a = a.flatMap{ $0 } ?? nil }
      """)
  }

  func testNestedIfs() {
    let nest = 22
    var source = "func nestThoseIfs() {\n"
    for index in (0...nest) {
        let indent = String(repeating: "    ", count: index + 1)
        source += indent + "if false != true {\n"
        source += indent + "   print(\"\\(i)\")\n"
    }

    for index in (0...nest).reversed() {
        let indent = String(repeating: "    ", count: index + 1)
        source += indent + "}\n"
    }
    source += "}"
    AssertParse(source)
  }

  func testDo() {
    AssertParse(
       """
       do {

       }
       """
    )
  }

  func testDoCatch() {
    AssertParse(
       """
       do {

       } catch {

       }
       """
    )

    AssertParse(
      """
      do {}
      catch where (error as NSError) == NSError() {}
      """)
  }

  func testReturn() {
    AssertParse("return actor", { StmtSyntax.parse(from: &$0) })

    AssertParse(
      "{ 1️⃣return 0 }",
      { ExprSyntax.parse(from: &$0) },
      substructure: Syntax(ReturnStmtSyntax(returnKeyword: .returnKeyword(),
                                            expression: ExprSyntax(IntegerLiteralExprSyntax(digits: .integerLiteral("0"))))),
      substructureAfterMarker: "1️⃣"
    )

    AssertParse("return")

    AssertParse(
       #"""
       return "assert(\(assertChoices.joined(separator: " || ")))"
       """#
    )

    AssertParse("return true ? nil : nil")

    AssertParse(
      """
      switch command {
      case .start:
        break

      case .stop:
        return

      default:
        break
      }
      """
    )
  }

  func testSwitch() {
    AssertParse(
      """
      switch x {
      case .A, .B:
        break
      }
      """
    )

    AssertParse(
      """
      switch 0 {
      @$dollar case _:
        break
      }
      """
    )

    AssertParse(
      """
      switch x {
      case .A:
        break
      case .B:
        break
      #if NEVER
      #elseif ENABLE_C
      case .C:
        break
      #endif
      }
      """
    )
  }

  func testCStyleForLoop() {
    AssertParse(
      """
      1️⃣for let x = 0; x < 10; x += 1, y += 1 {
      }
      """,
      diagnostics: [
        DiagnosticSpec(message: "C-style for statement has been removed in Swift 3", highlight: "let x = 0; x < 10; x += 1, y += 1 ")
      ]
    )
  }

  func testTopLevelCaseRecovery() {
    AssertParse(
      "/*#-editable-code Swift Platground editable area*/1️⃣default/*#-end-editable-code*/",
      diagnostics: [
        DiagnosticSpec(message: "'default' label can only appear inside a 'switch' statement")
      ]
    )

    AssertParse(
      "1️⃣case:",
      diagnostics: [
        DiagnosticSpec(message: "'case' can only appear inside a 'switch' statement or 'enum' declaration")
      ])

    AssertParse(
      #"""
      1️⃣case: { ("Hello World") }
      """#,
      diagnostics: [
        DiagnosticSpec(message: #"'case' can only appear inside a 'switch' statement or 'enum' declaration"#)
      ]
    )
  }

  func testMissingIfClauseIntroducer() {
    AssertParse("if _ = 42 {}")
  }

  func testAttributesOnStatements() {
    AssertParse(
      """
      func test1() {
        1️⃣@s return
      }
      func test2() {
        2️⃣@unknown return
      }
      """,
      diagnostics: [
        DiagnosticSpec(locationMarker: "1️⃣", message: "unexpected code '@s return' in function"),
        DiagnosticSpec(locationMarker: "2️⃣", message: "unexpected code '@unknown return' in function")
      ]
    )
  }

  func testBogusSwitchStatement() {
    AssertParse(
      """
      switch x {
        1️⃣foo()
      #if true
        2️⃣bar()
      #endif
        case .A, .B:
          break
      }
      """,
      diagnostics: [
        DiagnosticSpec(locationMarker: "1️⃣", message: "unexpected code 'foo()' before conditional compilation clause"),
        DiagnosticSpec(locationMarker: "2️⃣", message: "all statements inside a switch must be covered by a 'case' or 'default' label"),
      ]
    )

    AssertParse(
      """
      switch x {
      1️⃣print()
      #if ENABLE_C
      case .NOT_EXIST:
        break
      case .C:
        break
      #endif
      case .A, .B:
        break
      }
      """,
      diagnostics: [
        DiagnosticSpec(message: "unexpected code 'print()' before conditional compilation clause")
      ]
    )
  }

  func testBogusLineLabel() {
    AssertParse(
      "LABEL1️⃣:",
      diagnostics: [
        DiagnosticSpec(message: "extraneous code ':' at top level")
      ]
    )
  }

  func testIfHasSymbol() {
    AssertParse(
      """
      if #_hasSymbol(foo) {}
      """
    )
    
    AssertParse(
      """
      if #_hasSymbol(foo as () -> ()) {}
      """
    )
  }

  func testIdentifierPattern() {
    AssertParse(
      "switch x { case let .y(z): break }",
      substructure: Syntax(IdentifierPatternSyntax(
        identifier: .identifier("z")
      ))
    )
  }

  func testCaseContext() {
    AssertParse(
      """
      graphQLMap["clientMutationId"] as? 1️⃣Swift.Optional<String?> ?? Swift.Optional<String?>.none
      """,
    substructure: Syntax(MemberTypeIdentifierSyntax(
      baseType: TypeSyntax(SimpleTypeIdentifierSyntax(
        name: .identifier("Swift"),
        genericArgumentClause: nil)),
      period: .periodToken(),
      name: .identifier("Optional"),
      genericArgumentClause: GenericArgumentClauseSyntax(
        leftAngleBracket: .leftAngleToken(),
        arguments: GenericArgumentListSyntax([
          GenericArgumentSyntax(
            argumentType: TypeSyntax(OptionalTypeSyntax(
              wrappedType: TypeSyntax(SimpleTypeIdentifierSyntax(
                name: .identifier("String"),
                genericArgumentClause: nil)),
              questionMark: .postfixQuestionMarkToken())),
            trailingComma: nil)
        ]),
        rightAngleBracket: .rightAngleToken()))),
    substructureAfterMarker: "1️⃣")

    AssertParse(
      """
      if case 1️⃣Optional<Any>.none = object["anyCol"] { }
      """,
      substructure: Syntax(SpecializeExprSyntax(
        expression: ExprSyntax(IdentifierExprSyntax(
          identifier: .identifier("Optional"), declNameArguments: nil)),
        genericArgumentClause: GenericArgumentClauseSyntax(
          leftAngleBracket: .leftAngleToken(), arguments: GenericArgumentListSyntax([
        GenericArgumentSyntax(
          argumentType: TypeSyntax(SimpleTypeIdentifierSyntax(
            name: .anyKeyword(), genericArgumentClause: nil)),
          trailingComma: nil)
      ]), rightAngleBracket: .rightAngleToken()))),
      substructureAfterMarker: "1️⃣")
  }

  func testHangingYieldArgument() {
    AssertParse(
      """
      1️⃣yield
      print("huh")
      """,
      substructure: Syntax(IdentifierExprSyntax(identifier: .identifier("yield"), declNameArguments: nil)),
    substructureAfterMarker: "1️⃣")
  }

  func testYield() {
    // Make sure these are always considered a yield statement
    AssertParse(
      """
      var x: Int {
        _read {
          1️⃣yield &x
        }
      }
      """,
      substructure: Syntax(YieldStmtSyntax(
        yieldKeyword: .contextualKeyword("yield"),
        yields: .init(InOutExprSyntax(
          ampersand: .prefixAmpersandToken(),
          expression: ExprSyntax(IdentifierExprSyntax(
            identifier: .identifier("x"),
            declNameArguments: nil)))))),
      substructureAfterMarker: "1️⃣")

    AssertParse(
      """
      @inlinable internal subscript(key: Key) -> Value? {
        @inline(__always) get {
          return lookup(key)
        }
        @inline(__always) _modify {
          guard isNative else {
            let cocoa = asCocoa
            var native = _NativeDictionary<Key, Value>(
              cocoa, capacity: cocoa.count + 1)
            self = .init(native: native)
            1️⃣yield &native[key, isUnique: true]
            return
          }
          let isUnique = isUniquelyReferenced()
          yield &asNative[key, isUnique: isUnique]
        }
      }
      """,
      substructure: Syntax(YieldStmtSyntax(
        yieldKeyword: .contextualKeyword("yield"),
        yields: .init(InOutExprSyntax(
          ampersand: .prefixAmpersandToken(),
          expression: ExprSyntax(SubscriptExprSyntax(
            calledExpression: ExprSyntax(IdentifierExprSyntax(identifier: .identifier("native"), declNameArguments: nil)),
            leftBracket: .leftSquareBracketToken(),
            argumentList: TupleExprElementListSyntax([
              TupleExprElementSyntax(
                label: nil,
                colon: nil,
                expression: ExprSyntax(IdentifierExprSyntax(identifier: .identifier("key"), declNameArguments: nil)),
                trailingComma: .commaToken()),
              TupleExprElementSyntax(
                label: .identifier("isUnique"),
                colon: .colonToken(),
                expression: ExprSyntax(BooleanLiteralExprSyntax(booleanLiteral: .trueKeyword())),
                trailingComma: nil),
            ]),
            rightBracket: .rightSquareBracketToken(),
            trailingClosure: nil,
            additionalTrailingClosures: nil)))))),
      substructureAfterMarker: "1️⃣")

    // Make sure these are not.
    AssertParse(
      """
      var x: Int {
        _read {
          1️⃣yield ()
        }
      }
      """,
      substructure: Syntax(FunctionCallExprSyntax(
        calledExpression: ExprSyntax(IdentifierExprSyntax(
          identifier: .identifier("yield"),
          declNameArguments: nil)),
        leftParen: .leftParenToken(),
        argumentList: TupleExprElementListSyntax([]),
        rightParen: .rightParenToken(),
        trailingClosure: nil,
        additionalTrailingClosures: nil)),
    substructureAfterMarker: "1️⃣")

    AssertParse(
      """
      var x: Int {
        get {
          1️⃣yield ()
        }
      }
      """,
      substructure: Syntax(FunctionCallExprSyntax(
        calledExpression: ExprSyntax(IdentifierExprSyntax(
          identifier: .identifier("yield"),
          declNameArguments: nil)),
        leftParen: .leftParenToken(),
        argumentList: TupleExprElementListSyntax([]),
        rightParen: .rightParenToken(),
        trailingClosure: nil,
        additionalTrailingClosures: nil)),
    substructureAfterMarker: "1️⃣")

    AssertParse(
      """
      yield([])
      """,
      substructure: Syntax(FunctionCallExprSyntax(
        calledExpression: ExprSyntax(IdentifierExprSyntax(
          identifier: .identifier("yield"),
          declNameArguments: nil)),
        leftParen: .leftParenToken(),
        argumentList: TupleExprElementListSyntax([
          TupleExprElementSyntax(
            label: nil,
            colon: nil,
            expression: ExprSyntax(ArrayExprSyntax(
              leftSquare: .leftSquareBracketToken(),
              elements: ArrayElementListSyntax([]),
              rightSquare: .rightSquareBracketToken())),
            trailingComma: nil),
        ]),
        rightParen: .rightParenToken(),
        trailingClosure: nil,
        additionalTrailingClosures: nil)))

    AssertParse(
      """
      func f() -> Int {
        1️⃣yield & 5
      }
      """,
      substructure: Syntax(SequenceExprSyntax(elements: ExprListSyntax([
        IdentifierExprSyntax(identifier: .identifier("yield"), declNameArguments: nil),
        BinaryOperatorExprSyntax(operatorToken: .spacedBinaryOperator("&")),
        IntegerLiteralExprSyntax(5)
      ]))),
      substructureAfterMarker: "1️⃣")

    AssertParse(
      """
      func f() -> Int {
        1️⃣yield&5
      }
      """,
      substructure: Syntax(SequenceExprSyntax(elements: ExprListSyntax([
        IdentifierExprSyntax(identifier: .identifier("yield"), declNameArguments: nil),
        BinaryOperatorExprSyntax(operatorToken: .unspacedBinaryOperator("&")),
        IntegerLiteralExprSyntax(5)
      ]))),
      substructureAfterMarker: "1️⃣")
  }

  func testDefaultIdentIdentifierInReturnStmt() {
    AssertParse("return FileManager.default")
  }
  
  func testDefaultAsIdentifierInSubscript() {
    AssertParse(
         """
         data[position, default: 0]
         """,
         substructure: Syntax(ExprSyntax(SubscriptExprSyntax(
          calledExpression: ExprSyntax(IdentifierExprSyntax(identifier: .identifier("data"), declNameArguments: nil)),
          leftBracket: .leftSquareBracketToken(),
          argumentList: TupleExprElementListSyntax([
            TupleExprElementSyntax(
              label: nil,
              colon: nil,
              expression: ExprSyntax(IdentifierExprSyntax(identifier: .identifier("position"), declNameArguments: nil)),
              trailingComma: .commaToken()),
            TupleExprElementSyntax(
              label: .identifier("default"),
              colon: .colonToken(),
              expression: ExprSyntax(IntegerLiteralExprSyntax(0)),
              trailingComma: nil),
          ]),
          rightBracket: .rightSquareBracketToken(),
          trailingClosure: nil,
          additionalTrailingClosures: nil)))
    )
  }
}
