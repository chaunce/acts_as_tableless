class UserColor < ActiveRecord::Base
  belongs_to :user
  belongs_to :color
  attr_accessible :user_id, :color_id
end
