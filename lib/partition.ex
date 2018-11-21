defmodule GeoPartition.Partition do

  alias GeoPartition.{Geometry, Graph, Util}

  def partition(shape = %{__struct__: Geo.Polygon, coordinates: [ring]}) do
    ring
    |> add_split(0)
  end

  def add_split(ring, target) do
    dups = get_dups(ring)
    {opposite, _} = ring
                    |> length
                    |> Kernel./(2)
                    |> Float.to_string
                    |> Integer.parse
    opposite_vertex = Enum.at(ring, opposite)
    target_vertex = Enum.at(ring, target)
                    # exhausted source?
    if abs(target) >= opposite do
      add_split(GeoPartition.DeHole.rotate_poly_ring(ring), 0)
    else
      line = %Geo.LineString{coordinates: [hd(ring), Enum.at(ring, opposite + target)]}
      poly = %Geo.Polygon{ coordinates: [ring] }
      poly1 = %Geo.Polygon{coordinates: [Enum.slice(ring, 0..(opposite + target)) ++ [hd(ring)]]}
      poly2 = %Geo.Polygon{coordinates: [[hd(ring)] ++ Enum.slice(ring, (opposite + target)..-1) ++ [hd(ring)]]}
      if Util.contains(poly, line) && !Enum.member?(dups, target_vertex) && !Enum.member?(dups, opposite_vertex) do
        [
          %Geo.Polygon{coordinates: [Enum.slice(ring, 0..(opposite + target)) ++ [hd(ring)]]},
          %Geo.Polygon{coordinates: [[hd(ring)] ++ Enum.slice(ring, (opposite + target)..-1) ++ [hd(ring)]]}
        ]
      else
        add_split(ring, inc(target))
      end
    end
  end

  defp split_check(polys = [poly1, poly2, ref]) do
    [p1, p2, r] = Enum.map(polys, &Geometry.area(&1))
    is_close(p1 + p2, r)
  end

  defp is_close(x, y) do
    abs(x - y) < 0.0000001
  end

  def inc(x) do
    if x <= 0 do
      (x * -1) + 1
    else
      x * -1
    end
  end

  def get_dups(list) do
    Enum.map(list, fn(x) ->
      Enum.slice(list, Enum.find_index(list, &(&1==x)) + 1..-1)
      |> Enum.find(&(&1 == x))
    end)
    |> Enum.reject(&is_nil(&1))
  end

  @doc """
  If a polygon has a hole that overlaps the outer ring, redraw the outer ring to exclude
  the occluded areas

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
  iex> GeoPartition.Partition.dehole(shape)
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
        {0.0, 0.0}
      ]
    ],
    properties: %{},
    srid: nil
  }
  ````
  """
  def dehole(poly = %Geo.Polygon{}) do
    graph = poly
            |> Geometry.polygon_to_graph
            |> Geometry.cycle_to_polygon
  end

  defp uncovered_inner(vertex) do
    vertex.properties.ring == :inner && vertex.properties.covered == false
  end

  defp covered_outer(vertex) do
    vertex.properties.ring == :outer && vertex.properties.covered == true
  end
end
