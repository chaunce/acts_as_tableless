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
      end
      ActsAsTableless.class_variable_set(:"@@#{self.name.underscore}", [])
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
      if validate ? valid? : true
        ActsAsTableless.class.class_variable_set(:"@@#{self.class.name.underscore}", ActsAsTableless.class_variable_get(:"@@#{self.class.name.underscore}").push(self))
      end
    end
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
        if ActsAsTableless.class_variables.include?(:"@@#{class_variable_name}")
          association_class = class_variable_name.camelize.constantize rescue nil
          if options.include?(:through)
            define_method(association_class.name.pluralize.underscore) do
              through_objects = self.send(options[:through])
              records = if through_objects.nil?
                []
              else
                through_objects = [through_objects] unless through_objects.is_a?(Array)
                through_objects.collect{|object| association_class.find(object.send("#{association_class.name.underscore}_id")) }
              end

              records.instance_variable_set(:@parent, self)
              records.instance_variable_set(:@options, options)
              records.instance_variable_set(:@association_class, association_class)
              def records.<<(associated_records)
                case @parent.class.reflect_on_all_associations.select{|association| association.name == @options[:through]}.first.macro
                when :has_many
                  associated_records = [associated_records] unless associated_records.is_a?(Array)
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
                @parent.roles
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
            define_method(association_class.name.pluralize.underscore) do
              association_class.all.select{|record| record.send("#{self.class.name.underscore}_id") == self.id}
            end
          end
        end
      end

      def has_one(association_id, options = {})
        active_record_has_one(association_id, options)
        class_variable_name = association_id.to_s.singularize
        if ActsAsTableless.class_variables.include?(:"@@#{class_variable_name}")
          association_class = class_variable_name.camelize.constantize rescue nil
          if options.include?(:through)
            define_method(association_class.name.pluralize.underscore) do
              through_object = self.send(options[:through])
              return nil if through_object.nil?
              association_class.find(through_object.send("#{association_class.name.underscore}_id"))
            end
          else
            define_method(association_class.name.pluralize.underscore) do
              association_class.all.select{|record| record.send("#{self.class.name.underscore}_id") == self.id}.first
            end
          end
        end
      end

      def belongs_to(association_id, options = {})
        active_record_belongs_to(association_id, options)
        class_variable_name = association_id.to_s.singularize
        if ActsAsTableless.class_variables.include?(:"@@#{class_variable_name}")
          association_class = class_variable_name.camelize.constantize rescue nil
          define_method(association_class.name.underscore) do
            association_class.find(self.send("#{association_class.name.underscore}_id"))
          end
        end
      end

      def has_and_belongs_to_many(association_id, options = {}, &extension)
        active_record_has_and_belongs_to_many(association_id, options, &extension)
        class_variable_name = association_id.to_s.singularize
        if ActsAsTableless.class_variables.include?(:"@@#{class_variable_name}")
          association_class = class_variable_name.camelize.constantize rescue nil
          # not yet implemented
          []
        end
      end
    end
  end
end