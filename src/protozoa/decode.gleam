//// Protocol Buffer Decode Module  
////
//// This module provides a composable, type-safe API for decoding Protocol Buffer binary data
//// into Gleam values. It follows the gleam/dynamic/decode pattern for familiar composability
//// and error handling, making it easy to work with protobuf data in Gleam applications.
////
//// ## Design Philosophy
////
//// - **Composable decoders**: Small, focused decoder functions that can be combined
//// - **Type safety**: Compile-time guarantees about decoded data structure
//// - **Error handling**: Clear error messages for debugging decode failures
//// - **Performance**: Efficient binary parsing with minimal allocations
//// - **Gleam idioms**: Follows Result and Option patterns familiar to Gleam developers
////
//// ## Capabilities
////
//// - **All proto3 types**: Scalars (int32, string, bool), messages, enums, repeated fields
//// - **Advanced features**: Oneofs, maps, optional fields, nested messages  
//// - **Wire format parsing**: Handles protobuf binary wire format correctly
//// - **Field-level decoding**: Individual field decoders for fine-grained control
//// - **Message-level decoding**: Complete message decoders with field validation
//// - **Default values**: Proper proto3 default value handling
////
//// ## Usage Pattern
////
//// Generated code uses this module to create message-specific decoder functions:
//// ```gleam
//// pub fn decode_user(data: BitArray) -> Result(User, DecodeError) {
////   decode.message(data, user_decoder())
//// }
////
//// fn user_decoder() -> decode.Decoder(User) {
////   decode.into({
////     use name <- decode.field("name", decode.string_field(1))
////     use age <- decode.field("age", decode.int32_field(2))  
////     User(name: name, age: age)
////   })
//// }
//// ```
////
//// ## Error Handling  
////
//// All decode functions return `Result(T, DecodeError)` with descriptive error messages
//// for debugging binary format issues, missing required fields, or type mismatches.

import gleam/bit_array
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import protozoa/wire.{type WireType}

// Core types

/// Represents an error that occurred during decoding.
/// Contains what was expected, what was found, and the path to the error.
pub type DecodeError {
  DecodeError(expected: String, found: String, path: List(String))
  FieldNotFound(field_number: Int)
}

/// Represents a decoded Protocol Buffer field.
/// Contains the field number, wire type, and raw data.
@internal
pub type Field {
  Field(number: Int, wire_type: WireType, data: BitArray)
}

/// Represents a decoded Protocol Buffer value.
/// Can be a message, varint, fixed32, fixed64, or length-delimited data.
@internal
pub type ProtoValue {
  ProtoMessage(List(Field))
  ProtoVarint(Int)
  ProtoFixed32(BitArray)
  ProtoFixed64(BitArray)
  ProtoLengthDelimited(BitArray)
}

// Keep cross-number wire order separately from the indexed field lookup.
type Context {
  Context(ordered: List(Field), indexed: Dict(Int, List(Field)))
}

/// Composable message decoder with ordered fields and indexed lookup internally.
/// Returns a decoded value or explicit decode errors; construct using combinators.
pub opaque type Decoder(a) {
  Decoder(fn(Context) -> Result(a, List(DecodeError)))
}

/// Run a decoder on a BitArray containing Protocol Buffer data.
/// Returns either the decoded value or a list of all errors encountered.
/// 
/// ## Examples
/// 
/// ```gleam
/// let decoder = field(1, varint_field)
/// run(<<8, 42>>, decoder) // Decodes field 1 with value 42
/// ```
pub fn run(
  data: BitArray,
  with decoder: Decoder(a),
) -> Result(a, List(DecodeError)) {
  use fields <- result.try(
    decode_message(data)
    |> result.map_error(fn(err) { [err] }),
  )
  let field_dict = build_field_dict(fields)
  let Decoder(f) = decoder
  f(Context(fields, field_dict))
}

/// Normalize decoded map `entries`, retaining only the last value for each key.
/// Cannot fail. Example: `map_entries([#(1, "old"), #(1, "new")])` returns
/// `[#(1, "new")]`. Entries retain reverse final-occurrence order, though
/// protobuf itself does not specify map order.
pub fn map_entries(entries: List(#(k, v))) -> List(#(k, v)) {
  let #(_, unique) =
    list.fold(list.reverse(entries), #(dict.new(), []), fn(acc, entry) {
      let #(seen, unique) = acc
      case dict.has_key(seen, entry.0) {
        True -> acc
        False -> #(dict.insert(seen, entry.0, Nil), [entry, ..unique])
      }
    })
  list.reverse(unique)
}

/// Decode a oneof in wire order. Alternatives contain the field number, expected
/// wire type, message-merge flag and payload decoder. Wrong wire types are unknown
/// fields; malformed recognized payloads return errors, never absence.
/// Example: `oneof([#(1, wire.Varint, False, int32_field)])`.
pub fn oneof(
  alternatives: List(
    #(Int, WireType, Bool, fn(Field) -> Result(a, DecodeError)),
  ),
) -> Decoder(option.Option(a)) {
  Decoder(fn(context) {
    use selected <- result.try(
      list.try_fold(
        context.ordered,
        None,
        fn(selected: option.Option(#(Field, a)), field) {
          case
            list.find(alternatives, fn(alt) {
              alt.0 == field.number && alt.1 == field.wire_type
            })
          {
            Error(_) -> Ok(selected)
            Ok(#(_, _, merge, decode)) -> {
              let combined = case selected, merge {
                Some(#(previous, _)), True if previous.number == field.number ->
                  Field(..field, data: <<previous.data:bits, field.data:bits>>)
                _, _ -> field
              }
              // Validate even an occurrence subsequently overwritten by another case.
              use _ <- result.try(
                decode(field) |> result.map_error(fn(err) { [err] }),
              )
              use value <- result.try(
                decode(combined) |> result.map_error(fn(err) { [err] }),
              )
              Ok(Some(#(combined, value)))
            }
          }
        },
      ),
    )
    Ok(option.map(selected, fn(pair) { pair.1 }))
  })
}

/// Create a decoder that always succeeds with a value.
/// Useful for providing default values or building complex decoders.
/// 
/// ## Examples
/// 
/// ```gleam
/// success(42) // Always returns Ok(42)
/// ```
pub fn success(value: a) -> Decoder(a) {
  Decoder(fn(_fields) { Ok(value) })
}

/// Create a decoder from a function that takes a dict of fields.
/// This is useful for creating custom decoders for complex types like oneofs.
/// 
/// ## Examples
/// 
/// ```gleam
/// from_field_dict(fn(fields) {
///   // Custom decoding logic using dict.get
///   Ok(value)
/// })
/// ```
pub fn from_field_dict(
  f: fn(Dict(Int, List(Field))) -> Result(a, List(DecodeError)),
) -> Decoder(a) {
  Decoder(fn(context) { f(context.indexed) })
}

/// Create a decoder that always fails with an error message.
/// Useful for handling unsupported fields or validation errors.
/// 
/// ## Examples
/// 
/// ```gleam
/// fail("Unsupported field type") // Always returns Error
/// ```
pub fn fail(expected: String, found: String, path: List(String)) -> Decoder(a) {
  Decoder(fn(_fields) { Error([DecodeError(expected, found, path)]) })
}

/// Decode a required field with a specific decoder.
/// Returns an error if the field is not present.
/// 
/// ## Examples
/// 
/// ```gleam
/// field(1, varint_field) // Decodes field 1 as a varint
/// field(2, string_field) // Decodes field 2 as a string
/// ```
pub fn field(
  number: Int,
  decoder: fn(Field) -> Result(a, DecodeError),
) -> Decoder(a) {
  Decoder(fn(fields) {
    case dict.get(fields.indexed, number) {
      Ok([first, ..rest]) -> {
        let field = list.fold(rest, first, fn(_, next) { next })
        decoder(field)
        |> result.map_error(fn(err) { [err] })
      }
      Ok([]) -> Error([FieldNotFound(number)])
      Error(_) -> Error([FieldNotFound(number)])
    }
  })
}

/// Decode an optional field.
/// Returns Ok(Ok(value)) if the field is present and valid,
/// Ok(Error(Nil)) if the field is missing. Present invalid values return errors.
/// 
/// ## Examples
/// 
/// ```gleam
/// optional_field(1, varint_field) // Decodes optional field 1
/// ```
pub fn optional_field(
  number: Int,
  decoder: fn(Field) -> Result(a, DecodeError),
) -> Decoder(Result(a, Nil)) {
  Decoder(fn(fields) {
    case dict.get(fields.indexed, number) {
      Ok([first, ..rest]) -> {
        let field = list.fold(rest, first, fn(_, next) { next })
        decoder(field) |> result.map(Ok) |> result.map_error(fn(err) { [err] })
      }
      Ok([]) -> Ok(Error(Nil))
      Error(_) -> Ok(Error(Nil))
    }
  })
}

/// Decode a field with a default value.
/// Returns the decoded value if present, otherwise returns the default.
/// 
/// ## Examples
/// 
/// ```gleam
/// field_with_default(1, varint_field, 0) // Returns 0 if field 1 is missing
/// ```
pub fn field_with_default(
  number: Int,
  decoder: fn(Field) -> Result(a, DecodeError),
  default: a,
) -> Decoder(a) {
  Decoder(fn(fields) {
    case dict.get(fields.indexed, number) {
      Ok([first, ..rest]) -> {
        let field = list.fold(rest, first, fn(_, next) { next })
        decoder(field) |> result.map_error(fn(err) { [err] })
      }
      Ok([]) -> Ok(default)
      Error(_) -> Ok(default)
    }
  })
}

/// Decode all fields with a given number (for repeated fields).
/// Returns a list of all decoded values for the field number.
/// Collects all errors encountered during decoding.
/// 
/// ## Examples
/// 
/// ```gleam
/// repeated_field(1, varint_field) // Decodes all field 1 occurrences
/// ```
pub fn repeated_field(
  number: Int,
  decoder: fn(Field) -> Result(a, DecodeError),
) -> Decoder(List(a)) {
  Decoder(fn(fields) {
    case dict.get(fields.indexed, number) {
      Ok(field_list) -> {
        let results = list.map(field_list, decoder)
        let errors =
          list.filter_map(results, fn(result) {
            case result {
              Error(err) -> Ok(err)
              Ok(_) -> Error(Nil)
            }
          })
        case errors {
          [] -> {
            let values =
              list.filter_map(results, fn(result) {
                case result {
                  Ok(value) -> Ok(value)
                  Error(_) -> Error(Nil)
                }
              })
            Ok(values)
          }
          _ -> Error(errors)
        }
      }
      Error(_) -> Ok([])
    }
  })
}

// Type-specific field decoders

/// Decodes a varint field to an integer.
/// Used for int32, int64, uint32, uint64, bool, and enum fields.
@internal
pub fn varint_field(field: Field) -> Result(Int, DecodeError) {
  case field.wire_type {
    wire.Varint -> {
      case field.data {
        <<value:64>> -> Ok(value)
        _ -> Error(DecodeError("valid varint data", "invalid varint data", []))
      }
    }
    _ -> Error(DecodeError("varint wire type", "non-varint wire type", []))
  }
}

/// Decodes a length-delimited field as a UTF-8 string.
@internal
pub fn string_field(field: Field) -> Result(String, DecodeError) {
  case field.wire_type {
    wire.LengthDelimited -> {
      bit_array.to_string(field.data)
      |> result.map_error(fn(_) {
        DecodeError("valid UTF-8 string", "invalid UTF-8 bytes", [])
      })
    }
    _ ->
      Error(
        DecodeError(
          "length-delimited wire type",
          "non-length-delimited wire type",
          [],
        ),
      )
  }
}

/// Decodes a length-delimited field as raw bytes.
@internal
pub fn bytes_field(field: Field) -> Result(BitArray, DecodeError) {
  case field.wire_type {
    wire.LengthDelimited -> Ok(field.data)
    _ ->
      Error(
        DecodeError(
          "length-delimited wire type",
          "non-length-delimited wire type",
          [],
        ),
      )
  }
}

/// Decodes a fixed32 field as a float.
@internal
pub fn float_field(field: Field) -> Result(Float, DecodeError) {
  case field.wire_type {
    wire.Fixed32 -> {
      case field.data {
        <<value:32-float-little>> -> Ok(value)
        _ ->
          Error(
            DecodeError("valid 32-bit float data", "invalid float data", []),
          )
      }
    }
    _ -> Error(DecodeError("fixed32 wire type", "non-fixed32 wire type", []))
  }
}

/// Decodes a fixed64 field as a double (Float in Gleam).
@internal
pub fn double_field(field: Field) -> Result(Float, DecodeError) {
  case field.wire_type {
    wire.Fixed64 -> {
      case field.data {
        <<value:64-float-little>> -> Ok(value)
        _ ->
          Error(
            DecodeError("valid 64-bit double data", "invalid double data", []),
          )
      }
    }
    _ -> Error(DecodeError("fixed64 wire type", "non-fixed64 wire type", []))
  }
}

/// Decodes a varint field as a boolean (0 = false, non-zero = true).
@internal
pub fn bool_field(field: Field) -> Result(Bool, DecodeError) {
  use value <- result.try(varint_field(field))
  Ok(value != 0)
}

/// Decodes `field` as signed int32, using the low 32 wire bits.
/// Returns a DecodeError for invalid data or wire type.
/// Example: `int32_field(Field(1, wire.Varint, <<0:32, 4_294_967_295:32>>))` returns `Ok(-1)`.
@internal
pub fn int32_field(field: Field) -> Result(Int, DecodeError) {
  case field {
    Field(_, wire.Varint, <<_:32, value:32-signed>>) -> Ok(value)
    _ -> varint_field(field)
  }
}

/// Decodes `field` as signed int64 without an unsigned Int intermediate.
/// Returns a DecodeError for invalid data or wire type.
/// Example: `int64_field(Field(1, wire.Varint, <<-1:64>>))` returns `Ok(-1)`.
/// JavaScript application values are limited to ±(2^53−1).
@internal
pub fn int64_field(field: Field) -> Result(Int, DecodeError) {
  case field {
    Field(_, wire.Varint, <<high:32-signed, low:32>>) ->
      Ok(high * 4_294_967_296 + low)
    _ -> varint_field(field)
  }
}

/// Decodes a varint field as a uint32.
@internal
pub fn uint32_field(field: Field) -> Result(Int, DecodeError) {
  varint_field(field)
}

/// Decodes a varint field as a uint64.
@internal
pub fn uint64_field(field: Field) -> Result(Int, DecodeError) {
  varint_field(field)
}

/// Decodes a fixed32 field as an integer.
@internal
pub fn fixed32_int_field(field: Field) -> Result(Int, DecodeError) {
  case field.wire_type {
    wire.Fixed32 -> {
      case field.data {
        <<value:32-little>> -> Ok(value)
        _ ->
          Error(
            DecodeError("valid 32-bit integer data", "invalid fixed32 data", []),
          )
      }
    }
    _ -> Error(DecodeError("fixed32 wire type", "non-fixed32 wire type", []))
  }
}

/// Decodes a fixed64 field as an integer.
@internal
pub fn fixed64_int_field(field: Field) -> Result(Int, DecodeError) {
  case field.wire_type {
    wire.Fixed64 -> {
      case field.data {
        <<value:64-little>> -> Ok(value)
        _ ->
          Error(
            DecodeError("valid 64-bit integer data", "invalid fixed64 data", []),
          )
      }
    }
    _ -> Error(DecodeError("fixed64 wire type", "non-fixed64 wire type", []))
  }
}

/// Decodes an sfixed32 field as a signed integer.
@internal
pub fn sfixed32_field(field: Field) -> Result(Int, DecodeError) {
  case field.wire_type {
    wire.Fixed32 -> {
      case field.data {
        <<value:32-signed-little>> -> Ok(value)
        _ ->
          Error(
            DecodeError(
              "valid signed 32-bit integer data",
              "invalid sfixed32 data",
              [],
            ),
          )
      }
    }
    _ -> Error(DecodeError("fixed32 wire type", "non-fixed32 wire type", []))
  }
}

/// Decodes an sfixed64 field as a signed integer.
@internal
pub fn sfixed64_field(field: Field) -> Result(Int, DecodeError) {
  case field.wire_type {
    wire.Fixed64 -> {
      case field.data {
        <<value:64-signed-little>> -> Ok(value)
        _ ->
          Error(
            DecodeError(
              "valid signed 64-bit integer data",
              "invalid sfixed64 data",
              [],
            ),
          )
      }
    }
    _ -> Error(DecodeError("fixed64 wire type", "non-fixed64 wire type", []))
  }
}

/// Decodes a nested message field using the provided decoder.
@internal
pub fn message_field(
  field: Field,
  decoder: Decoder(a),
) -> Result(a, DecodeError) {
  use bytes <- result.try(bytes_field(field))
  use inner_fields <- result.try(
    decode_message(bytes)
    |> result.map_error(fn(err) { err }),
  )
  let field_dict = build_field_dict(inner_fields)
  let Decoder(f) = decoder
  case f(Context(inner_fields, field_dict)) {
    Ok(value) -> Ok(value)
    Error([first_error, ..]) -> Error(first_error)
    Error([]) ->
      Error(DecodeError("valid message data", "empty error list", []))
  }
}

// Convenience decoders combining field number and type

/// Decoder for int32 fields.
pub fn int32(number: Int) -> Decoder(Int) {
  field(number, int32_field)
}

/// Decoder for int32 fields with a default value.
pub fn int32_with_default(number: Int, default: Int) -> Decoder(Int) {
  field_with_default(number, int32_field, default)
}

/// Decodes signed int64 field `number`, returning `default` when absent.
/// Malformed present fields return errors when run.
/// Example: `run(<<>>, int64_with_default(1, -1))` returns `Ok(-1)`.
pub fn int64_with_default(number: Int, default: Int) -> Decoder(Int) {
  field_with_default(number, int64_field, default)
}

/// Decoder for int64 fields.
pub fn int64(number: Int) -> Decoder(Int) {
  field(number, int64_field)
}

/// Decoder for uint32 fields.
pub fn uint32(number: Int) -> Decoder(Int) {
  field(number, varint_field)
}

/// Decoder for uint32 fields with a default value.
pub fn uint32_with_default(number: Int, default: Int) -> Decoder(Int) {
  field_with_default(number, varint_field, default)
}

/// Decoder for uint64 fields.
pub fn uint64(number: Int) -> Decoder(Int) {
  field(number, varint_field)
}

/// Decoder for uint64 fields with a default value.
pub fn uint64_with_default(number: Int, default: Int) -> Decoder(Int) {
  field_with_default(number, varint_field, default)
}

/// Decoder for string fields.
pub fn string(number: Int) -> Decoder(String) {
  field(number, string_field)
}

/// Decoder for string fields with a default value.
pub fn string_with_default(number: Int, default: String) -> Decoder(String) {
  field_with_default(number, string_field, default)
}

/// Decoder for boolean fields.
pub fn bool(number: Int) -> Decoder(Bool) {
  field(number, bool_field)
}

/// Decoder for boolean fields with a default value.
pub fn bool_with_default(number: Int, default: Bool) -> Decoder(Bool) {
  field_with_default(number, bool_field, default)
}

/// Decoder for bytes fields.
pub fn bytes(number: Int) -> Decoder(BitArray) {
  field(number, bytes_field)
}

/// Decoder for float fields.
pub fn float(number: Int) -> Decoder(Float) {
  field(number, float_field)
}

/// Decoder for double fields.
pub fn double(number: Int) -> Decoder(Float) {
  field(number, double_field)
}

/// Decoder for fixed32 fields (unsigned 32-bit integers).
pub fn fixed32(number: Int) -> Decoder(Int) {
  field(number, fixed32_int_field)
}

/// Decoder for fixed64 fields (unsigned 64-bit integers).
pub fn fixed64(number: Int) -> Decoder(Int) {
  field(number, fixed64_int_field)
}

/// Decoder for sfixed32 fields (signed 32-bit integers).
pub fn sfixed32(number: Int) -> Decoder(Int) {
  field(number, sfixed32_field)
}

/// Decoder for sfixed64 fields (signed 64-bit integers).
pub fn sfixed64(number: Int) -> Decoder(Int) {
  field(number, sfixed64_field)
}

/// Decode repeated int32 field `number`, accepting packed, unpacked, or mixed
/// occurrences in wire order. Malformed packed varints return decode errors.
///
/// ```gleam
/// run(<<8, 1, 10, 2, 2, 3>>, repeated_int32(1)) // Ok([1, 2, 3])
/// ```
pub fn repeated_int32(number: Int) -> Decoder(List(Int)) {
  repeated_field(number, fn(field) {
    case field.wire_type {
      wire.LengthDelimited -> decode_packed_int32(field.data, [])
      _ -> result.map(int32_field(field), fn(value) { [value] })
    }
  })
  |> map(list.flatten)
}

fn decode_packed_int32(
  data: BitArray,
  reversed: List(Int),
) -> Result(List(Int), DecodeError) {
  case data {
    <<>> -> Ok(list.reverse(reversed))
    _ -> {
      case decode_varint_raw(data) {
        Error(error) -> Error(error)
        Ok(#(value, rest)) ->
          case int32_field(Field(0, wire.Varint, value)) {
            Error(error) -> Error(error)
            Ok(signed) -> decode_packed_int32(rest, [signed, ..reversed])
          }
      }
    }
  }
}

/// Decoder for repeated string fields.
pub fn repeated_string(number: Int) -> Decoder(List(String)) {
  repeated_field(number, string_field)
}

/// Decoder for nested message fields.
pub fn nested_message(number: Int, decoder: Decoder(a)) -> Decoder(a) {
  field(number, fn(f) { message_field(f, decoder) })
}

/// Decode optional nested message `number` with `decoder`, merging occurrences.
/// Missing fields return `Ok(Error(Nil))`; malformed present messages return errors.
/// Example: `optional_nested_message(1, user_decoder())`.
pub fn optional_nested_message(
  number: Int,
  decoder: Decoder(a),
) -> Decoder(Result(a, Nil)) {
  Decoder(fn(context) {
    case dict.get(context.indexed, number) {
      Error(_) | Ok([]) -> Ok(Error(Nil))
      Ok(fields) -> {
        use chunks <- result.try(
          list.try_map(fields, fn(field) {
            use bytes <- result.try(
              bytes_field(field) |> result.map_error(fn(err) { [err] }),
            )
            // Each embedded occurrence must be framed correctly on its own.
            use _ <- result.try(
              decode_message(bytes) |> result.map_error(fn(err) { [err] }),
            )
            Ok(bytes)
          }),
        )
        let bytes = bit_array.concat(chunks)
        run(bytes, decoder) |> result.map(Ok)
      }
    }
  })
}

/// Decode a map-entry message value, supplying an empty message when omitted.
/// `number` is the value tag and `decoder` its message decoder. Malformed data
/// returns errors. Example: `nested_message_with_default(2, item_decoder())`.
pub fn nested_message_with_default(
  number: Int,
  decoder: Decoder(a),
) -> Decoder(a) {
  then(optional_nested_message(number, decoder), fn(value) {
    case value {
      Ok(value) -> success(value)
      Error(_) -> from_field_dict(fn(_) { run(<<>>, decoder) })
    }
  })
}

// Builder pattern combinators - removed as they don't work well with Gleam's type system
// Use the subrecord pattern instead

// Alternative approach: use use syntax for building decoders
// This is more idiomatic Gleam and follows the pattern of gleam/dynamic/decode

/// Build a decoder using Gleam's use syntax.
/// This allows for composing multiple field decoders into a single decoder.
/// Collects all errors from both decoder stages.
/// 
/// ## Examples
/// 
/// ```gleam
/// use name <- decode.then(decode.string(1))
/// use age <- decode.then(decode.int32(2))
/// decode.success(Person(name: name, age: age))
/// ```
pub fn then(decoder: Decoder(a), next: fn(a) -> Decoder(b)) -> Decoder(b) {
  Decoder(fn(fields) {
    let Decoder(f) = decoder
    case f(fields) {
      Ok(value) -> {
        let Decoder(g) = next(value)
        g(fields)
      }
      Error(errors) -> Error(errors)
    }
  })
}

/// Transform the result of a decoder using a mapping function.
/// 
/// ## Examples
/// 
/// ```gleam
/// decode.int32(1)
/// |> decode.map(fn(x) { x * 2 })
/// ```
pub fn map(decoder: Decoder(a), f: fn(a) -> b) -> Decoder(b) {
  Decoder(fn(fields) {
    let Decoder(g) = decoder
    use value <- result.try(g(fields))
    Ok(f(value))
  })
}

// Low-level message decoding

fn decode_message(data: BitArray) -> Result(List(Field), DecodeError) {
  decode_fields(data, [])
}

/// Build an index without copying growing per-number prefixes.
/// Fields with the same number are grouped together in a list.
fn build_field_dict(fields: List(Field)) -> Dict(Int, List(Field)) {
  list.fold(fields, dict.new(), fn(acc, field) {
    dict.upsert(acc, field.number, fn(existing) {
      case existing {
        Some(fields) -> [field, ..fields]
        None -> [field]
      }
    })
  })
  |> dict.map_values(fn(_, occurrences) { list.reverse(occurrences) })
}

fn decode_fields(
  data: BitArray,
  acc: List(Field),
) -> Result(List(Field), DecodeError) {
  case data {
    <<>> -> Ok(list.reverse(acc))
    _ -> {
      case decode_field(data) {
        Ok(#(field, rest)) -> decode_fields(rest, [field, ..acc])
        Error(error) -> Error(error)
      }
    }
  }
}

fn decode_field(data: BitArray) -> Result(#(Field, BitArray), DecodeError) {
  use #(tag, rest1) <- result.try(decode_varint_raw(data))
  let assert <<tag_high:32, tag_low:32>> = tag
  use _ <- result.try(case tag_high == 0 && tag_low >= 8 {
    True -> Ok(Nil)
    False ->
      Error(
        DecodeError("field number 1..536870911", "invalid field number", []),
      )
  })
  let field_number = tag_low / 8
  use wire_type <- result.try(
    wire.get_wire_type(tag_low)
    |> result.map_error(fn(_) {
      DecodeError("valid wire type", "invalid wire type", [])
    }),
  )

  case wire_type {
    wire.Varint -> {
      use #(value, rest2) <- result.try(decode_varint_raw(rest1))
      // Store varint as 64-bit integer in BitArray
      Ok(#(Field(field_number, wire_type, value), rest2))
    }
    wire.Fixed64 -> {
      use #(value, rest2) <- result.try(decode_fixed64_raw(rest1))
      Ok(#(Field(field_number, wire_type, value), rest2))
    }
    wire.LengthDelimited -> {
      use #(value, rest2) <- result.try(decode_length_delimited_raw(rest1))
      Ok(#(Field(field_number, wire_type, value), rest2))
    }
    wire.Fixed32 -> {
      use #(value, rest2) <- result.try(decode_fixed32_raw(rest1))
      Ok(#(Field(field_number, wire_type, value), rest2))
    }
    _ -> Error(DecodeError("supported wire type", "unsupported wire type", []))
  }
}

fn decode_varint_raw(
  data: BitArray,
) -> Result(#(BitArray, BitArray), DecodeError) {
  decode_varint_helper(data, 0, 0, 0, 1)
}

// Two bounded 32-bit chunks preserve safe final signed values on JavaScript.
fn decode_varint_helper(
  data: BitArray,
  low: Int,
  high: Int,
  index: Int,
  factor: Int,
) -> Result(#(BitArray, BitArray), DecodeError) {
  case data {
    <<byte, rest:bits>> -> {
      case index == 9 && byte > 1 {
        True ->
          Error(
            DecodeError("64-bit varint", "overflow or over-width varint", []),
          )
        False -> {
          let payload = byte % 128
          let #(low, high) = case index {
            n if n < 4 -> #(low + payload * factor, high)
            4 -> #(low + payload % 16 * factor, high + payload / 16)
            _ -> #(low, high + payload * factor)
          }
          case byte < 128 {
            True -> Ok(#(<<high:32, low:32>>, rest))
            False ->
              decode_varint_helper(rest, low, high, index + 1, case index {
                4 -> 8
                _ -> factor * 128
              })
          }
        }
      }
    }
    _ -> Error(DecodeError("more varint data", "unexpected end of data", []))
  }
}

fn decode_fixed32_raw(
  data: BitArray,
) -> Result(#(BitArray, BitArray), DecodeError) {
  case data {
    <<value:32-bits, rest:bits>> -> Ok(#(value, rest))
    _ -> Error(DecodeError("4 bytes for fixed32", "insufficient data", []))
  }
}

fn decode_fixed64_raw(
  data: BitArray,
) -> Result(#(BitArray, BitArray), DecodeError) {
  case data {
    <<value:64-bits, rest:bits>> -> Ok(#(value, rest))
    _ -> Error(DecodeError("8 bytes for fixed64", "insufficient data", []))
  }
}

fn decode_length_delimited_raw(
  data: BitArray,
) -> Result(#(BitArray, BitArray), DecodeError) {
  use #(length_bits, rest) <- result.try(decode_varint_raw(data))
  let assert <<length:64>> = length_bits
  case bit_array.byte_size(rest) >= length {
    True -> {
      let bytes_to_take = length * 8
      case rest {
        <<value:size(bytes_to_take)-bits, rest:bits>> -> Ok(#(value, rest))
        _ ->
          Error(
            DecodeError(
              "sufficient bytes for length-delimited field",
              "insufficient data",
              [],
            ),
          )
      }
    }
    False ->
      Error(
        DecodeError(
          "sufficient bytes for length-delimited field",
          "insufficient data",
          [],
        ),
      )
  }
}

/// Decodes a zigzag-encoded integer back to its signed value.
/// Zigzag encoding is used for sint32 and sint64 fields to efficiently
/// encode negative numbers.
/// 
/// ## Examples
/// 
/// ```gleam
/// decode_zigzag(0) // Returns 0
/// decode_zigzag(1) // Returns -1
/// decode_zigzag(2) // Returns 1
/// ```
pub fn decode_zigzag(value: Int) -> Int {
  case int.bitwise_and(value, 1) {
    0 -> value / 2
    _ -> -{ value / 2 } - 1
  }
}

/// Decoder for sint32 fields (signed 32-bit integers with zigzag encoding).
/// 
/// ## Examples
/// 
/// ```gleam
/// sint32(1) // Decodes field 1 as a zigzag-encoded int32
/// ```
pub fn sint32(number: Int) -> Decoder(Int) {
  field(number, sint32_field)
}

/// Decoder for sint64 fields (signed 64-bit integers with zigzag encoding).
/// 
/// ## Examples
/// 
/// ```gleam
/// sint64(1) // Decodes field 1 as a zigzag-encoded int64
/// ```
pub fn sint64(number: Int) -> Decoder(Int) {
  field(number, sint64_field)
}

/// Decode zigzag integer `field`; wrong wire types return a DecodeError.
/// Example: `field(1, sint32_field)` reads an explicitly present sint32.
pub fn sint32_field(field: Field) -> Result(Int, DecodeError) {
  case field {
    Field(_, wire.Varint, <<_:32, value:32>>) -> Ok(decode_zigzag(value))
    _ -> varint_field(field)
  }
}

/// Decode zigzag integer `field`; wrong wire types return a DecodeError.
/// Example: `field(1, sint64_field)` reads an explicitly present sint64.
pub fn sint64_field(field: Field) -> Result(Int, DecodeError) {
  case field {
    Field(_, wire.Varint, <<high:32, low:32>>) -> {
      // Shift bounded chunks before constructing the final application integer.
      let half = high * 2_147_483_648 + low / 2
      case low % 2 {
        0 -> Ok(half)
        _ -> Ok(-half - 1)
      }
    }
    _ -> varint_field(field)
  }
}

/// Decode repeated varint field `number` using scalar `decoder`, accepting
/// packed/unpacked/mixed occurrences in wire order. Invalid varints and scalar
/// values return DecodeError records.
/// Example: `run(<<8, 1, 10, 1, 2>>, repeated_varint(1, int64_field))`
/// returns `Ok([1, 2])`.
pub fn repeated_varint(
  number: Int,
  decoder: fn(Field) -> Result(a, DecodeError),
) -> Decoder(List(a)) {
  repeated_scalar(number, wire.Varint, decoder)
}

/// Decode repeated 32-bit field `number` using scalar `decoder`, accepting
/// packed/unpacked/mixed occurrences in wire order. Invalid lengths and scalar
/// values return DecodeError records.
/// Example: `run(<<>>, repeated_fixed32(1, float_field))` returns `Ok([])`.
pub fn repeated_fixed32(
  number: Int,
  decoder: fn(Field) -> Result(a, DecodeError),
) -> Decoder(List(a)) {
  repeated_scalar(number, wire.Fixed32, decoder)
}

/// Decode repeated 64-bit field `number` using scalar `decoder`, accepting
/// packed/unpacked/mixed occurrences in wire order. Invalid lengths and scalar
/// values return DecodeError records.
/// Example: `run(<<>>, repeated_fixed64(1, double_field))` returns `Ok([])`.
pub fn repeated_fixed64(
  number: Int,
  decoder: fn(Field) -> Result(a, DecodeError),
) -> Decoder(List(a)) {
  repeated_scalar(number, wire.Fixed64, decoder)
}

fn repeated_scalar(
  number: Int,
  wire_type: wire.WireType,
  decoder: fn(Field) -> Result(a, DecodeError),
) -> Decoder(List(a)) {
  repeated_field(number, fn(field) {
    case field.wire_type {
      wire.LengthDelimited ->
        decode_packed_scalar(field.data, wire_type, decoder, [])
      _ -> result.map(decoder(field), fn(value) { [value] })
    }
  })
  |> map(list.flatten)
}

fn decode_packed_scalar(
  data: BitArray,
  wire_type: wire.WireType,
  decoder: fn(Field) -> Result(a, DecodeError),
  reversed: List(a),
) -> Result(List(a), DecodeError) {
  case data {
    <<>> -> Ok(list.reverse(reversed))
    _ -> {
      let parsed = case wire_type {
        wire.Varint -> decode_varint_raw(data)
        wire.Fixed32 -> decode_fixed32_raw(data)
        wire.Fixed64 -> decode_fixed64_raw(data)
        _ ->
          Error(
            DecodeError(
              "packable scalar wire type",
              "unsupported wire type",
              [],
            ),
          )
      }
      case parsed {
        Error(error) -> Error(error)
        Ok(#(raw, rest)) ->
          case decoder(Field(0, wire_type, raw)) {
            Error(error) -> Error(error)
            Ok(value) ->
              decode_packed_scalar(rest, wire_type, decoder, [value, ..reversed])
          }
      }
    }
  }
}
