require "rake"
require "rake/rdoctask"
require "rake/testtask"
require "rake/gempackagetask"

Rake::RDocTask.new do |rd|
  rd.main = "README"
  rd.rdoc_files.include("README", "{lib/**/*.rb,ext/**/*.c}")
  rd.options = ["--line-numbers", "--inline-source", "--title", "s7",
                "--main", "README"]
  rd.rdoc_dir = "docs/rdoc"
end

app_version = nil
File.open(File.expand_path("VERSION", File.dirname(__FILE__))) do |f|
  app_version = f.gets.chomp
end

spec = Gem::Specification.new do |s|
  s.name = "s7"
  s.version = app_version
  s.summary = "The secret informations manager."
  s.description = <<EOS
s7 (seven) is the secret informations(password, credit number, file, etc..) manager.
EOS
  s.author = "TAKAO Kouji"
  s.email = "kouji@takao7.net"
  s.homepage = "http://code.google.com/p/s7-seven/"
  s.rubyforge_project = "s7-seven"

  s.default_executable = "s7cli"
  s.executables = ["s7cli"]

  s.requirements << "Ruby, version 1.9.1 (or newer)"
  s.required_ruby_version = '>= 1.9.1'

  s.files = Dir.glob("{ChangeLog,LICENCE,README,Rakefile,VERSION,{bin,lib,test}/**/*,setup.rb}").delete_if { |s| /(\.svn|~$|\.bak$)/.match(s) }
  
  s.test_files = Dir.glob("test/**/*_test.rb")

  s.has_rdoc = true
  s.rdoc_options =
    ["--line-numbers", "--inline-source", "--title", "s7",
     "--main", "README"]
  s.extra_rdoc_files = ["README"]
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

ruby_path = File.join(RbConfig::CONFIG["bindir"],
                      RbConfig::CONFIG["ruby_install_name"])

namespace :setup do
  desc "run 'config' task in setup.rb."
  task :config do
    system("#{ruby_path} setup.rb config #{ENV["SETUP_OPTS"]}")
  end
  
  desc "run 'setup' task in setup.rb."
  task :setup do
    system("#{ruby_path} setup.rb setup #{ENV["SETUP_OPTS"]}")
  end
  
  desc "run 'install' task in setup.rb."
  task :install do
    system("#{ruby_path} setup.rb install #{ENV["SETUP_OPTS"]}")
  end

  desc "run 'test' task in setup.rb."
  task :test do
    system("#{ruby_path} setup.rb test #{ENV["SETUP_OPTS"]}")
  end

  desc "run 'clean' task in setup.rb."
  task :clean do
    system("#{ruby_path} setup.rb clean #{ENV["SETUP_OPTS"]}")
  end

  desc "run 'distclean' task in setup.rb."
  task :distclean do
    system("#{ruby_path} setup.rb distclean #{ENV["SETUP_OPTS"]}")
  end

  desc "run default tasks in setup.rb."
  task :all do
    system("#{ruby_path} setup.rb #{ENV["SETUP_OPTS"]}")
  end
end

=begin
require "gettext/rgettext"
require "gettext/utils"

File.open(File.expand_path("lib/s7.rb", File.dirname(__FILE__)), 
          "r:utf-8") do |f|
  VERSION = f.read.slice(/VERSION\s*=\s*"([\w.]+)"/m, 1)
end
GETTEXT_TEXT_DOMAIN = "s7"
GETTEXT_TARGETS = Dir.glob("{bin/s7cli,lib/**/*.rb}")

desc "Create pot file"
task :makepot do
  RGetText.run(GETTEXT_TARGETS, "po/s7.pot")
end

desc "Update pot/po files."
task :updatepo do
  GetText.update_pofiles(GETTEXT_TEXT_DOMAIN,
                         GETTEXT_TARGETS,
                         [GETTEXT_TEXT_DOMAIN, VERSION].join(" "))
end

desc "Create mo-files"
task :makemo do
  GetText.create_mofiles(true)
end
=end

Rake::TestTask.new do |t|
  t.libs << "lib"
  t.libs << "test"
  t.test_files = FileList["test/**/*_{helper,test}.rb"]
end

task :default => :test
