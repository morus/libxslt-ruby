require 'net/ftp'
require 'rake/clean'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'

CLEAN.include '**/*.o'
CLEAN.include '**/*.so'
CLEAN.include 'html'
CLEAN.include 'tests/fuzface.html'
CLOBBER.include '**/*.log'
CLOBBER.include '**/Makefile'
CLOBBER.include '**/extconf.h'

desc "Default Task (Build release)"
task :default => :test

# Determine the current version of the software
if File.read('ext/xml/libxslt.h') =~ /\s*RUBY_LIBXSLT_VERSION\s*['"](\d.+)['"]/
  CURRENT_VERSION = $1
else
  CURRENT_VERSION = "0.0.0"
end

PKG_VERSION = ENV['REL'] || CURRENT_VERSION
LIBXMLH = ENV['LIBXMLH'] || '../libxml/ext/xml'

task :test_ver do
  puts PKG_VERSION
end

# Make tasks -----------------------------------------------------
MAKECMD = ENV['MAKE_CMD'] || 'make'
MAKEOPTS = ENV['MAKE_OPTS'] || ''

# Copy libxml headers in if needed or official release
task :copy_libxml_headers do  
  rm_rf 'ext/xml/libxml-ruby' if ENV['REL'] || ENV['ALLCLEAN']

  unless File.exist?('ext/xml/libxml-ruby')
    unless File.exist?(LIBXMLH)
      fail <<-EOM
      
    LibXML-Ruby headers are required to build a release.
  
    Install libxml-ruby source at ../libxml, or supply
    LIBXMLH option to rake (e.g. LIBXMLH=../myinc/path)
    
      EOM
    end
    
    mkdir 'ext/xml/libxml-ruby'
    
    Dir[File.join(LIBXMLH, '*.h')].each do |fn|
      unless fn =~ /extconf.h$/
        File.open(File.join('ext/xml/libxml-ruby', File.basename(fn)), 'w+') do |f|
          f << "/* DO NOT EDIT THIS FILE - UPDATE FROM LIBXML-RUBY ONLY */\n"
          f << "/* Generated: #{Time.now} */\n"
          f << "/* Release  : #{CURRENT_VERSION} */\n\n\n\n\n\n\n\n"
          f << File.read(fn)
        end
      end
    end
  end
end

file 'ext/xml/extconf.rb' => :copy_libxml_headers

file 'ext/xml/Makefile' => 'ext/xml/extconf.rb' do
  Dir.chdir('ext/xml') do
    ruby 'extconf.rb'
  end
end

def make(target = '')
  Dir.chdir('ext/xml') do
    pid = fork { exec "#{MAKECMD} #{MAKEOPTS} #{target}" }
    Process.waitpid pid
  end
  $?.exitstatus
end

# Let make handle dependencies between c/o/so - we'll just run it. 
file 'ext/xml/libxslt.so' => 'ext/xml/Makefile' do
  m = make
  fail "Make failed (status #{m})" unless m == 0
end

desc "Compile the shared object"
task :compile => 'ext/xml/libxslt.so'

desc "Install to your site_ruby directory"
task :install => :compile do
  m = make 'install' 
  fail "Make install failed (status #{m})" unless m == 0
end

# Test Tasks ---------------------------------------------------------
task :ta => :alltests
task :tu => :unittests
task :test => :unittests

Rake::TestTask.new(:alltests) do |t|
  t.test_files = FileList[
    'tests/tc_*.rb',
    'tests/contrib/*.rb',
  ]
  t.verbose = true
end
                    
Rake::TestTask.new(:unittests) do |t|
  t.test_files = FileList['tests/tc_*.rb']
  t.verbose = false
end
                          
#Rake::TestTask.new(:funtests) do |t|
  #  t.test_files = FileList['test/fun*.rb']
  #t.warning = true
  #t.warning = true
#end

task :unittests => :compile
task :alltests => :compile

# RDoc Tasks ---------------------------------------------------------
desc "Create the RDOC documentation tree"
rd = Rake::RDocTask.new(:doc) do |rdoc|
  rdoc.rdoc_dir = 'html'
  rdoc.title    = "Libxsl-Ruby API"
  rdoc.options << '--main' << 'README'
  rdoc.rdoc_files.include('README', 'LICENSE', 'TODO')
  rdoc.rdoc_files.include('ext/xml/ruby_xslt*.c', 'ext/xml/libxslt.c', '*.rdoc')
end

desc "Publish the RDoc documentation to project web site"
task :pubdoc => [ :doc ] do
  unless ENV['RUBYFORGE_ACCT']
    raise "Need to set RUBYFORGE_ACCT to your rubyforge.org user name (e.g. 'fred')"
  end
  require 'rake/contrib/sshpublisher'
  Rake::SshDirPublisher.new(
    "#{ENV['RUBYFORGE_ACCT']}@rubyforge.org",
    "/var/www/gforge-projects/libxsl",
    "html"
  ).upload
end

# Packaging / Version number tasks -----------------------------------
#
# You can create a Rubygem with 'rake package'
#
# You can build a release package set with 'rake release'
#
# The project can build official release packages with
# 'rake release REL=x.y.z' in a working copy (with correct 
# libxml-ruby headers in ../libxml/ext/xml or alternative dir
# specified with LIBXMLH=/path/to/headers/ )

# Used during release packaging if a REL is supplied
task :update_version do
  unless PKG_VERSION == CURRENT_VERSION
    maj, min, mic = /(\d+)\.(\d+)(?:\.(\d+))?/.match(PKG_VERSION).captures
    File.open('ext/xml/libxslt.h.new','w+') do |f|
      f << File.read('ext/xml/libxslt.h').
           gsub(/RUBY_LIBXSLT_VERSION\s+"(\d.+)"/) { "RUBY_LIBXSLT_VERSION  \"#{PKG_VERSION}\"" }.
           gsub(/RUBY_LIBXSLT_VERNUM\s+\d+/) { "RUBY_LIBXSLT_VERNUM   #{PKG_VERSION.tr('.','')}" }.
           gsub(/RUBY_LIBXSLT_VER_MAJ\s+\d+/) { "RUBY_LIBXSLT_VER_MAJ   #{maj}" }.
           gsub(/RUBY_LIBXSLT_VER_MIN\s+\d+/) { "RUBY_LIBXSLT_VER_MIN   #{min}" }.
           gsub(/RUBY_LIBXSLT_VER_MIC\s+\d+/) { "RUBY_LIBXSLT_VER_MIC   #{mic || 0}" }           
    end
    mv('ext/xml/libxslt.h.new', 'ext/xml/libxslt.h')     
  end
end

PKG_FILES = FileList[
  'ext/xml/extconf.rb',
  '[A-Z]*',
  'ext/xml/*.c', 
  'ext/xml/libxml-ruby/*.h',
  'ext/xml/ruby_xslt*.h',
  'ext/xml/libxslt.h',
  'tests/**/*',
]

if ! defined?(Gem)
  warn "Package Target requires RubyGEMs"
else
  spec = Gem::Specification.new do |s|
    
    #### Basic information.

    s.name = 'libxsl-ruby'
    s.version = PKG_VERSION
    s.summary = "LibXSLT bindings for Ruby"
    s.description = <<-EOF
      C-language bindings for Gnome LibXSLT and Ruby.
      Part of the LibXML-Ruby project.
    EOF
    s.extensions = 'ext/xml/extconf.rb'    

    #### Which files are to be included in this gem? 
    s.files = PKG_FILES.to_a
    
    #### dependencies
    s.add_dependency('libxml-ruby', '>= 0.3.6')    

    #### Load-time details
    s.require_path = 'ext'
    
    #### Documentation and testing.
    s.has_rdoc = true
    s.extra_rdoc_files = rd.rdoc_files.reject { |fn| fn =~ /\.rb$/ }.to_a
    s.rdoc_options <<
      '--title' <<  'Libxsl-Ruby API' <<
      '--main' << 'README' <<
      '-o' << 'rdoc'      

    s.test_files = Dir.glob('tests/*runner.rb')
    
    #### Author and project details.

    s.author = "Sean Chittenden"
    s.email = "libxsl-devel@rubyforge.org"
    s.homepage = "http://libxsl.rubyforge.org"
    s.rubyforge_project = "libxsl"
  end
  
  # Quick fix for Ruby 1.8.3 / YAML bug
  if (RUBY_VERSION == '1.8.3')
    def spec.to_yaml
      out = super
      out = '--- ' + out unless out =~ /^---/
      out
    end  
  end

  package_task = Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_zip = true
    pkg.need_tar_gz = true
    pkg.package_dir = 'pkg'    
  end
      
  desc "Build a full release"
  task :release => [:clobber, :update_version, :compile, :test, :package]  
end