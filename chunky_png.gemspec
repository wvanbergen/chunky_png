Gem::Specification.new do |s|
  s.name    = 'chunky_png'
  
  # Do not change the version and date fields by hand. This will be done
  # automatically by the gem release script.
  s.version = "0.0.1"
  s.date    = "2009-10-02"

  s.summary     = "Pure ruby library for read/write, chunk-level access to PNG files"
  s.description = "Pure ruby library for read/write, chunk-level access to PNG files"

  s.authors  = ['Willem van Bergen']
  s.email    = ['willem@railsdoctors.com']
  s.homepage = 'http://wiki.github.com/wvanbergen/chunky_png'

  s.add_development_dependency('rspec', '>= 1.1.4')

  s.rdoc_options << '--title' << s.name << '--main' << 'README.rdoc' << '--line-numbers' << '--inline-source'
  s.extra_rdoc_files = ['README.rdoc']

  # Do not change the files and test_files fields by hand. This will be done
  # automatically by the gem release script.
  s.files      = %w(spec/spec_helper.rb spec/integration/string_querying_spec.rb spec/integration/relation_querying_spec.rb .gitignore spec/lib/mocks.rb scoped_search.gemspec lib/scoped_search/query_language/parser.rb LICENSE spec/lib/matchers.rb lib/scoped_search/definition.rb init.rb spec/unit/tokenizer_spec.rb spec/unit/parser_spec.rb spec/unit/ast_spec.rb lib/scoped_search/query_language/ast.rb spec/lib/database.rb Rakefile tasks/github-gem.rake spec/unit/query_builder_spec.rb lib/scoped_search/query_language.rb lib/scoped_search/query_builder.rb README.rdoc spec/unit/definition_spec.rb spec/database.yml spec/integration/api_spec.rb spec/integration/ordinal_querying_spec.rb lib/scoped_search/query_language/tokenizer.rb lib/scoped_search.rb)
  s.test_files = %w(spec/integration/string_querying_spec.rb spec/integration/relation_querying_spec.rb spec/unit/tokenizer_spec.rb spec/unit/parser_spec.rb spec/unit/ast_spec.rb spec/unit/query_builder_spec.rb spec/unit/definition_spec.rb spec/integration/api_spec.rb spec/integration/ordinal_querying_spec.rb)
end