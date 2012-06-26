class CreateUserColors < ActiveRecord::Migration
  def change
    create_table :user_colors do |t|
      t.references :user
      t.references :color
 
      t.timestamps
    end
  end
end
