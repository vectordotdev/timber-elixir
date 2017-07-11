defmodule Timber.Installer.FakeFileContents do
  def default_config_contents do
    """
    # This file is responsible for configuring your application
    # and its dependencies with the aid of the Mix.Config module.
    #
    # This configuration file is loaded before any dependency and
    # is restricted to this project.
    use Mix.Config

    # General application configuration
    config :elixir_phoenix_example_app,
      ecto_repos: [TimberElixir.Repo]

    # Configures the endpoint
    config :elixir_phoenix_example_app, TimberElixir.Endpoint,
      url: [host: "localhost"],
      secret_key_base: "PIW+jnFP5piAAlp679uxb3Px1YD2pA7IQXqnQz67AC/tZXiAoqMpjjJTEFZ6RQXp",
      render_errors: [view: TimberElixir.ErrorView, accepts: ~w(html json)],
      pubsub: [name: TimberElixir.PubSub,
               adapter: Phoenix.PubSub.PG2],
      instrumenters: [Timber.Integrations.PhoenixInstrumenter]

    # Configures Elixir's Logger
     config :logger, :console,
       format: "$time $metadata[$level] $message\n",
       metadata: [:request_id]

    # Import environment specific config. This must remain at the bottom
    # of this file so it overrides the configuration defined above.
    import_config "#{Mix.env}.exs"
    """
  end

  def default_endpoint_contents do
    """
    defmodule TimberElixir.Endpoint do
      use Phoenix.Endpoint, otp_app: :elixir_phoenix_example_app

      socket "/socket", TimberElixir.UserSocket

      # Serve at "/" the static files from "priv/static" directory.
      #
      # You should set gzip to true if you are running phoenix.digest
      # when deploying your static files in production.
      plug Plug.Static,
        at: "/", from: :elixir_phoenix_example_app, gzip: false,
        only: ~w(css fonts images js favicon.ico robots.txt)

      # Code reloading can be explicitly enabled under the
      # :code_reloader configuration of your endpoint.
      if code_reloading? do
        socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
        plug Phoenix.LiveReloader
        plug Phoenix.CodeReloader
      end

      plug Plug.RequestId
      plug Plug.Logger

      plug Plug.Parsers,
        parsers: [:urlencoded, :multipart, :json],
        pass: ["*/*"],
        json_decoder: Poison

      plug Plug.MethodOverride
      plug Plug.Head

      # The session will be stored in the cookie and signed,
      # this means its contents can be read but not tampered with.
      # Set :encryption_salt if you would also like to encrypt it.
      plug Plug.Session,
        store: :cookie,
        key: "_elixir_phoenix_example_app_key",
        signing_salt: "abfd232"

      plug TimberElixir.Router
    end
    """
  end

  def default_repo_contents do
    """
    defmodule ElixirPhoenixExampleApp.Repo do
      use Ecto.Repo, otp_app: :elixir_phoenix_example_app
    end
    """
  end

  def default_web_contents do
    """
    defmodule TimberElixir.Web do
      def model do
        quote do
          use Ecto.Schema

          import Ecto
          import Ecto.Changeset
          import Ecto.Query
        end
      end

      def controller do
        quote do
          use Phoenix.Controller

          alias TimberElixir.Repo
          import Ecto
          import Ecto.Query

          import TimberElixir.Router.Helpers
          import TimberElixir.Gettext
        end
      end

      def view do
        quote do
          use Phoenix.View, root: "web/templates"

          # Import convenience functions from controllers
          import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

          # Use all HTML functionality (forms, tags, etc)
          use Phoenix.HTML

          import TimberElixir.Router.Helpers
          import TimberElixir.ErrorHelpers
          import TimberElixir.Gettext
        end
      end

      def router do
        quote do
          use Phoenix.Router
        end
      end

      def channel do
        quote do
          use Phoenix.Channel

          alias TimberElixir.Repo
          import Ecto
          import Ecto.Query
          import TimberElixir.Gettext
        end
      end

      defmacro __using__(which) when is_atom(which) do
        apply(__MODULE__, which, [])
      end
    end
    """
  end

  def config_addition do
    """

    # Import Timber, structured logging
    import_config \"timber.exs\"
    """
  end

  def new_endpoint_contents do
    """
    defmodule TimberElixir.Endpoint do
      use Phoenix.Endpoint, otp_app: :elixir_phoenix_example_app

      socket "/socket", TimberElixir.UserSocket

      # Serve at "/" the static files from "priv/static" directory.
      #
      # You should set gzip to true if you are running phoenix.digest
      # when deploying your static files in production.
      plug Plug.Static,
        at: "/", from: :elixir_phoenix_example_app, gzip: false,
        only: ~w(css fonts images js favicon.ico robots.txt)

      # Code reloading can be explicitly enabled under the
      # :code_reloader configuration of your endpoint.
      if code_reloading? do
        socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
        plug Phoenix.LiveReloader
        plug Phoenix.CodeReloader
      end

      plug Plug.RequestId

      plug Plug.Parsers,
        parsers: [:urlencoded, :multipart, :json],
        pass: ["*/*"],
        json_decoder: Poison

      plug Plug.MethodOverride
      plug Plug.Head

      # The session will be stored in the cookie and signed,
      # this means its contents can be read but not tampered with.
      # Set :encryption_salt if you would also like to encrypt it.
      plug Plug.Session,
        store: :cookie,
        key: "_elixir_phoenix_example_app_key",
        signing_salt: "abfd232"

      # Add Timber plugs for capturing HTTP context and events
      plug Timber.Integrations.SessionContextPlug
      plug Timber.Integrations.HTTPContextPlug
      plug Timber.Integrations.EventPlug

      plug TimberElixir.Router
    end
    """
  end

  def new_web_contents do
    """
    defmodule TimberElixir.Web do
      def model do
        quote do
          use Ecto.Schema

          import Ecto
          import Ecto.Changeset
          import Ecto.Query
        end
      end

      def controller do
        quote do
          use Phoenix.Controller, log: false

          alias TimberElixir.Repo
          import Ecto
          import Ecto.Query

          import TimberElixir.Router.Helpers
          import TimberElixir.Gettext
        end
      end

      def view do
        quote do
          use Phoenix.View, root: "web/templates"

          # Import convenience functions from controllers
          import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

          # Use all HTML functionality (forms, tags, etc)
          use Phoenix.HTML

          import TimberElixir.Router.Helpers
          import TimberElixir.ErrorHelpers
          import TimberElixir.Gettext
        end
      end

      def router do
        quote do
          use Phoenix.Router
        end
      end

      def channel do
        quote do
          use Phoenix.Channel

          alias TimberElixir.Repo
          import Ecto
          import Ecto.Query
          import TimberElixir.Gettext
        end
      end

      defmacro __using__(which) when is_atom(which) do
        apply(__MODULE__, which, [])
      end
    end
    """
  end

  def timber_config_contents do
    """
    use Mix.Config

    # Update the instrumenters so that we can structure Phoenix logs
    config :timber_elixir, TimberElixir.Endpoint,
      instrumenters: [Timber.Integrations.PhoenixInstrumenter]

    # Structure Ecto logs
    config :timber_elixir, ElixirPhoenixExampleApp.Repo,
      loggers: [{Timber.Integrations.EctoLogger, :log, [:info]}]

    # Use Timber as the logger backend
    # Feel free to add additional backends if you want to send you logs to multiple devices.
    # For Heroku, use the `:console` backend provided with Logger but customize
    # it to use Timber's internal formatting system
    config :logger,
      backends: [:console],
      utc_log: true

    config :logger, :console,
      format: {Timber.Formatter, :format},
      metadata: [:timber_context, :event, :application, :file, :function, :line, :module, :meta]

    # For the following environments, do not log to the Timber service. Instead, log to STDOUT
    # and format the logs properly so they are human readable.
    environments_to_exclude = [:dev, :test]
    if Enum.member?(environments_to_exclude, Mix.env()) do
      # Fall back to the default `:console` backend with the Timber custom formatter
      config :logger,
        backends: [:console],
        utc_log: true

      config :logger, :console,
        format: {Timber.Formatter, :format},
        metadata: [:timber_context, :event, :application, :file, :function, :line, :module, :meta]

      config :timber, Timber.Formatter,
        colorize: true,
        format: :logfmt,
        print_timestamps: true,
        print_log_level: true,
        print_metadata: false # turn this on to view the additiional metadata
    end

    # Need help?
    # Email us: support@timber.io
    # Or, file an issue: https://github.com/timberio/timber-elixir/issues
    """
  end
end
