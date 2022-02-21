defmodule Changelog.File do
  defmacro __using__(types) do
    quote do
      use Waffle.Definition
      use Waffle.Ecto.Definition

      @acl :public_read

      # We can purge subsets of files from the CDN by setting a key on upload.
      # The module name that uses this module seems to be the best way of
      # categorizing sets of files we might want to purge together.
      # e.g. - purge all 'audio' files, purge all 'avatars', etc
      def cdn_key do
        __MODULE__
        |> to_string()
        |> String.split(".")
        |> List.last()
        |> String.downcase()
      end

      def default_url(_version, _scope) do
        ChangelogWeb.Router.Helpers.static_url(ChangelogWeb.Endpoint, "/images/defaults/black.png")
      end

      def s3_object_headers(version, {file, scope}) do
        [
          content_type: mime_type(file),
          meta: [
            {"surrogate-control", Application.get_env(:changelog, :cdn_cache_control_s3)},
            {"surrogate-key", cdn_key()}
          ]
        ]
      end

      def validate({file, _}) do
        Enum.member?(unquote(types), file_type(file))
      end

      def mime_type(file) do
        case file_type(file) do
          :jpg -> "image/jpg"
          :jpeg -> "image/jpg"
          :png -> "image/png"
          :gif -> "image/gif"
          :mp3 -> "audio/mpeg"
          :svg -> "image/svg+xml"
        end
      end

      defp file_type(file) do
        file.file_name
        |> Path.extname()
        |> String.replace(".", "")
        |> String.downcase()
        |> String.to_existing_atom()
      end

      defp hashed(id), do: Changelog.Hashid.encode(id)
      defp source(scope), do: scope.__meta__.source
    end
  end
end
