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
    end)
  end)

  ["test", "hpack-test-case", "raw-data"]
  |> Path.join
  |> File.ls!
  |> Enum.each(fn(file) ->
    for encode <- [:incremental, :without_index, :never_index],
        huffman <- [true, false],
        max_size <- [4016, 512] do
      test "encode #{file} #{encode}-#{huffman}-#{max_size}" do
        test_encode_file(unquote(file), unquote(encode), unquote(huffman), unquote(max_size))
      end
    end
  end)

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

  defp test_encode_file(file_name, encode, huffman, default_max_size) do
    cases = read_file("raw-data", file_name)
    max_size = Enum.at(cases, 0)["header_table_size"] || default_max_size
    context = HPACK.Context.new(%{max_size: max_size, encode: encode, huffman: huffman})
    cases
    |> Enum.reduce(context, fn(%{"headers" => map}, context) ->
      headers = convert_map_headers_to_list(map)
      {bin, new_context} = HPACK.encode(headers, context)
      {result_headers, _} = HPACK.decode(bin, context)
      assert headers == result_headers
      new_context
    end)
  end
end
