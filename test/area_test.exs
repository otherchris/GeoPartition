defmodule GeoPartition.AreaTest do
  use ExUnit.Case

  alias GeoPartition.{Area, Shapes}

  describe "intersects? finds non-trivially intersecting segments" do
    test "intersects" do
      assert Area.intersects?(Shapes.ref_line, Shapes.intersect_line) == true
    end

    test "disjoint" do
      assert Area.intersects?(Shapes.ref_line, Shapes.disjoint_line) == false
    end

    test "overlap" do
      assert Area.intersects?(Shapes.ref_line, Shapes.overlap_line) == false
    end

    test "incident" do
      assert Area.intersects?(Shapes.ref_line, Shapes.incident_line) == false
    end
  end

  describe "intersection finds the intersection" do
    test "intersection" do
      assert Area.intersection(Shapes.ref_line, Shapes.intersect_line) == {:intersects, Shapes.intersect_point}
    end

    test "disjoint" do
      assert Area.intersection(Shapes.ref_line, Shapes.disjoint_line) == {:disjoint, "disjoint"}
    end

    test "degen" do
      assert Area.intersection(Shapes.ref_line, Shapes.overlap_line) == {:degen, "degen"}
      assert Area.intersection(Shapes.ref_line, Shapes.incident_line) == {:degen, "degen"}
    end
  end
end
