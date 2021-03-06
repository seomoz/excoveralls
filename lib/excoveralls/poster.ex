defmodule ExCoveralls.Poster do
  @moduledoc """
  Post JSON to coveralls server.
  """
  @file_name "excoveralls.post.json"

  @doc """
  Create a temporarily json file and post it to server using hackney library.
  Then, remove the file after it's completed.
  """
  def execute(json, options \\ []) do
    File.write!(@file_name, json)
    response = send_file(@file_name, options)
    File.rm!(@file_name)

    case response do
      {:ok, message} -> IO.puts message
      {:error, message} -> raise message
    end
  end

  defp send_file(file_name, options) do
    :hackney.start
    endpoint = options[:endpoint] || "https://coveralls.io"
    response = :hackney.request(:post, "#{endpoint}/api/v1/jobs", [],
      {:multipart, [
        {:file, file_name,
          {"form-data", [{"name", "json_file"}, {"filename", file_name}]},
          [{"Content-Type", "application/json"}]
        }
      ]}
    )
    case response do
      {:ok, status_code, _, _} when status_code in 200..299 ->
        {:ok, "Finished to post a json file"}

      {:ok, status_code, _, client} ->
        {:ok, body} = :hackney.body(client)
        {:error, "Failed to posting a json file: status_code: #{status_code} body: #{body}"}

      {:error, reason} ->
        {:error, "Failed to posting a json file: #{reason}"}
    end
  end
end
