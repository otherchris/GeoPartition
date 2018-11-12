defmodule GeoPartition.GraphTest do
  use ExUnit.Case

  alias GeoPartition.{Graph, Shapes}

  describe "create graph from polygon" do

    test "no holes" do
      graph = Graph.from_polygon(Shapes.simple_rect)
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
          }
        ],
        edges: [[1], [2], [3], [0]]
      }
    end

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

  describe "get subgraphs" do
    #get_incident_edges
    #
  end
end
