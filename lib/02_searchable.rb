require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    cols = params.keys.map(&:to_s)
    values = params.values.map(&:to_s)
    search = []
    cols.each_with_index do |el, i|
      search << el
      search[i] += " = ?"
    end
    search = search.join(' AND ')
    result = DBConnection.execute(<<-SQL, *values)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{search}
      SQL
    obj = self.parse_all(result)
    obj
  end
end

class SQLObject
  extend Searchable
  # Mixin Searchable here...
end
