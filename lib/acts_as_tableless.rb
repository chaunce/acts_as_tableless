module ActsAsTableless
  def self.included(base)
    base.extend ActiveRecordMethods
  end

  module ActiveRecordMethods
    def acts_as_tableless
      class << self
        def table_name
          self.name.tableize
        end

        def columns()
          @columns ||= [];
        end

        def column(name, sql_type = nil, default = nil, null = true)
          columns << ActiveRecord::ConnectionAdapters::Column.new( name.to_s, default, sql_type.to_s, null )
        end

        def columns_hash
          @columns_hash ||= Hash[columns.map{|column| [column.name, column]}]
        end

        def column_names
          @column_names ||= columns.map{|column| column.name}
        end

        def column_defaults
          @column_defaults ||= columns.map{|column| [column.name, nil]}.inject({}){|m, e| m[e[0]] = e[1] ; m}
        end

        def descends_from_active_record?
          true
        end
        
        def all
          ActsAsTableless.class_variable_get(:"@@#{self.name.underscore}")
        end
        
        def find(id)
          ActsAsTableless.class_variable_get(:"@@#{self.name.underscore}").select{|record| record.id == id}.first
        end
        
        def delete(ids)
          ids = [ids] unless ids.is_a?(Array)
          # this might be able to be inproved
          ids.each do |id|
            find(id).delete
          end
        end
        
        def exists?(id)
          find(id).nil? ? false : true
        end
      end
      ActsAsTableless.class_variable_set(:"@@#{self.name.underscore}", [])
      ActsAsTableless.class_variable_set(:"@@#{self.name.underscore}_increment", 0)
      include InstanceMethods
    end
  end
  
  module InstanceMethods
    def persisted?
      false
    end
    
    def readonly?
      true
    end

    def save(validate = true)
      self.id ||= ActsAsTableless.class_variable_set(:"@@#{self.class.name.underscore}_increment", (ActsAsTableless.class_variable_get(:"@@#{self.class.name.underscore}_increment") + 1))
      raise "Duplicate ID" if self.class.send(:find, self.id) # these are read only
      if validate ? valid? : true
        ActsAsTableless.class.class_variable_set(:"@@#{self.class.name.underscore}", ActsAsTableless.class_variable_get(:"@@#{self.class.name.underscore}").push(self))
        return self
      end
    end
    
    def delete
      ActsAsTableless.class.class_variable_set(ActsAsTableless.class_variable_get(:"@@#{self.class.name.underscore}").delete(self))
      return true
    end
    
    alias :save! :save
    alias :delete! :delete
  end
end

ActiveRecord::Base.send :include, ActsAsTableless

module ActiveRecord
  module Associations
    module ClassMethods
      alias :active_record_has_many :has_many
      alias :active_record_has_one :has_one
      alias :active_record_belongs_to :belongs_to
      alias :active_record_has_and_belongs_to_many :has_and_belongs_to_many

      def has_many(association_id, options = {}, &extension)
        active_record_has_many(association_id, options, &extension)
        class_variable_name = association_id.to_s.singularize
        if class_variable_name.camelize.constantize.send(:included_modules).include?(ActsAsTableless) # || ActsAsTableless.class_variables.include?(:"@@#{class_variable_name}")
          association_class = class_variable_name.camelize.constantize rescue nil
          if options.include?(:through)
            define_method(association_id.to_s) do
              through_objects = self.send(options[:through])
              records = if through_objects.nil?
                []
              else
                through_objects = [through_objects] unless through_objects.is_a?(Array)
                through_association_id = [:has_one, :belongs_to].include?( options[:through].to_s.singularize.camelize.constantize.reflect_on_all_associations.select{ |associations| associations.name.to_s == class_variable_name }.first.macro ) ? association_id.to_s.singularize.to_sym : association_id
                through_objects.collect{|object| object.send(through_association_id) }.flatten
              end

              records.instance_variable_set(:@parent, self)
              records.instance_variable_set(:@options, options)
              records.instance_variable_set(:@association_class, association_class)
              def records.<<(associated_records)
                associated_records = [associated_records] unless associated_records.is_a?(Array)
                case @parent.class.reflect_on_all_associations.select{|association| association.name == @options[:through]}.first.macro
                when :has_many
                  associated_records.each do |associated_record|
                    raise ActiveRecord::AssociationTypeMismatch, "#{@association_class.name} expected, got #{associated_record.inspect}" unless @association_class.name == associated_record.class.name
                    @parent.send(@options[:through]).send(:new, "#{@association_class.name.underscore}_id".to_sym => associated_record.id)
                  end
                when :has_one
                  # not yet implemented
                  []
                when :belongs_to
                  # not yet implemented
                  []
                when :has_and_belongs_to_many
                  # not yet implemented
                  []
                end
                self
              end
              # def records.create(attributes = nil, options = {})
              #   if attributes.is_a?(Array)
              #     attributes.collect { |record_attributes| create(record_attributes, options) }
              #   else
              #     record = new(attributes, options)
              #     record.save
              #     record
              #   end
              # end

              return records
            end
          else
            define_method(association_id.to_s) do
              records = association_class.all.select{|record| record.send("#{self.class.name.underscore}_id") == self.id}
              
              records.instance_variable_set(:@parent, self)
              records.instance_variable_set(:@association_class, association_class)
              def records.create(attributes)
                new_record = @association_class.new(attributes)
                new_record.send("#{@parent.class.name.underscore}_id=", @parent.id)
                new_record.save
                return new_record
              end
              
              return records
            end
          end
        end
      end

      def has_one(association_id, options = {})
        active_record_has_one(association_id, options)
        class_variable_name = association_id.to_s.singularize
        if class_variable_name.camelize.constantize.send(:included_modules).include?(ActsAsTableless) # || ActsAsTableless.class_variables.include?(:"@@#{class_variable_name}")
          association_class = class_variable_name.camelize.constantize rescue nil
          if options.include?(:through)
            define_method(association_id.to_s) do
              through_object = self.send(options[:through])
              return nil if through_object.nil?
              association_class.find(through_object.send("#{association_class.name.underscore}_id"))
            end
          else
            define_method(association_id.to_s) do
              association_class.all.select{|record| record.send("#{self.class.name.underscore}_id") == self.id}.first
            end
          end
        end
      end

      def belongs_to(association_id, options = {})
        active_record_belongs_to(association_id, options)
        class_variable_name = association_id.to_s.singularize
        if class_variable_name.camelize.constantize.send(:included_modules).include?(ActsAsTableless) # || ActsAsTableless.class_variables.include?(:"@@#{class_variable_name}")
          association_class = class_variable_name.camelize.constantize rescue nil
          define_method(association_id.to_s) do
            association_class.all.select{|record| record.id == self.send("#{association_class.name.underscore}_id")}.first
          end
        end
      end

      def has_and_belongs_to_many(association_id, options = {}, &extension)
        active_record_has_and_belongs_to_many(association_id, options, &extension)
        class_variable_name = association_id.to_s.singularize
        if class_variable_name.camelize.constantize.send(:included_modules).include?(ActsAsTableless) # || ActsAsTableless.class_variables.include?(:"@@#{class_variable_name}")
          association_class = class_variable_name.camelize.constantize rescue nil
          # not yet implemented, may never be
          define_method(association_id.to_s) do
            []
          end
        end
      end
    end
  end
end
