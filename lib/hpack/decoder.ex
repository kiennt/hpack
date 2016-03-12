defmodule HPACK.Decoder do
  alias HPACK.{Integer, String, Context, ParseError}

  def process(<<>>, context, headers) do
    {headers, context}
  end
  # indexed header field
  # http://httpwg.org/specs/rfc7541.html#indexed.header.representation
  def process(<<1::1, bin::bitstring>>, context, headers) do
    # IO.inspect "----------------------------------"
    # IO.inspect "process indexed header"
    # IO.inspect bin
    # IO.inspect context
    # IO.inspect headers
    process_indexed_header(bin, context, headers)
  end
  # http://httpwg.org/specs/rfc7541.html#literal.header.with.incremental.indexing
  # literal header field with incremental index
  def process(<<1::2, bin::bitstring>>, context, headers) do
    # IO.inspect "----------------------------------"
    # IO.inspect "process literal header with indexing"
    # IO.inspect bin
    # IO.inspect context
    # IO.inspect headers
    process_literal_header_with_indexing(bin, context, headers)
  end
  # literal header field without index
  # http://httpwg.org/specs/rfc7541.html#literal.header.without.indexing
  def process(<<0::4, bin::bitstring>>, context, headers) do
    # IO.inspect "----------------------------------"
    # IO.inspect "process literal header without indexing"
    # IO.inspect bin
    # IO.inspect context
    # IO.inspect headers
    process_literal_header_without_indexing(bin, context, headers)
  end
  # literal header field never index
  # http://httpwg.org/specs/rfc7541.html#literal.header.never.indexed
  def process(<<1::4, bin::bitstring>>, context, headers) do
    # IO.inspect "----------------------------------"
    # IO.inspect "process literal header never indexed"
    # IO.inspect bin
    # IO.inspect context
    # IO.inspect headers
    process_literal_header_never_indexed(bin, context, headers)
  end
  def process(<<1::3, bin::bitstring>>, context, headers) do
    # IO.inspect "----------------------------------"
    # IO.inspect "update dynamic table"
    # IO.inspect bin
    # IO.inspect context
    # IO.inspect headers
    update_dynamic_table_size(bin, context, headers)
  end

  #############################################################################
  # Private functions
  #############################################################################

  defp process_indexed_header(bin, context, headers) do
    {index, remain} = Integer.decode(bin, 7)
    header = Context.at(context, index)
    if header == nil do
      raise ParseError, message: "indexed header #{index} out of bound"
    end
    process(remain, context, headers ++ [header])
  end

  defp process_literal_header_with_indexing(<<0::6, bin::bitstring>>, context, headers) do
    {name, remain} = String.decode(bin)
    # IO.inspect "name #{name} remain #{remain}"
    process_literal_header_value_with_indexing(remain, context, name, headers)
  end
  defp process_literal_header_with_indexing(bin, context, headers) do
    {index, remain} = Integer.decode(bin, 6)
    {name, _} = Context.at(context, index)
    # IO.inspect "remain #{remain}"
    process_literal_header_value_with_indexing(remain, context, name, headers)
  end

  defp process_literal_header_value_with_indexing(bin, context, name, headers) do
    # IO.inspect "----------"
    # IO.inspect "process literal header value with indexing"
    # IO.inspect bin
    # IO.inspect context
    # IO.inspect name
    # IO.inspect headers
    {value, remain} = String.decode(bin)
    new_context = Context.add(context, {name, value})
    process(remain, new_context, headers ++ [{name, value}])
  end

  defp process_literal_header_without_indexing(<<0::4, bin::bitstring>>, context, headers) do
    {name, remain} = String.decode(bin)
    process_literal_header_value_without_indexing(remain, context, name, headers)
  end
  defp process_literal_header_without_indexing(bin, context, headers) do
    {index, remain} = Integer.decode(bin, 4)
    {name, _} = Context.at(context, index)
    process_literal_header_value_without_indexing(remain, context, name, headers)
  end
  defp process_literal_header_value_without_indexing(bin, context, name, headers) do
    {value, remain} = String.decode(bin)
    process(remain, context, headers ++ [{name, value}])
  end

  defp process_literal_header_never_indexed(bin, context, headers) do
    process_literal_header_without_indexing(bin, context, headers)
  end

  defp update_dynamic_table_size(bin, context, headers) do
    {max_size, remain} = Integer.decode(bin, 5)
    process(remain, Context.change_size(context, max_size), headers)
  end
end
