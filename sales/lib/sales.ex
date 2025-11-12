defmodule Sales do
  defmodule Account do
    use TypedStruct

    @type segment :enterprise | :strategic | :existing | :private
    @type sales_channel :direct | :partner | :reseller | :online
    @type region :latam | :amer | :emea
    @type country_code :ba | :bl | :ca | :ch | :us

    defmodule Sector do
      use TypedStruct

      typedstruct enforce: true do
        value: String.t()
      end

      def new(value) when is_binary(value) do
        %__MODULE__{ value: value }
      end
    end

    typestruct enforce: true do
      id: pos_integer()
      region: region()
      country: country_code()
      sector: Sector.t()
      segment: segment()
      channel: sales_channel()
    end

   @spec new(pos_integer(), String.t(), String.t(), String.t(), String.t(), String.t()) :: t()
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

  @spec examples() :: list(t())
  def examples do
    Account.new(1, :amer, :us, Sector.new("finance"), :strategic, :direct),
    Account.new(2, :amer, :ch, Sector.new("medical"), :private, :partner),
    Account.new(3, :amer, :ba, Sector.new("finance"), :enterprise, :reseller),
    Account.new(4, :amer, :ca, Sector.new("education"), :existing, :reseller),
    Account.new(5, :emea, :bl, Sector.new("retail"), :enterprise, :online)
  end
end
