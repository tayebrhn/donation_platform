import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message", "paymentElement", "submit"]
  static values = {
    clientSecret: String,
    publishableKey: String,
    returnUrl: String
  }

  connect() {
    if (!window.Stripe) {
      this.showMessage("Secure payment fields could not be loaded. Please refresh and try again.")
      return
    }

    this.stripe = window.Stripe(this.publishableKeyValue)
    this.elements = this.stripe.elements({
      clientSecret: this.clientSecretValue,
      appearance: {
        theme: "stripe",
        variables: {
          colorPrimary: "#19302b",
          colorText: "#19302b",
          colorBackground: "#fffdf8",
          borderRadius: "3px",
          fontFamily: "Trebuchet MS, Arial, sans-serif"
        }
      }
    })
    this.paymentElement = this.elements.create("payment", { layout: "tabs" })
    this.paymentElement.on("ready", () => { this.submitTarget.disabled = false })
    this.paymentElement.on("loaderror", () => {
      this.showMessage("Secure payment fields could not be loaded. Please refresh and try again.")
    })
    this.paymentElementTarget.textContent = ""
    this.paymentElement.mount(this.paymentElementTarget)
  }

  disconnect() {
    this.paymentElement?.destroy()
  }

  async submit(event) {
    event.preventDefault()
    this.setLoading(true)

    try {
      const { error } = await this.stripe.confirmPayment({
        elements: this.elements,
        confirmParams: { return_url: this.returnUrlValue },
        redirect: "if_required"
      })

      if (error) {
        this.showMessage(error.message || "Stripe could not process this payment.")
        this.setLoading(false)
        return
      }

      window.location.assign(this.returnUrlValue)
    } catch (_error) {
      this.showMessage("Stripe could not process this payment. Please try again.")
      this.setLoading(false)
    }
  }

  setLoading(loading) {
    this.submitTarget.disabled = loading
    this.submitTarget.textContent = loading ? "Processing..." : "Pay now"
  }

  showMessage(message) {
    this.messageTarget.textContent = message
    this.messageTarget.hidden = false
  }
}
