# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/gps_exif_extractor'

class TestGpsExifExtractor < Minitest::Test

  def test_init_with_verbose_mode
    assert GpsExifExtractor.new(verbose: true).verbose
  end

end
