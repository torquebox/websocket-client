
require 'rubygems'

Gem::Specification.new do |s|
    s.platform  =   Gem::Platform::RUBY
    s.name      =   "websocket-client"
    s.version   =   "0.1.3"
    s.author    =   "The TorqueBox Team"
    s.email     =   "team@torquebox.org"
    s.summary   =   "Pure ruby WebSocket client"
    s.files     =   [
      Dir['lib/**/*.rb'],
      Dir['examples/**/*.rb'],
    ].flatten
    s.require_paths  =   [ 'lib' ]
    s.has_rdoc  =   true
end

