defmodule GeoPartition.Partition do

  alias GeoPartition.{Geometry, Graph}

  def partition(shape = %{__struct__: Geo.Polygon}, max_area) do
    polys = partition_list([shape], max_area)
  end

  def partition_list(list_of_polys, max_area) do
    new_list = Enum.map(list_of_polys, &maybe_split(&1, max_area)) |> List.flatten
    if length(new_list) == length(list_of_polys) do
      new_list
    else
      partition_list(new_list, max_area)
    end
  end

  def maybe_split(polygon, max_area) do
    clean_poly = polygon
                 |> Geometry.polygon_to_graph
                 |> Geometry.graph_to_polygon
    holed_poly = Map.put(clean_poly, :coordinates, clean_poly.coordinates ++ drop_bad_holes(polygon))
    if Geometry.area(holed_poly, [geo: :globe]) > max_area do
      {:ok, {ring1, ring2}} = add_split(Enum.at(holed_poly.coordinates, 0))
      [
        %Geo.Polygon{coordinates: [ring1] ++ drop_bad_holes(polygon)},
        %Geo.Polygon{coordinates: [ring2] ++ drop_bad_holes(polygon)}
      ]
    else
      [polygon]
    end
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
  ## Examples
  ```
  iex> ring = [{1, 2}, {5, 5}, {2, 1}, {1, 1}, {1, 2}]
  iex> GeoPartition.Partition.add_split(ring)
  {:ok, {[{1, 2}, {5, 5}, {2, 1}, {1, 2}], [{2, 1}, {1, 1}, {1, 2}, {2, 1}]}}
  ```
  """
  def add_split(ring) do
    {_, coords} = for x <- 0..(length(ring) - 1), y <- 0..(length(ring) - 1), good_line(ring, x, y) do
      {MapSet.new([Enum.at(ring, x), Enum.at(ring, y)]), MapSet.new([x, y])}
    end
    |> Enum.uniq
    |> Enum.sort_by(fn({e, c}) -> seg_len(e) end)
    |> hd
    [a, b] = MapSet.to_list(coords)
    make_split(ring, a, b)
  end

  @doc """
  Tests if a given pair of vertices form an acceptable split of a ring

  ## Examples
  ```
  iex> ring = [{1, 1}, {2, 0}, {3, 1}, {2, 2}, {1, 1}]
  iex> GeoPartition.Partition.good_line(ring, 1, 3)
  true


  iex> ring = [{1, 1}, {2, 0}, {3, 1}, {2, 2}, {1, 1}]
  iex> GeoPartition.Partition.good_line(ring, 1, 2)
  false

  iex> ring = [{2, 0}, {0, 1}, {0, 2}, {2, 4}, {1, 2}, {1, 1}, {2, 1}, {2, 0}]
  iex> GeoPartition.Partition.good_line(ring, 0, 3)
  false
  ```
  """
  def good_line(ring, source, target) do
    if abs(source - target) <= 1 do
      false
    else
      source_vertex = Enum.at(ring, source)
      target_vertex = Enum.at(ring, target)
      line = %Geo.LineString{coordinates: [source_vertex, target_vertex]}
      Enum.chunk_every(ring, 2, 1, :discard)
      |> Enum.reject(&(Enum.member?(&1, source_vertex) || Enum.member?(&1, target_vertex)))
      |> Enum.map(&Geometry.intersection(line, %Geo.LineString{coordinates: &1}))
      |> List.foldl(true, fn({disp, _}, acc) ->
        case disp do
           :intersects -> false
           :degen -> false
           :endpoint -> false
           :incident -> false
           :disjoint -> true
         end && acc
       end) && Topo.contains?(%Geo.Polygon{coordinates: [ring]}, midpoint_point(line))
    end
  end

  defp midpoint_point(line = %{coordinates: [{x1, y1}, {x2, y2}]}) do
    x = (x1 + x2) / 2
    y = (y1 + y2) / 2
    %Geo.Point{coordinates: {x, y}}
  end
  @doc """
  Rotate a list until a given index is the first element

  ## Examples
  ```
  iex> GeoPartition.Partition.rotate_to([11, 12, 13, 14, 15], 2)
  [13, 14, 15, 11, 12]
  ```
  """
  def rotate_to(list, index) do
    if index == 0 do
      list
    else
      list
      |> rotate
      |> rotate_to(index - 1)
    end
  end

  defp rotate(list) do
    tl(list) ++ [hd(list)]
  end

  @doc """
  Once a safe split is identified, make the split

  ## Examples
  ```
  iex> ring = [{1, 1}, {2, 0}, {3, 1}, {2, 2}, {1, 1}]
  iex> GeoPartition.Partition.make_split(ring, 1, 3)
  {:ok, {[{2, 0}, {3, 1}, {2, 2}, {2, 0}], [{2, 2}, {1, 1}, {2, 0}, {2, 2}]}}
  ```
  """
  def make_split(ring, source, target) do
    short_ring = Enum.slice(ring, 0..-2)
    ring1 = Enum.slice(short_ring, source..target) ++ [Enum.at(short_ring, source)]
    ring2 = Enum.slice(short_ring, target..-1) ++ Enum.slice(short_ring, 0..source) ++ [Enum.at(short_ring, target)]
    {:ok, {ring1, ring2}}
  end

  def add_split_triangle(ring) do
    split_seg = ring
                |> Enum.chunk_every(2, 1, :discard)
                |> Enum.sort_by(&seg_len(&1))
                |> List.last
    new_point = midpoint(split_seg)
    other_point = Enum.find(ring, &(!Enum.member?(split_seg, &1)))
    {:ok, {[other_point, List.first(split_seg), new_point, other_point], [other_point, List.last(split_seg), new_point, other_point]}}
  end

  def seg_len([a = {a1, a2}, b = {b1, b2}]) do
    :math.pow(a1 - b1, 2) + :math.pow(a2 - b2, 2)
  end

  def seg_len(a = %MapSet{}) do
    a
    |> MapSet.to_list
    |> seg_len
  end

  def midpoint([a = {a1, a2}, b = {b1, b2}]) do
    {(a1 + b1) /  2, (a2 + b2) / 2}
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
            |> Geometry.graph_to_polygon
  end

  defp uncovered_inner(vertex) do
    vertex.properties.ring == :inner && vertex.properties.covered == false
  end

  defp covered_outer(vertex) do
    vertex.properties.ring == :outer && vertex.properties.covered == true
  end
end
