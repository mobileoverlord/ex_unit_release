# ExUnitRelease

Run ExUnit tests from an OTP Release.

## Including tests

`ExUnitRelease` allows you to package and run ExUnit tests with an Elixir  generated OTP release. ExUnitRelease works with Elixir generated OTP releases and not `Distillery`.

To learn more about how to configure your project to use Elixir releases see the [docs](https://hexdocs.pm/mix/1.9.0/Mix.html). Ensure that you have run `mix release.init` to generate the `rel` directory and some basic release config files.

Add `:ex_unit_release` to your dependencies:

```elixir
{:ex_unit_release, "~> 0.1", only: :test}
```

In this example, we limit the dependency to only `:test`, but you could include it for all environments. This is useful if you want to use ExUnit test results as a means of performing recovery actions.

The tests that you run at runtime will likely differ from the tests that you would run at compile time. Therefore, the default location of the tests to be included are at `rel/test`. You can generate the initial files by running

```bash
MIX_ENV=test mix ex_unit_release.init
```

Test files need to be included in the release so they are available at runtime. To include test files, you need to add `&ExUnitRelease.include/1` to your release steps. Here is an example of how to include these tests when the release is being built for the test env:

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

ExUnitRelease tests can be run by calling `ExUnitRelease.run/1` at runtime. Any options passed to this command will be sent to `ExUnit.configure/1`.

```elixir
iex> ExUnitRelease.run
{:ok,
 {"\e[32m.\e[0m\n\nFinished in 0.1 seconds\n\e[32m1 test, 0 failures\e[0m\n\nRandomized with seed 262631\n",
  %{excluded: 0, failures: 0, skipped: 0, total: 1}}}
```
