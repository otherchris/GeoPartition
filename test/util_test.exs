defmodule GeoPartition.UtilTest do
  use ExUnit.Case

  alias GeoPartition.Shapes
  alias GeoPartition.Util
  @triangle """
  {
  "type": "MultiPolygon",
  "coordinates": [[
  [
  [ -106.19590759277344, 39.333983227838104 ],
  [ -106.30714416503905, 39.36894242038886 ],
  [ -106.08879089355467, 40.333983227838104],
  [ -106.19590759277344, 39.333983227838104]
  ]
  ]]

  }
  """
  @overlaps """
  {
  "type": "MultiPolygon",
  "coordinates": [[
  [
  [
  -102.9638671875,
  38.685509760012
  ],
  [
  -101.6455078125,
  38.685509760012
  ],
  [
  -101.6455078125,
  39.9434364619742
  ],
  [
  -102.9638671875,
  39.9434364619742
  ],
  [
  -102.9638671875,
  38.685509760012
  ]
  ],
  [
  [
  -102.293701171875,
  39.33429742980725
  ],
  [
  -102.293701171875,
  39.554883059924016
  ],
  [
  -102.041015625,
  39.554883059924016
  ],
  [
  -102.041015625,
  39.33429742980725
  ],
  [
  -102.293701171875,
  39.33429742980725
  ]
  ],
  [
  [
  -102.403564453125,
  39.223742741391305
  ],
  [
  -102.403564453125,
  39.436192999314095
  ],
  [
  -102.20581054687499,
  39.436192999314095
  ],
  [
  -102.20581054687499,
  39.223742741391305
  ],
  [
  -102.403564453125,
  39.223742741391305
  ]
  ]
  ]]
  }
  """
  describe "get all coords" do
    test "get_all_coords" do
      arr = [[1, 2], [[[3, 4, 5]], [7]], 8]
      assert GeoPartition.Util.get_all_coords(arr) |> MapSet.new == [1, 2, 3, 4, 5, 7, 8] |> MapSet.new
    end
  end

  describe "geo mean" do
    test "geo mean" do
      assert GeoPartition.Util.geo_mean([1, 2, 3, 10]) == 5.5
    end
  end

  describe "get long factor" do
    test "get long lactor" do
      assert GeoPartition.Util.get_long_factor([
        { -106.08879089355467, 40.333983227838104 },
        { -106.19590759277344, 39.333983227838104 }
      ]) == 53.11743661200859
    end
  end

  describe "polygon_errors" do
    test "yes it overlaps" do
      result = @overlaps
               |> Poison.decode!
               |> Geo.JSON.decode!
               |> GeoPartition.Util.polygon_errors
      assert result == ["Cannot process Polygon with ring intersection"]
    end
  end

  describe "poly_list to multiploygon" do
    test "non trivial list" do
      list = [Shapes.triangle_1, Shapes.triangle_2, Shapes.simple_rect]
      assert GeoPartition.Util.polys_to_multi(list) == Shapes.multi_polygon_basic
    end
  end

  describe "test containment of line in poly" do
    test "trivial is contained" do
      assert Util.contains(Shapes.simple_rect, Shapes.line_inside_simple_rect) == true
    end

    test "crosses boundary" do
      assert Util.contains(Shapes.simple_rect, Shapes.line_crosses_simple_rect) == false
    end

    test "crosses hole" do
      assert Util.contains(Shapes.rect_with_hole, Shapes.line_crosses_simple_rect) == false
    end
  end

  describe "calculate area of a polygon" do
    test "find area" do
      poly = %Geo.Polygon{coordinates: Shapes.monster_multi_out.coordinates |> hd}
      assert Util.area(poly) == 161.89243343361437
    end
  end
end
