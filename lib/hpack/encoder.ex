defmodule HPACK.Encoder do
  alias HPACK.{Integer, String, Context, ParseError}

  def process([], context, bin) do: {bin, context}
  def process([{name, value} | tail], context, bin) do
    {new_bin, new_context} =
      case Context.find(context, {name, value}) do
        {:indexed, index} -> encode_indexed(index, context)
        {:name_index, index} -> encode_header(index, name, value, context)
        {:none} -> encode_header(nil, name, value, context)
      end
    process(tail, new_context, bin <> new_bind)
  end

  #############################################################################
  # Private functions
  #############################################################################

  # indexed header field
  # http://httpwg.org/specs/rfc7541.html#indexed.header.representation
  defp encode_indexed(index, context) do
    bin = Integer.encode(index, 7)
    {<<1::1, bin::bitstring>>, context}
  end

  defp encode_header(index, name, value, context) do
    case context.encode do
      :incremental -> encode_literal_with_incremental_indexing(index, name, value, context)
      :without_index -> encode_literal_without_indexing(index, name, value, context)
      :never_index -> encode_literal_never_indexing(index, name, value, context)
    end
  end

  # http://httpwg.org/specs/rfc7541.html#literal.header.with.incremental.indexing
  # literal header field with incremental index
  defp encode_literal_with_incremental_indexing(nil, name, value, context) do
    new_context = Context.add(context, {name, value})
    {encode_name_and_value(<<1::2>>, 6, name, value), new_context}
  end
  defp encode_literal_with_incremental_indexing(index, name, value, context) do
    new_context = Context.add(context, {name, value})
    {encode_index_and_value(<<1::2>>, 6, index, value), new_context}
  end

  # literal header field without index
  # http://httpwg.org/specs/rfc7541.html#literal.header.without.indexing
  defp encode_literal_without_indexing(nil, name, value, context) do
    {encode_name_and_value(<<0::4>>, 4, name, value), context}
  end
  defp encode_literal_without_indexing(index, name, value, context) do
    {encode_index_and_value(<<0::4>>, 4, index, value), context}
  end

  # literal header field never index
  # http://httpwg.org/specs/rfc7541.html#literal.header.never.indexed
  defp encode_literal_never_indexing(nil, name, value, context) do
    {encode_name_and_value(<<1::4>>, 4, name, value), context}
  end
  defp encode_literal_never_indexing(index, name, value, context) do
    {encode_index_and_value(<<1::4>>, 4, index, value), context}
  end

  defp encode_index_and_value(prefix_bin, size, index, value) do
    index_bin = Integer.encode(index, size)
    value_bin = String.encode(value)
    <<prefix_bin::bitstring, index_bin::bitstring, value_bin::bitstring>>
  end
  defp encode_name_and_value(prefix_bin, size, name, value) do
    name_bin = String.encode(name, size)
    value_bin = String.encode(value)
    left_size = 8 - size
    <<prefix_bin::bitstring, 0::left_size, name_bin::bitstring, value_bin::bitstring>>
  end
end
