defmodule HPACKIntegerTest do
  use ExUnit.Case
  alias HPACK.Integer
  doctest Integer

  Enum.map([
    {10, 5, <<10::5>>},
    {1337, 5, <<31::5, 154, 10>>},
    {42, 8, <<42>>}
  ], fn(value) ->
    {number, prefix, bin} = value
    test "encode #{number} using a #{prefix}-bit prefix" do
      assert Integer.encode(unquote(number), unquote(prefix)) == unquote(Macro.escape(bin))
      {decode_number, _} = Integer.decode(unquote(Macro.escape(bin)), unquote(prefix))
      assert decode_number == unquote(number)
    end
  end)

  test "decode" do
    assert {10, <<>>} == Integer.decode(<<10::5>>, 5)
    assert {31, <<>>} == Integer.decode(<<31::5>>, 5)
    assert {41, <<>>} == Integer.decode(<<31::5, 10>>, 5)
    assert {1337, <<>>} == Integer.decode(<<31::5, 154, 10>>, 5)
    assert {1337, <<0::1>>} == Integer.decode(<<31::5, 154, 20::9>>, 5)
    assert {7, <<1::1, 131>>} = Integer.decode(<<15, 131>>, 7)
  end
end
