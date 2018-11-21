defmodule GeoPartition.Geometry do
  @moduledoc """
  Extensions of [Topo](https://github.com/pkinney/topo) and [Geo](https://github.com/bryanjos/geo)
  to perform calculations on map geometries
  """

  alias GeoPartition.{Graph, Util}

  @type graph() :: {list(), list(MapSet)}

  @doc """
  Converts a cycle (graph) into a polygon.

  ## Examples
  ```
  iex> cycle = {
  ...>  [
  ...>    %Geo.Point{ coordinates: {1.0, 1.0}, properties: %{covered: false, ring: :outer}, srid: nil },
  ...>    %Geo.Point{ coordinates: {3.0, 2.0}, properties: %{covered: false, ring: :outer}, srid: nil },
  ...>    %Geo.Point{ coordinates: {1.0, 3.0}, properties: %{covered: false, ring: :outer}, srid: nil }
  ...>  ], [
  ...>    MapSet.new([
  ...>      %Geo.Point{coordinates: {1.0, 1.0}, properties: %{covered: false, ring: :outer}, srid: nil},
  ...>      %Geo.Point{coordinates: {3.0, 2.0}, properties: %{covered: false, ring: :outer}, srid: nil}
  ...>    ]),
  ...>    MapSet.new([
  ...>      %Geo.Point{coordinates: {1.0, 3.0}, properties: %{covered: false, ring: :outer}, srid: nil},
  ...>      %Geo.Point{coordinates: {3.0, 2.0}, properties: %{covered: false, ring: :outer}, srid: nil}
  ...>    ]),
  ...>    MapSet.new([
  ...>      %Geo.Point{coordinates: {1.0, 3.0}, properties: %{covered: false, ring: :outer}, srid: nil},
  ...>      %Geo.Point{coordinates: {1.0, 1.0}, properties: %{covered: false, ring: :outer}, srid: nil}
  ...>    ])
  ...>  ]}
  iex>  GeoPartition.Geometry.cycle_to_polygon(cycle)
  %Geo.Polygon{
    coordinates: [
      [
        {1.0, 3.0},
        {3.0, 2.0},
        {1.0, 1.0},
        {1.0, 3.0}
      ]
    ],
    properties: %{},
    srid: nil
  }
  ```
  """
  def cycle_to_polygon({v, e}) do
    {:ok, {_, edges}} = Graph.cycle_sort({v, e})
    coordinates = edges
                  |> Enum.chunk_every(2, 1, :discard)
                  |> Kernel.++([[List.first(edges), List.last(edges)]])
                  |> Enum.map(fn([a, b]) -> MapSet.intersection(a, b) end)
                  |> Enum.map(&MapSet.to_list(&1))
                  |> List.flatten
                  |> Enum.map(&(&1.coordinates))
    %Geo.Polygon{
      properties: %{},
      coordinates: [coordinates ++ [hd(coordinates)]],
      srid: nil
    }
  end

  @doc """
  Converts a polygon (`Geo.Polygon`) to a graph. If the polygon has holes that overlap the
  outer ring, they will be circumvented

  ## Examples
  ```
  iex> shape = %Geo.Polygon{
  ...>   coordinates: [
  ...>     [
  ...>       {1.0, 1.0},
  ...>       {3.0, 2.0},
  ...>       {1.0, 3.0},
  ...>       {1.0, 1.0}
  ...>     ],
  ...>     [
  ...>       {2.0, 2.0},
  ...>       {4.0, 1.0},
  ...>       {4.0, 3.0},
  ...>       {2.0, 2.0}
  ...>     ]
  ...>   ]
  ...> }
  iex> GeoPartition.Geometry.polygon_to_graph(shape)
  {[
    %Geo.Point{ coordinates: {1.0, 1.0}, properties: %{covered: false, ring: :outer}, srid: nil },
    %Geo.Point{ coordinates: {1.0, 3.0}, properties: %{covered: false, ring: :outer}, srid: nil },
    %Geo.Point{ coordinates: {2.0, 2.0}, properties: %{covered: true, ring: :inner}, srid: nil },
    %Geo.Point{ coordinates: {2.5, 1.75}, srid: nil, properties: %{covered: false, ring: :intersection} },
    %Geo.Point{ coordinates: {2.5, 2.25}, srid: nil, properties: %{covered: false, ring: :intersection} }
  ], [
    MapSet.new([
      %Geo.Point{coordinates: {1.0, 3.0}, properties: %{covered: false, ring: :outer}, srid: nil},
      %Geo.Point{coordinates: {2.5, 2.25}, properties: %{covered: false, ring: :intersection}, srid: nil}
    ]),
    MapSet.new([
      %Geo.Point{coordinates: {2.0, 2.0}, properties: %{covered: true, ring: :inner}, srid: nil},
      %Geo.Point{coordinates: {2.5, 2.25}, properties: %{covered: false, ring: :intersection}, srid: nil}
    ]),
    MapSet.new([
      %Geo.Point{coordinates: {1.0, 1.0}, properties: %{covered: false, ring: :outer}, srid: nil},
      %Geo.Point{coordinates: {2.5, 1.75}, properties: %{covered: false, ring: :intersection}, srid: nil}
    ]),
    MapSet.new([
      %Geo.Point{coordinates: {2.0, 2.0}, properties: %{covered: true, ring: :inner}, srid: nil},
      %Geo.Point{coordinates: {2.5, 1.75}, properties: %{covered: false, ring: :intersection}, srid: nil}
    ]),
    MapSet.new([
      %Geo.Point{coordinates: {1.0, 1.0}, properties: %{covered: false, ring: :outer}, srid: nil},
      %Geo.Point{coordinates: {1.0, 3.0}, properties: %{covered: false, ring: :outer}, srid: nil}
    ])
  ]}
  ```
  """
  def polygon_to_graph(shape = %{__struct__: Geo.Polygon, coordinates: coords = [outer|holes]}) do
    {v, e} = add_ring_to_graph({[], []}, outer, :outer)
    {vertices, edges} = holes
                        |> List.foldl({v, e}, &add_ring_to_graph(&2, &1, :inner))
                        |> add_coverage(coords)
                        |> add_intersections
                        |> Graph.delete_vertices_by(&(&1.properties.ring == :inner && !&1.properties.covered))
                        |> Graph.delete_vertices_by(&(&1.properties.ring == :outer && &1.properties.covered))
                        |> reduce_intersection_edges
    {vertices, edges}
  end

  defp filter_edges({v, e}) do
    {v, Enum.filter(e, fn(x) ->
      x
      |> MapSet.to_list
      |> Enum.find(&(&1.properties.ring == :outer && !&1.properties.covered))
      |> is_nil
    end)}
  end

  defp add_ring_to_graph(intial = {v, e}, ring, ring_type) do
    vertices = Enum.map(ring, fn({lng, lat}) ->
      %Geo.Point{
        coordinates: {lng, lat},
        properties: %{
          ring: ring_type,
          covered: false,
        }
      }
    end)

    edges = vertices
            |> Enum.chunk_every(2, 1, :discard)
            |> Enum.map(&MapSet.new(&1))
    {v ++ Enum.uniq(vertices), e ++ edges}
  end

  defp add_coverage({v, e}, coords = [outer|holes]) do
    vertices = add_coverage(v, coords)
    edges = add_coverage(e, coords)
    {vertices, edges}
  end

  defp add_coverage(e = [%MapSet{}|_], coords) do
    e
    |> Enum.map(&MapSet.to_list(&1))
    |> List.flatten
    |> add_coverage(coords)
    |> Enum.chunk_every(2, 2, :discard)
    |> Enum.map(&MapSet.new(&1))
  end

  defp add_coverage(v, coords = [outer|holes]) when is_list(v) do
    Enum.map(v, fn(x = %{properties: %{ring: ring_type}}) ->
      if ring_type == :inner do
        props = Map.put(x.properties, :covered, covered?(outer, x))
        Map.put(x, :properties, props)
      else
        props = Map.put(x.properties, :covered, covered?(holes, x))
        Map.put(x, :properties, props)
      end
    end)
  end

  defp covered?(rings = [[_|_]], point = %{__struct__: Geo.Point}) do
    List.foldl(rings, false, &(covered?(&1, point) || &2))
  end

  defp covered?(ring = [{a, b}|_], point = %{__struct__: Geo.Point}) do
    Topo.contains?(
      %Geo.Polygon{coordinates: [ring]},
      point
    )
  end

  defp covered?([], point), do: false

  defp add_intersections({v, e}) do
    inters = for x <- e, y <- e do
      case intersection(edge_to_seg(x), edge_to_seg(y)) do
        {:intersects, point} ->
          props = %{covered: false, ring: :intersection}
          {Map.put(point, :properties, props), [x, y]}
        _ -> nil
      end
    end
    |> Enum.reject(&is_nil(&1))
    |> List.first
    case inters do
      nil -> {v, e}
      {p, edges} -> add_intersections(Graph.subdivide({v, e}, edges, p))
    end
  end

  defp reduce_intersection_edges({v, e}) do
    edges = Enum.reject(e, fn(ed) ->
      [x, y] = MapSet.to_list(ed)
      x.properties.ring == :intersection && y.properties.ring == :intersection
    end)
    {v, edges}
  end

  defp points_to_seg([a, b]) do
    %Geo.LineString{
      coordinates: [
        a.coordinates,
        b.coordinates
      ]
    }
  end

  defp edge_to_seg(e) do
    e |> MapSet.to_list |> points_to_seg
  end

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
        u = ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / ((y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1))
        {:intersects, %Geo.Point{
          coordinates: {
            x1 + u * (x2 - x1),
            y1 + u * (y2 - y1)
          }

        }}
    end
  end

  @doc """
  Find the area of a polygon. To find geographic area based on lat/long coords, use `geo: :globe`,
  default is `geo: :flat`

  ## Examples
  ```
  iex> shape = %Geo.Polygon{
  ...>   coordinates: [
  ...>     [
  ...>       {0.0, 0.0},
  ...>       {4.0, 0.0},
  ...>       {4.0, 3.0},
  ...>       {0.0, 3.0},
  ...>       {0.0, 0.0},
  ...>     ],
  ...>     [
  ...>       {1.0, 1.0},
  ...>       {3.0, 1.0},
  ...>       {3.0, 4.0},
  ...>       {1.0, 4.0},
  ...>       {1.0, 1.0},
  ...>     ]
  ...>   ]
  ...> }
  iex> GeoPartition.Geometry.area(shape, [geo: :flat])
  8.0
  ```
  """

  def area(shape = %Geo.Polygon{}, opts \\ [geo: :flat]) do
    %{coordinates: [outer|holes]} = shape
                                    |> polygon_to_graph
                                    |> cycle_to_polygon
    hole_area = holes
                |> Enum.map(&ring_area(&1, opts))
                |> List.foldl(0, &Kernel.+(&1, &2))
    ring_area(outer, opts) - hole_area
  end

  defp ring_area(shape = [{a, b}|_], opts) do
    flat_area = shape
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(&Util.det_seg(&1))
    |> List.foldr(0, &Kernel.+(&1, &2))
    |> Kernel./(2)
    |> abs
    if opts[:geo] == :globe do
      flat_area
      |> Kernel.*(get_long_factor(shape))
      |> Kernel.*(69.172)
    else
      flat_area
    end
  end

  defp get_long_factor(poly = %{__struct__: Geo.MultiPolygon}) do
    poly.coordinates
    |> get_long_factor
  end

  defp get_long_factor(coords) when is_list(coords) do
    coords
    |> Enum.map(fn({a, b}) -> b end)
    |> Util.geo_mean
    |> Util.deg_to_rad
    |> :math.cos
    |> Kernel.*(69.172)
  end
end
