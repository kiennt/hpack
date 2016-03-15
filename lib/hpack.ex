defmodule HPACK do
  alias HPACK.{Context, Decoder, Encoder}

  def encode(headers), do: encode(headers, Context.new)
  def encode(headers, context), do: Encoder.process(headers, context, <<>>)

  def decode(bin), do: decode(bin, Context.new)
  def decode(bin, context), do: Decoder.process(bin, context, [])
end
