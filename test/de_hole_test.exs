defmodule GeoPartition.DeHoleTest do
  use ExUnit.Case

  alias GeoPartition.DeHole
  alias GeoPartition.Shapes

  describe "No holes, no change" do
    test "MultiPolygon" do
      assert DeHole.de_hole(Shapes.multi_polygon_basic) == Shapes.multi_polygon_basic
    end

    test "Polygon" do
      assert DeHole.de_hole(Shapes.triangle_1) == Shapes.triangle_1
    end
  end

  describe "Deholing" do
    test "dehole the monster" do
      assert DeHole.de_hole(Shapes.monster_multi) == Shapes.monster_multi_out
    end
  end


end