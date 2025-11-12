defmodule Sales do
  @type segment :: :enterprise | :strategic | :existing | :private
  @type sales_channel :: :direct | :partner | :reseller | :online
  @type region :: :latam | :amer | :emea
  @type country_code :: :ba | :be | :bl | :ca | :ch | :fr | :na | :us

  defmodule SalesOrgId do
    use TypedStruct

    typedstruct enforce: true do
      field :value, String.t()
    end

    def new(value) when is_binary(value) do
      %__MODULE__{value: value}
    end
  end

  defmodule Sector do
    use TypedStruct

    typedstruct enforce: true do
      field :value, String.t()
    end

    def new(value) when is_binary(value) do
      %__MODULE__{value: value}
    end
  end

  defmodule Account do
    use TypedStruct

    @type attribute :: :region | :country | :sector | :segment | :channel

    typedstruct enforce: true do
      field :id, pos_integer()
      field :region, Sales.region()
      field :country, Sales.country_code()
      field :sector, Sales.Sector.t()
      field :segment, Sales.segment()
      field :channel, Sales.sales_channel()
    end

    @spec new(
            pos_integer(),
            Sales.region(),
            Sales.country_code(),
            Sales.Sector.t(),
            Sales.segment(),
            Sales.sales_channel()
          ) :: t()
    def new(id, region, country, sector, segment, channel) do
      %__MODULE__{
        id: id,
        region: region,
        country: country,
        sector: sector,
        segment: segment,
        channel: channel
      }
    end
  end

  defmodule Rule do
    defmodule Equals do
      use TypedStruct

      typedstruct enforce: true do
        field :attribute_name, Account.attribute()
        field :value, term()
      end

      @spec new(Account.attribute(), term()) :: t()
      def new(attribute_name, value) when is_atom(attribute_name) do
        %__MODULE__{attribute_name: attribute_name, value: value}
      end
    end

    defmodule And do
      use TypedStruct

      typedstruct enforce: true do
        field :a, Rule.t()
        field :b, Rule.t()
      end

      @spec new(Rule.t(), Rule.t()) :: Rule.t()
      def new(a, b) do
        %__MODULE__{a: a, b: b}
      end
    end

    defmodule Or do
      use TypedStruct

      typedstruct enforce: true do
        field :a, Rule.t()
        field :b, Rule.t()
      end

      @spec new(Rule.t(), Rule.t()) :: Rule.t()
      def new(a, b) do
        %__MODULE__{a: a, b: b}
      end
    end

    defmodule Not do
      use TypedStruct

      typedstruct enforce: true do
        field :rule, Rule.t()
      end

      @spec new(Rule.t()) :: Rule.t()
      def new(rule) do
        %__MODULE__{rule: rule}
      end
    end

    @type t :: Equals.t() | And.t() | Or.t() | Not.t()

    def r_eq(attribute_name, value), do: Equals.new(attribute_name, value)
    def r_and(a, b), do: And.new(a, b)
    def r_or(a, b), do: Or.new(a, b)
    def r_not(rule), do: Not.new(rule)
    def r_any(rules), do: Enum.reduce(rules, fn r, acc -> r_or(acc, r) end)
    def r_all(rules), do: Enum.reduce(rules, fn r, acc -> r_and(acc, r) end)

    def r_contains(attribute, options) do
      options
      |> Enum.map(&r_eq(attribute, &1))
      |> Enum.reduce(&r_or/2)
    end

    @spec get(Account.t(), Account.attribute()) :: term()
    def get(account, attr) do
      Map.fetch!(account, attr)
    end

    def interpret(rule, account) do
      case rule do
        %Equals{attribute_name: attribute, value: value} ->
          get(account, attribute) == value

        %Not{rule: rule} ->
          !interpret(rule, account)

        %And{a: a, b: b} ->
          interpret(a, account) and interpret(b, account)

        %Or{a: a, b: b} ->
          interpret(a, account) or interpret(b, account)
      end
    end
  end

  @spec example_accounts() :: list(Account.t())
  def example_accounts do
    [
      Account.new(1, :amer, :us, Sector.new("finance"), :strategic, :direct),
      Account.new(2, :amer, :ch, Sector.new("medical"), :private, :partner),
      Account.new(3, :amer, :ba, Sector.new("finance"), :enterprise, :reseller),
      Account.new(4, :amer, :ca, Sector.new("education"), :existing, :reseller),
      Account.new(5, :emea, :bl, Sector.new("retail"), :enterprise, :online)
    ]
  end

  def example_rule_1 do
    import Rule

    r_eq(:region, :emea)
    |> r_and(r_eq(:segment, :public))
    |> r_or(r_not(r_eq(:region, :latam)))
  end

  def example_rule_2 do
    import Rule

    [
      r_any([r_eq(:country, :us), r_eq(:country, :fr), r_eq(:country, :be)]),
      r_all([r_eq(:country, :na), r_eq(:segment, :enterprise)])
    ]
  end

  def example_rule_3 do
    import Rule

    r_contains(:country, [:us, :be, :fr])
    |> r_and(
      r_eq(:segment, :public)
      |> r_or(r_not(r_eq(:region, :latam)))
    )
  end

  def rule_for_org_111(account) do
    import Rule

    rule =
      r_eq(:region, :emea)
      |> r_and(r_not(r_contains(:country, [:us, :be, :fr])))

    if interpret(rule, account) do
      SalesOrgId.new("111")
    end
  end
end
