class VoteableGenerator < Rails::Generator::NamedBase 

  attr_accessor :model_name
  
  def manifest 
    @model_name = class_name.underscore.singularize
    record do |m| 
      m.migration_template 'migration.rb', 'db/migrate', :migration_file_name => "acts_as_voteable_migration"
    end 
  end
end
