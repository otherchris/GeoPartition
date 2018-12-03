defmodule GeoPartition.MixProject do
  use Mix.Project

  def project do
    [
      app: :geo_partition,
      version: "0.1.1",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: ["lib", "test/support"],
      description: "Decompose polygons into polygons smaller than a given area",
      source_url: "https://github.com/otherchris/GeoPartition",
      package: [
        name: "geo_partition",
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/otherchris/GeoPartition"}
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poison, "~> 3.1"},
      {:mix_test_watch, "~> 0.8", only: :dev, runtime: false},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:geo, "~> 3.0", override: true},
      {:credo, "~> 0.10.0", only: [:dev, :test], runtime: false},
      {:topo, "~> 0.1.2"},
      {:ex_simple_graph, "~> 0.1.3"}
    ]
  end
end
