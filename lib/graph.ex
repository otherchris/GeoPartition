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
    {vertices, edges}  = List.foldl(coords, {[], []}, &add_ring_to_graph(&2, &1))
    %GeoPartition.Graph{
      vertices: vertices,
      edges: edges
    };
  end

  def add_hole_vertices(outer, hole) do

  end

  defp add_ring_to_graph(intial = {v, e}, ring) do
    vertices = Enum.map(ring, fn({lng, lat}) ->
      %Geo.Point{
        coordinates: {lng, lat},
        properties: %{
          ring: :outer,
          covered: false
        }
      }
    end)
    |> Enum.slice(0..-2)

    offset = length(e)
    edges = Enum.to_list(offset..length(vertices) + offset - 1)
    |> List.foldr([], &(&2 ++ [[&1]]))
    |> Enum.reverse
    |> Util.rotate_list

    {v ++ vertices, e ++ edges}
  end
end
