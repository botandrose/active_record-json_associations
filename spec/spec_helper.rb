require "byebug"
require "timecop"

def database_config
  if ENV["DATABASE_URL"]
    { url: ENV["DATABASE_URL"] }
  else
    { adapter: "sqlite3", database: ":memory:" }
  end
end

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
end

def silence_stream(stream)
  old_stream = stream.dup
  stream.reopen "/dev/null"
  stream.sync = true
  yield
ensure
  stream.reopen(old_stream)
  old_stream.close
end

