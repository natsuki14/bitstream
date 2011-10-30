Gem::Specification.new do |s|
  s.name       = 'bitsream'
  s.files      = Dir['lib/*.rb'] + Dir['lib/types/*.rb']
  s.test_files = ['test/test-suite.rb']
  s.summary    = 'A bitstream parser supports dynamic-defined fields'
  s.version    = '0.0.0.pre'
  s.email      = 'natsuki.kawai@gmail.com'
  s.licenses   = ["Ruby's", 'BSD']
  s.required_ruby_version = '>= 1.9.1'
end
