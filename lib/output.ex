defmodule GeoPartition.Output do
  @moduledoc """
  Output formatting for the result of a partitioning
  """

  def format(list, :multipolygon) do
    coords = Enum.map(list, &(&1.coordinates))
    %Geo.MultiPolygon{coordinates: coords}
  end

  def format(list, :multipolygon_json) do
    format(list, :multipolygon)
    |> Geo.JSON.encode!
    |> Poison.encode!
  end

  def format(list, :list) do
    list
  end

  def format(list, :feature_collection) do
    polys = list
            |> Enum.map(&Geo.JSON.encode!(&1))
            |> Enum.map(&wrap_in_feature(&1, %{}))
    %{
      type: "FeatureCollection",
      features: polys
    }
  end

  def format(list, :feature_collection_json) do
    format(list, :feature_collection)
    |> Geo.JSON.encode!
    |> Poison.encode!
  end

  def format(list, :feature_collection_multipolygon) do
    polys = list
            |> Enum.map(&(poly_to_multi(&1)))
            |> Enum.map(&wrap_in_feature(&1, %{}))
            |> Enum.map(&Geo.JSON.encode!(&1))
    %{
      type: "FeatureCollection",
      features: polys
    }
  end

  def format(list, :feature_collection_multipolygon_json) do
    format(list, :feature_collection_multipolygon)
    |> Poison.encode!
  end

  defp get_poly_coords(poly), do: Map.get(poly, :coordinates)

  defp wrap_in_feature(shape, props \\ %{}) do
    %{
      type: "Feature",
      properties: props,
      geometry: shape
    }
  end

  defp poly_to_multi(shape) do
    shape_map = shape |> Geo.JSON.encode!

    Map.put(shape_map, "coordinates", [shape_map["coordinates"]])
    |> Map.put("type", "MultiPolygon")
    |> Geo.JSON.decode!
  end
end
