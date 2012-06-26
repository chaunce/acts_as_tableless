class User < ActiveRecord::Base
  has_many :shapes
  has_many :user_colors
  has_many :colors, :through => :user_colors
  has_one :size
  belongs_to :number
  has_and_belongs_to_many :letters
  attr_accessible :name, :number_id, :letter_id
end
