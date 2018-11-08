defmodule GeoPartition do
  @moduledoc """
  Documentation for GeoPartition.
  """

  def partition(list) when is_binary(list) do
    with {:ok, new_list} <- Poison.decode(list) do
      partition(new_list)
    else
      {:error, err} -> {:error, "Cannot decode string input"}
    end
  end

  def partition(list) when is_list(list) do
    Enum.map(list, &partition_shape(&1)) |> List.flatten
  end

  def partition_shape(shape) when is_binary(shape) do
    with {:ok, new_shape} <- Poison.decode(shape) do
      partition_shape(new_shape)
    else
      {:error, err} -> {:error, "Cannot decode string input"}
    end
  end

  def partition_shape(shape = %{"geometry" => geometry}) do
    with {:ok, new_shape} <- Geo.JSON.decode(geometry) do
      partition_shape(new_shape)
    else
      {:error, err} -> {:error, "Cannot parse input"}
    end
  end

  def partition_shape(shape = %{__struct__: Geo.Polygon}) do
    shape
    |> poly_to_multi
    |> partition_shape
  end

  def partition_shape(shape = %{__struct__: Geo.MultiPolygon}) do
    with [] <- GeoPartition.Util.polygon_errors(shape) do
      new_coords = shape
                   |> GeoPartition.Util.de_hole
                   |> Map.get(:coordinates)
      Map.put(shape, :coordinates, new_coords)
      "good"
    else
      [err|_] -> {:error, err}
    end
  end

  def partition_shape(shape) do
    {:error, "Cannot parse input"}
  end

  def poly_to_multi(shape) do
    shape_map = shape |> Geo.JSON.encode!

    Map.put(shape_map, "coordinates", [shape_map["coordinates"]])
    |> Map.put("type", "MultiPolygon")
    |> Geo.JSON.decode!
  end
end
