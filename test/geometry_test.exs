defmodule GeoPartition.GeometryTest do
  use ExUnit.Case
  doctest GeoPartition.Geometry

  alias GeoPartition.{Geometry, Shapes, Util}

  setup do
    vertices =  [
      %Geo.Point{
        coordinates: {-84.28848266601563, 36.80268739459133},
        properties: %{
          ring: :outer,
          covered: false
        }
      },
      %Geo.Point{
        coordinates: {-84.06463623046875, 36.80268739459133},
        properties: %{
          ring: :outer,
          covered: false
        }
      },
      %Geo.Point{
        coordinates: {-84.06463623046875, 36.9795180188502},
        properties: %{
          ring: :outer,
          covered: false
        }
      },
      %Geo.Point{
        coordinates: {-84.28848266601563, 36.9795180188502},
        properties: %{
          ring: :outer,
          covered: false
        }
      }
    ]
    corner_vertices = [
        #A
        %Geo.Point{
          coordinates: {-84.28848266601563, 36.80268739459133},
          properties: %{
            ring: :outer,
            covered: false
          }
        },
        #B
        %Geo.Point{
          coordinates: {-84.06463623046875, 36.80268739459133},
          properties: %{
            ring: :outer,
            covered: false
          }
        },
        #C
        %Geo.Point{
          coordinates: {-84.06463623046875, 36.9795180188502},
          properties: %{
            ring: :outer,
            covered: true
          }
        },
        #D
        %Geo.Point{
          coordinates: {-84.28848266601563, 36.9795180188502},
          properties: %{
            ring: :outer,
            covered: false
          }
        },
        #E
        %Geo.Point{
          coordinates: {-84.11338806152344, 36.93946500056987},
          properties: %{
            ring: :inner,
            covered: true
          }
        },
        #F
        %Geo.Point{
          coordinates: {-84.01107788085938, 36.93946500056987},
          properties: %{
            ring: :inner,
            covered: false
          }
        },
        #G
        %Geo.Point{
          coordinates: {-84.01107788085938, 37.008584404683155},
          properties: %{
            ring: :inner,
            covered: false
          }
        },
        #H
        %Geo.Point{
          coordinates: {-84.11338806152344, 37.008584404683155},
          properties: %{
            ring: :inner,
            covered: false
          }
        }
      ]
    %{
      simple_vertices: vertices,
      corner_vertices: corner_vertices,
      simple_edges: [
        MapSet.new([Enum.at(vertices, 0), Enum.at(vertices, 1)]),
        MapSet.new([Enum.at(vertices, 1), Enum.at(vertices, 2)]),
        MapSet.new([Enum.at(vertices, 2), Enum.at(vertices, 3)]),
        MapSet.new([Enum.at(vertices, 3), Enum.at(vertices, 0)]),
      ],
      corner_edges: [
        MapSet.new([Enum.at(corner_vertices, 0), Enum.at(corner_vertices, 1)]),
        MapSet.new([Enum.at(corner_vertices, 1), Enum.at(corner_vertices, 2)]),
        MapSet.new([Enum.at(corner_vertices, 2), Enum.at(corner_vertices, 3)]),
        MapSet.new([Enum.at(corner_vertices, 3), Enum.at(corner_vertices, 0)]),
        MapSet.new([Enum.at(corner_vertices, 4), Enum.at(corner_vertices, 5)]),
        MapSet.new([Enum.at(corner_vertices, 5), Enum.at(corner_vertices, 6)]),
        MapSet.new([Enum.at(corner_vertices, 6), Enum.at(corner_vertices, 7)]),
        MapSet.new([Enum.at(corner_vertices, 7), Enum.at(corner_vertices, 4)]),
      ]
    }
  end
  describe "create graph from polygon" do
    test "no holes", %{simple_vertices: vertices, simple_edges: edges} do
      {v, e} = Geometry.polygon_to_graph(Shapes.simple_rect)
      assert MapSet.new(v) == MapSet.new(vertices)
      assert MapSet.new(e) == MapSet.new(edges)
    end

    test "simple hole", %{simple_vertices: vertices, simple_edges: edges} do
      {v, e} = Geometry.polygon_to_graph(Shapes.rect_with_hole)
      vertices = vertices ++ [
        %Geo.Point{
          coordinates: {-84.20059204101562, 36.88566207736627},
          properties: %{
            ring: :inner,
            covered: true
          }
        },
        %Geo.Point{
          coordinates: {-84.18514251708984, 36.88566207736627},
          properties: %{
            ring: :inner,
            covered: true
          }
        },
        %Geo.Point{
          coordinates: {-84.18514251708984, 36.90186184771291},
          properties: %{
            ring: :inner,
            covered: true
          }
        },
        %Geo.Point{
          coordinates: {-84.20059204101562, 36.90186184771291},
          properties: %{
            ring: :inner,
            covered: true
          }
        }
      ]
      edges = edges ++ [
        MapSet.new([Enum.at(vertices, 4), Enum.at(vertices, 5)]),
        MapSet.new([Enum.at(vertices, 5), Enum.at(vertices, 6)]),
        MapSet.new([Enum.at(vertices, 6), Enum.at(vertices, 7)]),
        MapSet.new([Enum.at(vertices, 7), Enum.at(vertices, 4)])
      ]
      assert MapSet.new(v) == MapSet.new(vertices)
      assert MapSet.new(e) == MapSet.new(edges)
    end

    test "corner hole", %{corner_vertices: vertices, corner_edges: edges} do
      {v, e} = Geometry.polygon_to_graph(Shapes.rect_with_corner_hole)
      assert length(v) == 6
      assert length(e) == 6
    end

    test "diamonds" do
      #graph = Graph.from_polygon(Shapes.intersecting_diamonds)
      #assert length(graph.vertices) == 10
      #assert length(graph.edges) == 12
    end
  end

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
      assert Geometry.intersection(Shapes.ref_line, Shapes.incident_line) == {:incident, "incident"}
    end
  end

  describe "calculate area of a polygon" do
    test "find area" do
      poly = Shapes.rect_with_corner_hole
      assert Geometry.area(poly, [geo: :globe]) == 144.00153645029894
    end

    test "add area to props" do
      poly = Shapes.rect_with_corner_hole
      new_poly = Util.add_area(poly)
      assert new_poly.properties.area == 144.00153645029894
    end

    test "change existing area" do
      poly = Shapes.rect_with_corner_hole
      new_poly = Util.add_area(poly)
      assert new_poly.properties.area == 144.00153645029894
    end
  end
end
