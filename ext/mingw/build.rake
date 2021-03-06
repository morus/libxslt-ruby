# We can't use Ruby's standard build procedures
# on Windows because the Ruby executable is
# built with VC++ while here we want to build
# with MingW.  So just roll our own...

require 'rubygems'
require 'rake/clean'
require 'rbconfig'

RUBY_INCLUDE_DIR = Config::CONFIG["archdir"]
RUBY_BIN_DIR = Config::CONFIG["bindir"]
RUBY_LIB_DIR = Config::CONFIG["libdir"]
RUBY_SHARED_LIB = Config::CONFIG["LIBRUBY"]
RUBY_SHARED_DLL = RUBY_SHARED_LIB.gsub(/lib$/, 'dll')

EXTENSION_NAME = "libxslt_ruby.#{Config::CONFIG['DLEXT']}"

gem_specs = Gem::SourceIndex.from_installed_gems.search('libxml-ruby')
LIBXML_RUBY_DIR = gem_specs.sort_by {|spec| spec.version}.reverse.first.full_gem_path

CLEAN.include('*.o')
CLOBBER.include('libxslt.so')

task :default => "libxslt"

SRC = FileList['../libxslt/*.c']
OBJ = SRC.collect do |file_name|
  File.basename(file_name).ext('o')
end

SRC.each do |srcfile|
  objfile = File.basename(srcfile).ext('o')
  file objfile => srcfile do
    command = "gcc -c -fPIC -O2 -Wall -o #{objfile} -I/usr/local/include -I../../rlibxml/ext #{srcfile} -I#{LIBXML_RUBY_DIR}/ext -I#{RUBY_INCLUDE_DIR}"
    sh "sh -c '#{command}'"
  end
end

file "libxslt" => OBJ do
  command = "gcc -shared -o #{EXTENSION_NAME} -L#{LIBXML_RUBY_DIR}/lib -L/usr/local/lib #{OBJ} -lxml_ruby -lexslt -lxslt -lxml2 #{RUBY_BIN_DIR}/#{RUBY_SHARED_DLL}"
  sh "sh -c '#{command}'"
end
