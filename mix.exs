defmodule Timber.Mixfile do
  use Mix.Project

  @project_description """
  Timber automatically enhances your logs, turning them into rich structured events.
  Paried with the timber.io service, Timber helps you solve issues fast so you can go back
  to doing what you do.
  """

  @source_url "https://github.com/timberio/timber-elixir"
  @homepage_url "https://github.com/timberio/timber-elixir"
  @version "2.2.1"

  # Project manifest for Mix
  #
  # See `mix help` entries for the following if you need
  # more information about the options used in this section:
  #
  #   - `compile`
  #   - `compile.elixir`
  #   - `compile.erlang`
  def project do
    [
      app: :timber,
      name: "Timber",
      version: @version,
      elixir: "~> 1.3",
      elixirc_paths: elixirc_paths(Mix.env),
      description: @project_description,
      source_url: @source_url,
      homepage_url: @homepage_url,
      package: package(),
      deps: deps(),
      docs: docs(),
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      preferred_cli_env: preferred_cli_env(),
      test_coverage: test_coverage(),
      dialyzer: dialyzer()
    ]
  end

  # Appication definition for building the `.app` file
  #
  # See `mix help compile.app` for more information about the
  # options used in this section
  #
  # Note: Because this is a package, the default environment
  # is specified in this section. The `config/*` files in this
  # repository are only useful for this package's local development
  # and are not distributed with the package.
  def application do
    [
      mod: {Timber, []},
      env: env(),
      applications: apps(Mix.env)
    ]
  end

  # List of applications to be loaded for the specified
  # Mix environment.
  defp apps(:test), do: apps()
  defp apps(:dev), do: apps()
  defp apps(_), do: apps()

  # Default list of applications to be loaded regardless
  # of Mix environment
  defp apps(), do: [:logger, :poison, :msgpax, :hackney]

  # The environment to be configured by default
  defp env() do
    [
      transport: Timber.Transports.IODevice,
    ]
  end

  # Compiler paths switched on the Mix environment
  #
  # The `lib` directory is always compiled
  #
  # In the :test environment, `test/support` will also be compiled
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Preferred CLI Environment details
  #
  # Defines the preferred environment for Mix tasks
  defp preferred_cli_env() do
    [
      "coveralls": :test,
      "coveralls.details": :test,
      "coveralls.circle": :test,
      "coveralls.html": :test
    ]
  end

  # Test Coverage configuration
  #
  # Sets the test converage tool to be Coveralls
  defp test_coverage() do
    [
      tool: ExCoveralls
    ]
  end

  # Dialyzer configuration
  defp dialyzer() do
    [
      plt_add_deps: true
    ]
  end

  # Package options for the Hex package listing
  #
  # See `mix help hex.publish` for more information about
  # the options used in this section
  defp package() do
    [
      name: :timber,
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Ben Johnson", "David Antaramian"],
      licenses: ["ISC"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end

  # Documentation options for ExDoc
  defp docs() do
    [
      source_ref: "v#{@version}",
      main: "readme",
      logo: "doc_assets/logo.png",
      extras: [
        "README.md": [title: "README"],
        "LICENSE.md": [title: "LICENSE"]
      ]
    ]
  end

  # Dependencies for this application
  #
  # See `mix help deps` for more information about the options used
  # in this section
  #
  # Please:
  #
  #   - Keep this as the last section in `mix.exs` to make
  #     it easily discoverable
  #   - Keep this section sorted in alphabetical order
  defp deps() do
    deps =
      [
        {:credo, "~> 0.4", only: [:dev, :test]},
        {:dialyxir, "~> 0.3", only: [:dev, :test]},
        {:earmark, "~> 1.2", only: [:dev, :docs]},
        {:ex_doc, "~> 0.15", only: [:dev, :docs]},
        {:excoveralls, "~> 0.5", only: [:test]},

        # Hackney is pinned because other versions are known to have bugs. This is the
        # safest route.
        {:hackney, "1.6.3 or 1.6.5 or 1.7.1 or ~> 1.8.0"},
        {:msgpax, "~> 1.0"},
        {:poison, "~> 1.0 or ~> 2.0 or ~> 3.0"}
      ]

    # This is used for CI to ensure we can test across multiple versions.
    # It defaults to nil for everything else, which we handle.
    deps =
      case System.get_env("ECTO_VERSION_CONSTRAINT") do
        v when v in ["latest", nil] -> deps ++ [{:ecto, "~> 2.0", optional: true}]
        "omit" -> deps
        v -> deps ++ [{:ecto, v, optional: true}]
      end

    # This is used for CI to ensure we can test across multiple versions
    # It defaults to nil for everything else, which we handle.
    deps =
      case System.get_env("PHOENIX_VERSION_CONSTRAINT") do
        v when v in ["latest", nil] -> deps ++ [{:phoenix, "~> 1.2 or ~> 1.3.0-rc", optional: true}]
        "omit" -> deps
        v -> deps ++ [{:phoenix, v, optional: true}]
      end

    # This is used for CI to ensure we can test across multiple versions
    # It defaults to nil for everything else, which we handle.
    deps =
      case System.get_env("PLUG_VERSION_CONTRAINT") do
        v when v in ["latest", nil] -> deps ++ [{:plug, "~> 1.2", optional: true}]
        "omit" -> deps
        v -> deps ++ [{:plug, v, optional: true}]
      end

    deps
  end
end
