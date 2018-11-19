defmodule GeoPartition.Graph do
  @moduledoc """
  Some functions for working with undirected graphs
  """

  alias GeoPartition.{Geometry, Util}

  @type graph() :: {list(), list(MapSet)}

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
    edges = edges_to_subdivide
            |> new_edges(new_vertex)
            |> Kernel.++(edges)
            |> Enum.reject(&(Enum.member?(edges_to_subdivide, &1)))
            |> Enum.uniq
    {vertices, edges}
  end

  defp new_edges(intersected_edges, point) do
    inters = intersected_edges
             |> Enum.map(&MapSet.to_list(&1))
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
    edge = e
           |> hd
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
      next == nil && used == [] ->
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
      next
      |> MapSet.difference(MapSet.new([last]))
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
  def delete_vertex({v, e}, vertex) do
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
