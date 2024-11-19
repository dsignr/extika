defmodule ExTika.Mixfile do
  use Mix.Project

  def project do
    [
      app: :extika,
      version: "0.0.6",
      elixir: "~> 1.1",
      compilers: [:tika | Mix.compilers()],
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger, :httpoison]]
  end

  defp deps do
    [
      {:httpoison, "~> 2.0"},
      {:poison, "~> 3.0"}
    ]
  end
end

defmodule Mix.Tasks.Compile.Tika do
  @shortdoc "Downloads the Apache Tika JAR file(s)"

  def run(_) do
    version = File.read!(".tika-version") |> String.trim()
    dest = Path.join("priv", "tika-#{version}.jar")

    Extika.Compiler.fetch_tika(version, dest)

    Mix.shell().info("Done!")
  end
end
