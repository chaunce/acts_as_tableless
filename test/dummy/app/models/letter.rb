class Letter < ActiveRecord::Base
  acts_as_tableless
  column :id, :integer
  column :name, :string
  column :user_id, :integer
  attr_accessible :id, :name, :user_id
  
  has_and_belongs_to_many :users
end