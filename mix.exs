defmodule Thaibreak.MixProject do
  use Mix.Project

  def project do
    [
      app: :thaibreak,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      compilers: [:elixir_make] ++ Mix.compilers(),
      make_env: fn -> %{"FINE_INCLUDE_DIR" => Fine.include_dir()} end,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:elixir_make, github: "elixir-lang/elixir_make", runtime: false},
      {:fine, github: "elixir-nx/fine", runtime: false}
    ]
  end
end
