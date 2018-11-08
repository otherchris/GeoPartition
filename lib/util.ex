defmodule GeoPartition.Util do

  def area(poly) do
    long_factor = get_long_factor(poly)
    36.02
  end

  def get_long_factor(poly = %{__struct__: Geo.MultiPolygon}) do
    poly.coordinates
    |> get_long_factor
  end

  def get_long_factor(coords) when is_list(coords) do
    coords
    |> get_all_coords
    |> Enum.map(fn({a, b}) -> b end)
    |> geo_mean
    |> deg_to_rad
    |> :math.cos
    |> Kernel.*(69.172)
  end

  def get_all_coords(poly) when is_list(poly) do
    Enum.map(poly, &get_all_coords(&1))
    |> List.flatten
  end

  def get_all_coords(coords) do
    coords
  end

  def geo_mean(list) do
    list = Enum.sort(list)
    ( List.first(list) + List.last(list) ) / 2
  end

  defp deg_to_rad(deg) do
    deg * 2 * :math.pi / 360
  end

  @doc """
  Disallow polygons with overlapping rings
  """
  def polygon_errors(shape) do
    Enum.map(shape.coordinates, &check_overlap(%Geo.Polygon{coordinates: &1}))
    |> List.flatten
    |> Enum.filter(&(&1))
  end

  defp check_overlap(shape = %{__struct__: Geo.Polygon}) do
    if length(shape.coordinates) == 1 do
      [false]
    else
      shape.coordinates
      |> tl
      |> Enum.map(fn(ring) ->
        if Topo.intersects?(
          %Geo.LineString{coordinates: hd(shape.coordinates)},
          %Geo.LineString{coordinates: ring}
        ) do
          "Cannot process Polygon with ring intersection"
        else
          [false]
        end
      end)
      |> Kernel.++(check_overlap(%Geo.Polygon{coordinates: tl(shape.coordinates)}))
    end
  end

  def de_hole(shape = %{__struct__: Geo.MultiPolygon}) do
    new_polys = Enum.map(shape.coordinates, &de_hole(%Geo.Polygon{coordinates: &1}))
    %Geo.MultiPolygon{coordinates: new_polys}
  end

  def de_hole(shape = %{__struct__: Geo.Polygon}) do
    if length(shape.coordinates) == 1 do
      [shape]
    else
      de_hole(shape.coordinates, 0)
    end
  end

  @doc """
  if we have iterated through the next hole, rotate the holes
  if the hole is not contained throw it out
  see if a line from vertex zero of outer ring to vertex iter of hole intersects anything
  either return deholed list or try next vertex
  """
  def de_hole(shape = [[{a,b}|_]|_], iter) when is_integer(iter) do
    cond do
      #one ring, nothing to do
      length(shape) == 1 -> shape
      #if we have iterated through the next hole, rotate the holes
      iter > length(Enum.at(shape, 1)) - 1 ->
        if length(tl(shape)) == 1 do
          de_hole([rotate_list(hd(shape))] ++ tl(shape), 0)
        else
          de_hole([hd(shape)] ++ rotate_list(tl(shape)), 0)
        end
      #if the hole is not contained throw it out
      !Topo.contains?(
        %Geo.Polygon{coordinates: [Enum.at(shape, 0)]},
        %Geo.Polygon{coordinates: [Enum.at(shape, 1)]}
      ) ->
        de_hole(%Geo.Polygon{coordinates: [hd(shape)] ++ tl(tl(shape))})
      true ->
        line = %Geo.Polygon{coordinates: [[
          shape |> hd |> hd,
          Enum.at(shape, 1) |> Enum.at(iter),
          nudge(shape |> hd |> hd),
          shape |> hd |> hd
        ]]}
        inters = shape
                 |> tl
                 |> tl
                 |> Enum.map(fn(x) ->
                   cond do
                     Topo.intersects?(%Geo.LineString{coordinates: x}, line) -> true
                     !Topo.contains?(%Geo.Polygon{coordinates: hd(shape)}, line) -> true
                     true -> false
                   end
                 end)
        if length(Enum.filter(inters, &(&1))) > 0 do
          de_hole(shape, iter + 1)
        else
          de_hole(hd(shape), tl(shape), iter)
        end
    end
  end



  def de_hole(outer, rest, index) when is_integer(index) do
    inner = hd(rest)
    new_outer = outer
    ++ Enum.slice(inner, index..-1)
    ++ Enum.slice(inner, 0..index)
    ++ [hd(outer)]
    de_hole([new_outer] ++ tl(rest), 0)
  end

  defp rotate_list(list) do
    tl(list) ++ [hd(list)]
  end

  defp nudge({a, b}) do
    {a + 0.00000001, b + 0.00000001}
  end
end
