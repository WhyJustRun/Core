# Browser test plan

The 240 integration tests cover routing, authorization, tenancy, and data
behavior server-side, but none of the JavaScript-driven UI. This plan covers
the browser layer: what gets automated as system tests, what stays manual,
and the infrastructure needed.

## Infrastructure (one-time setup)

- **Stack**: Rails system tests (`test/system/`, `ActionDispatch::SystemTestCase`)
  with Capybara + selenium-webdriver driving headless Chromium. Gems go in the
  test group; the Docker dev image and CI runner need `chromium` +
  `chromium-chromedriver`.
- **Multi-domain**: club fixtures use `cluba.test` domains. Chrome is launched
  with `--host-resolver-rules=MAP *.test 127.0.0.1` so no DNS is needed;
  `Capybara.app_host` switches between the apex and club domains per test.
- **Port handling (enabling change)**: `Clubsite::BaseController#set_current_club`
  matches `request.host_with_port` against `clubs.domain`. The system-test
  server runs on a random port, so the lookup must also try the portless
  `request.host` (falling back exactly as production does, where domains have
  no port).
- **Console-error tripwire**: a shared teardown assertion fails any system
  test whose page produced severe browser console errors. This is the widest
  net for catching de-AMD/wiring regressions in JS we don't otherwise assert
  on.
- **CI**: a separate `test:system` job (system tests are slower and flakier
  than integration tests; a separate job keeps the fast suite's signal
  clean). If flakiness becomes a tax, the job can be made non-blocking while
  keeping the local suite mandatory — but it starts as a required check.

## P0 — automate first (the flows that would block cutover)

Each of these exercises JS that the integration suite cannot reach.

1. **SSO round trip**: club → Sign in link → apex form → back to club signed
   in; sign out ends both sessions. (Backstops the token handoff in a real
   browser with real cookies.)
2. **Event create + edit**: fill the form, add two courses and an organizer
   through the Knockout editors (role select populated from `/roles/index.json`,
   person picker autocomplete from `/users/index.json`), save, verify
   persistence; re-edit and verify the editors rehydrate from the JSON blobs.
3. **Results editor**: open `editResults`, enter a time/status/score for an
   existing registrant, add a new person (fake-user path), save, verify rows;
   delete a result (exercises the `$.post` AJAX path).
4. **Course registration**: register self, register another person via the
   register-others picker (creates a fake user), unregister; verify the
   permission-driven button states.
5. **In-place editing**: jEditable content block on the home page and a
   Resources page title/body — edit, save, reload, verify (exercises the
   jEditable + CSRF token wiring).
6. **Map create/edit with image upload**: submit the multipart form, verify
   thumbnails render on the map page; drag-update is simulated by posting the
   marker JS's endpoint from the page context.
7. **Calendar page**: FullCalendar renders the seeded events from
   `/club/:id/events.json`; month navigation updates the URL (pushState
   path).
8. **Event listing + home event list**: the Knockout list populates from the
   IOF XML feed (same-origin fetch + XML parsing path).
9. **Club settings + privileges admin**: edit club fields, grant and revoke a
   privilege; verifies the admin forms end-to-end after the PATCH/POST fix.

## P1 — automate second

- Live results visibility toggle; registrant comment modal.
- Printable entries page (printable layout, member checkmarks).
- Series admin with the color picker; series colors appearing in the
  calendar legend and list.
- Branding uploads (header image/logo/custom CSS) and their appearance in
  the layout (srcset header, CSS override link last).
- User merge + duplicates screen.
- `.embed` iframe variants of the calendar and maps pages.
- Memberships, officials, map standards, roles admin CRUD through the real
  forms.
- Password reset email flow (assert the mail, follow the link).

## Not automated — manual checklist

- **Visual fidelity vs the PHP site**: run both apps against the same dev
  database (`localhost:3001` PHP club vs the Rails club) and compare the main
  pages side by side. Automation can't judge "looks right".
- **Redactor**: licensed, not in the repo. With a copy in `public/redactor/`,
  manually verify rich-text editing on event description + pages, and image
  upload through the editor. (Automatable later if a licensed copy is
  available to CI — keep it manual for now.)
- **Third-party embeds**: Google Maps rendering/draggable markers, Flickr
  photos, Facebook box, Juicer feed — external services; spot-check manually.
  Automated tests assert only the container markup and that no console
  errors fire when keys are absent.
- **Cross-browser/mobile**: one manual pass in Safari and a phone-sized
  viewport (navbar collapse, calendar touch).
- **Pre-cutover, against production**: the smoke script over every real
  domain (see deploy/CUTOVER.md), then a manual pass of P0 flows 1-6 on one
  real club with production data.

## Sequencing

1. Infrastructure + the console-error tripwire + P0 flows 1, 5, 7, 8 (pure
   read/JS wiring — fast wins that would already have caught the PATCH bug's
   class).
2. P0 flows 2, 3, 4, 6, 9 (editor-heavy).
3. P1 as time allows; anything still red-flagged by then stays on the manual
   checklist.
