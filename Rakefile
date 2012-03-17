require "bundler/gem_tasks"
require "rake"
require "rake/testtask"
require "rdoc/task"
require "gettext/tools"

require "rubygems"
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

require File.expand_path("../lib/s7n/version", __FILE__)

Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc", "{lib/**/*.rb,ext/**/*.c}")
  rd.options = ["--line-numbers", "--inline-source", "--title", "s7n",
                "--main", "README.rdoc"]
  rd.rdoc_dir = "doc/rdoc"
end

GETTEXT_TEXT_DOMAIN = "s7n"
GETTEXT_TARGETS = Dir.glob("{bin/s7ncli,lib/**/*.rb}")

desc "Create pot file"
task :makepot do
  GetText::RGetText.run(GETTEXT_TARGETS, "po/s7n.pot")
end

desc "Update pot/po files."
task :updatepo do
  GetText.update_pofiles(GETTEXT_TEXT_DOMAIN,
                         GETTEXT_TARGETS,
                         [GETTEXT_TEXT_DOMAIN, S7n::VERSION].join(" "))
end

desc "Create mo-files"
task :makemo do
  GetText.create_mofiles(true)
end

Rake::TestTask.new do |t|
  require "test-unit"
  
  t.libs << "lib"
  t.libs << "test"
  t.test_files = FileList["test/**/*_{helper,test}.rb"]
end

task :default => :test
