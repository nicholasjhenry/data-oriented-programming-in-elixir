defmodule Sales do
  @type segment :: :enterprise | :strategic | :existing | :private
  @type sales_channel :: :direct | :partner | :reseller | :online
  @type region :: :latam | :amer | :emea
  @type country_code :: :ba | :bl | :ca | :ch | :us

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
        field :value, String.t()
      end

      @spec new(Account.attribute(), String.t()) :: t()
      def new(attribute_name, value) when is_atom(attribute_name) and is_binary(value) do
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

  def example_rules do
    [
      Rule.Equals.new(:region, "amer"),
      Rule.Equals.new(:segment, "enterprise")
    ]
  end
end
