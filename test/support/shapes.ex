defmodule GeoPartition.Shapes do

  def multi_polygon_basic do
    %Geo.MultiPolygon{
      coordinates: [
        [
          [
            {-83.85520935058594, 36.9105094697079},
            {-83.86070251464842, 36.90021457048955},
            {-83.82637023925781, 36.90048911916291},
            {-83.85520935058594, 36.9105094697079}
          ]
        ],
        [
          [
            {-83.9300537109375, 36.86643755175846},
            {-83.96713256835938, 36.83566824724438},
            {-83.88473510742186, 36.83566824724438},
            {-83.9300537109375, 36.86643755175846}
          ]
        ],
        [

          [
            {-84.28848266601563, 36.80268739459133},
            {-84.06463623046875, 36.80268739459133},
            {-84.06463623046875, 36.9795180188502},
            {-84.28848266601563, 36.9795180188502},
            {-84.28848266601563, 36.80268739459133}
          ]
        ]
      ],
      properties: %{},
      srid: nil
    }
  end

  def triangle_1 do
    %Geo.Polygon{
      coordinates: [
        [
          {-83.85520935058594, 36.9105094697079},
          {-83.86070251464842, 36.90021457048955},
          {-83.82637023925781, 36.90048911916291},
          {-83.85520935058594, 36.9105094697079}
        ]
      ],
      properties: %{},
      srid: nil
    }
  end

  def triangle_2 do
    %Geo.Polygon{
      coordinates: [
        [
          {-83.9300537109375, 36.86643755175846},
          {-83.96713256835938, 36.83566824724438},
          {-83.88473510742186, 36.83566824724438},
          {-83.9300537109375, 36.86643755175846}
        ]
      ],
      properties: %{},
      srid: nil
    }

  end

  def simple_rect do
    %Geo.Polygon{
      coordinates: [
        [
          {-84.28848266601563, 36.80268739459133},
          {-84.06463623046875, 36.80268739459133},
          {-84.06463623046875, 36.9795180188502},
          {-84.28848266601563, 36.9795180188502},
          {-84.28848266601563, 36.80268739459133}
        ]
      ],
      properties: %{},
      srid: nil
    }
  end

  def rect_with_corner_hole do
    %Geo.Polygon{
      coordinates: [
        [
          {-84.28848266601563, 36.80268739459133},
          {-84.06463623046875, 36.80268739459133},
          {-84.06463623046875, 36.9795180188502},
          {-84.28848266601563, 36.9795180188502},
          {-84.28848266601563, 36.80268739459133}
        ],
        [
          {-84.11338806152344, 36.93946500056987},
          {-84.01107788085938, 36.93946500056987},
          {-84.01107788085938, 37.008584404683155},
          {-84.11338806152344, 37.008584404683155},
          {-84.11338806152344, 36.93946500056987 }
        ]
      ],
      properties: %{},
      srid: nil
    }
  end

  def rect_with_hole do
    %Geo.Polygon{
      coordinates: [
        [
          {-84.28848266601563, 36.80268739459133},
          {-84.06463623046875, 36.80268739459133},
          {-84.06463623046875, 36.9795180188502},
          {-84.28848266601563, 36.9795180188502},
          {-84.28848266601563, 36.80268739459133}
        ],
        [
          { -84.20059204101562, 36.88566207736627 },
          { -84.18514251708984, 36.88566207736627 },
          { -84.18514251708984, 36.90186184771291 },
          { -84.20059204101562, 36.90186184771291 },
          { -84.20059204101562, 36.88566207736627 }
        ]
      ],
      properties: %{},
      srid: nil
    }
  end

  def line_inside_simple_rect do
    %Geo.LineString{
      coordinates: [
        {-84.22119140625, 36.89280138293983},
        {-84.15939331054688, 36.89280138293983}
      ],
      properties: %{},
      srid: nil
    }
  end

  def line_crosses_simple_rect do
    %Geo.LineString{
      coordinates: [
        {-84.22119140625, 36.89280138293983},
        {-83.15939331054688, 36.89280138293983}
      ],
      properties: %{},
      srid: nil
    }
  end

  def monster do
    %Geo.Polygon{
      properties: %{},
      srid: nil,
      coordinates: [
        [
          {-84.28848266601562, 36.80268739459133},
          {-84.06463623046875, 36.80268739459133},
          {-84.06463623046875, 36.9795180188502},
          {-84.28848266601562, 36.9795180188502},
          {-84.28848266601562, 36.80268739459133}
        ],
        [
          {-84.20059204101562, 36.88566207736627},
          {-84.20059204101562, 36.90186184771291},
          {-84.18514251708984, 36.90186184771291},
          {-84.18514251708984, 36.88566207736627},
          {-84.20059204101562, 36.88566207736627}
        ],
        [
          {-84.12918090820312, 36.8988418123063},
          {-84.19029235839844, 36.8713814633579},
          {-84.23080444335938, 36.89335053263666},
          {-84.20608520507812, 36.937269705848934},
          {-84.08317565917969, 36.90652894006401},
          {-84.21295166015625, 36.953732874654285},
          {-84.25140380859374, 36.891153910144624},
          {-84.19029235839844, 36.85764758564407},
          {-84.12918090820312, 36.8988418123063}
        ]
      ]
    }
  end

  def monster_multi do
    %Geo.MultiPolygon{
      properties: %{},
      srid: nil,
      coordinates: [
        [
          [
            {-84.28848266601562, 36.80268739459133},
            {-84.06463623046875, 36.80268739459133},
            {-84.06463623046875, 36.9795180188502},
            {-84.28848266601562, 36.9795180188502},
            {-84.28848266601562, 36.80268739459133}
          ],
          [
            {-84.20059204101562, 36.88566207736627},
            {-84.20059204101562, 36.90186184771291},
            {-84.18514251708984, 36.90186184771291},
            {-84.18514251708984, 36.88566207736627},
            {-84.20059204101562, 36.88566207736627}
          ],
          [
            {-84.12918090820312, 36.8988418123063},
            {-84.19029235839844, 36.8713814633579},
            {-84.23080444335938, 36.89335053263666},
            {-84.20608520507812, 36.937269705848934},
            {-84.08317565917969, 36.90652894006401},
            {-84.21295166015625, 36.953732874654285},
            {-84.25140380859374, 36.891153910144624},
            {-84.19029235839844, 36.85764758564407},
            {-84.12918090820312, 36.8988418123063}
          ]
        ]
      ]
    }
  end

  def monster_multi_out do
    %Geo.MultiPolygon{
      coordinates: [
        [
          [
            {-84.08317565917969, 36.90652894006401},
            {-84.21295166015625, 36.953732874654285},
            {-84.25140380859374, 36.891153910144624},
            {-84.19029235839844, 36.85764758564407},
            {-84.12918090820313, 36.8988418123063},
            {-84.19029235839844, 36.8713814633579},
            {-84.23080444335938, 36.89335053263666},
            {-84.20608520507813, 36.937269705848934},
            {-84.08317565917969, 36.90652894006401},
            {-84.08317565917969, 36.90652894006401},
            {-84.28848266601563, 36.80268739459133},
            {-84.06463623046875, 36.80268739459133},
            {-84.06463623046875, 36.9795180188502},
            {-84.28848266601563, 36.9795180188502},
            {-84.28848266601563, 36.80268739459133},
            {-84.08317565917969, 36.90652894006401},
            {-84.20059204101563, 36.90186184771291},
            {-84.18514251708984, 36.90186184771291},
            {-84.18514251708984, 36.88566207736627},
            {-84.20059204101563, 36.88566207736627},
            {-84.20059204101563, 36.90186184771291},
            {-84.20059204101563, 36.90186184771291},
            {-84.08317565917969, 36.90652894006401}
          ]
        ]
      ],
      properties: %{},
      srid: nil
    }
  end

  def ref_line do
    %Geo.LineString{
      properties: %{},
      srid: nil,
      coordinates: [
        {-89.37583923339844, 37.27459920466868},
        {-89.37583923339844, 37.24180850465067}
      ]
    }
  end

  def disjoint_line do
    %Geo.LineString{
      coordinates: [
        {-89.3631362915039, 37.262577605443454},
        {-89.34288024902344, 37.249187656673975}
      ],
      properties: %{},
      srid: nil
    }
  end

  def overlap_line do
    %Geo.LineString{
      coordinates: [
        {-89.37583923339844, 37.25383341872526},
        {-89.37583923339844, 37.224314295273366}
      ],
      properties: %{},
      srid: nil
    }
  end

  def incident_line do
    %Geo.LineString{
      coordinates: [
        {-89.37583923339844, 37.25820563896855},
        {-89.36107635498047, 37.25847889430797}
      ],
      properties: %{},
      srid: nil
    }
  end

  def intersect_line do
    %Geo.LineString{
      coordinates: [
        {-89.3906021118164, 37.26203112351243},
        {-89.36347961425781, 37.25410668992488}
      ],
      properties: %{},
      srid: nil
    }
  end

  def intersect_point do
    %Geo.Point{
      coordinates: [
        {-89.37583923339844, 37.25771782421794}
      ],
      properties: %{},
      srid: nil
    }
  end
end
