Gem::Specification.new do |s|
  s.name        = 'mrdu'
  s.version     = '1.0.0'
  s.date        = '2013-05-21'
  s.summary     = "Spawn a temporary MySQL instance off a RAM disk on Ubuntu."
  s.description = "Spawn a temporary MySQL instance off a RAM disk on Ubuntu."
  s.authors     = ["Tom Van Eyck"]
  s.email       = 'tomvaneyck@gmail.com'
  s.files       = ["lib/mrdu.rb"]
  s.homepage    = 'https://github.com/vaneyckt/mrdu'

  s.add_runtime_dependency 'trollop'
  s.add_runtime_dependency 'systemu'
end
