defmodule Solr do
  @moduledoc """
  Tools to ease the use of solr with dynamic fields based schemas
  """

  @doc """
  Example usage:

  defmodule Solr.DynamicFields.Banana do
    require Solr
  
    Solr.fields_mapping [
      solr_query_field: [
        [:also_text],
        [:text, :to, :transform, Solr.transform_with(fn x -> String.replace(x, ~r/\s/, "") end)],
      ],
      solr_field_str: [
        [:text],
        [:data, :to, :duplicate_and_update, Solr.update_with(fn x -> %{upcased: String.upcase(x.the_field)} end), :upcased],
      ],
      solr_field_bool: [
        [:flag1],
        [:flag2],
      ],
      solr_field_int_m: [
        [:path, :to, Access.all(), :ints],
      ],
    ]
  end
  """
  defmacro fields_mapping(t) do
    call? = fn {_, _, _} -> true ; _ -> false end

    x = Enum.flat_map(t, fn {type, fields} ->
      Enum.map(fields, fn source_path ->
        {r_transforms, [source_field | r_path]} = Enum.split_while(Enum.reverse(source_path), call?)
        transforms = Enum.reverse(r_transforms)
        path = Enum.reverse(r_path)
        dynamic_query_field = :"#{source_field}_#{type}" # <-- lookit da colon
        {path, {[source_field | transforms], [dynamic_query_field]}}
      end)
    end)

    literal? = fn {_, _, _} -> false ; _ -> true end

    in_out_pairs = Enum.map(x, fn {path, {[source_field | _], [dynamic_query_field]}} ->
      source_field = String.to_atom(Enum.join(Enum.filter(path, literal?) ++ [source_field], "_"))
      query_field = String.to_atom(Enum.join(Enum.filter(path, literal?) ++ [dynamic_query_field], "_"))
      {source_field, query_field}
    end)

    quote do
      def add_dynamic_fields(t) do
        Enum.reduce(unquote(x), t, fn
          {[], {source_field, dynamic_query_field}}, acc ->
            case get_in(acc, source_field) do
              nil -> acc
              x -> put_in(acc, dynamic_query_field, x)
            end

          {path, {source_field, dynamic_query_field}}, acc ->
            # We don't want to insert a nil, so we have to use get_and_update_in
            # instead of update_in.
            add_or_nothing = fn
              nil -> :pop
              x -> case get_in(x, source_field) do
                nil -> {nil, x}
                y -> {nil, put_in(x, dynamic_query_field, y)}
              end
            end
            {_, acc} = get_and_update_in(acc, path, add_or_nothing)
            acc
        end)
      end

      def to_solr_field(x) do
        Map.fetch!(unquote(Macro.escape(Map.new(in_out_pairs))), x)
      end

      def from_solr_field(x) do
        Map.fetch!(unquote(Macro.escape(Map.new(in_out_pairs, fn {x, y} -> {y, x} end))), x)
      end

      def search_fields do
        unquote(Macro.escape(Enum.map(in_out_pairs, fn {field, _} -> field end)))
      end

      def solr_fields do
        unquote(Macro.escape(Enum.map(in_out_pairs, fn {_, field} -> field end)))
      end
    end
    #|> case do x -> IO.puts(Macro.to_string(x)) ; x |> IO.inspect() end
  end

  def escape(x) do
    String.replace(x, [":", " ", "\\", "\t", "\""], "\\", insert_replaced: 1)
  end

  def encode_query(t, opts \\ []) do
    root_operator = Keyword.get(opts, :root_op, "AND")
    multi_operator = Keyword.get(opts, :multi_op, "OR")
    t
    |> Enum.map(fn
      {:and, t} when is_map(t) -> "(#{encode_query(t, root_op: "AND")})"
      {:or, t} when is_map(t) -> "(#{encode_query(t, root_op: "OR")})"
      {k, %{not: xs}} when is_list(xs) -> "NOT+#{k}:(#{Enum.join(xs, "+#{multi_operator}+")})"
      {k, %{not: v}} -> "NOT+#{k}:#{v}"
      {k, xs} when is_list(xs) -> "#{k}:(#{Enum.join(xs, "+#{multi_operator}+")})"
      {k, v} -> "#{k}:#{v}"
    end)
    |> Enum.join("+#{root_operator}+")
    |> URI.encode()
    |> String.replace("%5C+", "%5C%2B") # special encode for the "+" character that has \\ before it
  end

  ### WARNING ! When not used as the last of a nested path for the fields_mapping,
  # be EXTREMELY careful to keep the passed content as is, and simply add to it,
  # otherwise you will lose everything but what you returned in the stored content in Riak.
  # Prefer using update_with/1 in that kind of case.

  def transform_with(f) when is_function(f, 1) do
    fn _, data, next -> next.(f.(data)) end
  end

  def transform_with({m, f, a}) do
    fn _, data, next -> next.(apply(m, f, [data | a])) end
  end

  def transform_with(m, f, a) do
    fn _, data, next -> next.(apply(m, f, [data | a])) end
  end

  def update_with(f) when is_function(f, 1) do
    fn _, data, next ->
      next.(Map.merge(data, f.(data), fn _, _, v -> v end))
    end
  end

  def dynamic_suffixes_bin do
    [
      "_query_field",
      "_solr_field_str",
      "_solr_field_str_m",
      "_solr_field_int",
      "_solr_field_int_m",
      "_solr_field_float",
      "_solr_field_float_m",
      "_solr_field_double",
      "_solr_field_double_m",
      "_solr_field_bool",
      "_solr_field_bool_m",
      "_solr_field_date",
      "_solr_field_date_m",

      "_stored_only_field_str",
      "_stored_only_field_str_m",
      "_stored_only_field_int",
      "_stored_only_field_int_m",
      "_stored_only_field_float",
      "_stored_only_field_float_m",
      "_stored_only_field_double",
      "_stored_only_field_double_m",
      "_stored_only_field_bool",
      "_stored_only_field_bool_m",
      "_stored_only_field_date",
      "_stored_only_field_date_m",
    ]
  end

  def remove_dynamic_fields(xs) when is_list(xs), do: Enum.map(xs, &remove_dynamic_fields/1)
  def remove_dynamic_fields(t) when is_map(t) do
    t
    |> Enum.filter(fn
      {k, _} when is_atom(k) -> not String.ends_with?(Atom.to_string(k), dynamic_suffixes_bin())
      {k, _} when is_binary(k) -> not String.ends_with?(k, dynamic_suffixes_bin())
      _ -> true
    end)
    |> Map.new(fn {k, v} -> {k, remove_dynamic_fields(v)} end)
  end
  def remove_dynamic_fields(x), do: x
end
