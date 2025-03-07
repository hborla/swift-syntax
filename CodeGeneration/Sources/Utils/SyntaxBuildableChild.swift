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

import SwiftSyntax
import SwiftSyntaxBuilder
import SyntaxSupport

/// Extension to the `Child` type to provide functionality specific to
/// SwiftSyntaxBuilder.
public extension Child {
  /// The type of this child, represented by a `SyntaxBuildableType`, which can
  /// be used to create the corresponding `Buildable` and `ExpressibleAs` types.
  var type: SyntaxBuildableType {
    SyntaxBuildableType(
      syntaxKind: syntaxKind,
      isOptional: isOptional
    )
  }

  var parameterBaseType: String {
    if !self.nodeChoices.isEmpty {
      return self.name
    } else {
      return type.parameterBaseType
    }
  }

  var parameterType: Type {
    return self.type.optionalWrapped(type: SimpleTypeIdentifier(name: .identifier(parameterBaseType)))
  }

  /// If the child node has documentation associated with it, return it as single
  /// line string. Otherwise return an empty string.
  var documentation: String {
    flattened(indentedDocumentation: description ?? "")
  }

  /// If this node is a token that can't contain arbitrary text, generate a Swift
  /// `assert` statement that verifies the variable with name var_name and of type
  /// `TokenSyntax` contains one of the supported text options. Otherwise return `nil`.
  func generateAssertStmtTextChoices(varName: String) -> FunctionCallExpr? {
    guard type.isToken else {
      return nil
    }

    let choices: [String]
    if !textChoices.isEmpty {
      choices = textChoices
    } else if tokenCanContainArbitraryText {
      // Don't generate an assert statement if token can contain arbitrary text.
      return nil
    } else if !tokenChoices.isEmpty {
      choices = tokenChoices.compactMap(\.text)
    } else {
      return nil
    }

    var assertChoices: [Expr] = []
    if type.isOptional {
      assertChoices.append(Expr(SequenceExpr {
        IdentifierExpr(identifier: .identifier(varName))
        BinaryOperatorExpr(text: "==")
        NilLiteralExpr()
      }))
    }
    for textChoice in choices {
      assertChoices.append(Expr(SequenceExpr {
        MemberAccessExpr(base: type.forceUnwrappedIfNeeded(expr: IdentifierExpr(identifier: .identifier(varName))), name: "text")
        BinaryOperatorExpr(text: "==")
        StringLiteralExpr(content: textChoice)
      }))
    }
    let disjunction = ExprList(assertChoices.flatMap { [$0, Expr(BinaryOperatorExpr(text: "||"))] }.dropLast())
    return FunctionCallExpr(callee: "assert") {
      TupleExprElement(expression: SequenceExpr(elements: disjunction))
    }
  }
}
