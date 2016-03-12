defmodule HPACKStringTest do
  use ExUnit.Case
  doctest HPACK.String

  test "decode normal string" do
    bin = <<0::1, 8::7, ?C, ?o, ?m, ?m, ?a, ?n, ?d, ?s, 10::3>>
    assert {"Commands", <<10::3>>} == HPACK.String.decode(bin)
  end

  test "decode huffman string" do
    bin = <<1::1,
            8::7,         # now it's 8 bytes
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
          >>
    assert {"CommandsCo", <<10::3>>} == HPACK.String.decode(bin)
  end
end
