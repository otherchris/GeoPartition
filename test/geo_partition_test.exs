defmodule GeoPartitionTest do
  use ExUnit.Case
  doctest GeoPartition

  alias GeoPartition.Shapes

  describe "partition" do
    test "Polygon input" do
      shape = Shapes.top_level_test
      assert GeoPartition.partition(shape, 100, :multipolygon) == %Geo.MultiPolygon{
        coordinates: [
          [
            [
              {-92.67242431640625, 39.157752153690964},
              {-93.08441162109374, 38.78406349514289},
              {-93.09206631367219, 38.84038993622543},
              {-92.82073974609375, 39.06184913429154},
              {-92.67242431640625, 39.157752153690964}
            ]
          ],
          [
            [
              {-92.82073974609375, 39.06184913429154},
              {-93.07891845703125, 38.90813299596705},
              {-93.10319008974786, 38.92224334984317},
              {-93.1146240234375, 39.00637903337455},
              {-92.67242431640625, 39.157752153690964},
              {-92.82073974609375, 39.06184913429154}
            ]
          ],
          [
            [
              {-93.09814453125, 38.83542884007305},
              {-93.09206631367219, 38.84038993622543},
              {-93.08441162109374, 38.78406349514289},
              {-93.09814453125, 38.83542884007305}
            ],
            [
              {-93.31787109374999, 39.49344386279537},
              {-93.34465026855469, 39.46641460192054},
              {-93.31443786621094, 39.4669446883827},
              {-93.31787109374999, 39.49344386279537}
            ]
          ],
          [
            [
              {-93.08441162109374, 38.78406349514289},
              {-93.09814453125, 38.83542884007305},
              {-93.603515625, 39.16414104768742},
              {-93.08441162109374, 38.78406349514289}
            ]
          ],
          [
            [
              {-93.603515625, 39.16414104768742},
              {-93.68865966796875, 39.142842478062505},
              {-93.08441162109374, 38.78406349514289},
              {-93.603515625, 39.16414104768742}
            ]
          ],
          [
            [
              {-93.37005615234375, 39.42346418978382},
              {-93.526611328125, 39.16839998800286},
              {-93.46343994140625, 39.18117526158749},
              {-93.37005615234375, 39.42346418978382}
            ],
            [
              {-93.31787109374999, 39.49344386279537},
              {-93.34465026855469, 39.46641460192054},
              {-93.31443786621094, 39.4669446883827},
              {-93.31787109374999, 39.49344386279537}
            ]
          ],
          [
            [
              {-93.37005615234375, 39.42346418978382},
              {-93.603515625, 39.16414104768742},
              {-93.68865966796875, 39.142842478062505},
              {-93.1915283203125, 39.65011210186371},
              {-93.37005615234375, 39.42346418978382}
            ],
            [
              {-93.31787109374999, 39.49344386279537},
              {-93.34465026855469, 39.46641460192054},
              {-93.31443786621094, 39.4669446883827},
              {-93.31787109374999, 39.49344386279537}
            ]
          ],
          [
            [
              {-93.1915283203125, 39.65011210186371},
              {-93.46343994140625, 39.18117526158749},
              {-93.37005615234375, 39.42346418978382},
              {-93.1915283203125, 39.65011210186371}
            ],
            [
              {-93.31787109374999, 39.49344386279537},
              {-93.34465026855469, 39.46641460192054},
              {-93.31443786621094, 39.4669446883827},
              {-93.31787109374999, 39.49344386279537}
            ]
          ],
          [
            [
              {-93.526611328125, 39.16839998800286},
              {-93.10319008974786, 38.92224334984317},
              {-93.1146240234375, 39.00637903337455},
              {-93.46343994140625, 39.18117526158749},
              {-93.526611328125, 39.16839998800286}
            ],
            [
              {-93.31787109374999, 39.49344386279537},
              {-93.34465026855469, 39.46641460192054},
              {-93.31443786621094, 39.4669446883827},
              {-93.31787109374999, 39.49344386279537}
            ]
          ]
        ],
        properties: %{},
        srid: nil
      }


      assert GeoPartition.partition(shape, 100, :multipolygon_json) == ~S({"type":"MultiPolygon","coordinates":[[[[-92.67242431640625,39.157752153690964],[-93.08441162109374,38.78406349514289],[-93.09206631367219,38.84038993622543],[-92.82073974609375,39.06184913429154],[-92.67242431640625,39.157752153690964]]],[[[-92.82073974609375,39.06184913429154],[-93.07891845703125,38.90813299596705],[-93.10319008974786,38.92224334984317],[-93.1146240234375,39.00637903337455],[-92.67242431640625,39.157752153690964],[-92.82073974609375,39.06184913429154]]],[[[-93.09814453125,38.83542884007305],[-93.09206631367219,38.84038993622543],[-93.08441162109374,38.78406349514289],[-93.09814453125,38.83542884007305]],[[-93.31787109374999,39.49344386279537],[-93.34465026855469,39.46641460192054],[-93.31443786621094,39.4669446883827],[-93.31787109374999,39.49344386279537]]],[[[-93.08441162109374,38.78406349514289],[-93.09814453125,38.83542884007305],[-93.603515625,39.16414104768742],[-93.08441162109374,38.78406349514289]]],[[[-93.603515625,39.16414104768742],[-93.68865966796875,39.142842478062505],[-93.08441162109374,38.78406349514289],[-93.603515625,39.16414104768742]]],[[[-93.37005615234375,39.42346418978382],[-93.526611328125,39.16839998800286],[-93.46343994140625,39.18117526158749],[-93.37005615234375,39.42346418978382]],[[-93.31787109374999,39.49344386279537],[-93.34465026855469,39.46641460192054],[-93.31443786621094,39.4669446883827],[-93.31787109374999,39.49344386279537]]],[[[-93.37005615234375,39.42346418978382],[-93.603515625,39.16414104768742],[-93.68865966796875,39.142842478062505],[-93.1915283203125,39.65011210186371],[-93.37005615234375,39.42346418978382]],[[-93.31787109374999,39.49344386279537],[-93.34465026855469,39.46641460192054],[-93.31443786621094,39.4669446883827],[-93.31787109374999,39.49344386279537]]],[[[-93.1915283203125,39.65011210186371],[-93.46343994140625,39.18117526158749],[-93.37005615234375,39.42346418978382],[-93.1915283203125,39.65011210186371]],[[-93.31787109374999,39.49344386279537],[-93.34465026855469,39.46641460192054],[-93.31443786621094,39.4669446883827],[-93.31787109374999,39.49344386279537]]],[[[-93.526611328125,39.16839998800286],[-93.10319008974786,38.92224334984317],[-93.1146240234375,39.00637903337455],[-93.46343994140625,39.18117526158749],[-93.526611328125,39.16839998800286]],[[-93.31787109374999,39.49344386279537],[-93.34465026855469,39.46641460192054],[-93.31443786621094,39.4669446883827],[-93.31787109374999,39.49344386279537]]]]})

      assert GeoPartition.partition(shape, 100, :feature_collection) == ~S({"type":"FeatureCollection","features":[{"type":"Feature","properties":{},"geometry":{"type":"Polygon","properties":{"area":61.17714538507219},"coordinates":[[[-92.67242431640625,39.157752153690964],[-93.08441162109374,38.78406349514289],[-93.09206631367219,38.84038993622543],[-92.82073974609375,39.06184913429154],[-92.67242431640625,39.157752153690964]]]}},{"type":"Feature","properties":{},"geometry":{"type":"Polygon","properties":{"area":97.92029807396524},"coordinates":[[[-92.82073974609375,39.06184913429154],[-93.07891845703125,38.90813299596705],[-93.10319008974786,38.92224334984317],[-93.1146240234375,39.00637903337455],[-92.67242431640625,39.157752153690964],[-92.82073974609375,39.06184913429154]]]}},{"type":"Feature","properties":{},"geometry":{"type":"Polygon","properties":{"area":0.709012692075248},"coordinates":[[[-93.09814453125,38.83542884007305],[-93.09206631367219,38.84038993622543],[-93.08441162109374,38.78406349514289],[-93.09814453125,38.83542884007305]],[[-93.31787109374999,39.49344386279537],[-93.34465026855469,39.46641460192054],[-93.31443786621094,39.4669446883827],[-93.31787109374999,39.49344386279537]]]}},{"type":"Feature","properties":{},"geometry":{"type":"Polygon","properties":{"area":39.884647228923065},"coordinates":[[[-93.08441162109374,38.78406349514289],[-93.09814453125,38.83542884007305],[-93.603515625,39.16414104768742],[-93.08441162109374,38.78406349514289]]]}},{"type":"Feature","properties":{},"geometry":{"type":"Polygon","properties":{"area":80.75270669293299},"coordinates":[[[-93.603515625,39.16414104768742],[-93.68865966796875,39.142842478062505],[-93.08441162109374,38.78406349514289],[-93.603515625,39.16414104768742]]]}},{"type":"Feature","properties":{},"geometry":{"type":"Polygon","properties":{"area":26.128714904063237},"coordinates":[[[-93.37005615234375,39.42346418978382],[-93.526611328125,39.16839998800286],[-93.46343994140625,39.18117526158749],[-93.37005615234375,39.42346418978382]],[[-93.31787109374999,39.49344386279537],[-93.34465026855469,39.46641460192054],[-93.31443786621094,39.4669446883827],[-93.31787109374999,39.49344386279537]]]}},{"type":"Feature","properties":{},"geometry":{"type":"Polygon","properties":{"area":71.95967544687367},"coordinates":[[[-93.37005615234375,39.42346418978382],[-93.603515625,39.16414104768742],[-93.68865966796875,39.142842478062505],[-93.1915283203125,39.65011210186371],[-93.37005615234375,39.42346418978382]],[[-93.31787109374999,39.49344386279537],[-93.34465026855469,39.46641460192054],[-93.31443786621094,39.4669446883827],[-93.31787109374999,39.49344386279537]]]}},{"type":"Feature","properties":{},"geometry":{"type":"Polygon","properties":{"area":39.89304521717056},"coordinates":[[[-93.1915283203125,39.65011210186371],[-93.46343994140625,39.18117526158749],[-93.37005615234375,39.42346418978382],[-93.1915283203125,39.65011210186371]],[[-93.31787109374999,39.49344386279537],[-93.34465026855469,39.46641460192054],[-93.31443786621094,39.4669446883827],[-93.31787109374999,39.49344386279537]]]}},{"type":"Feature","properties":{},"geometry":{"type":"Polygon","properties":{"area":89.75121737835246},"coordinates":[[[-93.526611328125,39.16839998800286],[-93.10319008974786,38.92224334984317],[-93.1146240234375,39.00637903337455],[-93.46343994140625,39.18117526158749],[-93.526611328125,39.16839998800286]],[[-93.31787109374999,39.49344386279537],[-93.34465026855469,39.46641460192054],[-93.31443786621094,39.4669446883827],[-93.31787109374999,39.49344386279537]]]}}]})


      assert GeoPartition.partition(shape, 100, :feature_collection_multipolygon) == ~S({"type":"FeatureCollection","features":[{"type":"Feature","properties":{},"geometry":{"type":"MultiPolygon","coordinates":[[[[-92.67242431640625,39.157752153690964],[-93.08441162109374,38.78406349514289],[-93.09206631367219,38.84038993622543],[-92.82073974609375,39.06184913429154],[-92.67242431640625,39.157752153690964]]]]}},{"type":"Feature","properties":{},"geometry":{"type":"MultiPolygon","coordinates":[[[[-92.82073974609375,39.06184913429154],[-93.07891845703125,38.90813299596705],[-93.10319008974786,38.92224334984317],[-93.1146240234375,39.00637903337455],[-92.67242431640625,39.157752153690964],[-92.82073974609375,39.06184913429154]]]]}},{"type":"Feature","properties":{},"geometry":{"type":"MultiPolygon","coordinates":[[[[-93.09814453125,38.83542884007305],[-93.09206631367219,38.84038993622543],[-93.08441162109374,38.78406349514289],[-93.09814453125,38.83542884007305]],[[-93.31787109374999,39.49344386279537],[-93.34465026855469,39.46641460192054],[-93.31443786621094,39.4669446883827],[-93.31787109374999,39.49344386279537]]]]}},{"type":"Feature","properties":{},"geometry":{"type":"MultiPolygon","coordinates":[[[[-93.08441162109374,38.78406349514289],[-93.09814453125,38.83542884007305],[-93.603515625,39.16414104768742],[-93.08441162109374,38.78406349514289]]]]}},{"type":"Feature","properties":{},"geometry":{"type":"MultiPolygon","coordinates":[[[[-93.603515625,39.16414104768742],[-93.68865966796875,39.142842478062505],[-93.08441162109374,38.78406349514289],[-93.603515625,39.16414104768742]]]]}},{"type":"Feature","properties":{},"geometry":{"type":"MultiPolygon","coordinates":[[[[-93.37005615234375,39.42346418978382],[-93.526611328125,39.16839998800286],[-93.46343994140625,39.18117526158749],[-93.37005615234375,39.42346418978382]],[[-93.31787109374999,39.49344386279537],[-93.34465026855469,39.46641460192054],[-93.31443786621094,39.4669446883827],[-93.31787109374999,39.49344386279537]]]]}},{"type":"Feature","properties":{},"geometry":{"type":"MultiPolygon","coordinates":[[[[-93.37005615234375,39.42346418978382],[-93.603515625,39.16414104768742],[-93.68865966796875,39.142842478062505],[-93.1915283203125,39.65011210186371],[-93.37005615234375,39.42346418978382]],[[-93.31787109374999,39.49344386279537],[-93.34465026855469,39.46641460192054],[-93.31443786621094,39.4669446883827],[-93.31787109374999,39.49344386279537]]]]}},{"type":"Feature","properties":{},"geometry":{"type":"MultiPolygon","coordinates":[[[[-93.1915283203125,39.65011210186371],[-93.46343994140625,39.18117526158749],[-93.37005615234375,39.42346418978382],[-93.1915283203125,39.65011210186371]],[[-93.31787109374999,39.49344386279537],[-93.34465026855469,39.46641460192054],[-93.31443786621094,39.4669446883827],[-93.31787109374999,39.49344386279537]]]]}},{"type":"Feature","properties":{},"geometry":{"type":"MultiPolygon","coordinates":[[[[-93.526611328125,39.16839998800286],[-93.10319008974786,38.92224334984317],[-93.1146240234375,39.00637903337455],[-93.46343994140625,39.18117526158749],[-93.526611328125,39.16839998800286]],[[-93.31787109374999,39.49344386279537],[-93.34465026855469,39.46641460192054],[-93.31443786621094,39.4669446883827],[-93.31787109374999,39.49344386279537]]]]}}]})

      assert GeoPartition.partition(shape, 100, :list) == [
  %Geo.Polygon{
    coordinates: [
      [
        {-92.67242431640625, 39.157752153690964},
        {-93.08441162109374, 38.78406349514289},
        {-93.09206631367219, 38.84038993622543},
        {-92.82073974609375, 39.06184913429154},
        {-92.67242431640625, 39.157752153690964}
      ]
    ],
    properties: %{area: 61.17714538507219},
    srid: nil
  },
  %Geo.Polygon{
    coordinates: [
      [
        {-92.82073974609375, 39.06184913429154},
        {-93.07891845703125, 38.90813299596705},
        {-93.10319008974786, 38.92224334984317},
        {-93.1146240234375, 39.00637903337455},
        {-92.67242431640625, 39.157752153690964},
        {-92.82073974609375, 39.06184913429154}
      ]
    ],
    properties: %{area: 97.92029807396524},
    srid: nil
  },
  %Geo.Polygon{
    coordinates: [
      [
        {-93.09814453125, 38.83542884007305},
        {-93.09206631367219, 38.84038993622543},
        {-93.08441162109374, 38.78406349514289},
        {-93.09814453125, 38.83542884007305}
      ],
      [
        {-93.31787109374999, 39.49344386279537},
        {-93.34465026855469, 39.46641460192054},
        {-93.31443786621094, 39.4669446883827},
        {-93.31787109374999, 39.49344386279537}
      ]
    ],
    properties: %{area: 0.709012692075248},
    srid: nil
  },
  %Geo.Polygon{
    coordinates: [
      [
        {-93.08441162109374, 38.78406349514289},
        {-93.09814453125, 38.83542884007305},
        {-93.603515625, 39.16414104768742},
        {-93.08441162109374, 38.78406349514289}
      ]
    ],
    properties: %{area: 39.884647228923065},
    srid: nil
  },
  %Geo.Polygon{
    coordinates: [
      [
        {-93.603515625, 39.16414104768742},
        {-93.68865966796875, 39.142842478062505},
        {-93.08441162109374, 38.78406349514289},
        {-93.603515625, 39.16414104768742}
      ]
    ],
    properties: %{area: 80.75270669293299},
    srid: nil
  },
  %Geo.Polygon{
    coordinates: [
      [
        {-93.37005615234375, 39.42346418978382},
        {-93.526611328125, 39.16839998800286},
        {-93.46343994140625, 39.18117526158749},
        {-93.37005615234375, 39.42346418978382}
      ],
      [
        {-93.31787109374999, 39.49344386279537},
        {-93.34465026855469, 39.46641460192054},
        {-93.31443786621094, 39.4669446883827},
        {-93.31787109374999, 39.49344386279537}
      ]
    ],
    properties: %{area: 26.128714904063237},
    srid: nil
  },
  %Geo.Polygon{
    coordinates: [
      [
        {-93.37005615234375, 39.42346418978382},
        {-93.603515625, 39.16414104768742},
        {-93.68865966796875, 39.142842478062505},
        {-93.1915283203125, 39.65011210186371},
        {-93.37005615234375, 39.42346418978382}
      ],
      [
        {-93.31787109374999, 39.49344386279537},
        {-93.34465026855469, 39.46641460192054},
        {-93.31443786621094, 39.4669446883827},
        {-93.31787109374999, 39.49344386279537}
      ]
    ],
    properties: %{area: 71.95967544687367},
    srid: nil
  },
  %Geo.Polygon{
    coordinates: [
      [
        {-93.1915283203125, 39.65011210186371},
        {-93.46343994140625, 39.18117526158749},
        {-93.37005615234375, 39.42346418978382},
        {-93.1915283203125, 39.65011210186371}
      ],
      [
        {-93.31787109374999, 39.49344386279537},
        {-93.34465026855469, 39.46641460192054},
        {-93.31443786621094, 39.4669446883827},
        {-93.31787109374999, 39.49344386279537}
      ]
    ],
    properties: %{area: 39.89304521717056},
    srid: nil
  },
  %Geo.Polygon{
    coordinates: [
      [
        {-93.526611328125, 39.16839998800286},
        {-93.10319008974786, 38.92224334984317},
        {-93.1146240234375, 39.00637903337455},
        {-93.46343994140625, 39.18117526158749},
        {-93.526611328125, 39.16839998800286}
      ],
      [
        {-93.31787109374999, 39.49344386279537},
        {-93.34465026855469, 39.46641460192054},
        {-93.31443786621094, 39.4669446883827},
        {-93.31787109374999, 39.49344386279537}
      ]
    ],
    properties: %{area: 89.75121737835246},
    srid: nil
  }
]

    end

    test "Multipolygon input" do
      shape = Shapes.top_level_test
      shape_multi = %Geo.MultiPolygon{
        coordinates: [shape.coordinates]
      }
      assert GeoPartition.partition(shape_multi, 100, :multipolygon) == %Geo.MultiPolygon{
        coordinates: [
          [
            [
              {-92.67242431640625, 39.157752153690964},
              {-93.08441162109374, 38.78406349514289},
              {-93.09206631367219, 38.84038993622543},
              {-92.82073974609375, 39.06184913429154},
              {-92.67242431640625, 39.157752153690964}
            ]
          ],
          [
            [
              {-92.82073974609375, 39.06184913429154},
              {-93.07891845703125, 38.90813299596705},
              {-93.10319008974786, 38.92224334984317},
              {-93.1146240234375, 39.00637903337455},
              {-92.67242431640625, 39.157752153690964},
              {-92.82073974609375, 39.06184913429154}
            ]
          ],
          [
            [
              {-93.09814453125, 38.83542884007305},
              {-93.09206631367219, 38.84038993622543},
              {-93.08441162109374, 38.78406349514289},
              {-93.09814453125, 38.83542884007305}
            ],
            [
              {-93.31787109374999, 39.49344386279537},
              {-93.34465026855469, 39.46641460192054},
              {-93.31443786621094, 39.4669446883827},
              {-93.31787109374999, 39.49344386279537}
            ]
          ],
          [
            [
              {-93.08441162109374, 38.78406349514289},
              {-93.09814453125, 38.83542884007305},
              {-93.603515625, 39.16414104768742},
              {-93.08441162109374, 38.78406349514289}
            ]
          ],
          [
            [
              {-93.603515625, 39.16414104768742},
              {-93.68865966796875, 39.142842478062505},
              {-93.08441162109374, 38.78406349514289},
              {-93.603515625, 39.16414104768742}
            ]
          ],
          [
            [
              {-93.37005615234375, 39.42346418978382},
              {-93.526611328125, 39.16839998800286},
              {-93.46343994140625, 39.18117526158749},
              {-93.37005615234375, 39.42346418978382}
            ],
            [
              {-93.31787109374999, 39.49344386279537},
              {-93.34465026855469, 39.46641460192054},
              {-93.31443786621094, 39.4669446883827},
              {-93.31787109374999, 39.49344386279537}
            ]
          ],
          [
            [
              {-93.37005615234375, 39.42346418978382},
              {-93.603515625, 39.16414104768742},
              {-93.68865966796875, 39.142842478062505},
              {-93.1915283203125, 39.65011210186371},
              {-93.37005615234375, 39.42346418978382}
            ],
            [
              {-93.31787109374999, 39.49344386279537},
              {-93.34465026855469, 39.46641460192054},
              {-93.31443786621094, 39.4669446883827},
              {-93.31787109374999, 39.49344386279537}
            ]
          ],
          [
            [
              {-93.1915283203125, 39.65011210186371},
              {-93.46343994140625, 39.18117526158749},
              {-93.37005615234375, 39.42346418978382},
              {-93.1915283203125, 39.65011210186371}
            ],
            [
              {-93.31787109374999, 39.49344386279537},
              {-93.34465026855469, 39.46641460192054},
              {-93.31443786621094, 39.4669446883827},
              {-93.31787109374999, 39.49344386279537}
            ]
          ],
          [
            [
              {-93.526611328125, 39.16839998800286},
              {-93.10319008974786, 38.92224334984317},
              {-93.1146240234375, 39.00637903337455},
              {-93.46343994140625, 39.18117526158749},
              {-93.526611328125, 39.16839998800286}
            ],
            [
              {-93.31787109374999, 39.49344386279537},
              {-93.34465026855469, 39.46641460192054},
              {-93.31443786621094, 39.4669446883827},
              {-93.31787109374999, 39.49344386279537}
            ]
          ]
        ],
        properties: %{},
        srid: nil
      }
    end

    test "JSON input" do
      shape = Shapes.top_level_test |> Geo.JSON.encode! |> Poison.encode!
      assert GeoPartition.partition(shape, 100, :multipolygon) == %Geo.MultiPolygon{
        coordinates: [
          [
            [
              {-92.67242431640625, 39.157752153690964},
              {-93.08441162109374, 38.78406349514289},
              {-93.09206631367219, 38.84038993622543},
              {-92.82073974609375, 39.06184913429154},
              {-92.67242431640625, 39.157752153690964}
            ]
          ],
          [
            [
              {-92.82073974609375, 39.06184913429154},
              {-93.07891845703125, 38.90813299596705},
              {-93.10319008974786, 38.92224334984317},
              {-93.1146240234375, 39.00637903337455},
              {-92.67242431640625, 39.157752153690964},
              {-92.82073974609375, 39.06184913429154}
            ]
          ],
          [
            [
              {-93.09814453125, 38.83542884007305},
              {-93.09206631367219, 38.84038993622543},
              {-93.08441162109374, 38.78406349514289},
              {-93.09814453125, 38.83542884007305}
            ],
            [
              {-93.31787109374999, 39.49344386279537},
              {-93.34465026855469, 39.46641460192054},
              {-93.31443786621094, 39.4669446883827},
              {-93.31787109374999, 39.49344386279537}
            ]
          ],
          [
            [
              {-93.08441162109374, 38.78406349514289},
              {-93.09814453125, 38.83542884007305},
              {-93.603515625, 39.16414104768742},
              {-93.08441162109374, 38.78406349514289}
            ]
          ],
          [
            [
              {-93.603515625, 39.16414104768742},
              {-93.68865966796875, 39.142842478062505},
              {-93.08441162109374, 38.78406349514289},
              {-93.603515625, 39.16414104768742}
            ]
          ],
          [
            [
              {-93.37005615234375, 39.42346418978382},
              {-93.526611328125, 39.16839998800286},
              {-93.46343994140625, 39.18117526158749},
              {-93.37005615234375, 39.42346418978382}
            ],
            [
              {-93.31787109374999, 39.49344386279537},
              {-93.34465026855469, 39.46641460192054},
              {-93.31443786621094, 39.4669446883827},
              {-93.31787109374999, 39.49344386279537}
            ]
          ],
          [
            [
              {-93.37005615234375, 39.42346418978382},
              {-93.603515625, 39.16414104768742},
              {-93.68865966796875, 39.142842478062505},
              {-93.1915283203125, 39.65011210186371},
              {-93.37005615234375, 39.42346418978382}
            ],
            [
              {-93.31787109374999, 39.49344386279537},
              {-93.34465026855469, 39.46641460192054},
              {-93.31443786621094, 39.4669446883827},
              {-93.31787109374999, 39.49344386279537}
            ]
          ],
          [
            [
              {-93.1915283203125, 39.65011210186371},
              {-93.46343994140625, 39.18117526158749},
              {-93.37005615234375, 39.42346418978382},
              {-93.1915283203125, 39.65011210186371}
            ],
            [
              {-93.31787109374999, 39.49344386279537},
              {-93.34465026855469, 39.46641460192054},
              {-93.31443786621094, 39.4669446883827},
              {-93.31787109374999, 39.49344386279537}
            ]
          ],
          [
            [
              {-93.526611328125, 39.16839998800286},
              {-93.10319008974786, 38.92224334984317},
              {-93.1146240234375, 39.00637903337455},
              {-93.46343994140625, 39.18117526158749},
              {-93.526611328125, 39.16839998800286}
            ],
            [
              {-93.31787109374999, 39.49344386279537},
              {-93.34465026855469, 39.46641460192054},
              {-93.31443786621094, 39.4669446883827},
              {-93.31787109374999, 39.49344386279537}
            ]
          ]
        ],
        properties: %{},
        srid: nil
      }
    end
  end
end
