# Be sure to restart your server when you modify this file.

Dummy::Application.config.session_jobs :cookie_jobs, key: '_dummy_session'

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# Dummy::Application.config.session_jobs :active_record_jobs
