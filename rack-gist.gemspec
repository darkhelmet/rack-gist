# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rack-gist}
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Daniel Huckstep"]
  s.date = %q{2010-07-16}
  s.description = %q{Load gists in the background. KTHXBYE!}
  s.email = %q{darkhelmet@darkhelmetlive.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "Gemfile",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "lib/rack/gist.rb",
     "rack-gist.gemspec",
     "spec/body-full.html",
     "spec/body-multiple.html",
     "spec/body-none.html",
     "spec/body-partial.html",
     "spec/full-gist.js",
     "spec/partial-gist.js",
     "spec/rack-gist_spec.rb",
     "spec/spec.opts",
     "spec/spec_helper.rb"
  ]
  s.homepage = %q{http://github.com/darkhelmet/rack-gist}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Asynchronous Github Gists. All with rack.}
  s.test_files = [
    "spec/rack-gist_spec.rb",
     "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<hpricot>, [">= 0.8.2"])
      s.add_runtime_dependency(%q<rest-client>, [">= 1.6.0"])
      s.add_development_dependency(%q<fakeweb>, [">= 1.2.8"])
      s.add_development_dependency(%q<rspec>, [">= 1.3.0"])
      s.add_development_dependency(%q<yard>, [">= 0.5.8"])
      s.add_development_dependency(%q<rack>, [">= 1.2.1"])
      s.add_development_dependency(%q<activesupport>, [">= 2.3.8"])
      s.add_development_dependency(%q<ruby-debug>, [">= 0"])
    else
      s.add_dependency(%q<hpricot>, [">= 0.8.2"])
      s.add_dependency(%q<rest-client>, [">= 1.6.0"])
      s.add_dependency(%q<fakeweb>, [">= 1.2.8"])
      s.add_dependency(%q<rspec>, [">= 1.3.0"])
      s.add_dependency(%q<yard>, [">= 0.5.8"])
      s.add_dependency(%q<rack>, [">= 1.2.1"])
      s.add_dependency(%q<activesupport>, [">= 2.3.8"])
      s.add_dependency(%q<ruby-debug>, [">= 0"])
    end
  else
    s.add_dependency(%q<hpricot>, [">= 0.8.2"])
    s.add_dependency(%q<rest-client>, [">= 1.6.0"])
    s.add_dependency(%q<fakeweb>, [">= 1.2.8"])
    s.add_dependency(%q<rspec>, [">= 1.3.0"])
    s.add_dependency(%q<yard>, [">= 0.5.8"])
    s.add_dependency(%q<rack>, [">= 1.2.1"])
    s.add_dependency(%q<activesupport>, [">= 2.3.8"])
    s.add_dependency(%q<ruby-debug>, [">= 0"])
  end
end

