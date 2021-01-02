require "byebug"
require "timecop"

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

