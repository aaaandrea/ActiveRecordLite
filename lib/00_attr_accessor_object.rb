# One of the many strengths of ruby is it's ability for 'reflection'.
# This means ruby can read information about a class or object at rubtime
# and use any new information to help program itself. This is called metaprogramming.
# Some key methods for this are: class(), instance_methods(),
# instance_variables(), send(), and define_method()

# below we use define_ethod to degine the getter and setter methods.

class AttrAccessorObject
  def self.my_attr_accessor(*names)
    names.each do |name|

      define_method(name) do
        instance_variable_get("@#{name}")
      end

      define_method("#{name}=") do |val|
        instance_variable_set("@#{name}", val)
      end

    end
  end
end
