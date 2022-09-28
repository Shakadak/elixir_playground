defmodule Type do
  defmacro data({:=, _, [type, constructor]}) do
    generate_data(type, [constructor])
  end

  defmacro data({:|, _, [{:=, _, [type, constructor]}, constructors]}) do
    constructors = [constructor | to_list(constructors)]
    generate_data(type, constructors)
  end

  @doc false
  def generate_data(type, constructors) do
    constructors = Enum.map(constructors, fn {name, _, context} ->
      arity = case context do
        x when is_atom(x) -> 0
        xs when is_list(xs) -> Enum.count(xs)
      end
      {name, arity}
    end)

    {type_name, _, type_context} = type
    _type_arity = case type_context do
      x when is_atom(x) -> 0
      xs when is_list(xs) -> Enum.count(xs)
    end

    ast_constructors = Enum.map(constructors, fn {name, arity} ->
      args = Macro.generate_unique_arguments(arity, __MODULE__)
      quote do
        defmacro unquote(name)(unquote_splicing(args)) do
          module = __MODULE__
          type_name = unquote(type_name)
          name = unquote(name)
          args = unquote(args)
          quote do
            %unquote(__MODULE__){unquote(type_name) => {unquote(name), unquote_splicing(args)}}
          end
          #|> case do x -> _ = IO.puts("#{name} ->\n#{Macro.to_string(x)}") ; x end
        end
      end
    end)

    quote do
      @enforce_keys [unquote(type_name)]
      defstruct [unquote(type_name)]

      unquote_splicing(ast_constructors)
    end
    |> case do x -> _ = IO.puts("data ->\n#{Macro.to_string(x)}") ; x end
  end

  @doc false
  def to_list({:|, _, [left, right]}) do
    [left | to_list(right)]
  end

  def to_list({_, _, _} = last) do
    [last]
  end

  defmacro record({:=, _, [_type, constructor]}) do
    {constructor_name, _, [{:%{}, _, fields}]} = constructor
    _constructor_arity = Enum.count(fields)

    {field_names, _field_types} = Enum.unzip(fields)
    args = Enum.map(field_names, &Macro.var(&1, __MODULE__))

    quote do
      @enforce_keys unquote(field_names)
      defstruct unquote(field_names)

      defmacro unquote(constructor_name)(unquote_splicing(args)) do
        module = __MODULE__
        struct_fields = Enum.zip(unquote(field_names), [unquote_splicing(args)])
        quote do
          %unquote(__MODULE__){unquote_splicing(struct_fields)}
        end
        #|> case do x -> _ = IO.puts("#{unquote(constructor_name)} ->\n#{Macro.to_string(x)}") ; x end
      end
    end
    |> case do x -> _ = IO.puts("record ->\n#{Macro.to_string(x)}") ; x end
  end
end
