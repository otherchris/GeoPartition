defmodule GeoPartition.DeHole do
  @moduledoc """
  Turn a polygon with holes into a polygon without holes

  (Future work: turn a polygon with holes into a several hole-free polygons without
  duplicate edges)
  """

  alias GeoPartition.Util

  @doc """
  MultiPolygon entry point for deholing.

  Map the Geo.Polygon version of de_hole over the Polygons in the MultiPolygon
  Return a MultiPolygon of the results
  """
  def de_hole(shape = %{__struct__: Geo.MultiPolygon}) do
    new_polys = Enum.map(shape.coordinates, &de_hole(%Geo.Polygon{coordinates: &1}))
    Util.polys_to_multi(new_polys)
  end

  @doc """
  Polygon deholer

  if the polygon has no holes, return the polygon
  otherwise remove the holes
  """
  def de_hole(shape = %{__struct__: Geo.Polygon}) do
    if length(shape.coordinates) == 1 do
      shape
    else
      de_hole(shape.coordinates, {0, 0}, shape.coordinates)
    end
  end

  @doc """
  Dehole the coordinates of a Polygon

  if no hole, return the shape
  if we have iterated through the next hole, rotate the holes
  Draw a line from the hole_vertex to the outer_vertex
    try hole_vertex to outer_vertex
    try next hole vertex, if exhausted
    try next
  if the hole is not contained throw it out
  see if a line from vertex zero of outer ring to vertex iter of hole intersects anything
  either return deholed list or try next vertex

  """
  def de_hole(shape = [[{a,b}|_]|_], {outer_vertex, hole_vertex}, orig) do
    outer = shape |> hd
    hole = shape |> tl |> hd
    cond do
      # have we exhausted the hole?
      outer_vertex >= length(outer) ->
        de_hole([outer] ++ rotate_list(shape |> tl), {0, 0}, orig)
      # have we exhausted the outer vertex?
      hole_vertex >= length(hole) ->
        de_hole(shape, {outer_vertex + 1, 0}, orig)
      # do the check
      true ->
        line = %Geo.LineString{coordinates: [Enum.at(hole, hole_vertex), Enum.at(outer, outer_vertex)]}
        if (Util.contains(%Geo.Polygon{coordinates: orig}, line)) do
          # DEHOLE IT
          de_hole(outer, shape |> tl, {outer_vertex, hole_vertex}, orig)
        else
          # next hole vertex
          de_hole(shape, {outer_vertex, hole_vertex + 1}, orig)
        end
    end
  end

  def de_hole(outer, rest, {outer_index, hole_index}, orig) do
    rotated_inner = rotate_poly_ring(hd(rest), hole_index)
    rotated_outer = rotate_poly_ring(outer, outer_index)

    new_outer = rotated_outer ++ rotated_inner ++ [hd(rotated_inner)] ++ [hd(rotated_outer)]
    if length(rest) > 1 do
      de_hole([new_outer] ++ tl(rest), {0, 0}, orig)
    else
      %Geo.Polygon{coordinates: [new_outer]}
    end
  end

  defp rotate_list(list) do
    tl(list) ++ [hd(list)]
  end

  defp rotate_poly_ring(list) do
    tl(list) ++ [Enum.at(list, 1)]
  end

  def rotate_poly_ring(list, index) do
    if index == 0 do
      list
    else
      rotate_poly_ring(rotate_poly_ring(list), index - 1)
    end
  end

  defp nudge({a, b}) do
    {a + 0.00000001, b + 0.00000001}
  end
end
