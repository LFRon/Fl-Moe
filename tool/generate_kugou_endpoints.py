#!/usr/bin/env python3
"""Translate the declarative KuGou Node endpoint subset into static Dart.

This tool is development-only. The generated application has no Python,
JavaScript, Node, reflection, or runtime interpreter dependency.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

from tree_sitter import Language, Node, Parser
import tree_sitter_javascript


class Unsupported(Exception):
    pass


class Translator:
    def __init__(self, source: bytes, module_name: str) -> None:
        self.source = source
        self.module_name = module_name
        self.parser = Parser(Language(tree_sitter_javascript.language()))

    def text(self, node: Node) -> str:
        return self.source[node.start_byte : node.end_byte].decode("utf-8")

    def field(self, node: Node, name: str) -> Node:
        child = node.child_by_field_name(name)
        if child is None:
            raise Unsupported(f"{node.type} has no {name}: {self.text(node)!r}")
        return child

    @staticmethod
    def dart_string(value: str) -> str:
        return json.dumps(value, ensure_ascii=False).replace("$", r"\$")

    def string_value(self, node: Node) -> str:
        raw = self.text(node)
        if node.type not in {"string", "string_fragment"}:
            raise Unsupported(f"not a string: {raw}")
        if node.type == "string_fragment":
            return raw
        if len(raw) < 2:
            return ""
        quote = raw[0]
        body = raw[1:-1]
        if quote == '"':
            return json.loads(raw)
        # Decode the common JavaScript single-quoted string escape subset.
        body = body.replace(r"\'", "'").replace(r'\"', '"')
        body = body.replace(r"\n", "\n").replace(r"\r", "\r").replace(r"\t", "\t")
        body = body.replace(r"\\", "\\")
        return body

    def parse(self) -> tuple[list[Node], Node]:
        tree = self.parser.parse(self.source)
        if tree.root_node.has_error:
            raise Unsupported("JavaScript parser reported an error")
        top_declarations: list[Node] = []
        exported: Node | None = None
        for child in tree.root_node.named_children:
            if child.type == "comment":
                continue
            if child.type == "lexical_declaration":
                if "require(" not in self.text(child):
                    top_declarations.append(child)
                continue
            if child.type != "expression_statement":
                continue
            expression = child.named_children[0] if child.named_children else None
            if expression is None or expression.type != "assignment_expression":
                continue
            left = self.field(expression, "left")
            if self.text(left) != "module.exports":
                continue
            right = self.field(expression, "right")
            if right.type != "arrow_function":
                raise Unsupported("module export is not an inline arrow function")
            exported = right
        if exported is None:
            raise Unsupported("module export function was not found")
        return top_declarations, exported

    def translate(self) -> str:
        top_declarations, function = self.parse()
        body = self.field(function, "body")
        if body.type != "statement_block":
            raise Unsupported("endpoint body is not a statement block")
        lines: list[str] = []
        for declaration in top_declarations:
            lines.extend(self.statement(declaration, 1))
        for statement in body.named_children:
            if statement.type == "comment":
                continue
            lines.extend(self.statement(statement, 1))
        route = "/" + self.module_name.replace("_", "/")
        name = "_generated" + "".join(part.title() for part in self.module_name.split("_"))
        content = [
            f"Future<KugouResponse<Object?>> {name}(",
            "  KugouEndpointContext context,",
            "  Map<String, Object?> input,",
            ") async {",
            *lines,
            "}",
        ]
        return route, name, "\n".join(content)

    def statement(self, node: Node, indent: int) -> list[str]:
        prefix = "  " * indent
        if node.type == "lexical_declaration":
            output: list[str] = []
            keyword = "var" if self.text(node).lstrip().startswith("let ") else "final"
            for declarator in [c for c in node.named_children if c.type == "variable_declarator"]:
                name_node = self.field(declarator, "name")
                if name_node.type != "identifier":
                    raise Unsupported("destructuring declaration")
                value_node = declarator.child_by_field_name("value")
                if value_node is None:
                    output.append(f"{prefix}{keyword} {self.text(name_node)} = null;")
                elif value_node.type in {"arrow_function", "function_expression"}:
                    raise Unsupported("local helper function")
                else:
                    output.append(
                        f"{prefix}{keyword} {self.text(name_node)} = {self.expression(value_node)};"
                    )
            return output
        if node.type == "expression_statement":
            expression = node.named_children[0]
            if expression.type != "assignment_expression":
                raise Unsupported(f"expression statement: {self.text(node)}")
            return [f"{prefix}{self.assignment(expression)};"]
        if node.type == "if_statement":
            condition = self.field(node, "condition")
            consequence = self.field(node, "consequence")
            output = [f"{prefix}if (jsTruthy({self.expression(condition)})) {{"]
            output.extend(self.statement_body(consequence, indent + 1))
            alternative = node.child_by_field_name("alternative")
            if alternative is None:
                output.append(f"{prefix}}}")
            else:
                output.append(f"{prefix}}} else {{")
                output.extend(self.statement_body(alternative, indent + 1))
                output.append(f"{prefix}}}")
            return output
        if node.type == "return_statement":
            if not node.named_children:
                return [f"{prefix}return;"]
            value = node.named_children[0]
            if value.type != "call_expression" or self.text(self.field(value, "function")) != "useAxios":
                raise Unsupported(f"non-request return: {self.text(value)[:80]}")
            arguments = self.field(value, "arguments").named_children
            if len(arguments) != 1 or arguments[0].type != "object":
                raise Unsupported("useAxios argument is not an object literal")
            request = self.request(arguments[0], indent)
            return [f"{prefix}return context.request(", *request, f"{prefix});"]
        if node.type == "statement_block":
            output: list[str] = []
            for child in node.named_children:
                if child.type != "comment":
                    output.extend(self.statement(child, indent))
            return output
        if node.type == "empty_statement":
            return []
        raise Unsupported(f"statement {node.type}: {self.text(node)[:100]}")

    def statement_body(self, node: Node, indent: int) -> list[str]:
        if node.type == "statement_block":
            output: list[str] = []
            for child in node.named_children:
                if child.type != "comment":
                    output.extend(self.statement(child, indent))
            return output
        return self.statement(node, indent)

    def assignment(self, node: Node) -> str:
        left = self.field(node, "left")
        right_node = self.field(node, "right")
        operator = self.source[left.end_byte : right_node.start_byte].decode("utf-8").strip()
        if operator != "=":
            raise Unsupported(f"assignment operator {operator}")
        right = self.expression(right_node)
        if left.type == "identifier":
            return f"{self.text(left)} = {right}"
        if left.type == "subscript_expression":
            target = self.expression(self.field(left, "object"))
            index = self.expression(self.field(left, "index"))
            return f"{target}[jsString({index})] = {right}"
        if left.type == "member_expression":
            target = self.expression(self.field(left, "object"))
            prop = self.text(self.field(left, "property"))
            return f"{target}[{self.dart_string(prop)}] = {right}"
        raise Unsupported(f"assignment target {left.type}")

    def request(self, node: Node, indent: int) -> list[str]:
        options = self.object_pairs(node)
        prefix = "  " * (indent + 1)
        output = [f"{prefix}KugouRequest("]
        path = options.get("url")
        if path is None:
            raise Unsupported("request has no URL")
        output.append(f"{prefix}  path: jsString({self.expression(path)}),")
        if "baseURL" in options:
            output.append(
                f"{prefix}  baseUri: Uri.parse(jsString({self.expression(options['baseURL'])})),"
            )
        if "method" in options:
            output.append(f"{prefix}  method: jsString({self.expression(options['method'])}),")
        if "params" in options:
            output.append(
                f"{prefix}  parameters: stringObjectMap({self.expression(options['params'])}),"
            )
        if "data" in options:
            output.append(f"{prefix}  data: {self.expression(options['data'])},")
        if "headers" in options:
            output.append(
                f"{prefix}  headers: stringObjectMap({self.expression(options['headers'])}),"
            )
        if "cookie" in options:
            output.append(
                f"{prefix}  cookies: stringStringMap({self.expression(options['cookie'])}),"
            )
        signature = options.get("encryptType")
        if signature is not None:
            signature_text = self.string_value(signature) if signature.type == "string" else ""
            if signature_text == "web":
                output.append(f"{prefix}  signatureType: KugouSignatureType.web,")
            elif signature_text == "register":
                output.append(f"{prefix}  signatureType: KugouSignatureType.register,")
        flags = {
            "encryptKey": "encryptKey",
            "clearDefaultParams": "clearDefaultParameters",
            "clearDefaultHeaders": "clearDefaultHeaders",
            "notSignature": "skipSignature",
            # NOTE: Upstream request.js only reads `notSignature`. `notSign`
            # is ignored by the reference implementation, so it must not
            # suppress the signature in generated Dart either.
        }
        for source_name, dart_name in flags.items():
            if source_name in options:
                output.append(
                    f"{prefix}  {dart_name}: jsTruthy({self.expression(options[source_name])}),"
                )
        response_type = options.get("responseType")
        if response_type is not None:
            value = self.string_value(response_type) if response_type.type == "string" else ""
            if value in {"arraybuffer", "bytes"}:
                output.append(f"{prefix}  responseType: KugouResponseType.bytes,")
            elif value == "text":
                output.append(f"{prefix}  responseType: KugouResponseType.text,")
        ip = options.get("realIP") or options.get("ip")
        if ip is not None:
            output.append(f"{prefix}  realIp: jsString({self.expression(ip)}),")
        output.append(f"{prefix}),")
        return output

    def object_pairs(self, node: Node) -> dict[str, Node]:
        result: dict[str, Node] = {}
        for child in node.named_children:
            if child.type == "comment":
                continue
            if child.type in {"shorthand_property_identifier", "shorthand_property_identifier_pattern"}:
                key = self.text(child)
                result[key] = child
                continue
            if child.type != "pair":
                raise Unsupported(f"request option {child.type}")
            key_node = self.field(child, "key")
            value_node = self.field(child, "value")
            if key_node.type in {"property_identifier", "identifier"}:
                key = self.text(key_node)
            elif key_node.type == "string":
                key = self.string_value(key_node)
            else:
                raise Unsupported("computed request option")
            result[key] = value_node
        return result

    def expression(self, node: Node) -> str:
        kind = node.type
        if kind == "identifier":
            value = self.text(node)
            constants = {
                "appid": "context.config.appId",
                "clientver": "context.config.clientVersion",
                "liteAppid": "3116",
                "liteClientver": "11440",
                "apiver": "KugouApiConfig.apiVersion",
                "srcappid": "KugouApiConfig.sourceAppId",
                "isLite": "context.config.isLite",
                "undefined": "null",
            }
            return constants.get(value, "input" if value == "params" else value)
        if kind == "member_expression":
            text = self.text(node)
            if text == "process.env.platform":
                return '(context.config.isLite ? "lite" : "")'
            if text == "process.env.CMT_VER":
                return "6"
        if kind in {"shorthand_property_identifier", "shorthand_property_identifier_pattern"}:
            value = self.text(node)
            constants = {
                "appid": "context.config.appId",
                "clientver": "context.config.clientVersion",
                "apiver": "KugouApiConfig.apiVersion",
                "srcappid": "KugouApiConfig.sourceAppId",
                "isLite": "context.config.isLite",
            }
            return constants.get(value, value)
        if kind in {"number", "true", "false", "null"}:
            return self.text(node)
        if kind == "string":
            return self.dart_string(self.string_value(node))
        if kind == "parenthesized_expression":
            children = [child for child in node.named_children if child.type != "comment"]
            if len(children) != 1:
                raise Unsupported("parenthesized expression")
            return f"({self.expression(children[0])})"
        if kind == "member_expression":
            path = self.parameter_path(node)
            if path is not None:
                if path == ["cookie"]:
                    return "context.session.cookies"
                if len(path) >= 2 and path[0] == "cookie":
                    return f"endpointCookie(context, input, {self.dart_string(path[1])})"
                if len(path) == 1:
                    return f"input[{self.dart_string(path[0])}]"
            target = self.expression(self.field(node, "object"))
            prop = self.text(self.field(node, "property"))
            if prop == "length":
                return f"jsLength({target})"
            if prop == "key":
                return f"({target}).key"
            if prop == "str":
                return f"({target}).ciphertext"
            return f"mapValue({target}, {self.dart_string(prop)})"
        if kind == "subscript_expression":
            target = self.expression(self.field(node, "object"))
            index = self.expression(self.field(node, "index"))
            return f"mapValue({target}, {index})"
        if kind == "object":
            items: list[str] = []
            for child in node.named_children:
                if child.type == "comment":
                    continue
                if child.type == "spread_element":
                    value = child.named_children[0]
                    items.append(f"...stringObjectMap({self.expression(value)})")
                    continue
                if child.type in {"shorthand_property_identifier", "shorthand_property_identifier_pattern"}:
                    name = self.text(child)
                    items.append(f"{self.dart_string(name)}: {self.expression(child)}")
                    continue
                if child.type != "pair":
                    raise Unsupported(f"object child {child.type}")
                key_node = self.field(child, "key")
                value_node = self.field(child, "value")
                if key_node.type in {"property_identifier", "identifier", "number"}:
                    key = self.text(key_node)
                    dart_key = self.dart_string(key)
                elif key_node.type == "string":
                    dart_key = self.dart_string(self.string_value(key_node))
                elif key_node.type == "computed_property_name":
                    dart_key = f"jsString({self.expression(key_node.named_children[0])})"
                else:
                    raise Unsupported(f"object key {key_node.type}")
                items.append(f"{dart_key}: {self.expression(value_node)}")
            if not items:
                return "<String, Object?>{}"
            return "<String, Object?>{" + ", ".join(items) + "}"
        if kind == "array":
            values = [self.expression(child) for child in node.named_children if child.type != "comment"]
            return "<Object?>[" + ", ".join(values) + "]"
        if kind == "binary_expression":
            left = self.expression(self.field(node, "left"))
            right = self.expression(self.field(node, "right"))
            operator = self.text(self.field(node, "operator"))
            if operator == "||":
                return f"jsOr({left}, {right})"
            if operator == "&&":
                return f"jsAnd({left}, {right})"
            if operator == "??":
                return f"({left} ?? {right})"
            if operator in {"===", "=="}:
                return f"({left} == {right})"
            if operator in {"!==", "!="}:
                return f"({left} != {right})"
            if operator == "+":
                return f"jsAdd({left}, {right})"
            if operator in {"-", "*", "/", "%"}:
                return f"(jsNumber({left}) {operator} jsNumber({right}))"
            if operator in {"<", ">", "<=", ">="}:
                return f"(jsNumber({left}) {operator} jsNumber({right}))"
            raise Unsupported(f"binary operator {operator}")
        if kind == "ternary_expression":
            condition = self.expression(self.field(node, "condition"))
            consequence = self.expression(self.field(node, "consequence"))
            alternative = self.expression(self.field(node, "alternative"))
            return f"(jsTruthy({condition}) ? {consequence} : {alternative})"
        if kind == "unary_expression":
            operator = self.text(self.field(node, "operator"))
            argument = self.expression(self.field(node, "argument"))
            if operator == "!":
                return f"!jsTruthy({argument})"
            if operator in {"-", "+"}:
                return f"{operator}jsNumber({argument})"
            if operator == "typeof":
                return f"jsTypeOf({argument})"
            raise Unsupported(f"unary operator {operator}")
        if kind == "template_string":
            parts: list[str] = []
            for child in node.named_children:
                if child.type == "string_fragment":
                    parts.append(self.dart_string(self.text(child)))
                elif child.type == "template_substitution":
                    parts.append(f"jsString({self.expression(child.named_children[0])})")
            return " + ".join(parts) if parts else '""'
        if kind == "call_expression":
            return self.call(node)
        if kind == "new_expression":
            constructor = self.text(self.field(node, "constructor"))
            if constructor == "Date":
                return "DateTime.fromMillisecondsSinceEpoch(context.nowMilliseconds)"
            raise Unsupported(f"new {constructor}")
        if kind == "assignment_expression":
            return f"({self.assignment(node)})"
        raise Unsupported(f"expression {kind}: {self.text(node)[:100]}")

    def call(self, node: Node) -> str:
        function = self.field(node, "function")
        args_node = self.field(node, "arguments")
        raw_function = self.text(function)
        if function.type == "member_expression":
            receiver_node = self.field(function, "object")
            method = self.text(self.field(function, "property"))
            receiver = self.expression(receiver_node)
            if method in {"map", "flatMap", "filter"}:
                if not args_node.named_children:
                    raise Unsupported(f"{method} without callback")
                callback = args_node.named_children[0]
                if method == "map":
                    return self.map_call(receiver, callback, flat=False)
                if method == "flatMap":
                    return self.map_call(receiver, callback, flat=True)
                parameters, body = self.arrow(callback)
                if len(parameters) != 1:
                    raise Unsupported("filter callback arity")
                return f"({receiver}).where(({parameters[0]}) => jsTruthy({body})).toList(growable: false)"
        arguments = [self.expression(child) for child in args_node.named_children]
        args = ", ".join(arguments)
        direct = {
            "Number": "jsNumber",
            "String": "jsString",
            "cryptoMd5": "md5Hex",
            "cryptoSha1": "sha1Hex",
            "signParamsKey": "context.signatures.parametersKey",
            "signKey": "context.signatures.key",
            "signCloudKey": "context.signatures.cloudKey",
            "randomString": "randomString",
            "randomNumber": "randomNumber",
            "rsaEncrypt2": "context.crypto.rsaPkcs1Encrypt",
            "cryptoRSAEncrypt": "context.crypto.rsaRawEncrypt",
            "cryptoAesEncrypt": "context.crypto.aesEncrypt",
            "playlistAesEncrypt": "context.crypto.playlistAesEncrypt",
            "decodeLyrics": "decodeKrcLyrics",
            "encodeURIComponent": "Uri.encodeComponent",
            "generateWebGLHash": "generateWebGlHash",
        }
        if raw_function in direct:
            return f"{direct[raw_function]}({args})"
        if raw_function == "parseInt":
            return f"jsNumber({arguments[0]}).toInt()"
        if raw_function == "decodeURIComponent":
            return f"Uri.decodeComponent(jsString({arguments[0]}))"
        if raw_function == "Date.now":
            return "context.nowMilliseconds"
        if raw_function == "Math.floor":
            return f"jsNumber({arguments[0]}).floor()"
        if raw_function == "Math.ceil":
            return f"jsNumber({arguments[0]}).ceil()"
        if raw_function == "Math.max":
            return f"jsMax(<Object?>[{args}])"
        if raw_function == "JSON.stringify":
            return f"jsJsonEncode({arguments[0]})"
        if raw_function == "Array.isArray":
            return f"({arguments[0]} is List<Object?>)"
        if raw_function == "Object.assign":
            spreads = ", ".join(f"...stringObjectMap({arg})" for arg in arguments)
            return f"<String, Object?>{{{spreads}}}"
        if function.type != "member_expression":
            raise Unsupported(f"call {raw_function}")
        receiver_node = self.field(function, "object")
        method = self.text(self.field(function, "property"))
        receiver = self.expression(receiver_node)
        if method in {"toString", "toLocaleString"}:
            return f"jsString({receiver})"
        if method in {"toLowerCase", "toLocaleLowerCase"}:
            return f"jsString({receiver}).toLowerCase()"
        if method == "toUpperCase":
            return f"jsString({receiver}).toUpperCase()"
        if method == "trim":
            return f"jsString({receiver}).trim()"
        if method == "split":
            return f"jsString({receiver}).split(jsString({arguments[0]}))"
        if method == "substring":
            return f"jsString({receiver}).substring({', '.join(f'jsNumber({a}).toInt()' for a in arguments)})"
        if method == "includes":
            return f"({receiver}).contains({arguments[0]})"
        if method == "join":
            separator = arguments[0] if arguments else '""'
            return f"({receiver}).map(jsString).join(jsString({separator}))"
        if method == "getTime":
            return "context.nowMilliseconds"
        if method == "padStart":
            fill = arguments[1] if len(arguments) > 1 else '" "'
            return f"jsString({receiver}).padLeft(jsNumber({arguments[0]}).toInt(), jsString({fill}))"
        if method == "toFixed":
            return f"jsNumber({receiver}).toStringAsFixed(jsNumber({arguments[0]}).toInt())"
        raise Unsupported(f"method {method}")

    def map_call(self, receiver: str, callback: Node, flat: bool) -> str:
        parameters, body = self.arrow(callback)
        params = ", ".join(parameters)
        mapped = f"({receiver}).map<Object?>(({params}) => {body})"
        if flat:
            return f"{mapped}.expand<Object?>((item) => item as Iterable<Object?>).toList(growable: false)"
        return f"{mapped}.toList(growable: false)"

    def arrow(self, node: Node) -> tuple[list[str], str]:
        if node.type != "arrow_function":
            raise Unsupported("callback is not an arrow function")
        parameters_node = node.child_by_field_name("parameters")
        if parameters_node is None:
            parameter = node.child_by_field_name("parameter")
            if parameter is None:
                raise Unsupported("arrow parameters")
            parameters = [self.text(parameter)]
        else:
            parameters = [self.text(child) for child in parameters_node.named_children]
        body = self.field(node, "body")
        if body.type == "statement_block":
            statements = [child for child in body.named_children if child.type != "comment"]
            if len(statements) != 1 or statements[0].type != "return_statement":
                raise Unsupported("complex arrow body")
            body = statements[0].named_children[0]
        return parameters, self.expression(body)

    def parameter_path(self, node: Node) -> list[str] | None:
        if node.type == "identifier":
            return [] if self.text(node) == "params" else None
        if node.type != "member_expression":
            return None
        root = self.parameter_path(self.field(node, "object"))
        if root is None:
            return None
        prop = self.field(node, "property")
        return [*root, self.text(prop)]


def generate(source_dir: Path, output: Path) -> tuple[int, list[tuple[str, str]]]:
    successful: list[tuple[str, str, str]] = []
    skipped: list[tuple[str, str]] = []
    manual = {"lyric", "playlist_track_all", "search", "song_url"}
    for source_file in sorted(source_dir.glob("*.js")):
        name = source_file.stem
        # Files prefixed with "_" are internal helpers and are not HTTP routes.
        if name.startswith("_") or name in manual:
            continue
        try:
            route, handler, body = Translator(source_file.read_bytes(), name).translate()
            successful.append((route, handler, body))
        except (Unsupported, IndexError, ValueError) as error:
            skipped.append((name, str(error)))

    route_lines = [f"      {json.dumps(route)}: {handler}," for route, handler, _ in successful]
    functions = "\n\n".join(body for _, _, body in successful)
    generated = f"""// GENERATED CODE - DO NOT EDIT BY HAND.
// Generated from KuGouMusicApi/module by tool/generate_kugou_endpoints.py.
// ignore_for_file: non_constant_identifier_names, prefer_interpolation_to_compose_strings, unused_local_variable, equal_keys_in_map

import '../config.dart';
import '../endpoint.dart';
import '../js_compat.dart';
import '../models.dart';
import '../signatures.dart';
import '../utilities.dart';

Map<String, KugouEndpointHandler> createGeneratedEndpointHandlers() =>
    <String, KugouEndpointHandler>{{
{chr(10).join(route_lines)}
    }};

{functions}
"""
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(generated, encoding="utf-8")
    return len(successful), skipped


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    count, skipped = generate(args.source, args.output)
    print(f"generated {count} endpoints", file=sys.stderr)
    for name, reason in skipped:
        print(f"SKIP {name}: {reason}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
