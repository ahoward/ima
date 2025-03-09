## ima.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "ima"
  spec.version = "0.4.2"
  spec.required_ruby_version = '>= 3.0'
  spec.platform = Gem::Platform::RUBY
  spec.summary = "ima # WIP"
  spec.description = "ima # WIP"
  spec.license = "LicenseRef-LICENSE.md"

  spec.files =
["LICENSE.md",
 "README.md",
 "Rakefile",
 "TODO.md",
 "a.rb",
 "bin",
 "bin/ima",
 "docs",
 "ima.gemspec",
 "lib",
 "lib/ima",
 "lib/ima.rb",
 "lib/ima/_lib.rb",
 "lib/ima/ai.rb",
 "lib/ima/cast.rb",
 "lib/ima/error.rb",
 "lib/ima/rate_limiter.rb",
 "lib/ima/task.rb",
 "test"]

  spec.executables = ["ima"]
  
  spec.require_path = "lib"

  
    spec.add_dependency(*["parallel", "~> 1.26"])
  
    spec.add_dependency(*["map", "~> 6.6"])
  
    spec.add_dependency(*["front_matter_parser", "~> 1.0"])
  
    spec.add_dependency(*["lockfile", "~> 2.1"])
  
    spec.add_dependency(*["groq", "~> 0.3"])
  
    spec.add_dependency(*["clee", "~> 0.4"])
  

  spec.extensions.push(*[])

  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "https://github.com/ahoward/ima"
end
