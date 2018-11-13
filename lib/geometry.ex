defmodule GeoPartition.Geometry do
  @moduledoc """
  Functions for calculating area of polygons
  """

  # "soft" contains for finding a point on a line
  def contains?(a = %Geo.LineString{}, b = %Geo.Point{coordinates: {x, y}}) do
    smudge = %Geo.Polygon{
      coordinates: [
        [
          {x + 0.000001, y},
          {x, y + 0.000001},
          {x - 0.000001, y},
          {x, y - 0.000001},
          {x + 0.000001, y}
        ]
      ]
    }
    Topo.intersects?(a, smudge)
  end

  def intersects?(a = %{__struct__: Geo.LineString}, b = %{__struct__: Geo.LineString}) do
    Topo.intersects?(a, b)
    && !Topo.contains?(b, a)
    && !Topo.contains?(a, %Geo.Point{coordinates: hd(b.coordinates)})
    && !Topo.contains?(a, %Geo.Point{coordinates: List.last(b.coordinates)})
  end

  def intersection(l1 = %{coordinates: [a = {x1, y1}, b = {x2, y2}]}, l2 = %{coordinates: [c = {x3, y3}, d = {x4, y4}]}) do
    cond do
      !Topo.intersects?(l1, l2) -> {:disjoint, "disjoint"}
      !intersects?(l1, l2) && Topo.intersects?(l1, l2) -> {:degen, "degen"}
      a == c || a == d || b == c || b == d -> {:incident, "incident"}
      true ->
        u = ((x4-x3)*(y1-y3)-(y4-y3)*(x1-x3)) / ((y4-y3)*(x2-x1)-(x4-x3)*(y2-y1))
        {:intersects, %Geo.Point{
          coordinates: {
            x1 + u * (x2 - x1),
            y1 + u * (y2 - y1)
          }

        }}
    end
  end

end
