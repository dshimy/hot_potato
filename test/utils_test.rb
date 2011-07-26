require 'helper'

class UtilsTest < Test::Unit::TestCase
  
  def test_process_alive
    pid = Process.pid
    assert Process.alive?(pid)
  end
  
  def test_clasify
    assert_equal "MyTask", classify("my_task")
    assert_equal "Mytask", classify("mytask")
    assert_equal "MyTask", classify("MyTask")
    
  end

  def test_underscore
    assert_equal "my_task", underscore("MyTask")
    assert_equal "mytask", underscore("Mytask")
    assert_equal "my_task", underscore("my_task")
  end
  
end