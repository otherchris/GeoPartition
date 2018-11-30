defmodule GeoPartition.Geometry do
  @moduledoc """
  Extensions of [Topo](https://github.com/pkinney/topo) and [Geo](https://github.com/bryanjos/geo)
  to perform calculations on map geometries
  """

  @type graph() :: {list(), list(MapSet)}

  @doc """
  Removes occluding holes from a given polygon, preserving properly contained holes

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
  ...>     ],
  ...>     [
  ...>       {1.0, 0.3},
  ...>       {3.0, 0.3},
  ...>       {3.0, 0.7},
  ...>       {1.0, 0.3}
  ...>     ]
  ...>   ]
  ...> }
  iex> GeoPartition.Geometry.clean_holes(shape)
  %Geo.Polygon{
    coordinates: [
       [
         {0.0, 0.0},
         {4.0, 0.0},
         {4.0, 3.0},
         {3.0, 3.0},
         {3.0, 1.0},
         {1.0, 1.0},
         {1.0, 3.0},
         {0.0, 3.0},
         {0.0, 0.0},
       ],
       [
         {1.0, 0.3},
         {3.0, 0.3},
         {3.0, 0.7},
         {1.0, 0.3}
       ]
    ],
    properties: %{},
    srid: nil
   }

  ```
  """
  def clean_holes(shape = %{coordinates: [outer|holes]}) do
    new_outer = shape
    |> polygon_to_graph
    |> graph_to_polygon
    |> Map.get(:coordinates)
    |> hd
    %Geo.Polygon{
      coordinates: [new_outer] ++ drop_bad_holes(shape)
    }
  end

  defp drop_bad_holes(polygon) do
    [outer|holes] = polygon.coordinates
    holes
    |> Enum.reject(&is_bad_hole(outer, &1))
  end

  defp is_bad_hole(outer, hole) do
    !Topo.contains?(%Geo.Polygon{coordinates: [outer]}, %Geo.Polygon{coordinates: [hole]})
  end

  @doc """
  Converts a graph into a polygon

  ## Examples
  ```
  iex> graph = {[
  ...>  %Geo.Point{ coordinates: {1.0, 1.0}, properties: %{covered: false, ring: :outer}, srid: nil },
  ...>  %Geo.Point{ coordinates: {1.0, 3.0}, properties: %{covered: false, ring: :outer}, srid: nil },
  ...>  %Geo.Point{ coordinates: {2.0, 2.0}, properties: %{covered: true, ring: :inner}, srid: nil },
  ...>  %Geo.Point{ coordinates: {2.5, 1.75}, srid: nil, properties: %{covered: false, ring: :intersection} },
  ...>  %Geo.Point{ coordinates: {2.5, 2.25}, srid: nil, properties: %{covered: false, ring: :intersection} }
  ...>  ], [
  ...>  MapSet.new([
  ...>  %Geo.Point{coordinates: {1.0, 3.0}, properties: %{covered: false, ring: :outer}, srid: nil},
  ...>  %Geo.Point{coordinates: {2.5, 2.25}, properties: %{covered: false, ring: :intersection}, srid: nil}
  ...>  ]),
  ...>  MapSet.new([
  ...>  %Geo.Point{coordinates: {2.0, 2.0}, properties: %{covered: true, ring: :inner}, srid: nil},
  ...>  %Geo.Point{coordinates: {2.5, 2.25}, properties: %{covered: false, ring: :intersection}, srid: nil}
  ...>  ]),
  ...>  MapSet.new([
  ...>  %Geo.Point{coordinates: {1.0, 1.0}, properties: %{covered: false, ring: :outer}, srid: nil},
  ...>  %Geo.Point{coordinates: {2.5, 1.75}, properties: %{covered: false, ring: :intersection}, srid: nil}
  ...>  ]),
  ...>  MapSet.new([
  ...>  %Geo.Point{coordinates: {2.0, 2.0}, properties: %{covered: true, ring: :inner}, srid: nil},
  ...>  %Geo.Point{coordinates: {2.5, 1.75}, properties: %{covered: false, ring: :intersection}, srid: nil}
  ...>  ]),
  ...>  MapSet.new([
  ...>  %Geo.Point{coordinates: {1.0, 1.0}, properties: %{covered: false, ring: :outer}, srid: nil},
  ...>  %Geo.Point{coordinates: {1.0, 3.0}, properties: %{covered: false, ring: :outer}, srid: nil}
  ...>  ])
  ...>]}
  iex> GeoPartition.Geometry.graph_to_polygon(graph)
  %Geo.Polygon{
    coordinates: [
      [
        {1.0, 1.0},
        {2.5, 1.75},
        {2.0, 2.0},
        {2.5, 2.25},
        {1.0, 3.0},
        {1.0, 1.0}
      ]
    ]
  }
  ```
  """
  def graph_to_polygon({v, e}) do
    %Geo.Polygon{
      coordinates: [cycle_to_ring({v,e})]
    }
  end

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
  iex>  GeoPartition.Geometry.cycle_to_ring(cycle)
  [
    {1.0, 3.0},
    {3.0, 2.0},
    {1.0, 1.0},
    {1.0, 3.0}
  ]
  ```
  """
  def cycle_to_ring({v, e}) do
    {:ok, {_, edges}} = ExSimpleGraph.cycle_sort({v, e})
    coordinates = edges
                  |> Enum.chunk_every(2, 1, :discard)
                  |> Kernel.++([[List.first(edges), List.last(edges)]])
                  |> Enum.map(fn([a, b]) -> MapSet.intersection(a, b) end)
                  |> Enum.map(&MapSet.to_list(&1))
                  |> List.flatten
                  |> Enum.map(&(&1.coordinates))
    coordinates ++ [hd(coordinates)]
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
  ...>     ],
  ...>     [
  ...>       {1.4, 2.4},
  ...>       {1.4, 1.6},
  ...>       {1.8, 1.6},
  ...>       {1.8, 2.4},
  ...>       {1.4, 2.4}
  ...>     ]
  ...>   ]
  ...> }
  iex> GeoPartition.Geometry.polygon_to_graph(shape)
  {[
    %Geo.Point{ coordinates: {1.0, 1.0}, properties: %{covered: false, ring: :outer}, srid: nil },
    %Geo.Point{ coordinates: {1.0, 3.0}, properties: %{covered: false, ring: :outer}, srid: nil },
    %Geo.Point{ coordinates: {2.0, 2.0}, properties: %{covered: true, ring: :inner}, srid: nil },
    %Geo.Point{ coordinates: {1.4, 2.4}, properties: %{covered: true, ring: :inner}, srid: nil },
    %Geo.Point{ coordinates: {1.4, 1.6}, properties: %{covered: true, ring: :inner}, srid: nil },
    %Geo.Point{ coordinates: {1.8, 1.6}, properties: %{covered: true, ring: :inner}, srid: nil },
    %Geo.Point{ coordinates: {1.8, 2.4}, properties: %{covered: true, ring: :inner}, srid: nil },
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
    ]),
    MapSet.new([
      %Geo.Point{coordinates: {1.4, 1.6}, properties: %{covered: true, ring: :inner}, srid: nil},
      %Geo.Point{coordinates: {1.4, 2.4}, properties: %{covered: true, ring: :inner}, srid: nil}
    ]),
    MapSet.new([
      %Geo.Point{coordinates: {1.8, 1.6}, properties: %{covered: true, ring: :inner}, srid: nil},
      %Geo.Point{coordinates: {1.4, 1.6}, properties: %{covered: true, ring: :inner}, srid: nil}
    ]),
    MapSet.new([
      %Geo.Point{coordinates: {1.8, 2.4}, properties: %{covered: true, ring: :inner}, srid: nil},
      %Geo.Point{coordinates: {1.8, 1.6}, properties: %{covered: true, ring: :inner}, srid: nil}
    ]),
    MapSet.new([
      %Geo.Point{coordinates: {1.8, 2.4}, properties: %{covered: true, ring: :inner}, srid: nil},
      %Geo.Point{coordinates: {1.4, 2.4}, properties: %{covered: true, ring: :inner}, srid: nil}
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
                        |> ExSimpleGraph.delete_vertices_by(&(&1.properties.ring == :inner && !&1.properties.covered))
                        |> ExSimpleGraph.delete_vertices_by(&(&1.properties.ring == :outer && &1.properties.covered))
                        |> reduce_intersection_edges
    {vertices, edges}
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

  defp add_coverage({v, e}, coords) do
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

  defp covered?(rings = [[_|_]|_], point = %{__struct__: Geo.Point}) do
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
      {p, edges} -> add_intersections(ExSimpleGraph.subdivide({v, e}, edges, p))
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
  Find the intersection point of two LineStrings. Returns a tuple indicating the
  type of intersection:
  - `:disjoint`, the LineStrings have no points in common
  - `:degen`, the LineStrings share points but are collinear, the endpoint of one
  incident with non-endpoint of other, or they share an endpoint
  - `:intersects`, the LineStrings have a non-trivial point of intersection

  ## Examples
  ```
  iex> reference = %Geo.LineString{coordinates: [{1.0, 1.0}, {2.0, 2.0}]}
  iex> disjoint = %Geo.LineString{coordinates: [{2.0, 1.0}, {2.0, 2.0}]}
  iex> GeoPartition.Geometry.intersection(reference, disjoint)
  {:endpoint, "endpoint"}

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
      a == c || a == d || b == c || b == d -> {:endpoint, "endpoint"}
      collinear?(a, c, d) && collinear?(b, c, d) && Topo.intersects?(l1, l2) -> {:degen, "degen"}
      collinear?(a, c, d) ||
      collinear?(b, c, d) ||
      collinear?(a, b, c) ||
      collinear?(a, b, d) -> {:incident, "incident"}
      !Topo.intersects?(l1, l2) -> {:disjoint, "disjoint"}
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
  Check if three points are collinear

  ## Examples
  ```
  iex> GeoPartition.Geometry.collinear?({1, 1}, {2, 2}, {3, 3})
  true

  iex> GeoPartition.Geometry.collinear?({1, 1}, {2, 2}, {3, 4})
  false
  ```
  """
  @spec collinear?({any, any}, {any, any}, {any, any}) :: boolean
  def collinear?(a = {x1, y1}, b = {x2, y2}, c = {x3, y3}) do
    abs(x1 * (y2 - y3) + x2 * (y3 - y1) + x3 * (y1 - y2)) < 0.0000000001
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
    %{coordinates: [outer|holes]} = shape |> clean_holes
    hole_area = holes
                |> Enum.map(&ring_area(&1, opts))
                |> List.foldl(0, &Kernel.+(&1, &2))
    ring_area(outer, opts) - hole_area
  end

  defp ring_area(shape = [{a, b}|_], opts) do
    flat_area = shape
                |> Enum.chunk_every(2, 1, :discard)
                |> Enum.map(&det_seg(&1))
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

  defp det_seg([{a, b}, {c, d}]) do
    (b * c) - (a * d)
  end

  defp get_long_factor(poly = %{__struct__: Geo.MultiPolygon}) do
    poly.coordinates
    |> get_long_factor
  end

  defp get_long_factor(coords) when is_list(coords) do
    coords
    |> Enum.map(fn({a, b}) -> b end)
    |> geo_mean
    |> deg_to_rad
    |> :math.cos
    |> Kernel.*(69.172)
  end

  defp geo_mean(list) do
    list = Enum.sort(list)
    ( List.first(list) + List.last(list) ) / 2
  end

  defp deg_to_rad(deg) do
    deg * 2 * :math.pi / 360
  end
end
