defmodule ExUnitRelease.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_unit_release,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: true,
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:ex_unit, :logger]]
  end

  defp deps do
    []
  end
end
