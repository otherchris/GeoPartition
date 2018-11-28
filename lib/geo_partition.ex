defmodule GeoPartition do
  @moduledoc """
  Documentation for GeoPartition.
  """

  def partition(shape = %Geo.Polygon{}, area, output) do
    Partition.partition(shape, area)
    |> Output.format(output)
  end

  def poly_to_multi(shape) do
    shape_map = shape |> Geo.JSON.encode!

    Map.put(shape_map, "coordinates", [shape_map["coordinates"]])
    |> Map.put("type", "MultiPolygon")
    |> Geo.JSON.decode!
  end
end
