defmodule Sales do
  @type segment :: :enterprise | :strategic | :existing | :private
  @type channel :: :direct | :partner | :reseller | :online
  @type region :: :latam | :amer | :emea
  @type country_code :: :ba | :be | :bl | :ca | :ch | :fr | :na | :us

  @type attribute :: :region | :country | :sector | :segment | :channel

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

  @type sector() :: Sector.t()

  defmodule Account do
    use TypedStruct

    typedstruct enforce: true do
      field :id, pos_integer()
      field :region, Sales.region()
      field :country, Sales.country_code()
      field :sector, Sales.Sector.t()
      field :segment, Sales.segment()
      field :channel, Sales.channel()
    end

    @spec new(
            pos_integer(),
            Sales.region(),
            Sales.country_code(),
            Sales.Sector.t(),
            Sales.segment(),
            Sales.channel()
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

    @spec region(t()) :: Sales.region()
    def region(%__MODULE__{region: region}), do: region

    @spec country(t()) :: Sales.country_code()
    def country(%__MODULE__{country: country}), do: country

    @spec sector(t()) :: Sales.sector()
    def sector(%__MODULE__{sector: sector}), do: sector

    @spec segment(t()) :: Sales.segment()
    def segment(%__MODULE__{segment: segment}), do: segment

    @spec channel(t()) :: Sales.channel()
    def channel(%__MODULE__{channel: channel}), do: channel
  end

  defmodule Attr do
    @type t(value_type) :: %__MODULE__{
            attribute: Sales.attribute(),
            getter: (Account.t() -> value_type)
          }

    defstruct [:attribute, :getter]

    def new(attribute, getter) do
      %__MODULE__{attribute: attribute, getter: getter}
    end
  end

  # Predefined attribute accessors
  @spec channel() :: Attr.t(channel())
  def channel do
    Attr.new(:channel, &Account.channel/1)
  end

  @spec sector() :: Attr.t(sector())
  def sector do
    Attr.new(:sector, &Account.sector/1)
  end

  @spec country() :: Attr.t(country_code())
  def country do
    Attr.new(:country, &Account.country/1)
  end

  @spec region() :: Attr.t(region())
  def region do
    Attr.new(:region, &Account.region/1)
  end

  @spec segment() :: Attr.t(segment())
  def segment do
    Attr.new(:segment, &Account.segment/1)
  end

  @type attr() ::
          Attr.t(channel())
          | Attr.t(sector())
          | Attr.t(country_code())
          | Attr.t(region())
          | Attr.t(segment())

  defmodule Rule do
    defmodule Result do
      use TypedStruct

      typedstruct enforce: true do
        field :matched, boolean()
        field :expected, String.t()
        field :found, String.t()
      end

      @spec new(boolean(), term(), term()) :: t()
      def new(matched, expected, found) do
        %__MODULE__{matched: matched, expected: expected, found: found}
      end
    end

    defmodule Equals do
      @type t :: %__MODULE__{
              attr: Sales.attr(),
              value: term()
            }

      defstruct [:attr, :value]

      @spec new(Sales.attr(), term()) :: t()
      def new(attr, value) do
        %__MODULE__{attr: attr, value: value}
      end

      defimpl Jason.Encoder do
        def encode(struct, opts) do
          Jason.Encode.map(
            %{
              "type" => "EQ",
              "field" => struct.attr.attribute,
              "value" => struct.value
            },
            opts
          )
        end
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

    def r_eq(attribute_name, value) do
      attr =
        case attribute_name do
          :region -> Sales.region()
          :country -> Sales.country()
          :sector -> Sales.sector()
          :segment -> Sales.segment()
          :channel -> Sales.channel()
        end

      Equals.new(attr, value)
    end

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

    def interpret(rule, account) do
      case rule do
        %Equals{attr: attr, value: value} ->
          found = attr.getter.(account)
          field = attr.attribute
          Result.new(found == value, "#{field} == #{value}", "#{field} == #{found}")

        %Not{rule: rule} ->
          result = interpret(rule, account)
          Result.new(!result.matched, "NOT(#{result.expected})", "#{result.found}")

        %And{a: a, b: b} ->
          result_a = interpret(a, account)
          result_b = interpret(b, account)

          Result.new(
            result_a.matched and result_b.matched,
            "(#{result_a.expected} AND #{result_b.expected})",
            "(#{result_a.found} AND #{result_b.found})"
          )

        %Or{a: a, b: b} ->
          result_a = interpret(a, account)
          result_b = interpret(b, account)

          Result.new(
            result_a.matched or result_b.matched,
            "(#{result_a.expected} OR #{result_b.expected})",
            "(#{result_a.found} OR #{result_b.found})"
          )
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

    result = interpret(rule, account)

    if result.matched do
      {:passed, SalesOrgId.new("111"), result}
    else
      {:failed, result}
    end
  end
end
