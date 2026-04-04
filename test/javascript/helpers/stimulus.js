import { Application } from "@hotwired/stimulus"

export async function connectStimulusController(identifier, Controller, html) {
  document.body.innerHTML = html

  const application = Application.start()
  application.register(identifier, Controller)
  await flushPromises()

  const element = document.querySelector(`[data-controller~="${identifier}"]`)
  const controller = application.getControllerForElementAndIdentifier(element, identifier)

  return { application, controller, element }
}

export async function disconnectStimulus(application) {
  if (application) application.stop()
  document.body.innerHTML = ""
  document.head.innerHTML = ""
  await flushPromises()
}

export async function flushPromises() {
  await Promise.resolve()
  await Promise.resolve()
}
