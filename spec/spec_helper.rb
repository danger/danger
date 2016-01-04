$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'danger'
require 'webmock'

WebMock.disable_net_connect!(allow: 'coveralls.io')
