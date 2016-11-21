defmodule Echo.Mixfile do
  use Mix.Project

  def project do
    [app: :echo,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [ mod: {Echo, []},
      applications: [:logger]]
  end

  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:registry, git: "https://github.com/elixir-lang/registry.git"}]
  end
end
