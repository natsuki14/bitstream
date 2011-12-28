Gem::Specification.new do |s|
  s.name       = 'bitstream'
  s.files      = Dir['lib/*.rb'] + Dir['lib/types/*.rb'] +
                 Dir['test/*.rb'] + Dir['test/types/*.rb'] +
                 Dir['sample/*.rb']
  s.extra_rdoc_files = ['README.en']
  s.test_files = ['test/test-suite.rb']
  s.summary    = 'A bitstream parser supports dynamic-defined fields'
  s.description = <<EOS
BitStream is a mixin to write data structures of bit streams such as picture, music, movie files, and e.t.c.. You can refer contents of bit streams even when you are defining the data structures. With the function, you can write a data structure easily that the header contains the data length of the body field.
EOS
  s.version    = '0.0.1'
  s.author     = 'Natsuki Kawai'
  s.email      = 'natsuki.kawai@gmail.com'
  s.licenses   = ["Ruby's", '2-clause BSDL']
  s.required_ruby_version = '>= 1.9.1'
  s.add_runtime_dependency 'random-accessible', '>= 0.2.0'
  s.homepage = 'https://github.com/natsuki14/bitstream'
end
