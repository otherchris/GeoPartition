defmodule GeoPartition.Graph do
  @moduledoc """
  Graph representation of a polygon
  """

  alias GeoPartition.{Area, Util}

  defstruct [
    vertices: [],
    edges: []
  ]

  def from_polygon(shape = %{__struct__: Geo.Polygon, coordinates: coords = [outer|holes]}) do
    {v, e} = add_ring_to_graph({[], []}, outer, :outer)
    {vertices, edges}  = List.foldl(holes, {v, e}, &add_ring_to_graph(&2, &1, :inner))
                         |> add_coverage(coords)
                         |> add_intersections
    %GeoPartition.Graph{
      vertices: vertices,
      edges: edges
    };
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
    segs = e
           |> Enum.map(&MapSet.to_list/1)
           |> Enum.map(&points_to_seg(&1))
    add_intersections(segs, tl(segs), {v, e})
  end

  defp add_intersections(segs, others, {v, e}) when is_list(segs) do
    cond do
      length(segs) <= 1 -> {v, e}
      others == [] -> add_intersections(tl(segs), tl(tl(segs)), {v, e})
      true ->
        case Area.intersection(hd(segs), hd(others)) do
          {:intersects, point} ->
            add_intersections(segs, tl(others), subdivide({v, e}, point))
          _ -> add_intersections(segs, tl(others), {v, e})
        end
    end
  end

  def subdivide({vertices, edges}, point) do
    props = Map.put(point.properties, :ring, :intersection)
            |> Map.put(:covered, false)
    vertices = vertices ++ [c = Map.put(point, :properties, props)]
    intersected_edges = Enum.filter(edges, &Area.contains?(edge_to_seg(&1), c))
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
end
