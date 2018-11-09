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
end
