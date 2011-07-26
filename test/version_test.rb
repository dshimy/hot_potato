require 'helper'

class VersionTest < Test::Unit::TestCase
  
  def test_version
    assert_not_nil HotPotato::VERSION
  end
  
end