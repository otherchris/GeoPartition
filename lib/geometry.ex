defmodule GeoPartition.Geometry do
  @moduledoc """
  Extensions of [Topo](https://github.com/pkinney/topo) and [Geo](https://github.com/bryanjos/geo)
  to perform calculations on map geometries
  """

  alias GeoPartition.Util

  @doc """
  Determines if a Point is _very nearly_ on a LineString. Creates a polar rectangle
  with diagonal of 2 * epsilon (default value is less than an inch). If this rectangle
  intersects the LineString, we say the Point is "on" the LineString.

  ## Examples
  ```
  iex> line = %Geo.LineString{coordinates: [{1.0, 1.0}, {2.0, 1.0}]}
  iex> point = %Geo.Point{coordinates: {1.5, 1.0000001}}
  iex> GeoPartition.Geometry.soft_contains?(line, point)
  true

  iex> line = %Geo.LineString{coordinates: [{1.0, 1.0}, {2.0, 1.0}]}
  iex> point = %Geo.Point{coordinates: {1.5, 1.0000001}}
  iex> GeoPartition.Geometry.soft_contains?(line, point, 0.00000001)
  false
  ```
  """
  @spec soft_contains?(Geo.LineString, Geo.Point, float) :: boolean
  def soft_contains?(line = %Geo.LineString{}, point = %Geo.Point{coordinates: {x, y}}, epsilon \\ 0.0000001) do
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
    Topo.intersects?(line, smudge)
  end

  @doc """
  Determines if two LineStrings "cross", which is to say an intersection of interior
  of each consisting of a single point.

  ## Examples
  ```
  iex> reference = %Geo.LineString{coordinates: [{1.0, 1.0}, {2.0, 2.0}]}
  iex> disjoint = %Geo.LineString{coordinates: [{2.0, 1.0}, {3.0, 2.0}]}
  iex> GeoPartition.Geometry.crosses?(reference, disjoint)
  false

  iex> reference = %Geo.LineString{coordinates: [{1.0, 1.0}, {2.0, 2.0}]}
  iex> shares_endpoint = %Geo.LineString{coordinates: [{2.0, 1.0}, {2.0, 2.0}]}
  iex> GeoPartition.Geometry.crosses?(reference, shares_endpoint)
  false

  iex> reference = %Geo.LineString{coordinates: [{1.0, 1.0}, {2.0, 2.0}]}
  iex> incident = %Geo.LineString{coordinates: [{2.0, 1.0}, {1.5, 1.5}]}
  iex> GeoPartition.Geometry.crosses?(reference, incident)
  false

  iex> reference = %Geo.LineString{coordinates: [{1.0, 1.0}, {2.0, 2.0}]}
  iex> overlap = %Geo.LineString{coordinates: [{1.5, 1.5}, {3.0, 3.0}]}
  iex> GeoPartition.Geometry.crosses?(reference, overlap)
  false

  iex> reference = %Geo.LineString{coordinates: [{1.0, 1.0}, {2.0, 2.0}]}
  iex> intersect = %Geo.LineString{coordinates: [{2.0, 1.0}, {1.0, 2.0}]}
  iex> GeoPartition.Geometry.crosses?(reference, intersect)
  true
  ```
  """
  @spec crosses?(Geo.LineString, Geo.LineString) :: boolean
  def crosses?(a = %{__struct__: Geo.LineString}, b = %{__struct__: Geo.LineString}) do
    Topo.intersects?(a, b)
    && !Enum.member?(a.coordinates, List.first(b.coordinates))
    && !Enum.member?(a.coordinates, List.last(b.coordinates))
    && !(Topo.contains?(b, a) || Topo.contains?(a, b))
    && !Topo.contains?(a, %Geo.Point{coordinates: hd(b.coordinates)})
    && !Topo.contains?(a, %Geo.Point{coordinates: List.last(b.coordinates)})
  end

  @doc """
  Find the intersection point of two LineStrings. Returns a tuple indicating the
  type of intersection:
    - `:disjoint`, the LineStrings have no points in common
    - `:degen`, the LineStrings share points but are collinear, or endpoint of one
      incident with non-endpoint of other
    - `:intersects`, the LineStrings have a non-trivial point of intersection

  ## Examples
  ```
  iex> reference = %Geo.LineString{coordinates: [{1.0, 1.0}, {2.0, 2.0}]}
  iex> disjoint = %Geo.LineString{coordinates: [{2.0, 1.0}, {3.0, 2.0}]}
  iex> GeoPartition.Geometry.intersection(reference, disjoint)
  {:disjoint, "disjoint"}

  iex> reference = %Geo.LineString{coordinates: [{1.0, 1.0}, {2.0, 2.0}]}
  iex> overlap = %Geo.LineString{coordinates: [{1.5, 1.5}, {3.0, 3.0}]}
  iex> GeoPartition.Geometry.intersection(reference, overlap)
  {:degen, "degen"}

  iex> reference = %Geo.LineString{coordinates: [{1.0, 1.0}, {2.0, 2.0}]}
  iex> intersect = %Geo.LineString{coordinates: [{2.0, 1.0}, {1.0, 2.0}]}
  iex> GeoPartition.Geometry.intersection(reference, intersect)
  {:intersects, %Geo.Point{coordinates: {1.5, 1.5}, properties: %{}, srid: nil}}
  ```
  """
  @spec intersection(Geo.LineString, Geo.LineString) :: {atom, any}
  def intersection(l1 = %{coordinates: [a = {x1, y1}, b = {x2, y2}]}, l2 = %{coordinates: [c = {x3, y3}, d = {x4, y4}]}) do
    cond do
      !Topo.intersects?(l1, l2) -> {:disjoint, "disjoint"}
      !crosses?(l1, l2) && Topo.intersects?(l1, l2) -> {:degen, "degen"}
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

  @doc """
  Find the area WIP
  """
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

  defp get_long_factor(poly = %{__struct__: Geo.MultiPolygon}) do
    poly.coordinates
    |> get_long_factor
  end

  defp get_long_factor(coords) when is_list(coords) do
    coords
    |> Util.get_all_coords
    |> Enum.map(fn({a, b}) -> b end)
    |> Util.geo_mean
    |> Util.deg_to_rad
    |> :math.cos
    |> Kernel.*(69.172)
  end
end
