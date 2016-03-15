defmodule HPACKIntegerTest do
  use ExUnit.Case
  alias HPACK.Integer
  doctest Integer

  [
    {10, 5, <<10::5>>, <<>>},
    {31, 5, <<31::5, 0>>, <<>>},
    {41, 5, <<31::5, 10>>, <<>>},
    {1337, 5, <<31::5, 154, 10>>, <<>>},
    {1337, 5, <<31::5, 154, 20::9>>, <<0::1>>},
    {7, 7, <<15, 131>>, <<1::1, 131>>}
  ]
  |> Stream.with_index
  |> Enum.each(fn({value, index}) ->
    {number, prefix, bin, left} = value

    test "decode case #{index}" do
      assert {unquote(number), unquote(Macro.escape(left))} == Integer.decode(unquote(Macro.escape(bin)), unquote(prefix))
    end

    test "encode case #{index}" do
      data = Integer.encode(unquote(number), unquote(prefix))
      assert unquote(Macro.escape(bin)) == <<data::bitstring, unquote(Macro.escape(left))::bitstring>>
    end
  end)
end
