from playwright.sync_api import sync_playwright, expect
import sys

def run(playwright):
    browser = playwright.chromium.launch(headless=True)
    context = browser.new_context()
    page = context.new_page()

    try:
        # 1. Navigate to the playground page.
        page.goto("http://127.0.0.1:9393/playground", timeout=10000)

        # 2. Take an immediate screenshot for debugging purposes.
        page.screenshot(path="jules-scratch/verification/debug_page_view.png")

        # 3. Print the page's HTML content to the console for inspection.
        html_content = page.content()
        print("--- START PAGE HTML ---")
        print(html_content)
        print("--- END PAGE HTML ---")

        # 4. Attempt to find the panel label again.
        left_panel_label = page.locator('.sp-panel[data-sp-panel-position-value="left"] .sp-panel__label')

        # 5. Add an explicit wait to be sure, then check visibility.
        page.wait_for_selector('.sp-panel[data-sp-panel-position-value="left"] .sp-panel__label', timeout=5000)
        expect(left_panel_label).to_be_visible()

        # If successful, continue with the original verification steps...
        print("Selector found! Continuing with verification...")
        left_panel_label.hover()
        page.wait_for_timeout(500)
        page.screenshot(path="jules-scratch/verification/02_hover_expanded_state.png")
        left_panel_label.click()
        page.mouse.move(10, 10)
        page.wait_for_timeout(500)
        page.screenshot(path="jules-scratch/verification/03_sticky_expanded_state.png")
        print("Playwright script completed successfully.")

    except Exception as e:
        print(f"An error occurred: {e}", file=sys.stderr)
        # Save an error screenshot if something goes wrong.
        page.screenshot(path="jules-scratch/verification/error.png")

    finally:
        browser.close()

with sync_playwright() as playwright:
    run(playwright)