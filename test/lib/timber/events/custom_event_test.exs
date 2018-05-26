defmodule Timber.Events.CustomEventTest do
  use Timber.TestCase

  describe "Timber.Eventable.to_event/1" do
    test "converting to a custom event" do
      event = %Timber.PaymentRejectedEvent{customer_id: "1234", amount: 100, currency: "USD"}
      custom_event = Timber.Eventable.to_event(event)

      assert custom_event == %Timber.Events.CustomEvent{
               data: %{amount: 100, currency: "USD", customer_id: "1234"},
               type: :payment_rejected
             }
    end
  end
end
