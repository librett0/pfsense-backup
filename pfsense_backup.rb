#!/usr/bin/ruby

require 'optparse'
require 'etc'
require 'highline/import'
require 'net/scp'

# Display help if no arguments given.
ARGV << '-h' if ARGV.empty?

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options] servers"

  opts.separator ""

  opts.on('-u', '--username (username)',
          'Defaults to current user') do |u|
    options[:username] = u
  end

  opts.on('-k', '--key (ssh key)',
          'Defaults to ~/.ssh/id_rsa or ~/.ssh/id_dsa (if present)') do |k|
    options[:sshkey] = k
  end

  opts.on('-h', '--help', 'Show this help') do
    puts opts
    exit
  end
end.parse!

if ARGV.length == 0
  puts "No servers specified"
  exit 1
end

# Default to current user.
user = options[:username] || Etc.getlogin

# Default ssh key
ssh_key = options[:sshkey] || Dir.glob("#{ENV['HOME']}/.ssh/id_?sa")[0]

# Warn if key isn't found.
puts "#{ssh_key} not found." unless File.file?(ssh_key)

ARGV.each do |host|
  unless File.file?(ssh_key)
    begin
      pass = ask("#{user}@#{host}'s password: ") { |q| q.echo = false }
    rescue => e
      puts e
    end
  end
  begin
    outfile = "config-#{host}-#{Time.now.strftime "%Y%m%d%k%M%S"}.xml"
    Net::SCP.start(host, user, :password => pass) do |scp|
      puts "Downloading " + outfile
      scp.download('/conf/config.xml', outfile)
    end
  rescue => e
    puts e
  end
end
