require "test_helper"
require "capybara/cuprite"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite, screen_size: [ 1440, 1000 ], options: {
    headless: true, process_timeout: 20, timeout: 10,
    browser_options: { "no-sandbox" => nil, "disable-dev-shm-usage" => nil }
  }

  AXE_SOURCE = File.read(Rails.root.join("test/support/axe.min.js"))

  # Runs axe-core against the current page and fails on WCAG 2.x A/AA violations.
  # axe is injected over the DevTools protocol, which is not subject to page CSP.
  def assert_accessible(context = "document")
    page.execute_script(AXE_SOURCE)
    result = page.evaluate_async_script(<<~JS, context)
      const [ctx, done] = arguments;
      axe.run(ctx === "document" ? document : ctx,
              { runOnly: { type: "tag", values: ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"] } })
         .then(r => done(r.violations.map(v => `${v.id} (${v.impact}): ${v.help} — ${v.nodes.length} node(s): ${v.nodes.slice(0, 3).map(n => n.target.join(" ")).join(", ")}`)))
         .catch(e => done(["axe error: " + e.message]));
    JS
    assert_empty result, "Accessibility violations on #{current_path}:\n#{result.join("\n")}"
  end
end
