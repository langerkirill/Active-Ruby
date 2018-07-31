require 'byebug'
require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @syms if @syms
    names = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    first = names[0].clone
    @syms = first.map {|name| name.intern}
    @syms
  end

  def self.finalize!
    self.columns.each do |col|
      define_method(col) do
        self.attributes[col]
      end

      define_method("#{col}=") do |value|
        self.attributes[col] = value
      end
    end
  end

  def self.table_name=(table_name)
  end

  def self.table_name
    self.name.downcase + "s"
  end

  def self.all
    all = DBConnection.execute(<<-SQL)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
    SQL
    parse_all(all)
  end

  def self.parse_all(results)
    objects = []
    results.each do |result|
      instance = self.new
      result.each do |k, v|
        instance.send("#{k}=", v)
      end
      objects.push(instance)
      instance.save
    end
    objects
  end

  def self.find(id)
    find_me = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id IS ?
    SQL
    cat = self.parse_all(find_me)
    cat.first
  end

  def initialize(params = {})
    params.each do |pkey, val|
      skey = pkey.to_sym
      if self.class.columns.include?(skey)
        self.send("#{skey}=", val)
      else
        raise "unknown attribute '#{pkey}'"
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    @attributes.values
  end

  def insert
    insert_me = attribute_values
    cols = self.class.columns.map do |col|
      col if col != :id
    end.compact
    questions = (['?'] * cols.length).join(', ')
    cols = cols.join(", ")
    DBConnection.execute(<<-SQL, *insert_me)
      INSERT INTO
        #{self.class.table_name} (#{cols})
      VALUES
        (#{questions})
      SQL
      last_id = DBConnection.last_insert_row_id
      self.id = last_id
  end

  def update
    cols = self.class.columns.map do |col|
      "#{col} = ?"
    end.compact
    id = self.id
    values = attribute_values
    values = values.drop(1)
    cols = cols.drop(1)
    cols = cols.join(', ')
    DBConnection.execute(<<-SQL, *values)
      UPDATE
        #{self.class.table_name}
      SET
        #{cols}
      WHERE
        id = #{id}
      SQL
  end

  def save
    # ...
  end
end
