defmodule GeoPartition.Partition do

  alias GeoPartition.{Graph, Util}

  def partition(shape = %{__struct__: Geo.Polygon, coordinates: [ring]}) do
    ring
    |> add_split(0)
  end

  def add_split(ring, target) do
    dups = get_dups(ring)
    {opposite, _} = ring
                    |> length
                    |> Kernel./(2)
                    |> Float.to_string
                    |> Integer.parse
    opposite_vertex = Enum.at(ring, opposite)
    target_vertex = Enum.at(ring, target)
                    # exhausted source?
    if abs(target) >= opposite do
      add_split(GeoPartition.DeHole.rotate_poly_ring(ring), 0)
    else
      line = %Geo.LineString{coordinates: [hd(ring), Enum.at(ring, opposite + target)]}
      poly = %Geo.Polygon{ coordinates: [ring] }
      poly1 = %Geo.Polygon{coordinates: [Enum.slice(ring, 0..(opposite + target)) ++ [hd(ring)]]}
      poly2 = %Geo.Polygon{coordinates: [[hd(ring)] ++ Enum.slice(ring, (opposite + target)..-1) ++ [hd(ring)]]}
      if Util.contains(poly, line) && !Enum.member?(dups, target_vertex) && !Enum.member?(dups, opposite_vertex) do
        [
          %Geo.Polygon{coordinates: [Enum.slice(ring, 0..(opposite + target)) ++ [hd(ring)]]},
          %Geo.Polygon{coordinates: [[hd(ring)] ++ Enum.slice(ring, (opposite + target)..-1) ++ [hd(ring)]]}
        ]
      else
        add_split(ring, inc(target))
      end
    end
  end

  defp split_check(polys = [poly1, poly2, ref]) do
    [p1, p2, r] = Enum.map(polys, &Geometry.area(&1))
    is_close(p1 + p2, r)
  end

  defp is_close(x, y) do
    abs(x - y) < 0.0000001
  end

  def inc(x) do
    if x <= 0 do
      (x * -1) + 1
    else
      x * -1
    end
  end

  def get_dups(list) do
    Enum.map(list, fn(x) ->
      Enum.slice(list, Enum.find_index(list, &(&1==x)) + 1..-1)
      |> Enum.find(&(&1 == x))
    end)
    |> Enum.reject(&is_nil(&1))
  end

  def dehole({v, e}) do
    inters = Enum.filter(v, &(&1.properties.ring == :intersection))
    new_edges = for x <- inters, y <- inters do
      if x == y do
        nil
      else
        [x, y]
      end
    end
    |> Enum.reject(&is_nil(&1))
    |> Enum.uniq_by(&MapSet.new(&1))
    |> Enum.map(&get_best_path({v, e}, &1))
    |> List.flatten
    |> Enum.uniq
    |> Enum.reject(fn(x) ->
      Enum.to_list(x)
      |> Enum.map(&(&1.properties.ring == :intersection))
      |> IO.inspect
      |> List.foldl(true, &(&1 && &2))
    end)
    |> IO.inspect
    Graph.delete_vertices_by({v, e ++ new_edges}, &uncovered_inner(&1))
    |> Graph.delete_vertices_by(&covered_outer(&1))
    {v, new_edges}
  end

  defp covered_inner(vertex) do
    vertex.properties.ring == :inner && vertex.properties.covered
  end

  defp uncovered_inner(vertex) do
    vertex.properties.ring == :inner && vertex.properties.covered == false
  end

  defp covered_outer(vertex) do
    vertex.properties.ring == :outer && vertex.properties.covered == true
  end

  defp covered_inner_edge(edge) do
    edge
    |> Enum.map(&covered_inner(&1))
    |> List.foldl(false, &(&1 || &2))
    |> IO.inspect
  end

  defp get_best_path(graph, [start, stop]) do
    case Graph.find_path_by(graph, stop, [start], &(covered_inner(&1)), &(covered_inner_edge(&1))) do
      nil -> Graph.find_path_by(graph, stop, [start], &(&1.properties.ring != :outer), &(&1))
      path -> path
    end
  end

end
