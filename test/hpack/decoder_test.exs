defmodule HPACKDecoderTest do
  use ExUnit.Case
  alias HPACK.{Context, ParseError}

  @context Context.new

  test "process empty binary" do
    assert {[], @context} == HPACK.Decoder.process(<<>>, @context, [])
  end

  test "process indexed headers" do
    assert {[{":method", "POST"}], @context} = HPACK.Decoder.process(<<131>>, @context, [])
  end

  test "process indexed headers raise exception when index out of bound" do
    assert_raise ParseError, fn ->
      HPACK.Decoder.process(<<191>>, @context, [])
    end
  end

  test "process literal header with indexing and literal name" do
    {headers, %Context{table: table}} = HPACK.Decoder.process(<<64, 1, 97, 1, 97>>, @context, [])
    assert [{"a", "a"}] == table
    assert [{"a", "a"}] == headers
  end

  test "process literal header with indexing and indexed name" do
    {headers, %Context{table: table}} = HPACK.Decoder.process(<<65, 1, 97>>, @context, [])
    assert [{":authority", "a"}] == headers
    assert [{":authority", "a"}] == table
  end

  test "process literal header without indexing and literal name" do
    {headers, %Context{table: table}} = HPACK.Decoder.process(<<0, 1, 97, 1, 97>>, @context, [])
    assert [] == table
    assert [{"a", "a"}] == headers
  end

  test "process literal header without indexing and indexed name" do
    {headers, %Context{table: table}} = HPACK.Decoder.process(<<1, 1, 97>>, @context, [])
    assert [] == table
    assert [{":authority", "a"}] == headers
  end

  test "process literal header never indexing and literal name" do
    {headers, %Context{table: table}} = HPACK.Decoder.process(<<16, 1, 97, 1, 97>>, @context, [])
    assert [] == table
    assert [{"a", "a"}] == headers
  end

  test "process literal header never indexing and indexed name" do
    {headers, %Context{table: table}} = HPACK.Decoder.process(<<17, 1, 97>>, @context, [])
    assert [] == table
    assert [{":authority", "a"}] == headers
  end

  test "update dynamic table size" do
    {headers, %Context{table: table}} = HPACK.Decoder.process(<<65, 1, 97, 66, 1, 98, 1::3, 31::5, 9>>, @context, [])
    assert [{":method", "b"}] == table
    assert [{":authority", "a"}, {":method", "b"}] == headers
  end
end
