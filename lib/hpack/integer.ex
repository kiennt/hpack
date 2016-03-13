defmodule HPACK.Integer do
  use Bitwise

  @doc """
  Encoding integer with format describe at
  http://httpwg.org/specs/rfc7541.html#integer.representation
  """
  @spec encode(number, number) :: binary
  def encode(i, n) when i < bsl(1, n) - 1 do
     <<i::size(n)>>
  end
  def encode(i, n) do
    prefix = bsl(1, n) - 1
    remain = i - prefix
    bin = do_encode(remain, <<>>)
    <<prefix::size(n), bin::binary>>
  end

  defp do_encode(value, bin_acc) when value < 128,
    do: <<bin_acc::binary, value>>
  defp do_encode(value, bin_acc) do
    do_encode(div(value, 128), <<bin_acc::binary, 128 + rem(value, 128)>>)
  end

  @doc """
  Decoding integer with format describe at
  http://httpwg.org/specs/rfc7541.html#integer.representation
  """
  @spec decode(binary, number) :: {number, binary}
  1..8
  |> Enum.each(fn(index) ->
    value = bsl(1, index) - 1
    def decode(<<unquote(value)::unquote(index), bin::bitstring>>, unquote(index)) do
      do_decode(unquote(index), bin, unquote(value), 0)
    end
  end)
  def decode(bin, n) do
    <<value::size(n), remain::bitstring>> = bin
    {value, remain}
  end

  defp do_decode(_, <<>>, value, _),
    do: {value, <<>>}
  defp do_decode(_, <<0::1, next::7, bin::bitstring>>, value, m),
    do: {value + next * bsl(1, m), bin}
  defp do_decode(n, <<1::1, next::7, bin::bitstring>>, value, m) do
    do_decode(n, bin, value + next * bsl(1, m), m + 7)
  end
end
