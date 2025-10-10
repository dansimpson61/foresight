from playwright.sync_api import sync_playwright, expect

def run(playwright):
    browser = playwright.chromium.launch(headless=True)
    context = browser.new_context()
    page = context.new_page()

    # Navigate to the simple app
    page.goto("http://127.0.0.1:9393/")

    # Locate the Profile panel and its content
    profile_panel = page.locator('div[data-toggle-panel-label-value="Profile"]')
    profile_content = profile_panel.locator('.editor-form')

    # Locate the Simulation panel and its content
    simulation_panel = page.locator('div[data-toggle-panel-label-value="Simulation"]')
    simulation_content = simulation_panel.locator('.editor-form')

    # 1. Assert initial state: panels are visible, but their content is not.
    expect(profile_panel).to_be_visible()
    expect(profile_content).not_to_be_visible()
    expect(simulation_panel).to_be_visible()
    expect(simulation_content).not_to_be_visible()

    # Take a screenshot of the initial collapsed state.
    page.screenshot(path="jules-scratch/verification/initial_state.png")

    # 2. Hover over the Profile panel and assert it expands.
    profile_panel.hover()
    expect(profile_content).to_be_visible()

    # Take a screenshot of the expanded profile panel.
    page.screenshot(path="jules-scratch/verification/profile_expanded.png")

    # 3. Move the mouse away to collapse the profile panel, then hover over the Simulation panel.
    page.mouse.move(0, 0)
    simulation_panel.hover()
    expect(simulation_content).to_be_visible()
    expect(profile_content).not_to_be_visible()

    # Take a screenshot of the expanded simulation panel.
    page.screenshot(path="jules-scratch/verification/simulation_expanded.png")

    browser.close()

with sync_playwright() as playwright:
    run(playwright)