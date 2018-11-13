defmodule GeoPartition.GraphTest do
  use ExUnit.Case

  alias GeoPartition.{Graph, Shapes}

  describe "create graph from polygon" do

    test "no holes" do
      graph = Graph.from_polygon(Shapes.simple_rect)
      vertices = [
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
      assert graph == %Graph{
        vertices: vertices,
        edges: [
          MapSet.new([Enum.at(vertices, 0), Enum.at(vertices, 1)]),
          MapSet.new([Enum.at(vertices, 1), Enum.at(vertices, 2)]),
          MapSet.new([Enum.at(vertices, 2), Enum.at(vertices, 3)]),
          MapSet.new([Enum.at(vertices, 3), Enum.at(vertices, 0)]),
        ]
      }

    end

    @tag :skip
    test "simple hole" do
      graph = Graph.from_polygon(Shapes.rect_with_hole)
      assert graph == %Graph{
        vertices: [
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
          },
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
        ],
        edges: [[1], [2], [3], [0], [5], [6], [7], [4]]
      }
    end
  end

  @tag :skip
  test "corner hole" do
    graph = Graph.from_polygon(Shapes.rect_with_corner_hole)
    assert graph == %Graph{
      vertices: [
        %Geo.Point{
          coordinates: {-84.28848266601563, 36.80268739459133},
          properties: %{
            ring: :outer,
            covered: false,
            label: "001"
          }
        },
        %Geo.Point{
          coordinates: {-84.06463623046875, 36.80268739459133},
          properties: %{
            ring: :outer,
            covered: false,
            label: "002"
          }
        },
        %Geo.Point{
          coordinates: {-84.06463623046875, 36.9795180188502},
          properties: %{
            ring: :outer,
            covered: true,
            label: "003"
          }
        },
        %Geo.Point{
          coordinates: {-84.28848266601563, 36.9795180188502},
          properties: %{
            ring: :outer,
            covered: false,
            label: "004"
          }
        },
        %Geo.Point{
          coordinates: {-84.11338806152344, 36.93946500056987},
          properties: %{
            ring: :inner,
            covered: true,
            label: "005"
          }
        },
        %Geo.Point{
          coordinates: {-84.01107788085938, 36.93946500056987},
          properties: %{
            ring: :inner,
            covered: false,
            label: "006"
          }
        },
        %Geo.Point{
          coordinates: {-84.01107788085938, 37.008584404683155},
          properties: %{
            ring: :inner,
            covered: false,
            label: "007"
          }
        },
        %Geo.Point{
          coordinates: {-84.11338806152344, 37.008584404683155},
          properties: %{
            ring: :inner,
            covered: false,
            label: "008"
          }
        },
        %Geo.Point{
          coordinates: [{-84.11338806152344, 36.9795180188502}],
          properties: %{
            ring: :intersection,
            covered: false,
            label: "009"
          }
        },
        %Geo.Point{
          coordinates: [{-84.06463623046875, 36.9394650005698}],
          properties: %{
            ring: :intersection,
            covered: false,
            label: "010"
          }
        }
      ],
      edges: [[8], [2], [3], [0], [5], [6], [7], [4], [1, 2, 4, 7], [2, 3, ]]
    }
  end
  describe "get subgraphs" do
    #get_incident_edges
    #
  end
end
