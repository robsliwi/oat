module Kernel
  # Returns the object's singleton class.
  def singleton_class
    class << self
      self
    end
  end unless respond_to?(:singleton_class) # exists in 1.9.2

  # class_eval on an object acts like singleton_class.class_eval.
  def class_eval(*args, &block)
    singleton_class.class_eval(*args, &block)
  end
end

class Class
  def class_attribute(*attrs)
    attrs.each do |name|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def self.#{name}() nil end

          def self.#{name}=(val)
            singleton_class.class_eval do
              define_method(:#{name}) { val }
            end

            if singleton_class?
              class_eval do
                def #{name}
                  defined?(@#{name}) ? @#{name} : singleton_class.#{name}
                end
              end
            end
            val
          end
      RUBY

    end
  end

  private
  def singleton_class?
    ancestors.first != self
  end
end
