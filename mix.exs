defmodule Hpack.Mixfile do
  use Mix.Project

  def project do
    [app: :http2,
     version: "0.0.2",
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
      {:poison, "~> 1.5", only: [:dev, :test]},
      {:benchfella, "~> 0.3.0", only: [:dev, :test]},
      {:octet, "~> 0.0.2", only: [:test]},
      {:coverex, "~> 1.4.7", only: :test},
      {:ex_doc, only: [:dev]},
      {:earmark, ">= 0.0.0", only: [:dev]}
    ]
  end
end
