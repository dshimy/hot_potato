module Process
  
  # Return true if the process is still running, false otherwise.
  def self.alive?(pid)
    begin
      Process.getpgid(pid)
      return true
    rescue Errno::ESRCH
      return false
    end
  end
  
end

module Kernel
  
  # Taken from Rails ActiveSupport::Inflector
  def classify(name)
    # strip out any leading schema name
    camelize(name.to_s.sub(/.*\./, ''))
  end
  
  # Taken from Rails ActiveSupport::Inflector
  def camelize(lower_case_and_underscored_word, first_letter_in_uppercase = true)
    if first_letter_in_uppercase
      lower_case_and_underscored_word.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    else
      lower_case_and_underscored_word.to_s[0].chr.downcase + camelize(lower_case_and_underscored_word)[1..-1]
    end
  end
  
  # Taken from Rails ActiveSupport::Inflector
  def underscore(camel_cased_word)
    word = camel_cased_word.to_s.dup
    word.gsub!(/::/, '/')
    word.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
    word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
    word.tr!("-", "_")
    word.downcase!
    word
  end
  
end