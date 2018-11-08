defmodule GeoPartition.Util do

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

  def area(shape = %{__struct__: Geo.Polygon}) do
    shape.coordinates
    |> get_all_coords
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(&det_seg(&1))
    |> List.foldr(0, &Kernel.+(&1, &2))
    |> abs
    |> Kernel.*(get_long_factor(shape.coordinates))
    |> Kernel.*(69.172)
    |> Kernel./(2)
  end

  defp det_seg([{a, b}, {c, d}]) do
    (b * c) - (a * d)
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

  def polys_to_multi(list) when is_list(list) do
    %Geo.MultiPolygon{coordinates: Enum.map(list, &(&1.coordinates))}
  end

  def contains(poly = %{__struct__: Geo.Polygon}, line = %{__struct__: Geo.LineString}) do
    Topo.contains?(poly, line)
  end
end
