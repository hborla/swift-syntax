import hashlib
import textwrap
from . import Classification  # noqa: I201
from . import Token
from .AttributeNodes import ATTRIBUTE_NODES  # noqa: I201
from .AttributeKinds import DECL_ATTR_KINDS, DECL_MODIFIER_KINDS, \
    verify_attribute_serialization_codes
from .AvailabilityNodes import AVAILABILITY_NODES  # noqa: I201
from .CommonNodes import COMMON_NODES  # noqa: I201
from .DeclNodes import DECL_NODES  # noqa: I201
from .ExprNodes import EXPR_NODES  # noqa: I201
from .GenericNodes import GENERIC_NODES  # noqa: I201
from .PatternNodes import PATTERN_NODES  # noqa: I201
from .StmtNodes import STMT_NODES  # noqa: I201
from .Trivia import TRIVIAS  # noqa: I201
from .TypeNodes import TYPE_NODES  # noqa: I201
from .kinds import SYNTAX_BASE_KINDS  # noqa: I201


# Re-export global constants
SYNTAX_NODES = COMMON_NODES + EXPR_NODES + DECL_NODES + ATTRIBUTE_NODES + \
    STMT_NODES + GENERIC_NODES + TYPE_NODES + PATTERN_NODES + \
    AVAILABILITY_NODES
NON_BASE_SYNTAX_NODES = [node for node in SYNTAX_NODES if not node.is_base()]
SYNTAX_TOKENS = Token.SYNTAX_TOKENS
SYNTAX_TOKEN_MAP = Token.SYNTAX_TOKEN_MAP
SYNTAX_CLASSIFICATIONS = Classification.SYNTAX_CLASSIFICATIONS
TYPE_ATTR_KINDS = AttributeKinds.TYPE_ATTR_KINDS
DECL_ATTR_KINDS = AttributeKinds.DECL_ATTR_KINDS
DECL_MODIFIER_KINDS = AttributeKinds.DECL_MODIFIER_KINDS
DEPRECATED_MODIFIER_KINDS = AttributeKinds.DEPRECATED_MODIFIER_KINDS

verify_attribute_serialization_codes(DECL_ATTR_KINDS + DECL_MODIFIER_KINDS)

def make_missing_child(child):
    """
    Generates a C++ call to make the raw syntax for a given Child object.
    """
    if child.is_token():
        token = child.main_token()
        tok_kind = token.kind if token else "unknown"
        tok_text = token.text if token else ""
        return \
            'RawSyntax::missing(tok::%s, "%s", Arena)' % \
            (tok_kind, tok_text)
    else:
        missing_kind = "Unknown" if child.syntax_kind == "Syntax" \
                       else child.syntax_kind
        if child.node_choices:
            return make_missing_child(child.node_choices[0])
        return 'RawSyntax::missing(SyntaxKind::%s, Arena)' % missing_kind


def check_child_condition_raw(child):
    """
    Generates a C++ closure to check whether a given raw syntax node can
    satisfy the requirements of child.
    """
    result = '[](const RawSyntax *Raw) {\n'
    result += ' // check %s\n' % child.name
    if child.token_choices:
        result += 'if (!Raw->isToken()) return false;\n'
        result += 'auto TokKind = Raw->getTokenKind();\n'
        tok_checks = []
        for choice in child.token_choices:
            tok_checks.append("TokKind == tok::%s" % choice.kind)
        result += 'return %s;\n' % (' || '.join(tok_checks))
    elif child.text_choices:
        result += 'if (!Raw->isToken()) return false;\n'
        result += 'auto Text = Raw->getTokenText();\n'
        tok_checks = []
        for choice in child.text_choices:
            tok_checks.append('Text == "%s"' % choice)
        result += 'return %s;\n' % (' || '.join(tok_checks))
    elif child.node_choices:
        node_checks = []
        for choice in child.node_choices:
            node_checks.append(check_child_condition_raw(choice) + '(Raw)')
        result += 'return %s;\n' % ((' || ').join(node_checks))
    else:
        result += 'return %s::kindof(Raw->getKind());' % child.type_name
    result += '}'
    return result


def check_parsed_child_condition_raw(child):
    """
    Generates a C++ closure to check whether a given raw syntax node can
    satisfy the requirements of child.
    """
    result = '[](const ParsedRawSyntaxNode &Raw) {\n'
    result += ' // check %s\n' % child.name
    if child.is_optional:
        result += 'if (Raw.isNull()) return true;\n'
    if child.token_choices:
        result += 'if (!Raw.isToken()) return false;\n'
        result += 'auto TokKind = Raw.getTokenKind();\n'
        tok_checks = []
        for choice in child.token_choices:
            tok_checks.append("TokKind == tok::%s" % choice.kind)
        result += 'return %s;\n' % (' || '.join(tok_checks))
    elif child.text_choices:
        result += 'return Raw.isToken();\n'
    elif child.node_choices:
        node_checks = []
        for choice in child.node_choices:
            node_checks.append(
                check_parsed_child_condition_raw(choice) + '(Raw)')
        result += 'return %s;\n' % ((' || ').join(node_checks))
    else:
        result += 'return Parsed%s::kindof(Raw.getKind());' % child.type_name
    result += '}'
    return result


def make_missing_swift_child(child):
    """
    Generates a Swift call to make the raw syntax for a given Child object.
    """
    if child.is_token():
        token = child.main_token()
        tok_kind = token.swift_kind() if token else "unknown"
        if not token or not token.text:
            tok_kind += '("")'
        return f'RawSyntax.makeMissingToken(kind: TokenKind.{tok_kind}, ' + \
            'arena: arena)'
    else:
        if child.syntax_kind == "Syntax":
            missing_kind = "unknown"
        elif child.syntax_kind in SYNTAX_BASE_KINDS:
            missing_kind = f"missing{child.syntax_kind}"
        else:
            missing_kind = child.swift_syntax_kind
        return f'RawSyntax.makeEmptyLayout(kind: SyntaxKind.{missing_kind}, ' + \
            'arena: arena)'


def create_node_map():
    """
    Creates a lookup table to find nodes by their kind.
    """
    return {node.syntax_kind: node for node in SYNTAX_NODES}


def is_visitable(node):
    return not node.is_base()


def dedented_lines(description):
    """
    Each line of the provided string with leading whitespace stripped.
    """
    if not description:
        return []
    return textwrap.dedent(description).split('\n')


def calculate_node_hash():
    digest = hashlib.sha1()

    def _digest_syntax_node(node):
        # Hash into the syntax name
        digest.update(node.name.encode("utf-8"))
        for child in node.children:
            # Hash into the expected child syntax
            digest.update(child.syntax_kind.encode("utf-8"))
            # Hash into the child name
            digest.update(child.name.encode("utf-8"))
            # Hash into whether the child is optional
            digest.update(str(child.is_optional).encode("utf-8"))

    def _digest_syntax_token(token):
        # Hash into the token name
        digest.update(token.name.encode("utf-8"))

    def _digest_trivia(trivia):
        digest.update(trivia.name.encode("utf-8"))
        digest.update(str(trivia.characters).encode("utf-8"))

    for node in SYNTAX_NODES:
        _digest_syntax_node(node)
    for token in SYNTAX_TOKENS:
        _digest_syntax_token(token)
    for trivia in TRIVIAS:
        _digest_trivia(trivia)

    return digest.hexdigest()
