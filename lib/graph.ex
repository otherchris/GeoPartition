defmodule GeoPartition.Graph do
  @moduledoc """
  Graph representation of a polygon
  """

  alias GeoPartition.{Geometry, Util}

  defstruct [
    vertices: [],
    edges: []
  ]

  def from_polygon(shape = %{__struct__: Geo.Polygon, coordinates: coords = [outer|holes]}) do
    {v, e} = add_ring_to_graph({[], []}, outer, :outer)
    {vertices, edges} = List.foldl(holes, {v, e}, &add_ring_to_graph(&2, &1, :inner))
                        |> add_coverage(coords)
                        |> add_intersections
    %GeoPartition.Graph{
      vertices: vertices,
      edges: edges
    };
  end

  #def find_path_by({v, e}, target, fun, list) do
  def to_polygon({v, e}) do
    {_, edges} = find_cycle({v, e})
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

  defp get_next_vertex(next, last) do
    if next == nil do
      nil
    else
      MapSet.difference(next, MapSet.new([last]))
      |> Enum.to_list
      |> hd
    end
  end

  def find_cycle({v, e}) do
    edge = hd(e)
           |> Enum.to_list
    edges = find_path_by({v, tl(e)}, List.first(edge), [List.last(edge)], &(&1 || true), &(&1))
    {v, edges ++ [MapSet.new(edge)]}
  end

  def find_path_by({v, e}, target, list, choose_by, sort_by) do
    prev = List.last(list)
    used = Enum.slice(list, 0..-2)

    next = Enum.filter(e, &(
      MapSet.member?(&1, prev)
      && MapSet.disjoint?(&1, MapSet.new(used))
      && (choose_by.(get_next_vertex(&1, prev) || get_next_vertex(&1, prev) == target))
    ))
    |> Enum.sort_by(&sort_by.(&1), &>=/2)
    |> List.first
    next_vertex = get_next_vertex(next, prev)
    cond do
      list == [] -> nil # we're done, no path
      next == nil && length(list) == 1 -> nil # we're done, no path
      next == nil || Enum.member?(used, next_vertex) -> # back up and try again
        next_graph = delete_vertex({v, e}, prev)
        next_list = Enum.slice(list, 0..-2)
        find_path_by(next_graph, target, next_list, choose_by, sort_by)
      next_vertex == target -> # we're done, make the edges and return
        list
        |> Kernel.++([next_vertex])
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.map(&MapSet.new(&1))
      true -> find_path_by({v, e}, target, list ++ [next_vertex], choose_by, sort_by) # ok, go to next step
    end
  end

  defp delete_vertex({v,e}, vertex) do
    edges = e
    |> Enum.reject(&MapSet.member?(&1, vertex))
    vertices = Enum.reject(v, &(&1 == vertex))
    {vertices, edges}
  end

  def delete_vertices_by({v, e}, fun) do
    {new_v, new_e} = for vertex <- v do
      if fun.(vertex) do
        delete_vertex({v, e}, vertex)
      else
        {v, e}
      end
    end
    |> List.foldr({v, e}, &(intersection(&2, &1)))
    {MapSet.to_list(new_v), MapSet.to_list(new_e)}
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
  def intersection({v1, e1}, {v2, e2}) do
    vertex_sets = [v1, v2] |> Enum.map(&MapSet.new(&1))
    vertices = MapSet.intersection(List.first(vertex_sets), List.last(vertex_sets)) |> MapSet.to_list
    edge_sets = [e1, e2] |> Enum.map(&MapSet.new(&1))
    edges = MapSet.intersection(List.first(edge_sets), List.last(edge_sets)) |> MapSet.to_list
    {vertices, edges}
  end
end
