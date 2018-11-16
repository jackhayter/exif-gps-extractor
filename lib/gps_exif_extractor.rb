# frozen_string_literal: true

# Extracts GSP coordinates from EXIF data embedded in image files
#
class GpsExifExtractor

  attr_reader :verbose
  attr_reader :strict
  attr_reader :logger

  # Custom error type for clearer error handling
  #
  class ExtractionError < StandardError; end

  # Instanciates an extractor
  #
  # @param verbose [Boolean] Log debug info when true
  # @param strict [Boolean] Raise errors when an extraction fails
  # @param logger [Logger] Destination for log output from this and EXIFR
  # @return [ExtractionError] New instance
  #
  def initialize(verbose:, strict:, logger:)
    @verbose = verbose
    @strict  = strict
    @logger  = logger
    EXIFR.logger = logger
  end

  # Extracts GPS coordinates from all files in a directory
  #
  # @param directory [String] The path to recursively search for JPEG images
  # @return [Array] Hashes containing GPS data and file name
  #
  def extract_all(directory)

    # Ensure that the supplied directory actually exists
    #
    unless Dir.exist?(directory)
      logger.fatal "Specified directory does not exist: #{directory}"
      raise ExtractionError
    end

    # By looking at ALL files in the directory, we can find files that might
    # contain JPEG data but have the wrong (or no) file extension
    #
    extracted = Dir.glob(File.join(directory, '**/*')).collect do |file_path|
      coordinates = extract(file_path)
      next unless coordinates
      { path: file_path, coordinates: coordinates }
    end

    # Remove nil entries from the results, and sort alphabetically by path
    #
    return extracted.compact.sort_by{ |i| i[:path] }

  end

  # Extracts GPS coordinates from one single file
  #
  # @param file_path [String] The file path from which to extract GPS data
  # @return [Array] GPS coordinates from where the photograph was taken
  #
  def extract(file_path)

    # Ensure the requested file actually contains JPEG data
    #
    return unless ensure_jpg(file_path)

    # Extract the GPS data from the image's EXIF data
    # Uses `exifr` gem: https://github.com/remvee/exifr
    #
    logger.info "Extracting GPS data from #{file_path}"
    gps = EXIFR::JPEG.new(file_path).gps
    return [gps.latitude, gps.longitude]

  # Ignore errors unless operating in strict mode
  #
  rescue StandardError => ex
    return nil unless strict
    raise ex

  end

  # Provides logged output and exceptions for ensuring a file is actually JPEG
  #
  # @param file_path [String] Path of the file to verify
  # @return [Boolean] Indication of whether the file contains JPEG data
  #
  def ensure_jpg(file_path)

    # Guard statement to check validity of JPEG mime type
    #
    return true if jpg?(file_path)

    # Handle error state based on strict mode
    #
    message = "Path is not a valid JPEG file: #{file_path}"
    if strict
      logger.fatal message
      raise ExtractionError
    else
      logger.info message
      return false
    end

  end

  # Helper method for verifying MIME type of a JPEG file
  #
  # @param file_path [String] Path of the file to verify
  # @return [Boolean] Indication of whether the file contains JPEG data
  #
  def jpg?(file_path)
    MimeMagic.by_path(file_path)&.type == 'image/jpeg'
  end

end
