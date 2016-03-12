defmodule HPACK do
  alias HPACK.{Context, Decoder}

  def encode(headers, options) do
    "hello"
  end

  def decode(bin), do: decode(bin, Context.new)
  def decode(bin, context), do: Decoder.process(bin, context, [])
end
