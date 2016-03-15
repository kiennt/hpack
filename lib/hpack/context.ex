defmodule HPACK.Context do
  defstruct max_size: 4096, table: [], size: 0, encode: :incremental, huffman: true

  @static_table [
    {1, ":authority", ""},
    {2, ":method", "GET"},
    {3, ":method", "POST"},
    {4, ":path", "/"},
    {5, ":path", "/index.html"},
    {6, ":scheme", "http"},
    {7, ":scheme", "https"},
    {8, ":status", "200"},
    {9, ":status", "204"},
    {10, ":status", "206"},
    {11, ":status", "304"},
    {12, ":status", "400"},
    {13, ":status", "404"},
    {14, ":status", "500"},
    {15, "accept-charset", ""},
    {16, "accept-encoding", "gzip, deflate"},
    {17, "accept-language", ""},
    {18, "accept-ranges", ""},
    {19, "accept", ""},
    {20, "access-control-allow-origin", ""},
    {21, "age", ""},
    {22, "allow", ""},
    {23, "authorization", ""},
    {24, "cache-control", ""},
    {25, "content-disposition", ""},
    {26, "content-encoding", ""},
    {27, "content-language", ""},
    {28, "content-length", ""},
    {29, "content-location", ""},
    {30, "content-range", ""},
    {31, "content-type", ""},
    {32, "cookie", ""},
    {33, "date", ""},
    {34, "etag", ""},
    {35, "expect", ""},
    {36, "expires", ""},
    {37, "from", ""},
    {38, "host", ""},
    {39, "if-match", ""},
    {40, "if-modified-since", ""},
    {41, "if-none-match", ""},
    {42, "if-range", ""},
    {43, "if-unmodified-since", ""},
    {44, "last-modified", ""},
    {45, "link", ""},
    {46, "location", ""},
    {47, "max-forwards", ""},
    {48, "proxy-authenticate", ""},
    {49, "proxy-authorization", ""},
    {50, "range", ""},
    {51, "referer", ""},
    {52, "refresh", ""},
    {53, "retry-after", ""},
    {54, "server", ""},
    {55, "set-cookie", ""},
    {56, "strict-transport-security", ""},
    {57, "transfer-encoding", ""},
    {58, "user-agent", ""},
    {59, "vary", ""},
    {60, "via", ""},
    {61, "www-authenticate", ""}
  ]

  def new(options \\ %{}) do
    %__MODULE__{
      max_size: options[:max_size] || 4096,
      table: [],
      size: 0,
      encode: options[:encode] || :incremental,
      huffman: options[:huffman] || true
    }
  end

  @doc """
  Get header at specified index in table
  http://httpwg.org/specs/rfc7541.html#string.literal.representation
  """
  @static_table
  |> Enum.each(fn({index, name, value}) ->
    def at(_, unquote(index)), do: {unquote(name), unquote(value)}
  end)
  def at(context, index), do: Enum.at(context.table, index - 62)

  @doc """
  Find index of a header
  http://httpwg.org/specs/rfc7541.html#string.literal.representation
  """
  def find(%__MODULE__{table: table}, {name, value}) do
    index = Enum.find_index(table, fn({n, v}) -> n == name && v == value end)
    if index do
      {:indexed, index + 62}
    else
      name_index = Enum.find_index(table, fn({n, _}) -> n == name end)
      if name_index do
        {:name_index, name_index + 62}
      else
        static_find({name, value})
      end
    end
  end

  @doc """
  Change size of dynamic table
  http://httpwg.org/specs/rfc7541.html#string.literal.representation
  """
  def change_size(%__MODULE__{table: table, size: size} = context, new_size) do
    do_change_size(%__MODULE__{
      max_size: new_size,
      table: table,
      size: size,
      encode: context.encode,
      huffman: context.huffman,
    })
  end

  @doc """
  Add new header into dynamic table
  http://httpwg.org/specs/rfc7541.html#string.literal.representation
  """
  def add(context, header) do
    do_add(context, header, entry_size(header))
  end

  #############################################################################
  # Private functions
  #############################################################################

  @static_table
  |> Enum.each(fn({index, name, value}) ->
    defp static_find({unquote(name), unquote(value)}), do: {:indexed, unquote(index)}
  end)
  @static_table
  |> Enum.each(fn({index, name, value}) ->
    defp static_find({unquote(name), _}), do: {:name_index, unquote(index)}
  end)
  defp static_find({_, _}), do: {:none}


  defp do_change_size(%__MODULE__{max_size: max_size, size: size} = context) when max_size >= size,
    do: context
  defp do_change_size(context),
    do: do_change_size(drop_last(context))

  defp do_add(%__MODULE__{max_size: max_size, table: table, size: size} = context, header, header_size)
      when max_size >= size + header_size do
    %__MODULE__{
      max_size: max_size,
      table: [header | table],
      size: size + header_size,
      encode: context.encode,
      huffman: context.huffman,
    }
  end
  defp do_add(%__MODULE__{max_size: max_size} = context, _, header_size) when header_size > max_size do
    %__MODULE__{
      max_size: max_size,
      table: [],
      size: 0,
      encode: context.encode,
      huffman: context.huffman,
    }
  end
  defp do_add(context, header, header_size) do
    do_add(drop_last(context), header, header_size)
  end

  def drop_last(%__MODULE__{table: []} = context) do
    context
  end
  def drop_last(%__MODULE__{max_size: max_size, table: table, size: size} = context) do
    [last | new_table] = Enum.reverse(table)
    %__MODULE__{
      max_size: max_size,
      table: Enum.reverse(new_table),
      size: size - entry_size(last),
      encode: context.encode,
      huffman: context.huffman,
    }
  end

  def entry_size({name, value}), do: 32 + byte_size(name) + byte_size(value)
end
