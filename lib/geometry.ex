defmodule GeoPartition.Geometry do
  @moduledoc """
  Functions for calculating area of polygons
  """

  alias GeoPartition.Util

  @doc """
  Determines if a Point is _very nearly_ on a LineString. Creates a polar rectangle
  with diagonal of 2 * epsilon (default value is less than an inch). If this rectangle
  intersects the LineString, we say the Point is "on" the LineString.

  ## Examples

    iex> line = %Geo.LineString{coordinates: [{1.0, 1.0}, {2.0, 1.0}]}
    iex> point = %Geo.Point{coordinates: {1.5, 1.0000001}}
    iex> GeoPartition.Geometry.soft_contains?(line, point)
    true

    iex> line = %Geo.LineString{coordinates: [{1.0, 1.0}, {2.0, 1.0}]}
    iex> point = %Geo.Point{coordinates: {1.5, 1.0000001}}
    iex> GeoPartition.Geometry.soft_contains?(line, point, 0.00000001)
    false
  """
  def soft_contains?(a = %Geo.LineString{}, b = %Geo.Point{coordinates: {x, y}}, epsilon \\ 0.0000001) do
    smudge = %Geo.Polygon{
      coordinates: [
        [
          {x + epsilon, y},
          {x, y + epsilon},
          {x - epsilon, y},
          {x, y - epsilon},
          {x + epsilon, y}
        ]
      ]
    }
    Topo.intersects?(a, smudge)
  end

  def intersects?(a = %{__struct__: Geo.LineString}, b = %{__struct__: Geo.LineString}) do
    Topo.intersects?(a, b)
    && !Topo.contains?(b, a)
    && !Topo.contains?(a, %Geo.Point{coordinates: hd(b.coordinates)})
    && !Topo.contains?(a, %Geo.Point{coordinates: List.last(b.coordinates)})
  end

  def intersection(l1 = %{coordinates: [a = {x1, y1}, b = {x2, y2}]}, l2 = %{coordinates: [c = {x3, y3}, d = {x4, y4}]}) do
    cond do
      !Topo.intersects?(l1, l2) -> {:disjoint, "disjoint"}
      !intersects?(l1, l2) && Topo.intersects?(l1, l2) -> {:degen, "degen"}
      a == c || a == d || b == c || b == d -> {:incident, "incident"}
      true ->
        u = ((x4-x3)*(y1-y3)-(y4-y3)*(x1-x3)) / ((y4-y3)*(x2-x1)-(x4-x3)*(y2-y1))
        {:intersects, %Geo.Point{
          coordinates: {
            x1 + u * (x2 - x1),
            y1 + u * (y2 - y1)
          }

        }}
    end
  end

  def get_long_factor(poly = %{__struct__: Geo.MultiPolygon}) do
    poly.coordinates
    |> get_long_factor
  end

  def get_long_factor(coords) when is_list(coords) do
    coords
    |> Util.get_all_coords
    |> Enum.map(fn({a, b}) -> b end)
    |> Util.geo_mean
    |> Util.deg_to_rad
    |> :math.cos
    |> Kernel.*(69.172)
  end

  def area(shape = %{__struct__: Geo.Polygon}) do
    shape.coordinates
    |> Util.get_all_coords
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(&Util.det_seg(&1))
    |> List.foldr(0, &Kernel.+(&1, &2))
    |> Kernel./(2)
    |> abs
    |> Kernel.*(get_long_factor(shape.coordinates))
    |> Kernel.*(69.172)
  end
end
