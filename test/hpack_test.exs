defmodule HPACKTest do
  use ExUnit.Case
  require Poison
  doctest HPACK

  Enum.each([
    "go-hpack",
    "haskell-http2-linear",
    "haskell-http2-linear-huffman",
    "haskell-http2-naive",
    "haskell-http2-naive-huffman",
    "haskell-http2-static",
    "haskell-http2-static-huffman",
    "nghttp2",
    "nghttp2-16384-4096",
    "nghttp2-change-table-size",
    "node-http2-hpack",
  ], fn(name) ->
    ["test", "hpack-test-case", name]
    |> Path.join
    |> File.ls!
    |> Enum.each(fn(file) ->
      test "decode #{name}/#{file}" do
        test_decode_file(unquote(name), unquote(file))
      end

      test "encode #{name}/#{file}" do
        test_encode_file(unquote(name), unquote(file))
      end
    end)
  end)

  [
    {
      <<130,132,134,65,138,160,228,29,19,157,9,184,240,30,7,83,3,42,47,42,144,122,138,170,105,210,154,196,192,23,117,119,127>>,
      [
        {":method", "GET"},
        {":path", "/"},
        {":scheme", "http"},
        {":authority", "localhost:8080"},
        {"accept", "*/*"},
        {"accept-encoding", "gzip, deflate"},
        {"user-agent", "nghttp2/0.7.7"}
      ]
    },
    {
      <<130,132,134,65,138,160,228,29,19,157,9,184,240,30,15,83,3,42,47,42,144,122,138,170,105,210,154,196,192,23,117,112,135,64,135,242,178,125,117,73,236,175,1,66,126,1,79,64,133,242,181,37,63,143,1,112,126,1,116,127,1,1,116>>,
      [
        {":method", "GET"},
        {":path", "/"},
        {":scheme", "http"},
        {":authority", "localhost:8081"},
        {"accept", "*/*"},
        {"accept-encoding", "gzip, deflate"},
        {"user-agent", "nghttp2/0.7.11"},
        {"x-tyktorp", "B"},
        {"x-tyktorp", "O"},
        {"x-meow", "p"},
        {"x-meow", "t"},
        {"x-tyktorp", "t"},
      ]
    }
  ]
  |> Stream.with_index
  |> Enum.each(fn({{bin, expected_headers}, index}) ->
    test "#{index}" do
      bin = unquote(Macro.escape(bin))
      {headers, _} = HPACK.decode(bin)
      assert headers == unquote(expected_headers)
    end
  end)

  test "decode consecutive header lists without huffman" do
    wire1 = "828684410f7777772e6578616d706c652e636f6d"
    result1 = [
      {":method", "GET"},
      {":scheme", "http"},
      {":path", "/"},
      {":authority", "www.example.com"},
    ]
    wire2 = "828684be58086e6f2d6361636865"
    result2 = [
      {":method", "GET"},
      {":scheme", "http"},
      {":path", "/"},
      {":authority", "www.example.com"},
      {"cache-control", "no-cache"}
    ]
    wire3 = "828785bf400a637573746f6d2d6b65790c637573746f6d2d76616c7565"
    result3 = [
      {":method", "GET"},
      {":scheme", "https"},
      {":path", "/index.html"},
      {":authority", "www.example.com"},
      {"custom-key", "custom-value"}
    ]

    {headers1, context1} = HPACK.decode(Octet.string_to_bin(wire1))
    assert headers1 == result1
    {headers2, context2} = HPACK.decode(Octet.string_to_bin(wire2), context1)
    assert headers2 == result2
    {headers3, _} = HPACK.decode(Octet.string_to_bin(wire3), context2)
    assert headers3 == result3
  end

  test "decode consecutive header lists with huffman" do
    wire1 = "828684418cf1e3c2e5f23a6ba0ab90f4ff"
    result1 = [
      {":method", "GET"},
      {":scheme", "http"},
      {":path", "/"},
      {":authority", "www.example.com"},
    ]
    wire2 = "828684be5886a8eb10649cbf"
    result2 = [
      {":method", "GET"},
      {":scheme", "http"},
      {":path", "/"},
      {":authority", "www.example.com"},
      {"cache-control", "no-cache"}
    ]
    wire3 = "828785bf408825a849e95ba97d7f8925a849e95bb8e8b4bf"
    result3 = [
      {":method", "GET"},
      {":scheme", "https"},
      {":path", "/index.html"},
      {":authority", "www.example.com"},
      {"custom-key", "custom-value"}
    ]

    {headers1, context1} = HPACK.decode(Octet.string_to_bin(wire1))
    assert headers1 == result1
    {headers2, context2} = HPACK.decode(Octet.string_to_bin(wire2), context1)
    assert headers2 == result2
    {headers3, _} = HPACK.decode(Octet.string_to_bin(wire3), context2)
    assert headers3 == result3
  end

  test "decode consecutive header lists without huffman and change max size" do
    wire1 = "4803333032580770726976617465611d4d6f6e2c203231204f637420323031332032303a31333a323120474d546e1768747470733a2f2f7777772e6578616d706c652e636f6d"
    result1 = [
      {":status", "302"},
      {"cache-control", "private"},
      {"date", "Mon, 21 Oct 2013 20:13:21 GMT"},
      {"location", "https://www.example.com"},
    ]
    wire2 = "4803333037c1c0bf"
    result2 = [
      {":status", "307"},
      {"cache-control", "private"},
      {"date", "Mon, 21 Oct 2013 20:13:21 GMT"},
      {"location", "https://www.example.com"},
    ]
    wire3 = "88c1611d4d6f6e2c203231204f637420323031332032303a31333a323220474d54c05a04677a69707738666f6f3d4153444a4b48514b425a584f5157454f50495541585157454f49553b206d61782d6167653d333630303b2076657273696f6e3d31"
    result3 = [
      {":status", "200"},
      {"cache-control", "private"},
      {"date", "Mon, 21 Oct 2013 20:13:22 GMT"},
      {"location", "https://www.example.com"},
      {"content-encoding", "gzip"},
      {"set-cookie", "foo=ASDJKHQKBZXOQWEOPIUAXQWEOIU; max-age=3600; version=1"},
    ]

    {headers1, context1} = HPACK.decode(Octet.string_to_bin(wire1), HPACK.Context.new(%{max_size: 256}))
    assert headers1 == result1
    {headers2, context2} = HPACK.decode(Octet.string_to_bin(wire2), context1)
    assert headers2 == result2
    {headers3, _} = HPACK.decode(Octet.string_to_bin(wire3), context2)
    assert headers3 == result3
  end

  test "decode consecutive header lists with huffman and change max size" do
    wire1 = "488264025885aec3771a4b6196d07abe941054d444a8200595040b8166e082a62d1bff6e919d29ad171863c78f0b97c8e9ae82ae43d3"
    result1 = [
      {":status", "302"},
      {"cache-control", "private"},
      {"date", "Mon, 21 Oct 2013 20:13:21 GMT"},
      {"location", "https://www.example.com"},
    ]
    wire2 = "4883640effc1c0bf"
    result2 = [
      {":status", "307"},
      {"cache-control", "private"},
      {"date", "Mon, 21 Oct 2013 20:13:21 GMT"},
      {"location", "https://www.example.com"},
    ]
    wire3 = "88c16196d07abe941054d444a8200595040b8166e084a62d1bffc05a839bd9ab77ad94e7821dd7f2e6c7b335dfdfcd5b3960d5af27087f3672c1ab270fb5291f9587316065c003ed4ee5b1063d5007"
    result3 = [
      {":status", "200"},
      {"cache-control", "private"},
      {"date", "Mon, 21 Oct 2013 20:13:22 GMT"},
      {"location", "https://www.example.com"},
      {"content-encoding", "gzip"},
      {"set-cookie", "foo=ASDJKHQKBZXOQWEOPIUAXQWEOIU; max-age=3600; version=1"},
    ]

    {headers1, context1} = HPACK.decode(Octet.string_to_bin(wire1), HPACK.Context.new(%{max_size: 256}))
    assert headers1 == result1
    {headers2, context2} = HPACK.decode(Octet.string_to_bin(wire2), context1)
    assert headers2 == result2
    {headers3, _} = HPACK.decode(Octet.string_to_bin(wire3), context2)
    assert headers3 == result3
  end

  #############################################################################
  # Private functions
  #############################################################################

  defp read_file(test_type, file_name) do
    %{"cases" => cases} =
      ["test", "hpack-test-case", test_type, file_name]
      |> Path.join
      |> File.read!
      |> Poison.decode!
    cases
  end

  defp convert_map_headers_to_list(map) do
    map
    |> Enum.map(fn(item) ->
      [key] = Map.keys(item)
      {key, item[key]}
    end)
  end

  defp test_decode_file(test_type, file_name) do
    cases = read_file(test_type, file_name)
    max_size = Enum.at(cases, 0)["header_table_size"] || 4096
    context = HPACK.Context.new(%{max_size: max_size})
    cases
    |> Enum.reduce(context, fn(%{"headers" => headers, "wire" => wire}, context) ->
      bin = Octet.string_to_bin(wire)
      {result, context} = HPACK.decode(bin, context)
      assert result == convert_map_headers_to_list(headers)
      context
    end)
  end

  defp test_encode_file(test_type, file_name) do
    cases = read_file(test_type, file_name)
    max_size = Enum.at(cases, 0)["header_table_size"] || 4096
    encode_context = HPACK.Context.new(%{max_size: max_size})
    decode_context = HPACK.Context.new(%{max_size: max_size})
    cases
    |> Enum.reduce({encode_context, decode_context}, fn(%{"headers" => map, "wire" => wire}, {ec, dc}) ->
      headers = convert_map_headers_to_list(map)
      {bin, ec} = HPACK.encode(headers, ec)
      {result_headers, dc} = HPACK.decode(bin, dc)
      assert headers == result_headers
      {ec, dc}
    end)
  end
end
