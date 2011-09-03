#!/usr/bin/env ruby

begin
  require 'conrad_filer/cli'
rescue LoadError
  require 'rubygems'
  require 'conrad_filer/cli'
end

cli = ConradFiler::CLI.new(ARGV)
cli.run