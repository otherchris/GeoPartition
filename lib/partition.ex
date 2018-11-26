defmodule GeoPartition.Partition do

  alias GeoPartition.{Geometry, Graph, Util}

  def partition(shape = %{__struct__: Geo.Polygon}, max_area) do
    polys = partition_list([shape], max_area)
            |> Enum.map(&(&1.coordinates))
    %Geo.MultiPolygon{coordinates: polys}
  end

  def partition_list(list_of_polys, max_area) do
    new_list = Enum.map(list_of_polys, &maybe_split(&1, max_area)) |> List.flatten
    if length(new_list) == length(list_of_polys) do
      new_list
    else
      partition_list(new_list, max_area)
    end
  end

  defp maybe_split(polygon, max_area) do
    IO.puts polygon |> Geo.JSON.encode! |> Poison.encode!
    clean_poly = polygon
                 |> Geometry.polygon_to_graph
                 |> Geometry.cycle_to_polygon
    IO.puts "clean"
    IO.puts clean_poly |> Geo.JSON.encode! |> Poison.encode!
    if Geometry.area(clean_poly, [geo: :globe]) > max_area do
      {:ok, {ring1, ring2}} = add_split(Enum.at(clean_poly.coordinates, 0), 0, 0)
      [
        %Geo.Polygon{coordinates: [ring1]},
        %Geo.Polygon{coordinates: [ring2]}
      ]
    else
      [polygon]
    end
  end

  def diameter(ring) do
    {res, _} = ring
               |> length
               |> Kernel./(2)
               |> Float.to_string
               |> Integer.parse
    res
  end

  def add_split(ring, source, offset) do
    IO.inspect {source, offset}
    d = diameter(ring)
    ring = if length(ring) == 4 do
      add_split_triangle(ring)
    else
      short_ring = Enum.slice(ring, 0..-2)
      cond do
        source >= d -> {:error, "no split"}
        abs(offset) >= d - 1 -> add_split(ring, source + 1, 0)
        true ->
          if good_line(ring, source, d + offset + source) do
            make_split(ring, source, d + offset)
          else
            add_split(ring, source, inc(offset))
          end
      end
    end
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
  iex> GeoPartition.Partition.good_line(ring, 0, 4)
  false
  ```
  """
  def good_line(ring, source, target) do
    if abs(source - target) <= 1 do
      false
    else
      !Geometry.crosses?(
        %Geo.LineString{coordinates: ring},
        %Geo.LineString{coordinates: [Enum.at(ring, source), Enum.at(ring, target)]}
      )
    end
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
    IO.inspect "TRIANGLE"
    split_seg = ring
                |> Enum.chunk_every(2, 1, :discard)
                |> Enum.sort_by(&seg_len(&1))
                |> List.last
    new_point = midpoint(split_seg)
    other_point = Enum.find(ring, &(!Enum.member?(split_seg, &1)))
    {:ok, {[other_point, List.first(split_seg), new_point, other_point], [other_point, List.last(split_seg), new_point, other_point]}}
    |> IO.inspect
  end

  def seg_len([a = {a1, a2}, b = {b1, b2}]) do
    :math.pow(a1 - b1, 2) + :math.pow(a2 - b2, 2)
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
            |> Geometry.cycle_to_polygon
  end

  defp uncovered_inner(vertex) do
    vertex.properties.ring == :inner && vertex.properties.covered == false
  end

  defp covered_outer(vertex) do
    vertex.properties.ring == :outer && vertex.properties.covered == true
  end
end
