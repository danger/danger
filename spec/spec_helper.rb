$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'danger'
require 'webmock'
require 'webmock/rspec'
require 'json'

WebMock.disable_net_connect!(allow: 'coveralls.io')

def make_temp_file(contents)
  file = Tempfile.new('dangefile_tests')
  file.write contents
  file
end
