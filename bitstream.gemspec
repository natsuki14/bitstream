Gem::Specification.new do |s|
  s.name       = 'bitstream'
  s.files      = Dir['lib/*.rb'] + Dir['lib/types/*.rb'] +
                 Dir['test/*.rb'] + Dir['test/types/*.rb']
  s.test_files = ['test/test-suite.rb']
  s.summary    = 'A bitstream parser supports dynamic-defined fields'
  s.version    = '0.0.1'
  s.author     = 'Natsuki Kawai'
  s.email      = 'natsuki.kawai@gmail.com'
  s.licenses   = ["Ruby's", 'BSD']
  s.required_ruby_version = '>= 1.9.1'
  s.add_runtime_dependency 'random-accessible', '>= 0.2.0'
end
