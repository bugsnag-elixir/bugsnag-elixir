Mox.defmock(Bugsnag.HTTPMock, for: Bugsnag.HTTPClient)
Application.ensure_all_started(:httpoison)

ExUnit.start(capture_log: true)
