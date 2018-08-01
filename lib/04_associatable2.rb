require_relative '03_associatable'

module Associatable

  def has_one_through(name, through_name, source_name)
    options = {}
    options[name] = BelongsToOptions.new(name)
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options =
      through_options.model_class.assoc_options[source_name]
      through_key = self.send(through_options.foreign_key)
      source_options
              .model_class
              .where(source_options.primary_key => through_key).first
    end
  end
end
