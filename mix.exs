defmodule ExTika.Mixfile do
  use Mix.Project

  def project do
    [
      app: :extika,
      description: "Wrapper around Apache Tika",
      version: "0.0.4",
      package: package(),
      elixir: "~> 1.1",
      compilers: [:tika | Mix.compilers],
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [applications: [:logger, :httpoison]]
  end

  defp aliases do
    [
      clean: ["clean", "clean.tika"]
    ]
  end

  defp package do
    [
      name: :extika,
      files: ["lib", "mix.exs", "README*", "LICENSE*", ".tika-version"],
      maintainers: ["Andrew Dunham", "Neya"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/andrew-d/extika",
        "Docs" => "https://andrew-d.github.io/extika/"
      }
    ]
  end

  defp deps do
    [
      {:poison, "~> 3.0"},
      {:httpoison, "~> 2.0"},

      # Development / testing dependencies
      {:dialyxir, "~> 0.5", only: :test},
      {:ex_doc, "~> 0.19", only: :dev}
    ]
  end
end

defmodule Mix.Tasks.Compile.Tika do
  @shortdoc "Downloads the Apache Tika JAR file(s)"

  def run(_) do
    version = File.read!(".tika-version")
    |> String.trim()

    fetch_one(
      "tika-#{version}.jar",
      "https://archive.apache.org/dist/tika/tika-app-#{version}.jar",
      "4f377b42e122f92c3f1f3b4702029cf0642c7d6f3ce872a0dfb1472eac65be44"
    )

    Mix.shell().info("Done!")
  end

  # Fetches a single file and verifies the checksum.
  defp fetch_one(fname, url, sum) do
    dest = Path.join("priv", fname)

    # If the file doesn't exist, download it.
    unless File.exists?(dest) do
      Mix.shell().info("Fetching: #{fname}")
      fetch_url(url, dest)
    end

    Mix.shell().info("Verifying checksum of: #{fname}")
    case verify_checksum(dest, sum) do
      :ok ->
        :ok

      {:error, msg} ->
        Mix.shell().error(msg)
        File.rm(dest)
        exit(:checksum_mismatch)
    end
  end

  # Downloads the content of the URL and saves it to a file
  defp fetch_url(url, dest) do
    File.mkdir_p!(Path.dirname(dest))

    headers = [{"User-Agent", "ExTika/#{System.version()}"}]

    case HTTPoison.get(url, headers, stream_to: File.open!(dest, [:write])) do
      {:ok, %HTTPoison.AsyncResponse{}} ->
        :ok

      {:ok, %HTTPoison.Response{status_code: status}} when status >= 400 ->
        Mix.shell().error("HTTP request failed with status: #{status}")
        exit(:http_error)

      {:error, %HTTPoison.Error{reason: reason}} ->
        Mix.shell().error("HTTP request failed: #{inspect(reason)}")
        exit(:http_error)
    end
  end

  # Verifies that the hash of a file matches what's expected
  defp verify_checksum(path, expected) do
    actual = hash_file(path)

    if actual == expected do
      :ok
    else
      {:error, """
      Data does not match the given SHA-256 checksum.

      Expected: #{expected}
        Actual: #{actual}
      """}
    end
  end

  # Hashes an input file in chunks
  defp hash_file(path) do
    File.stream!(path, [], 4 * 1024 * 1024)
    |> Enum.reduce(:crypto.hash_init(:sha256), fn chunk, acc ->
      :crypto.hash_update(acc, chunk)
    end)
    |> :crypto.hash_final()
    |> Base.encode16(case: :lower)
  end
end

defmodule Mix.Tasks.Clean.Tika do
  @shortdoc "Cleans any downloaded JAR files"

  def run(_) do
    version = File.read!(".tika-version")
    |> String.trim()

    names = [
      "tika-#{version}.jar"
    ]

    Enum.each(names, fn name ->
      fpath = Path.join("priv", name)

      if File.exists?(fpath) do
        Mix.shell().info("Removing file: #{fpath}")
        File.rm!(fpath)
      end
    end)
  end
end
