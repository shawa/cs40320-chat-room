defmodule Chat.Mixfile do
  use Mix.Project

  def project do
    [app: :chat,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger, :gproc],
    mod: {Chat, []}]
  end


  defp deps do
    [
      {:gproc, "0.3.1"},
      {:registry, git: "https://github.com/elixir-lang/registry.git"}
    ]
  end
end
