defmodule ExUnitRelease.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_unit_release,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: true,
      docs: docs(),
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:ex_unit]]
  end

  defp deps do
    []
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md"
      ]
    ]
  end

  defp description do
    """
    Run ExUnit tests from an Elixir OTP Release
    """
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/mobileoverlord/ex_unit_release"}
    ]
  end
end
