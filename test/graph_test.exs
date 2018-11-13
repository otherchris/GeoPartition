defmodule GeoPartition.GraphTest do
  use ExUnit.Case

  alias GeoPartition.{Graph, Shapes}

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

  describe "helpers" do

    test "subdividesimple", %{
      simple_vertices: vertices,
      simple_edges: edges,
    } do
      point = %Geo.Point{
        coordinates: {-84.06463623046875, 36.93946500056987},
        properties: %{
          ring: :intersection,
          covered: false
        }
      }
      {v, e} = Graph.subdivide({vertices, edges}, point)
      assert length(v) == 5
      assert length(e) == 5
    end

    test "subdividehard", %{
      corner_vertices: corner_vertices,
      corner_edges: corner_edges
    } do
      point = %Geo.Point{
        coordinates: {-84.06463623046875, 36.93946500056987},
        properties: %{
          ring: :intersection,
          covered: false
        }
      }
      {v1, e1} = Graph.subdivide({corner_vertices, corner_edges}, point)
      assert length(v1) == 9
      assert length(e1) == 10
    end
  end

  describe "create graph from polygon" do
    test "no holes", %{simple_vertices: vertices, simple_edges: edges} do
      graph = Graph.from_polygon(Shapes.simple_rect)
      assert MapSet.new(graph.vertices) == MapSet.new(vertices)
      assert MapSet.new(graph.edges) == MapSet.new(edges)
    end

    test "simple hole", %{simple_vertices: vertices, simple_edges: edges} do
      graph = Graph.from_polygon(Shapes.rect_with_hole)
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
      assert MapSet.new(graph.vertices) == MapSet.new(vertices)
      assert MapSet.new(graph.edges) == MapSet.new(edges)
    end

    test "corner hole" do
      graph = Graph.from_polygon(Shapes.rect_with_corner_hole)
      vertices = [
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
        },
        #I
        %Geo.Point{
          coordinates: {-84.11338806152344, 36.9795180188502},
          properties: %{
            ring: :intersection,
            covered: false
          }
        },
        #J
        %Geo.Point{
          coordinates: {-84.06463623046875, 36.93946500056987},
          properties: %{
            ring: :intersection,
            covered: false
          }
        }
      ]
      edges = [
        MapSet.new([Enum.at(vertices, 0), Enum.at(vertices, 1)]),
        MapSet.new([Enum.at(vertices, 3), Enum.at(vertices, 0)]),
        MapSet.new([Enum.at(vertices, 5), Enum.at(vertices, 6)]),
        MapSet.new([Enum.at(vertices, 6), Enum.at(vertices, 7)]),
        MapSet.new([Enum.at(vertices, 3), Enum.at(vertices, 8)]),
        MapSet.new([Enum.at(vertices, 2), Enum.at(vertices, 8)]),
        MapSet.new([Enum.at(vertices, 7), Enum.at(vertices, 8)]),
        MapSet.new([Enum.at(vertices, 4), Enum.at(vertices, 8)]),
        MapSet.new([Enum.at(vertices, 4), Enum.at(vertices, 9)]),
        MapSet.new([Enum.at(vertices, 2), Enum.at(vertices, 9)]),
        MapSet.new([Enum.at(vertices, 5), Enum.at(vertices, 9)]),
        MapSet.new([Enum.at(vertices, 1), Enum.at(vertices, 9)]),
      ]
      assert length(graph.vertices) == 10
      assert length(graph.edges) == 12
      assert MapSet.new(graph.vertices) == MapSet.new(vertices)
      assert MapSet.new(graph.edges) == MapSet.new(edges)
    end
  end

  describe "get subgraphs" do
    #get_incident_edges
    #
  end
end
