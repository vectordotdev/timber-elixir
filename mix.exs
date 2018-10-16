defmodule Timber.Mixfile do
  use Mix.Project

  @project_description """
  Timber automatically enhances your logs, turning them into rich structured events.
  Paired with the timber.io service, Timber helps you solve issues fast so you can
  focus on your app, not logging.
  """

  @source_url "https://github.com/timberio/timber-elixir"
  @homepage_url "https://github.com/timberio/timber-elixir"
  @version "3.0.0-alpha.3"

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
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env()),
      description: @project_description,
      source_url: @source_url,
      homepage_url: @homepage_url,
      package: package(),
      deps: deps(),
      docs: docs(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
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
      mod: {Timber.Application, []},
      env: env(),
      extra_applications: [:logger]
    ]
  end

  # The environment to be configured by default
  defp env() do
    []
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
      coveralls: :test,
      "coveralls.details": :test,
      "coveralls.circle": :test,
      "coveralls.html": :test,
      "coveralls.travis": :test
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
      plt_add_deps: true,
      plt_add_apps: [:mix, :ssl, :inets],
      ignore_warnings: "dialyzer.ignore-warnings"
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
      ],
      groups_for_modules: doc_groups_for_modules()
    ]
  end

  defp doc_groups_for_modules() do
    [
      Contexts: [
        Timber.Context,
        Timber.Contextable,
        Timber.Contexts.CustomContext,
        Timber.Contexts.HTTPContext,
        Timber.Contexts.JobContext,
        Timber.Contexts.OrganizationContext,
        Timber.Contexts.RuntimeContext,
        Timber.Contexts.SessionContext,
        Timber.Contexts.SystemContext,
        Timber.Contexts.UserContext
      ],
      Events: [
        Timber.Eventable,
        Timber.Events.ChannelJoinEvent,
        Timber.Events.ChannelReceiveEvent,
        Timber.Events.ControllerCallEvent,
        Timber.Events.CustomEvent,
        Timber.Events.ErrorEvent,
        Timber.Events.HTTPRequestEvent,
        Timber.Events.HTTPResponseEvent,
        Timber.Events.SQLQueryEvent,
        Timber.Events.TemplateRenderEvent
      ],
      "Logger Backends": [
        Timber.LoggerBackends.HTTP
      ],
      "Test Helpers": [
        Timber.HTTPClients.Fake,
        Timber.LoggerBackends.InMemory
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
  #   - Keep deps categorized by direct dependencies, third-party integrations,
  #     tooling
  #   - Keep each category sorted in alphabetical order
  #   - End all declarations in `,` so that they can easily be re-arranged
  #     and sorted
  defp deps() do
    [
      # Hackney is pinned to known "safe" versions. While the pinned
      # versions below are _not_ guaranteed to be bug-free, they are
      # accepted by the community as stable.
      {:hackney, "1.6.3 or 1.6.5 or 1.7.1 or 1.8.6 or ~> 1.9"},
      {:jason, "~> 1.1"},
      {:msgpax, "~> 2.0"},

      #
      # Tooling
      #

      {:credo, "~> 0.10", only: [:dev, :test]},
      {:dialyxir, "~> 0.5", only: [:dev, :test]},
      {:earmark, "~> 1.2", only: [:dev]},
      {:ex_doc, "~> 0.18.0", only: [:dev]},
      {:excoveralls, "~> 0.5", only: [:dev, :test]},
      {:inch_ex, only: [:dev]}
    ]
  end
end
