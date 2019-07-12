defmodule Mix.Tasks.ExUnitRelease.Init do
  use Mix.Task

  @shortdoc "Generates sample ex_unit tests for releases"

  @moduledoc """
  Generates sample ex_unit tests for releases.
      mix ex_unit_release.init
      * creating rel/test/test_helper.exs
      * creating rel/test/my_app_test.exs
  """

  import Mix.Generator

  @switches [
    force: :boolean,
    quiet: :boolean
  ]

  @aliases [
    force: :f
  ]

  def run(args) do
    {opts, args} = OptionParser.parse!(args, strict: @switches, aliases: @aliases)

    if args != [] do
      Mix.raise("Expected \"mix ex_unit_release.init\" without arguments, got: #{inspect(args)}")
    end

    app =
      Mix.Project.config()[:app]
      |> to_string()

    create_file("rel/test/test_helper.exs", test_helper_text(), opts)
    create_file("rel/test/#{app}_test.exs", app_test(Macro.camelize(app)), opts)
  end

  def test_helper_text,
    do: ~S"""
    ExUnit.start()
    """

  def app_test(app_module),
    do: """
    defmodule #{app_module}Test do
      use ExUnit.Case

      test "the truth" do
        assert 1 + 1 == 2
      end
    end
    """
end
