defmodule GeoPartition.GeometryTest do
  use ExUnit.Case
  doctest GeoPartition.Geometry

  alias GeoPartition.{Geometry, Shapes, Util}

  describe "crosses? finds non-trivially intersecting segments" do
    test "intersects" do
      assert Geometry.crosses?(Shapes.ref_line, Shapes.intersect_line) == true
    end

    test "disjoint" do
      assert Geometry.crosses?(Shapes.ref_line, Shapes.disjoint_line) == false
    end

    test "overlap" do
      assert Geometry.crosses?(Shapes.ref_line, Shapes.overlap_line) == false
    end

    test "incident" do
      assert Geometry.crosses?(Shapes.ref_line, Shapes.incident_line) == false
    end
  end

  describe "intersection finds the intersection" do
    test "intersection" do
      assert Geometry.intersection(Shapes.ref_line, Shapes.intersect_line) == {:intersects, Shapes.intersect_point}
    end

    test "disjoint" do
      assert Geometry.intersection(Shapes.ref_line, Shapes.disjoint_line) == {:disjoint, "disjoint"}
    end

    test "degen" do
      assert Geometry.intersection(Shapes.ref_line, Shapes.overlap_line) == {:degen, "degen"}
      assert Geometry.intersection(Shapes.ref_line, Shapes.incident_line) == {:degen, "degen"}
    end
  end

  describe "calculate area of a polygon" do
    test "find area" do
      poly = %Geo.Polygon{coordinates: Shapes.monster_multi_out.coordinates |> hd}
      assert Geometry.area(poly) == 161.89243343361437
    end

    test "add area to props" do
      poly = %Geo.Polygon{coordinates: Shapes.monster_multi_out.coordinates |> hd}
      new_poly = Util.add_area(poly)
      assert new_poly.properties.area == 161.89243343361437
    end

    test "change existing area" do
      poly = %Geo.Polygon{coordinates: Shapes.monster_multi_out.coordinates |> hd, properties: %{area: 10}}
      new_poly = Util.add_area(poly)
      assert new_poly.properties.area == 161.89243343361437
    end
  end
end
