module ApplicationHelper
  def format_money(amount_cents, currency: "USD")
    amount = BigDecimal(amount_cents.to_s) / 100
    unit = currency == "USD" ? "$" : "#{currency} "

    number_to_currency(amount, unit: unit, strip_insignificant_zeros: true)
  end

  def format_percentage(percentage)
    number_with_precision(percentage, precision: 1, strip_insignificant_zeros: true)
  end
end
