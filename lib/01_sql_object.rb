require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @columns if @columns
    columns = DBConnection.execute2(<<-SQL).first
      SELECT *
      FROM #{table_name}
    SQL
    @columns = columns.map(&:to_sym)
  end

  def self.finalize!
    #creates setter and getter methods for each column
    columns.each do |col|
      # col = col.to_s
      define_method(col) do
        self.attributes[col]
      end

      define_method("#{col}=") do |val|
        self.attributes[col] = val
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.name.underscore.pluralize
  end

  def self.all
    rows = DBConnection.execute(<<-SQL)
      SELECT #{table_name}.*
      FROM #{table_name}
    SQL

    parse_all(rows)
  end

  def self.parse_all(results)
    results.map { |result| self.new(result) }
  end

  def self.find(id)
    self.all.find { |obj| obj.id == id }
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym

      if self.class.columns.include?(attr_name)
        self.send("#{attr_name}=", value)
      else
        raise "unknown attribute '#{attr_name}'"
      end

    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    #returns an array of the values for each attribute; uses send on instance to get value.
    self.class.columns.map { |k| self.send(k) }
  end

  def insert
    #set @columns to array and drop one so you don't include id.
    columns = self.class.columns.drop(1)

    #set both columns and question marks to joined string so they are usable in SQL
    col_names = columns.map(&:to_s).join(', ')
    question_marks = (['?'] * columns.length).join(', ')

    #execute database and pass it attribute values (leaving off id again)
    DBConnection.execute(<<-SQL, *attribute_values.drop(1))
      INSERT INTO #{self.class.table_name} (#{col_names})
      VALUES (#{question_marks})

    SQL

    #database inserts a record and assigns record id in self.
    #uses method set in DBConnection
    self.id = DBConnection.last_insert_row_id
  end

  def update
    #update record's attributes
    columns = self.class.columns.map { |k| "#{k} = ?" }.join(", ")

    #execute database and pass it attribute values (leaving off id again)
    DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE #{self.class.table_name}
      SET #{columns}
      WHERE #{self.class.table_name}.id = ?
    SQL

  end

  def save
    #calls #insert when record does not exist
    id.nil? ? insert : update
  end
end
