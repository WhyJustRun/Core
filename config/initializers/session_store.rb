# Be sure to restart your server when you modify this file.

# Store the session in an encrypted, signed cookie (the Rails default). The
# session only holds small values (return paths, a redirect club id, the signed
# in user id), so it fits comfortably in the cookie, and there is no server-side
# session table to serialize, sweep, or protect.
WhyJustRun::Application.config.session_store :cookie_store, key: '_whyjustrun_session'
