#!/usr/bin/env python3
"""Generate schema and oracle assertions (no production code).

Arguments: path to baseline oracle JSON. Errors propagate on missing/invalid input.
Example: python3 fixtures/codec_correctness/generate_scalars.py /tmp/oracle.json
Then generate scalars.proto with the real codegen CLI as documented in README.md.
Use --document after generation to annotate public fixture APIs without changing logic.
"""
import json
from pathlib import Path
import sys
import re

root = Path(__file__).resolve().parents[2]
if sys.argv[1] == "--document":
    # Documentation only; generated codec expressions are never repaired.
    def _document(match):
        name, args = match.group(1), match.group(2)
        params = re.findall(r"(\w+):", args)
        call = name + "(" + ", ".join(params) + ")"
        description = "Arguments: " + (", ".join(params) or "none") + ". "
        description += "Decode errors are returned as Result values." if name.startswith("decode_") else "No immediate errors; decoders report errors when run."
        return "/// " + description + "\n/// Example: `" + call + "`.\n" + match.group(0)
    for name in ("scalars", "packed_only"):
        path = root / f"test/codec_fixture/{name}.gleam"
        path.write_text(re.sub(r"pub fn (\w+)\(([^)]*)\)", _document, path.read_text()))
    sys.exit(0)
vectors = json.loads(Path(sys.argv[1]).read_text())
from google.protobuf import descriptor_pb2 as dp, descriptor_pool, message_factory
import google.protobuf
assert google.protobuf.__version__ == '6.33.5', 'Use the existing pinned codegen venv'


def _reference(kind, key_kind=None, repeated=False):
    """Build an independent Python oracle class; arguments select scalar/map shape.

    Invalid descriptor types raise protobuf errors. Example: _reference('int64').
    """
    file = dp.FileDescriptorProto(name='reference.proto', syntax='proto3')
    msg = file.message_type.add(name='Sample')
    field = msg.field.add(name='value', number=1)
    if key_kind:
        entry = msg.nested_type.add(name='Entry')
        entry.options.map_entry = True
        entry.field.add(name='key', number=1, type=getattr(dp.FieldDescriptorProto, 'TYPE_' + key_kind.upper()))
        entry.field.add(name='value', number=2, type=getattr(dp.FieldDescriptorProto, 'TYPE_' + kind.upper()))
        field.type = dp.FieldDescriptorProto.TYPE_MESSAGE
        field.type_name = '.Sample.Entry'
        field.label = dp.FieldDescriptorProto.LABEL_REPEATED
    else:
        field.type = getattr(dp.FieldDescriptorProto, 'TYPE_' + kind.upper())
        if repeated:
            field.label = dp.FieldDescriptorProto.LABEL_REPEATED
    pool = descriptor_pool.DescriptorPool()
    pool.Add(file)
    return message_factory.GetMessageClass(pool.FindMessageTypeByName('Sample'))


schema = ['syntax = "proto3";']
tests = ['import codec_fixture/scalars as s', 'import codec_fixture/packed_only as p', 'import gleam/option.{None, Some}']


def _bits(wire):
    return '<<' + ', '.join(str(b) for b in bytes.fromhex(wire)) + '>>'


def _test(name, assertions):
    tests.extend(['/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.',
                  f'pub fn {name}_test() {{', *['  ' + a for a in assertions], '  Nil', '}'])


for kind, v in vectors['scalars'].items():
    name = kind.capitalize()
    schema.extend([f'message Scalar{name} {{ {kind} value = 1; }}',
                   f'message Optional{name} {{ optional {kind} value = 1; }}',
                   f'message Choice{name} {{ oneof selection {{ {kind} value = 1; }} }}',
                   f'message Repeated{name} {{ repeated {kind} value = 1; }}'])
    zero = 'False' if kind == 'bool' else '0.0' if kind in ('float', 'double') else '0'
    one = 'True' if kind == 'bool' else '1.0' if kind in ('float', 'double') else '1'
    two = 'False' if kind == 'bool' else '2.0' if kind in ('float', 'double') else '2'
    _test(f'{kind}_defaults', [f'let assert Ok(s.Scalar{name}({zero})) = s.decode_scalar_{kind}(<<>>)',
        f'let assert Ok(s.Optional{name}(None)) = s.decode_optional_{kind}(<<>>)',
        f'let assert Ok(s.Optional{name}(Some({zero}))) = s.decode_optional_{kind}({_bits(v["optional_zero"])})'])
    _test(f'{kind}_oneof', [f'let assert Ok(s.Choice{name}(None)) = s.decode_choice_{kind}(<<>>)',
        *[f'let assert Ok(s.Choice{name}(Some(s.Choice{name}SelectionValue({value})))) = s.decode_choice_{kind}({_bits(wire)})'
          for value, wire in [(zero, v['oneof_zero']), (one, v['one'])]],
        f'let assert {_bits(v["oneof_zero"])} = s.encode_choice_{kind}(s.Choice{name}(Some(s.Choice{name}SelectionValue({zero}))))'])
    _test(f'{kind}_repeated', [f'let assert Ok(s.Repeated{name}({expected})) = s.decode_repeated_{kind}({_bits(v[mode])})'
        for mode, expected in [('packed', f'[{one}, {two}]'), ('unpacked', f'[{one}, {two}]'), ('mixed', f'[{one}, {one}, {two}, {two}]')]] + [
        f'let assert Ok(s.Repeated{name}([{one}, {two}])) = s.decode_repeated_{kind}({_bits("0a00" + v["packed"] + "0a00")})'])
# Canonical signed literals distinguish signed readers from unsigned fallbacks.
negative = {'int32': '08' + 'ff' * 9 + '01', 'int64': '08' + 'ff' * 9 + '01',
            'sint32': '0801', 'sint64': '0801',
            'sfixed32': '0dffffffff', 'sfixed64': '09ffffffffffffffff',
            'float': '0d000080bf', 'double': '09000000000000f0bf'}
for kind, wire in negative.items():
    name = kind.capitalize()
    minus = '-1.0' if kind in ('float', 'double') else '-1'
    one = '1.0' if kind in ('float', 'double') else '1'
    unpacked = wire + vectors['scalars'][kind]['one']
    payload = bytes.fromhex(wire)[1:] + bytes.fromhex(vectors['scalars'][kind]['one'])[1:]
    packed = (bytes([10, len(payload)]) + payload).hex()
    assert _reference(kind).FromString(bytes.fromhex(wire)).value == -1
    for data, expected in [(packed, [-1, 1]), (unpacked, [-1, 1]), (wire + packed + vectors['scalars'][kind]['one'], [-1, -1, 1, 1])]:
        assert list(_reference(kind, repeated=True).FromString(bytes.fromhex(data)).value) == expected
    _test(f'{kind}_negative', [
        f'let assert Ok(s.Choice{name}(Some(s.Choice{name}SelectionValue({minus})))) = s.decode_choice_{kind}({_bits(wire)})',
        *[f'let assert Ok(s.Repeated{name}({expected})) = s.decode_repeated_{kind}({_bits(data)})'
          for data, expected in [(packed, f'[{minus}, {one}]'), (unpacked, f'[{minus}, {one}]'),
                                 (wire + packed + vectors['scalars'][kind]['one'], f'[{minus}, {minus}, {one}, {one}]')]]])
# Each legal numeric key family paired with itself; float/double values use sint32 keys.
for kind, v in vectors['scalars'].items():
    if kind == 'bool':
        continue
    name = kind.capitalize()
    key_kind = 'sint32' if kind in ('float', 'double') else kind
    key_one = vectors['scalars'][key_kind]['one']
    zero = '0.0' if kind in ('float', 'double') else '0'
    one = '1.0' if kind in ('float', 'double') else '1'
    schema.append(f'message Map{name} {{ map<{key_kind}, {kind}> values = 1; }}')
    # Retag canonical field-one bytes as the map value (field two).
    raw = bytes.fromhex(v['one'])
    value_wire = bytes([raw[0] + 8]) + raw[1:]
    wires = [(b'', f'#(0, {zero})'), (bytes.fromhex(key_one), f'#(1, {zero})'), (value_wire, f'#(0, {one})')]
    ref = _reference(kind, key_kind=key_kind)
    for wire, expected in [(b'', {0: 0}), (bytes.fromhex(key_one), {1: 0}), (value_wire, {0: 1})]:
        assert dict(ref.FromString(bytes([10, len(wire)]) + wire).value) == expected
    _test(f'{kind}_map_defaults', [f'let assert Ok(s.Map{name}([{expected}])) = s.decode_map_{kind}({_bits((bytes([10, len(wire)]) + wire).hex())})'
                              for wire, expected in wires])
schema.extend(['enum State { ZERO = 0; FIRST = 1; SECOND = 2; }', 'message EnumList { repeated State value = 1; }'])
for wire, expected in [('0a020102', [1, 2]), ('08010802', [1, 2]), ('08010a0201020802', [1, 1, 2, 2])]:
    assert list(_reference('int32', repeated=True).FromString(bytes.fromhex(wire)).value) == expected
_test('enum_repeated', [f'let assert Ok(s.EnumList({expected})) = s.decode_enum_list({_bits(wire)})' for wire, expected in [
    ('0a020102', '[s.First, s.Second]'), ('08010802', '[s.First, s.Second]'), ('08010a0201020802', '[s.First, s.First, s.Second, s.Second]')]])
(root / 'fixtures/codec_correctness/scalars.proto').write_text('\n'.join(schema) + '\n')
test_errors = [
    'let assert Error(_) = s.decode_repeated_int64(<<10, 1, 128>>)',
    'let assert Error(_) = s.decode_repeated_uint64(<<10, 10, 255, 255, 255, 255, 255, 255, 255, 255, 255, 2>>)',
    'let assert Error(_) = s.decode_repeated_fixed32(<<10, 3, 1, 2, 3>>)',
    'let assert Error(_) = s.decode_repeated_double(<<10, 1, 0>>)',
    'let assert Error(_) = s.decode_repeated_bool(<<13, 0, 0, 0, 0>>)',
]
_test('packed_errors', test_errors)
(root / 'fixtures/codec_correctness/packed_only.proto').write_text('syntax = "proto3"; message PackedOnly { repeated double value = 1; }\n')
_test('packed_only', ['let assert Ok(p.PackedOnly([1.0, 2.0])) = p.decode_packed_only(' + _bits(vectors['scalars']['double']['packed']) + ')'])
# Independent safe-boundary zigzag vectors, including the odd unsigned values
# that cannot be represented as JavaScript Numbers before sign interpretation.
for kind, values in [('sint32', [-2147483648, -2147483647, 2147483646, 2147483647]),
                     ('sint64', [-9007199254740991, -9007199254740990, -4503599627370497,
                                 -4503599627370496, 4503599627370496, 4503599627370497,
                                 9007199254740990, 9007199254740991])]:
    name = kind.capitalize()
    assertions = []
    for value in values:
        wire = _reference(kind)(value=value).SerializeToString()
        if value == -9007199254740991:
            assert wire.hex() == '08fdffffffffffff1f'
        if value == 9007199254740991:
            assert wire.hex() == '08feffffffffffff1f'
        bits = _bits(wire.hex())
        packed = _bits((bytes([10, len(wire)-1]) + wire[1:]).hex())
        entry = bytes([8]) + wire[1:] + bytes([16]) + wire[1:]
        map_bits = _bits((bytes([10, len(entry)]) + entry).hex())
        assertions.extend([
            f'let assert Ok(s.Map{name}([#({value}, {value})])) = s.decode_map_{kind}({map_bits})',
            f'let assert Ok(s.Scalar{name}({value})) = s.decode_scalar_{kind}({bits})',
            f'let assert Ok(s.Optional{name}(Some({value}))) = s.decode_optional_{kind}({bits})',
            f'let assert Ok(s.Choice{name}(Some(s.Choice{name}SelectionValue({value})))) = s.decode_choice_{kind}({bits})',
            f'let assert Ok(s.Repeated{name}([{value}])) = s.decode_repeated_{kind}({packed})',
            f'let assert {bits} = s.encode_scalar_{kind}(s.Scalar{name}({value}))',
        ])
    _test(kind + '_safe_boundaries', assertions)
tests.append('@target(erlang)')
_test('sint64_full_endpoints', [
    f'let assert Ok(s.ScalarSint64({value})) = s.decode_scalar_sint64({_bits(_reference("sint64")(value=value).SerializeToString().hex())})'
    for value in [-9223372036854775808, 9223372036854775807]
] + [
    f'let assert {_bits(_reference("sint64")(value=value).SerializeToString().hex())} = s.encode_scalar_sint64(s.ScalarSint64({value}))'
    for value in [-9223372036854775808, 9223372036854775807]
])
# A single large segment (not merely many tiny fields) exercises packed loops.
tests.extend(['import gleam/bit_array', 'import gleam/list'])
for kind, unit, one in [('int64', '01', '1'), ('int32', '01', '1'),
                        ('fixed32', '01000000', '1'), ('fixed64', '0100000000000000', '1'),
                        ('enum_list', '01', 's.First')]:
    name = 'EnumList' if kind == 'enum_list' else 'Repeated' + kind.capitalize()
    decoder = 'decode_enum_list' if kind == 'enum_list' else 'decode_repeated_' + kind
    count = 12000
    size = count * len(bytes.fromhex(unit))
    length = []
    while size >= 128:
        length.append((size % 128) + 128)
        size //= 128
    length.append(size)
    tag = 8 if kind in ('int64', 'int32', 'enum_list') else 13 if kind == 'fixed32' else 9
    _test(kind + '_large_packed', [
        f'let payload = bit_array.concat(list.repeat({_bits(unit)}, 12_000))',
        f'let packed = bit_array.concat([{_bits(bytes([10] + length).hex())}, payload])',
        f'let assert Ok(s.{name}(values)) = s.{decoder}(packed)',
        f'let assert True = values == list.repeat({one}, 12_000)',
        f'let mixed = bit_array.concat([{_bits(bytes([tag]).hex()+unit)}, packed, {_bits(bytes([tag]).hex()+unit)}])',
        f'let assert Ok(s.{name}(values)) = s.{decoder}(mixed)',
        f'let assert True = values == list.repeat({one}, 12_002)',
    ])
_test('packed_int32_enum_errors', [
    'let assert Error(_) = s.decode_repeated_int32(<<10, 1, 128>>)',
    'let assert Error(_) = s.decode_enum_list(<<10, 1, 128>>)',
    'let assert Error(_) = s.decode_repeated_int32(<<10, 10, 255, 255, 255, 255, 255, 255, 255, 255, 255, 2>>)',
])
(root / 'test/codec_scalars_test.gleam').write_text('\n'.join(tests) + '\n')
