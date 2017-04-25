require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  # A module which will include ActiveRecord method where()
  def where(params)
    where_line = params.map { |k, v| "#{k} = ?"}.join(" AND ")

    results = DBConnection.execute(<<-SQL, *params.values)
      SELECT *
      FROM #{table_name}
      WHERE #{where_line}
    SQL

    # allows us to parse an object and maintain all original formats
    parse_all(results)
  end
end

class SQLObject
  extend Searchable
end
