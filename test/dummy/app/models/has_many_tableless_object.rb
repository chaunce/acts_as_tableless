class HasManyTablelessObject < ActiveRecord::Base
  acts_as_tableless
  column :id, :integer
  column :test, :string
  column :active_record_modle_with_association_id, :integer
  attr_accessible :id, :test, :active_record_modle_with_association_id
end
