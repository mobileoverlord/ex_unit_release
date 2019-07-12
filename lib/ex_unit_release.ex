defmodule ExUnitRelease do
  @moduledoc """
  Package and run ExUnit tests with an Elixir generated OTP release.

  ## Including tests

  Test files need to be included in the release so they are available at runtime. To include test files, you need to
  add `&ExUnitRelease.include/1` to your release steps. Here is an example of
  how to include these tests when the release is being built for the test env:

  ```elixir
  def project do
    [
      app: my_app,
      version: "0.1.0",
      elixir: "~> 1.9",
      # ...
      releases: [
        my_app: [
          steps: [:assemble] ++ ex_unit_release(Mix.env)
      ]]
    ]
  end

  defp ex_unit_release(:test),
    do: [&ExUnitRelease.include/1]

  defp ex_unit_release(_),
    do: []
  ```

  ## Running tests

  ExUnitRelease tests can be run by calling `ExUnitRelease.run/1` at runtime.
  Any options passed to this command will be sent to `ExUnit.configure/1`.

  ```elixir
  iex> ExUnitRelease.run
  {:ok,
  {"\e[32m.\e[0m\n\nFinished in 0.1 seconds\n\e[32m1 test, 0 failures\e[0m\n\nRandomized with seed 262631\n",
    %{excluded: 0, failures: 0, skipped: 0, total: 1}}}
  ```
  """


  @doc """
  Runs tests in the release

  Any options passed to this command will be sent to `ExUnit.configure/1`
  """
  @spec run(keyword()) :: {:ok, {iodata(), map}} | {:error, binary()}
  def run(opts \\ []) do
    opts
    |> Keyword.put(:autorun, false)
    |> ExUnit.configure()

    path = opts[:path] || runtime_include_path()
    case require_test_helper(path) do
      :ok ->
        tests = test_files([path])
        pid = self()
        fun =
          fn() ->
            {:ok, results} = require_and_run(tests)
            send(pid, {:ex_unit_results, results})
          end
        io = ExUnit.CaptureIO.capture_io(fun)

        results =
          receive do
            {:ex_unit_results, results} -> results
          end

        {:ok, {io, results}}
      error -> error
    end
  end

  @doc """
  Includes tests in an Elixir release

  This function is intended to be added to the elixir release steps:

      def project do
        [
          app: my_app,
          # ...
          releases: [
            my_app: [
              steps: [:assemble, &ExUnitRelease.include/1]
          ]]
        ]
      end

  The default include path for tests is `rel/test`. This can be changed in the
  application config

      config :ex_unit_release
        include_path: "other/path"

  """
  @spec include(Mix.Release.t()) :: Mix.Release.t()
  def include(release) do
    Application.get_env(:ex_unit_release, :include_path, "rel/test")
    |> Path.expand()
    |> copy_path(release.path)

    release
  end

  defp copy_path(test_path, destination_path) do
    if File.dir?(test_path) do
      Mix.shell().info([:green, "* including ", :reset, "exunit tests ", Path.relative_to_cwd(test_path)])
      destination_path = Path.join([destination_path, "test"])
      File.mkdir_p(destination_path)
      File.cp_r(test_path, destination_path)
    else
      Mix.shell().info([:yellow, "* skipping ", :reset, "exunit tests ", Path.relative_to_cwd(test_path)])
    end
  end

  defp runtime_include_path() do
    :code.root_dir()
    |> to_string()
    |> Path.join("test")
  end

  defp require_test_helper(path) do
    file = Path.join(path, "test_helper.exs")

    if File.exists?(file) do
      Code.require_file file
      :ok
    else
      {:error, "Cannot run tests because test helper file #{inspect file} does not exist"}
    end
  end

  defp test_files(paths) do
    pattern = "*_test.exs"
    Enum.flat_map(paths, fn path ->
      case :elixir_utils.read_file_type(path) do
        {:ok, :directory} -> Path.wildcard("#{path}/**/#{pattern}")
        {:ok, :regular} -> [path]
        _ -> []
      end
    end)
    |> Enum.uniq()
  end

  defp require_and_run(files) do
    task = Task.async(ExUnit, :run, [])
    {:ok, pid} = Agent.start_link(fn -> [] end)

    try do
      case Kernel.ParallelCompiler.require(files, [each_module: &each_module(pid, &1, &2, &3)]) do
        {:ok, _, _} -> :ok
        {:error, _, _} -> {:error, "Compiler failed"}
      end

      ExUnit.Server.modules_loaded()

      {:ok, Task.await(task, :infinity)}
    catch
      _kind, reason ->
        Task.shutdown(task)
        {:error, reason}
    after
      Agent.get(pid, &(&1))
      |> unload_modules()

      Agent.stop(pid)
    end
  end

  def unload_modules(modules) do
    Enum.each(modules, fn({mod, file}) ->
      :code.delete(mod)
      :code.purge(mod)
      Code.unrequire_files([file])
    end)
  end

  defp each_module(pid, file, module, _binary) do
    Agent.update(pid, &[{module, file} | &1])
  end
end
