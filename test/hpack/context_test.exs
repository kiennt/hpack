defmodule HPACKContextTest do
  use ExUnit.Case
  alias HPACK.Context

  test "add header without resize table" do
    context = %Context{max_size: 150, table: [{"name1", "value1"}], size: 43}
    new_context = Context.add(context, {"name2", "value2"})
    assert %Context{max_size: 150, table: [{"name2", "value2"}, {"name1", "value1"}], size: 86} == new_context
  end

  test "add header with resize table" do
    context = %Context{max_size: 85, table: [{"name1", "value1"}], size: 43}
    new_context = Context.add(context, {"name2", "value2"})
    assert %Context{max_size: 85, table: [{"name2", "value2"}], size: 43} == new_context
  end

  test "add header with empty table" do
    context = %Context{max_size: 43, table: [{"name1", "value1"}], size: 43}
    new_context = Context.add(context, {"name20", "value20"})
    assert %Context{max_size: 43, table: [], size: 0} == new_context
  end

  test "change size without resize table" do
    context = %Context{max_size: 150, table: [{"name1", "value1"}], size: 43}
    new_context = Context.change_size(context, 160)
    assert %Context{max_size: 160, table: [{"name1", "value1"}], size: 43} == new_context
  end

  test "change size with resize table" do
    context = %Context{max_size: 150, table: [{"name1", "value1"}], size: 43}
    new_context = Context.change_size(context, 40)
    assert %Context{max_size: 40, table: [], size: 0} == new_context
  end

  test "find header in static table" do
    context = %Context{}
    assert {:indexed, 59} == Context.find(context, {"vary", ""})
    assert {:name_index, 59} == Context.find(context, {"vary", "hello"})
  end

  test "find header in dynamic table" do
    context = %Context{table: [{"a", "a"}, {"a", "b"}]}
    assert {:indexed, 62} == Context.find(context, {"a", "a"})
    assert {:indexed, 63} == Context.find(context, {"a", "b"})
    assert {:name_index, 62} == Context.find(context, {"a", "c"})
    assert {:none} == Context.find(context, {"b", "c"})
  end
end
