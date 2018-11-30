defmodule GeoPartition do
  @moduledoc """
  Documentation for GeoPartition.
  """

  alias GeoPartition.{Output, Partition}

  @doc """
  Decomposes a given polygon or multipolygon into a list of polygons all of which
  have an area less than `area` (measured in square miles)

  Input format can be
  - `Geo.Polygon`
  - `Geo.MultiPolygon`
  - string keyed map decodable into `Geo.Polygon` or `Geo.MultiPolygon`
  - vaild GeoJSON polygon
  - valid GeoJSON multipolygon
  - valid GeoJSON feature with polygon or multipolygon geometry

  `output` specifies the output format of the decomposition
  - `:list` (default), a flat list of `Geo.Polygon`
  - `:multipolygon`, a single `Geo.MultiPolygon`
  - `:multipolygon_json`, a GeoJSON geometry object of type MultiPolygon
  - `:multipolygon_feature`, a GeoJSON feature with a MultiPolygon geometry
  - `:feature_collection`, a GeoJSON feature collection containing features with Polygon geometry
  - `:feature_collection_multipolygon`, a GeoJSON feature collection containing a single feature with multipolygon geometry
  """
  def partition(shape, area, output \\ :list)

  def partition(shape = %Geo.Polygon{}, area, output) do
    if errs = polygon_errors(shape) == [] do
      Partition.partition(shape, area)
      |> Output.format(output)
    else
      errs
    end
  end

  def partition(shape = %Geo.MultiPolygon{}, area, output) do
    poly_list = Enum.map(shape.coordinates, &(%Geo.Polygon{coordinates: &1}))
    errs = poly_list
            |> Enum.map(&polygon_errors(&1))
            |> List.flatten
    if errs == [] do
      poly_list
      |> Partition.partition_list(area)
      |> Output.format(output)
    else
      errs
    end
  end

  def partition(shape, area, output) when is_binary(shape) do
    shape
    |> Poison.decode!
    |> partition(area, output)
  end

  def partition(shape = %{"type" => "Polygon"}, area, output) do
    shape
    |> Geo.JSON.decode!
    |> partition(area, output)
  end

  def partition(shape = %{"type" => "MultiPolygon"}, area, output) do
    shape
    |> Geo.JSON.decode!
    |> partition(area, output)
  end

  def partition(shape = %{"type" => "Feature"}, area, output) do
    shape["geometry"]
    |> Geo.JSON.decode!
    |> partition(area, output)
  end

  @doc """
  Disallow polygons with overlapping holes
  """
  def polygon_errors(shape) do
    shape
    |> check_overlap
    |> List.flatten
    |> Enum.filter(&(&1))
  end

  defp check_overlap(shape = %{__struct__: Geo.Polygon}) do
    if length(shape.coordinates) == 1 do
      []
    else
      shape.coordinates
      |> tl
      |> Enum.map(fn(ring) ->
        if Topo.intersects?(
          %Geo.LineString{coordinates: hd(shape.coordinates)},
          %Geo.LineString{coordinates: ring}
        ) do
          "Cannot process Polygon with ring intersection"
        else
          []
        end
      end)
      |> Kernel.++(check_overlap(%Geo.Polygon{coordinates: tl(shape.coordinates)}))
    end
  end
end


