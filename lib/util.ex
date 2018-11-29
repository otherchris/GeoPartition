defmodule GeoPartition.Util do

  alias GeoPartition.Geometry

  def add_area(shape = %{__struct__: Geo.Polygon, properties: props}) do
    new_props = props
    |> Map.put(:area, Geometry.area(shape, [geo: :globe]))
    shape
    |> Map.put(:properties, new_props)
  end

  def get_all_coords(poly) when is_list(poly) do
    Enum.map(poly, &get_all_coords(&1))
    |> List.flatten
  end

  def get_all_coords(coords) do
    coords
  end

  @doc """
  Disallow polygons with overlapping holes
  """
  def polygon_errors(shape) do
    Enum.map(shape.coordinates, &check_overlap(%Geo.Polygon{coordinates: &1}))
    |> List.flatten
    |> Enum.filter(&(&1))
  end

  defp check_overlap(shape = %{__struct__: Geo.Polygon}) do
    if length(shape.coordinates) == 1 do
      [false]
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
          [false]
        end
      end)
      |> Kernel.++(check_overlap(%Geo.Polygon{coordinates: tl(shape.coordinates)}))
    end
  end
end
