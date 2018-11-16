#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'logger'
require 'mimemagic'
require 'exifr/jpeg'
require_relative 'lib/gps_exif_extractor'

# Configure debug logger to output to console, and only show warnings by default
#
logger = Logger.new(STDOUT)
logger.level = Logger::WARN

# Build an options parser to extract params from the command line call
#
opts = {}
parser = OptionParser.new do |opt|
  opt.on('-h', '--html',     'HTML output mode') { |v| opts[:html_mode] = v }
  opt.on('-v', '--verbose',  'Verbose logging')  { |v| opts[:verbose]   = v }
  opt.on('-s', '--strict',   'Strict mode')      { |v| opts[:verbose]   = v }
  opt.on('-d', '--dir PATH', 'Search directory') { |v| opts[:directory] = v }
end
unparsed_params = parser.parse!

# If no --dir was specified, it may have been passed in as an un-named argument
# Failing that, use the current working directory
#
opts[:directory] ||= unparsed_params.first || Dir.pwd

# Reconfigure the logger based on verbose mode
#
logger.level = Logger::INFO if opts[:verbose]
logger.info 'Started extraction with options:'
logger.info opts.inspect

# Initialize an extractor with supplied options
#
extractor = GpsExifExtractor.new(
  verbose: opts[:verbose],
  strict:  opts[:strict],
  logger:  logger
)
coordinates = extractor.extract_all(opts[:directory])
puts coordinates.inspect
