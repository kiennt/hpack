defmodule HPACKStringTest do
  use ExUnit.Case
  doctest HPACK.String

  [
    {
      false,
      <<0::1, 8::7, ?C, ?o, ?m, ?m, ?a, ?n, ?d, ?s, 10::3>>,
      "Commands",
      <<10::3>>
    },
    {
      true,
      <<1::1,
        8::7,         # it's 8 bytes
        0b1011110::7, # $C  7
        0b00111::5,   # $o  5
        0b101001::6,  # $m  6
        0b101001::6,  # $m  6
        0b00011::5,   # $a  5
        0b101010::6,  # $n  6
        0b100100::6,  # $d  6
        0b01000::5,   # $s  5
        0b1011110::7, # $C  7
        0b00111::5,   # $o  5
        0x3fffffff::6,#   =64
        10::3
      >>,
      "CommandsCo",
      <<10::3>>
    },
  ]
  |> Stream.with_index
  |> Enum.each(fn({{huffman, bin, value, rest}, index}) ->
    test "decode case #{index}" do
      assert {unquote(value), unquote(Macro.escape(rest))} == HPACK.String.decode(unquote(Macro.escape(bin)))
    end

    test "encode case #{index}" do
      assert unquote(Macro.escape(bin)) == <<HPACK.String.encode(unquote(value), unquote(huffman))::bitstring, unquote(Macro.escape(rest))::bitstring>>
    end
  end)
end
