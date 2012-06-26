class Color < ActiveRecord::Base
  acts_as_tableless
  column :id, :integer
  column :name, :string
  attr_accessible :id, :name
  
  belongs_to :user_colors
end