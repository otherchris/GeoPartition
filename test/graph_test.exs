defmodule GeoPartition.GraphTest do
  use ExUnit.Case
  doctest GeoPartition.Graph

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

  describe "dehole" do
    test "dehole" do
      #%{vertices: v, edges: e} = Graph.from_polygon(Shapes.rect_with_corner_hole)
      #IO.inspect Graph.dehole({v, e})
    end

    test "to po9lygon" do
      {v, e} = Graph.from_polygon(Shapes.intersecting_diamonds)
      deholed = Graph.dehole({v, e})
      Graph.to_polygon(deholed)
      |> Geo.JSON.encode!
      |> Poison.encode!
      |> IO.puts
    end

    test "find path" do
      vs = [1, 2, 3, 4, 5, 6, 7]
      set = [
        MapSet.new([1, 2]),
        MapSet.new([2, 3]),
        MapSet.new([3, 4]),
        MapSet.new([4, 6]),
        MapSet.new([6, 7]),
        MapSet.new([3, 5])
      ]
      #IO.inspect {"delete evens", Graph.delete_vertices_by({vs, set}, &(rem(&1, 2) == 0))}
        #IO.inspect Graph.find_path_by({vs, set}, 5, &(&1 || true), [1])
    end
  end

end
