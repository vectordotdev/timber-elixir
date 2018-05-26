defmodule Timber.PaymentRejectedEvent do
  use Timber.Events.CustomEvent, type: :payment_rejected

  @enforce_keys [:customer_id, :amount, :currency]
  defstruct [:customer_id, :amount, :currency]
end
