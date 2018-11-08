defmodule GeoPartition.UtilTest do
  use ExUnit.Case

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
  describe "area calc" do
    test "basic triangle" do
      poly = @triangle
             |> Poison.decode!
             |> Geo.JSON.decode!
      assert GeoPartition.Util.area(poly) == 36.02
    end
  end

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
      |> IO.inspect
      assert result == ["Cannot process Polygon with ring intersection"]
    end
  end
end
