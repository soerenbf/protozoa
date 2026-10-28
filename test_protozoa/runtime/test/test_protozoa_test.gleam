//// Generated service wrappers and repeated fields compose with runtime codecs.

import generated/combined/app as a
import generated/combined/service.{
  type TestserviceTestRequest, TestserviceTestRequest, TestserviceTestResponse,
  decode_testservice_test_response, encode_testservice_test_request,
  process_service,
}
import generated/combined/types.{
  TypesRepeatedTypes, decode_types_repeated_types, encode_types_repeated_types,
}
import gleam/option.{None, Some}
import gleeunit

/// Run runtime integration tests with `gleam test`.
pub fn main() {
  gleeunit.main()
}

/// Baseline imported messages and enum fields retain their values.
pub fn app_and_base_roundtrip_test() {
  let base = a.BaseBaseMessage("nested-id", a.BaseBaseStatusActive, None)
  let assert Ok(decoded) =
    a.decode_base_base_message(a.encode_base_base_message(base))
  let assert "nested-id" = decoded.id
  let assert a.BaseBaseStatusActive = decoded.status
  // Base field 3 explicitly selects UNKNOWN=0 rather than absence.
  let assert Ok(explicit) = a.decode_base_base_message(<<24, 0>>)
  let assert Some(a.BaseBaseStatusUnknown) = explicit.explicit_status
  let assert Ok(explicit_roundtrip) =
    a.decode_base_base_message(a.encode_base_base_message(explicit))
  let assert True = explicit_roundtrip == explicit
  let app =
    a.AppAppMessage(
      Some(base),
      a.BaseBaseStatusActive,
      None,
      None,
      None,
      None,
      None,
    )
  let assert Ok(decoded) =
    a.decode_app_app_message(a.encode_app_app_message(app))
  let assert Some(base) = decoded.base
  let assert a.BaseBaseStatusActive = decoded.status
}

/// The generated service wrapper decodes the request, calls the handler and encodes the response.
pub fn process_service_test() {
  let handler = fn(req: TestserviceTestRequest) {
    Ok(TestserviceTestResponse(result: "Processed: " <> req.data))
  }
  let request = TestserviceTestRequest(data: "test input")
  let request_bytes = encode_testservice_test_request(request)
  let assert Ok(response_bytes) = process_service(request_bytes, handler)
  let assert Ok(response) = decode_testservice_test_response(response_bytes)
  let assert "Processed: test input" = response.result
}

/// Generated repeated fields preserve element order.
pub fn repeated_types_roundtrip_test() {
  let msg =
    TypesRepeatedTypes(
      strings: ["a", "b", "c"],
      numbers: [1, 2, 3, 4, 5],
      flags: [True, False, True],
      messages: [],
      states: [],
    )
  let assert Ok(decoded) =
    decode_types_repeated_types(encode_types_repeated_types(msg))
  let assert ["a", "b", "c"] = decoded.strings
  let assert [1, 2, 3, 4, 5] = decoded.numbers
  let assert [True, False, True] = decoded.flags
}

/// Generated repeated fields default to empty lists.
pub fn empty_repeated_roundtrip_test() {
  let msg =
    TypesRepeatedTypes(
      strings: [],
      numbers: [],
      flags: [],
      messages: [],
      states: [],
    )
  let assert Ok(decoded) =
    decode_types_repeated_types(encode_types_repeated_types(msg))
  let assert [] = decoded.strings
  let assert [] = decoded.numbers
  let assert [] = decoded.flags
}
