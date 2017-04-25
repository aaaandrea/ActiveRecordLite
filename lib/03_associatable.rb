require_relative '02_searchable'
require 'active_support/inflector'
# inflector includes the use of String#camalecase, #singularize, and #underscore


class AssocOptions
  # include module Associatable
  attr_accessor :foreign_key, :class_name, :primary_key

  def model_class
    # This gets the target model class
    @class_name.constantize
  end

  def table_name
    # This returns the name of the table
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  #provide default values for belongs to functionality
  def initialize(name, options = {})
    defaults = {
      foreign_key: "#{name}_id".to_sym,
      class_name: name.to_s.camelcase,
      primary_key: :id
    }

    defaults.keys.each do |key|
      self.send("#{key}=", options[key] || defaults[key] )
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    options[:foreign_key] ||= "#{self_class_name.to_s.downcase.singularize.underscore}_id".to_sym
    options[:primary_key] ||= :id
    options[:class_name] ||= name.to_s.singularize.camelize
    options.each do |key, value|
      send("#{key}=", value)
    end
  end
end

module Associatable
  # Extension for Associations
  def belongs_to(name, options = {})
    # returns nil if no assiated object
    # self.class.assoc_options = {}

    self.assoc_options[name] = BelongsToOptions.new(name, options)

    define_method(name) do
      options = self.class.assoc_options[name]

      key_val = self.send(options.foreign_key)
      options
        .model_class
        .where(options.primary_key => key_val)
        .first
    end
  end

  def has_many(name, options = {})
    self.assoc_options[name] =
      HasManyOptions.new(name, self.name, options)

    define_method(name) do
      options = self.class.assoc_options[name]

      key_val = self.send(options.primary_key)
      options
        .model_class
        .where(options.foreign_key => key_val)
    end
  end

  def assoc_options
    @assoc_options ||= {}
    @assoc_options
  end
end

class SQLObject
  extend Associatable
end
