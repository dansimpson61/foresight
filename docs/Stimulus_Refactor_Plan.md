# Stimulus Controller Refactor: Events to Outlets

## Objective

To improve the clarity, robustness, and maintainability of the `simple` app's frontend by refactoring the communication between the `profile_editor` and `chart` Stimulus controllers.

This change aligns with the "Ode to Joy" principles of loose coupling, high cohesion, and intention-revealing code.

## The Problem

Currently, the `profile_editor_controller` communicates with the `chart_controller` by dispatching a custom browser event (`profile:updated`).

- **Invisible Coupling**: A developer must know to look for this custom event string in both files to understand the connection.
- **Fragile**: Relies on a global event bus (the `document` or `window` object), which can lead to naming collisions or unintended side effects.
- **Indirect**: The data flow is not immediately obvious from reading the HTML markup.

## The Solution: Stimulus Outlets

We will use the Stimulus Outlets API to create a direct, explicit connection between the controllers.

1.  **Markup Change (`index.slim`):** The `profile_editor` element will declare an `outlet` pointing to the `chart` controller's element. This makes the relationship visible in the DOM.
2.  **`profile_editor_controller.js`:** It will access the chart controller via `this.chartOutlet`. Instead of dispatching an event, it will directly call a public method on the outlet, e.g., `this.chartOutlet.update(newData)`.
3.  **`chart_controller.js`:** It will expose a public `update(newData)` method that redraws the chart. The old event listener will be removed.

## Benefits

- **Clarity**: The connection is declared in the HTML.
- **Robustness**: The connection is direct, not via a global event name.
- **Simplicity**: The logic is simpler and easier to follow. It is more "joyful" to read and maintain.