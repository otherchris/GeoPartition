defmodule GeoPartition.Graph do
  @moduledoc """
  Graph representation of a polygon
  """

  alias GeoPartition.Util

  defstruct [
    vertices: [],
    edges: []
  ]

  def from_polygon(shape = %{__struct__: Geo.Polygon, coordinates: coords = [outer|holes]}) do
    {v, e} = add_ring_to_graph({[], []}, outer, :outer)
    {vertices, edges}  = List.foldl(holes, {v, e}, &add_ring_to_graph(&2, &1, :inner))
                         |> add_coverage(coords)
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
end
