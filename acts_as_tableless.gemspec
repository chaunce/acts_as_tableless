$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "acts_as_tableless/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ActsAsTableless"
  s.version     = ActsAsTableless::VERSION
  s.authors     = ["chaunce"]
  s.email       = ["chaunce.slc@gmail.com"]
  s.homepage    = "https://github.com/chaunce/acts_as_tableless"
  s.summary     = "acts_as_tableless"
  s.description = "create tableless activerecord objects that support associations and validations"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", ">= 3.1.0"

  s.add_development_dependency "sqlite3"
end
