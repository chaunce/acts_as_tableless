class Shape < ActiveRecord::Base
  acts_as_tableless
  column :id, :integer
  column :name, :string
  column :user_id, :integer
  attr_accessible :id, :name, :user_id
  
  belongs_to :user
end