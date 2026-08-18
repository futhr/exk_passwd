Code.require_file("release_ref.exs", __DIR__)

version = Mix.Project.config() |> Keyword.fetch!(:version)

ExkPasswd.ReleaseRef.verify!(version, System.get_env(), File.cwd!())

Mix.shell().info("Verified refs/tags/v#{version} at #{System.fetch_env!("GITHUB_SHA")}")
