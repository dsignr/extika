defmodule Extika.Compiler do
  @moduledoc """
  Module for downloading and verifying Apache Tika JAR files.
  """

  def fetch_tika(version, dest) do
    url = "https://archive.apache.org/dist/tika/tika-app-#{version}.jar"
    checksum = "4f377b42e122f92c3f1f3b4702029cf0642c7d6f3ce872a0dfb1472eac65be44"

    unless File.exists?(dest) do
      IO.puts("Fetching: tika-#{version}.jar")
      fetch_url(url, dest)
    end

    IO.puts("Verifying checksum of: tika-#{version}.jar")
    verify_checksum(dest, checksum)
  end

  defp fetch_url(url, dest) do
    File.mkdir_p!(Path.dirname(dest))

    headers = [{"User-Agent", "Extika/#{System.version()}"}]

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        File.write!(dest, body)
        :ok

      {:ok, %HTTPoison.Response{status_code: status}} when status >= 400 ->
        Mix.raise("HTTP request failed with status: #{status}")

      {:error, %HTTPoison.Error{reason: reason}} ->
        Mix.raise("HTTP request failed: #{inspect(reason)}")
    end
  end

  defp verify_checksum(path, expected) do
    actual = hash_file(path)

    if actual == expected do
      :ok
    else
      Mix.raise("""
      Data does not match the given SHA-256 checksum.

      Expected: #{expected}
        Actual: #{actual}
      """)
    end
  end

  defp hash_file(path) do
    File.stream!(path, [], 4 * 1024 * 1024)
    |> Enum.reduce(:crypto.hash_init(:sha256), fn chunk, acc ->
      :crypto.hash_update(acc, chunk)
    end)
    |> :crypto.hash_final()
    |> Base.encode16(case: :lower)
  end
end
