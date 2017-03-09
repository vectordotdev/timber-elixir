defmodule Mix.Tasks.Timber.TestThePipes do
  alias Mix.Tasks.Timber.Install.{IOHelper, Messages}
  alias Timber.{Events, LogEntry}

  def run([]) do
    """
    #{Messages.header()}
    #{Messages.forgot_key()}
    """
    |> IOHelper.puts(:red)
  end

  def run([api_key]) do

  end

  def log_entries do
    dt = current_dt()

    [
      log_entry(dt, :info, http_server_request()),
      log_entry(dt_plus(dt, 2), :info, controller_call()),
      log_entry(dt_plus(dt, 7), :info, sql_query()),
      log_entry(dt_plus(dt, 13), :info, http_client_request_to_stripe()),
      log_entry(dt_plus(dt, 101), :info, http_client_response_from_stripe()),
      log_entry(dt_plus(dt, 125), :error, exception_event()),
      log_entry(dt_plus(dt, 128), :error, custom_event()),
      log_entry(dt_plus(dt, 131), :info, template_render()),
      log_entry(dt_plus(dt, 131), :info, http_server_response())
    ]
  end

  defp current_dt do
    case :calendar.universal_time() do
      {days, {hour, minute, second}} ->
        {days, {hour, minute, second, {0000, 4}}}
    end
  end

  defp dt_plus({days, {hour, minute, second, {microsecond, 4}}}, ms_addition) do
    new_microsecond = microsecond + (ms_addition * 10)
    {days, {hour, minute, second, {new_microsecond, 4}}}
  end

  defp log_entry(dt, level, %{__struct__: Events.CustomEvent} = event) do
    message = "Checkout failed for customer xd45bfd"
    LogEntry.new(dt, level, message, [event: event, timber_context: context()])
  end

  defp log_entry(dt, level, %{__struct__: module} = event) do
    message = module.message(event)
    LogEntry.new(dt, level, message, [event: event, timber_context: context()])
  end

  defp context do
    %{
      http: %{
        method: "POST",
        path: "/orders",
        request_id: request_id(),
        remote_addr: "123.123.123.123"
      },
      system: %{
        hostname: "server.host.net",
        pid: "123"
      },
      user: %{
        id: "24",
        name: "Paul Bunyan",
        email: "paul@timber.io"
      }
    }
  end

  defp controller_call do
    %Events.ControllerCallEvent{
      action: "create",
      controller: "OrderController"
    }
  end

  defp custom_event do
    %Events.CustomEvent{
      type: :checkout_failure,
      data: %{
        customer_id: "xd45bfd",
        amount: 523.43
      }
    }
  end

  defp exception_event do
    %Events.ExceptionEvent{
      backtrace: [
        %{app_name: "my_app", function: "MyApp.OrderController.create/2", file: "web/controllers/order_controller.ex", line: 23},
        %{app_name: "my_app", function: "MyApp.OrderController.phoenix_controller_pipeline/2", file: "web/controllers/order_controller.ex", line: 1},
        %{app_name: "my_app", function: "MyApp.Endpoint.instrument/4", file: "lib/my_app/endpoint.ex", line: 1},
        %{app_name: "my_app", function: "MyApp.Router.dispatch/2", file: "lib/phoenix/router.ex", line: 261},
        %{app_name: "my_app", function: "MyApp.Router.do_call/1", file: "web/router.ex", line: 1},
        %{app_name: "my_app", function: "MyApp.Endpoint.call/2", file: "lib/my_app/endpoint.ex", line: 1}
      ],
      name: "CaseClauseError",
      message: "no case clause matching: {:ok, 400}"
    }
  end

  defp http_server_request do
    %Events.HTTPServerRequestEvent{
      body: "{\"credit_card_token\": \"abcd1234\"}",
      host: "timber-test-events.com",
      headers: %{
        "accept": "application/json",
        "authorization": "Bearer [sanitized]",
        "content-type": "application/json",
        "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36",
        "x-request-id": request_id()
      },
      method: "POST",
      path: "/orders",
      port: 443,
      query_string: "?secure=true",
      request_id: request_id(),
      scheme: "https"
    }
  end

  defp http_server_response do
    %Events.HTTPServerResponseEvent{
      body: "{\"error\": \"Oops we had a problem\"}",
      headers: %{
        "content-type": "application/json",
        "x-request-id": request_id()
      },
      request_id: request_id(),
      status: 500,
      time_ms: 101.53
    }
  end

  defp http_client_request_to_stripe do
    %Events.HTTPClientRequestEvent{
      body: "{\"credit_card_token\": \"abcd1234\", \"customer_id\": \"xd45bfd\"}",
      headers: %{
        "accept": "application/json",
        "authorization": "Basic [sanitized]",
        "content-type": "application/json",
        "user-agent": "Stripe Elixir Client v1.2",
        "x-request-id": request_id()
      },
      host: "api.stripe.com",
      method: "POST",
      path: "/charge",
      port: 443,
      request_id: request_id(),
      scheme: "https",
      service_name: "stripe"
    }
  end

  defp http_client_response_from_stripe do
    %Events.HTTPClientResponseEvent{
      body: "{\"error\": \"credit card has expired\"}",
      headers: %{
        "content-type": "application/json",
        "x-request-id": request_id()
      },
      request_id: request_id(),
      service_name: "stripe",
      status: 422,
      time_ms: 86.23
    }
  end

  defp sql_query do
    %Events.SQLQueryEvent{
      sql: "SELECT * FROM productions WHERE id=2",
      time_ms: 13.2
    }
  end

  defp template_render do
    %Events.TemplateRenderEvent{
      name: "error.json",
      time_ms: 2.1
    }
  end

  defp request_id, do: "abcd1234"
end