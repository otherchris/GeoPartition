defmodule GeoPartition.GraphTest do
  use ExUnit.Case

  alias Geopartition.{Graph, Shapes}

  describe "create graph from polygon" do

    test "no holes" do
      assert Graph.from_polygon(Shapes.simple_rect) == %Graph{
        vertices: [
          %Geo.Point{
            coordinates: [
              {-84.28848266601563, 36.80268739459133},
            ],
            properties: %{
              ring: :outer,
              covered: false
            }
          },
          %Geo.Point{
            coordinates: [
              {-84.06463623046875, 36.80268739459133},
            ],
            properties: %{
              ring: :outer,
              covered: false
            }
          },
          %Geo.Point{
            coordinates: [
              {-84.06463623046875, 36.9795180188502},
            ],
            properties: %{
              ring: :outer,
              covered: false
            }
          },
          %Geo.Point{
            coordinates: [
              {-84.28848266601563, 36.9795180188502},
            ],
            properties: %{
              ring: :outer,
              covered: false
            }
          }
        ],
        edges: [{0, 1}, {1, 2}, {2, 3}, {3, 0}]
      }
    end
  end

  describe "get subgraphs" do
    #get_incident_edges
    #
  end
end
