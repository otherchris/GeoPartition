defmodule GeoPartition.Graph do
  @moduledoc """
  Graph representation of a polygon
  """

  alias GeoPartition.{Geometry, Util}

  @type graph() :: {list(), list(MapSet)}

  def from_polygon(shape = %{__struct__: Geo.Polygon, coordinates: coords = [outer|holes]}) do
    {v, e} = add_ring_to_graph({[], []}, outer, :outer)
    {vertices, edges} = List.foldl(holes, {v, e}, &add_ring_to_graph(&2, &1, :inner))
                        |> add_coverage(coords)
                        |> add_intersections
    {vertices, edges}
  end

  #def find_path_by({v, e}, target, fun, list) do
  def to_polygon({v, e}) do
    {_, edges} = cycle_sort({v, e})
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

  def add_coverage({v, e}, coords = [outer|holes]) do
    vertices = add_coverage(v, coords)
    edges = add_coverage(e, coords)
    {vertices, edges}
  end

  def add_coverage(e = [%MapSet{}|_], coords) do
    e
    |> Enum.map(&MapSet.to_list(&1))
    |> List.flatten
    |> add_coverage(coords)
    |> Enum.chunk_every(2, 2, :discard)
    |> Enum.map(&MapSet.new(&1))
  end

  def add_coverage(v, coords = [outer|holes]) when is_list(v) do
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
      %Geo.Polygon{ coordinates: [ring] },
      point
    )
  end

  defp covered?([], _), do: false

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

    offset = length(e)
    edges = vertices
            |> Enum.chunk_every(2, 1, :discard)
            |> Enum.map(&MapSet.new(&1))
    {v ++ Enum.slice(vertices, 0..-2), e ++ edges}
  end

  defp add_intersections({v, e}) do
    for x <- e, y <- e do
      case Geometry.intersection(edge_to_seg(x), edge_to_seg(y)) do
        {:intersects, point} -> point
        _ -> nil
      end
    end
    |> Enum.reject(&is_nil(&1))
    |> Enum.uniq
    |> List.foldr({v, e}, &subdivide(&2, &1))
  end

  def subdivide({vertices, edges}, point) do
    props = Map.put(point.properties, :ring, :intersection)
            |> Map.put(:covered, false)
    vertices = vertices ++ [c = Map.put(point, :properties, props)]
    intersected_edges = Enum.filter(edges, &Geometry.soft_contains?(edge_to_seg(&1), c))
    edges = new_edges(intersected_edges, c)
            |> Kernel.++(edges)
            |> Enum.reject(&(Enum.member?(intersected_edges, &1)))

    {vertices, edges}
  end

  @doc """
  Produce a subdivision of the given edges using the given point.

  Merges duplicate edges.
  ## Examples
  ```
  iex> g = {[1, 2, 3, 4], [MapSet.new([1, 2]), MapSet.new([2, 3]), MapSet.new([3, 4]), MapSet.new([4, 1])]}
  iex> GeoPartition.Graph.subdivide(g, [MapSet.new([1, 2]), MapSet.new([3, 4])], "x")
  {[1, 2, 3, 4, "x"], [MapSet.new([1, "x"]), MapSet.new([2, "x"]), MapSet.new([3, "x"]), MapSet.new([4, "x"]), MapSet.new([2, 3]), MapSet.new([4, 1])]}

  iex> g = {[1, 2, 3], [MapSet.new([1, 2]), MapSet.new([2, 3]), MapSet.new([3, 1])]}
  iex> GeoPartition.Graph.subdivide(g, [MapSet.new([1, 2]), MapSet.new([2, 3])], "x")
  {[1, 2, 3, "x"], [MapSet.new([1, "x"]), MapSet.new([2, "x"]), MapSet.new([3, "x"]), MapSet.new([1, 3])]}
  ````
  """
  @spec subdivide(graph, list(MapSet), any) :: graph
  def subdivide({vertices, edges}, edges_to_subdivide, new_vertex) do
    vertices = vertices ++ [new_vertex]
    edges = new_edges(edges_to_subdivide, new_vertex)
            |> Kernel.++(edges)
            |> Enum.reject(&(Enum.member?(edges_to_subdivide, &1)))
            |> Enum.uniq
    {vertices, edges}
  end

  defp new_edges(intersected_edges, point) do
    inters = Enum.map(intersected_edges, &MapSet.to_list(&1))
             |> List.flatten
             |> Enum.map(&MapSet.new([&1, point]))
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

  def dehole({v, e}) do
    inters = Enum.filter(v, &(&1.properties.ring == :intersection))
    new_edges = for x <- inters, y <- inters do
      if x == y do
        nil
      else
        [x, y]
      end
    end
    |> Enum.reject(&is_nil(&1))
    |> Enum.uniq_by(&MapSet.new(&1))
    |> Enum.map(&get_best_path({v, e}, &1))
    |> List.flatten
    |> Enum.uniq
    |> Enum.reject(fn(x) ->
      Enum.to_list(x)
      |> Enum.map(&(&1.properties.ring == :intersection))
      |> IO.inspect
      |> List.foldl(true, &(&1 && &2))
    end)
    |> IO.inspect
    delete_vertices_by({v, e ++ new_edges}, &uncovered_inner(&1))
    |> delete_vertices_by(&covered_outer(&1))
    {v, new_edges}
  end

  defp covered_inner(vertex) do
    vertex.properties.ring == :inner && vertex.properties.covered
  end

  defp uncovered_inner(vertex) do
    vertex.properties.ring == :inner && vertex.properties.covered == false
  end

  defp covered_outer(vertex) do
    vertex.properties.ring == :outer && vertex.properties.covered == true
  end

  defp covered_inner_edge(edge) do
    edge
    |> Enum.map(&covered_inner(&1))
    |> List.foldl(false, &(&1 || &2))
    |> IO.inspect
  end

  defp get_best_path(graph, [start, stop]) do
    case find_path_by(graph, stop, [start], &(covered_inner(&1)), &(covered_inner_edge(&1))) do
      nil -> find_path_by(graph, stop, [start], &(&1.properties.ring != :outer), &(&1))
      path -> path
    end
  end

  @doc """
  If a graph is a cycle, returns the graph with the edeges in cycle order

  ## Examples
  ```
  iex> v = [1, 2, 3, 4]
  iex> e = [MapSet.new([1, 2]), MapSet.new([2, 3]), MapSet.new([4, 1]), MapSet.new([3, 4])]
  iex> GeoPartition.Graph.cycle_sort({v, e})
  {:ok, {[1,2,3,4], [MapSet.new([1, 4]), MapSet.new([4, 3]), MapSet.new([3, 2]), MapSet.new([2, 1])]}}

  iex> v = [1, 2, 3, 4]
  iex> e = [MapSet.new([1, 2]), MapSet.new([2, 3]), MapSet.new([4, 1]), MapSet.new([3, 4]), MapSet.new([2, 4])]
  iex> GeoPartition.Graph.cycle_sort({v, e})
  {:error, "not a cycle"}

  iex> v = [1, 2, 3, 4]
  iex> e = [MapSet.new([1, 2]), MapSet.new([2, 3]), MapSet.new([2, 4]), MapSet.new([3, 4])]
  iex> GeoPartition.Graph.cycle_sort({v, e})
  {:error, "not a cycle"}
  ```
  """
  @spec cycle_sort(graph) :: {:ok, graph} | {:error, string}
  def cycle_sort(graph = {v, e}) do
    if length(v) != length(e) do
      {:error, "not a cycle"}
    else
      cycle_sort_fun({v, e})
    end
  end

  defp cycle_sort_fun({v, e}) do
    edge = hd(e)
           |> Enum.to_list
    case find_path_by({v, tl(e)}, List.first(edge), List.last(edge), &(&1 || true), &(&1)) do
      nil -> {:error, "not a cycle"}
      edges -> {:ok, {v, edges ++ [MapSet.new(edge)]}}
    end
  end

  @doc """
  Returns the complete graph induced by a set of vertices

  ## Examples
  ```
  iex> GeoPartition.Graph.clique([1, 2, 3])
  {[1, 2, 3], [MapSet.new([1, 2]), MapSet.new([1, 3]), MapSet.new([2, 3])]}
  ```
  """
  def clique(vertices) do
    edges = for(v1 <- vertices, v2 <- vertices, v1 != v2, do: MapSet.new([v1, v2]))
    |> Enum.uniq
    {vertices, edges}
  end

  @doc """
  Return a set of edges representing a path from `inital` to `target` wherein every vertex in
  between satisfies `choose_by`. If `sort_by` is specified, it will be used to prioritize
  candidate vertices.

  ## Examples
  ```
  iex> v = [1, 2, 3, 4, 5, 6, 7, 8, 9]
  iex> {v, e} = GeoPartition.Graph.clique(v)
  iex> GeoPartition.Graph.find_path_by({v, e}, 1, 9, &(rem(&1, 2) == 0))
  [MapSet.new([1, 2]), MapSet.new([2, 4]), MapSet.new([4, 6]), MapSet.new([6, 8]), MapSet.new([8, 9])]

  iex> v = [1, 2, 3, 4, 5, 6, 7, 8, 9]
  iex> {v, e} = GeoPartition.Graph.clique(v)
  iex> GeoPartition.Graph.find_path_by({v, e}, 1, 9, &(rem(&1, 2) == 0), &Kernel.>=(&1, &2))
  [MapSet.new([1, 9])]
  ```
  """
  @spec find_path_by(graph, any, any, fun, fun) :: list
  def find_path_by(graph = {v, e}, first, target, choose_by, sort_by \\ &Kernel.<=(&1, &2)) do
    fpb({v, e}, first, target, choose_by, sort_by, [])
  end

  defp fpb({v, e}, prev, target, choose_by, sort_by, used) when is_list(used) do
    next = get_next_edge(e, prev, target, choose_by, sort_by, used)
    next_vertex = get_next_vertex(next, prev)
    cond do
      next_vertex == target -> # we're done, make the edges and return
        used
        |> Kernel.++([prev, next_vertex])
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.map(&MapSet.new(&1))
      next == nil && length(used) == 0 ->
        nil # we're done, no path
      next == nil || Enum.member?(used, next_vertex) -> # back up and try again
        next_graph = delete_vertex({v, e}, prev)
        next_used = Enum.slice(used, 0..-2)
        fpb(next_graph, List.last(used), target, choose_by, sort_by, next_used)
      true -> # ok, go to the next step
        fpb({v, e}, next_vertex, target, choose_by, sort_by, used ++ [prev])
    end
  end

  defp get_next_vertex(next, last) do
    if next == nil do
      nil
    else
      MapSet.difference(next, MapSet.new([last]))
      |> Enum.to_list
      |> hd
    end
  end

  defp get_next_edge(e, prev, target, choose_by, sort_by, used) do
    a = Enum.filter(e, &(
      MapSet.member?(&1, prev)
      && MapSet.disjoint?(&1, MapSet.new(used))
      && (choose_by.(get_next_vertex(&1, prev)) || get_next_vertex(&1, prev) == target)
    ))
    a
    |> Enum.sort_by(&get_next_vertex(&1, prev), &sort_by.(&1, &2))
    |> List.first
  end

  @doc """
  Produce the induced subgraph of a graph resulting from removing a vertex

  ## Examples
  ```
  iex> v = [1, 2, 3, 4]
  iex> edge_pairs = [[1, 2], [1, 3], [2, 3], [3, 4], [4, 1]]
  iex> e = Enum.map(edge_pairs, &MapSet.new(&1))
  iex> GeoPartition.Graph.delete_vertex({v, e}, 3)
  {[1, 2, 4], [MapSet.new([1, 2]), MapSet.new([1, 4])]}
  ```
  """
  @spec delete_vertex(graph(), any()):: graph()
  def delete_vertex({v,e}, vertex) do
    edges = e
    |> Enum.reject(&MapSet.member?(&1, vertex))
    vertices = Enum.reject(v, &(&1 == vertex))
    {vertices, edges}
  end

  @doc """
  Produce the induced subgraph of a graph resulting from removing vertices that satisfy `condition`

  ## Examples
  ```
  iex> v = [1, 2, 3, 4]
  iex> edge_pairs = [[1, 2], [1, 3], [2, 3], [3, 4], [4, 1]]
  iex> e = Enum.map(edge_pairs, &MapSet.new(&1))
  iex> GeoPartition.Graph.delete_vertices_by({v, e}, &(rem(&1, 2) == 0))
  {[1, 3], [MapSet.new([1, 3])]}
  ```
  """
  @spec delete_vertices_by(graph(), function()) :: graph()
  def delete_vertices_by({v, e}, condition) do
    for(vertex <- v, condition.(vertex), do: delete_vertex({v, e}, vertex))
    |> List.foldr({v, e}, &(intersection(&2, &1)))
  end

  @doc """
  Given two graphs, return their intersection (vertices and edges included in both)

  ## Examples
  ```
  iex> g1 = {[1, 2, 3], [MapSet.new([1, 2]), MapSet.new([2, 3])]}
  iex> g2 = {[1, 2], [MapSet.new([1,2])]}
  iex> GeoPartition.Graph.intersection(g1, g2)
  {[1, 2], [MapSet.new([1, 2])]}
  ```
  """
  @spec intersection(graph(), graph()) :: graph()
  def intersection({v1, e1}, {v2, e2}) do
    {for(x <- v1, y <- v2, x == y, do: x), for(x <- e1, y <- e2, x == y, do: x)}
  end
end
