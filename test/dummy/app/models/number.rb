class Number < ActiveRecord::Base
  acts_as_tableless
  column :id, :integer
  column :name, :string
  attr_accessible :id, :name
  
  has_many :users
end