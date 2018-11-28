defmodule GeoPartition do
  @moduledoc """
  Documentation for GeoPartition.
  """

  alias GeoPartition.{Output, Partition}

  def partition(shape = %Geo.Polygon{}, area, output) do
    Partition.partition(shape, area)
    |> Output.format(output)
  end

end
