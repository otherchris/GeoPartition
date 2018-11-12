defmodule GeoPartition.Area do
  @moduledoc """
  Functions for calculating area of polygons
  """

  def intersects?(a = %{__struct__: Geo.LineString}, b = %{__struct__: Geo.LineString}) do
    Topo.intersects?(a, b)
    && !Topo.contains?(b, a)
    && !Topo.contains?(a, %Geo.Point{coordinates: hd(b.coordinates)})
    && !Topo.contains?(a, %Geo.Point{coordinates: List.last(b.coordinates)})
  end

  def intersection(l1 = %{coordinates: [{x1, y1}, {x2, y2}]}, l2 = %{coordinates: [{x3, y3}, {x4, y4}]}) do
    cond do
      !Topo.intersects?(l1, l2) -> {:disjoint, "disjoint"}
      !intersects?(l1, l2) && Topo.intersects?(l1, l2) -> {:degen, "degen"}
      true ->
        u = ((x4-x3)*(y1-y3)-(y4-y3)*(x1-x3)) / ((y4-y3)*(x2-x1)-(x4-x3)*(y2-y1))
        {:intersects, %Geo.Point{
          coordinates: [
            {
              x1 + u * (x2 - x1),
              y1 + u * (y2 - y1)
            }
          ]
        }}
    end
  end

  @doc """
  Return an outer ring with no overlapping polys

  If a hole is contained, no change
  If a hole overlaps, use the inside/outside strategy
  """
  def chop_hole(outer, hole) do
    if Topo.contains?(
      %Geo.Polygon{coordinates: [outer]},
      %Geo.Polygon{coordinates: [hole]}
    ) do
      outer
    else
      outer_edges = Enum.chunk_every(outer, 2, 1, :discard) |> Enum.map(&(%Geo.LineString{coordinates: &1}))
      hole_edges = Enum.chunk_every(hole, 2, 1, :discard) |> Enum.map(&(%Geo.LineString{coordinates: &1}))
      intersections = get_intersections(outer_edges, hole_edges)
    end
  end

  def get_intersections(a, b)do
    Enum.map(a, fn(x) ->
      Enum.map(b, fn(y) ->
        case intersection(x, y) do
          {:intersects, point} -> [{a, point}, {b, point}]
          _ -> nil
        end
      end)
    end)
    |> List.flatten
    |> Enum.uniq
    |> Enum.reject(&is_nil(&1))
  end

  def sort_segment(points) do
    Enum.sort_by(points, &dist_compare(hd(points), &1, &2))
  end

  def dist(a = {x1, y1}, b = {x2, y2}) do
    :math.sqrt(:math.pow((x1 - x2), 2) + :math.pow((y1 - y2), 2))
  end

  def dist_compare(near, a, b) do
    dist(near, a) <= dist(near, b)
  end
end
