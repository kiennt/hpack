defmodule Hpack.Mixfile do
  use Mix.Project

  def project do
    [app: :hpack,
     version: "0.0.1",
     elixir: "~> 1.2",
     description: description,
     package: package,
     test_coverage: [tool: Coverex.Task],
     deps: deps]
  end

  defp description do
    "HPACK implementation for Elixir"
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Kien Nguyen Trung"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/kiennt/hpack",
      }
    ]
  end

  defp deps do
    [
      {:poison, "~> 1.5"},
      {:benchfella, "~> 0.3.0", only: [:dev, :test]},
      {:octet, "~> 0.0.2", only: [:test]},
      {:coverex, "~> 1.4.7", only: :test},
    ]
  end
end
