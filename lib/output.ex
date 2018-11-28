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
      "type" => "FeatureCollection",
      "features" => polys
    }
  end

  def format(list, :feature_collection_json) do
    format(list, :feature_collection)
    |> Poison.encode!
  end

  def format(list, :feature_collection_multipolygon) do
    polys = list
            |> Enum.map(&(poly_to_multi(&1)))
            |> Enum.map(&wrap_in_feature(&1, %{}))
    %{
      "type" => "FeatureCollection",
      "features" => polys
    }
  end

  def format(list, :feature_collection_multipolygon_json) do
    format(list, :feature_collection_multipolygon)
    |> Poison.encode!
  end

  defp wrap_in_feature(shape = %{"type" => type}, props \\ %{}) do
    %{
      "type" => "Feature",
      "properties" =>  props,
      "geometry" => shape
    }
  end

  defp coords_to_list(coords) do
    case coords do
      [{a, b}|_] -> Enum.map(coords, fn({x, y}) -> [x, y] end)
      [] -> []
      _ -> Enum.map(coords, &([coords_to_list(&1)]))
    end
  end

  defp poly_to_multi(shape = %Geo.Polygon{}) do
    %Geo.MultiPolygon{
      coordinates: [shape.coordinates]
    }
    |> Geo.JSON.encode!
  end
end
