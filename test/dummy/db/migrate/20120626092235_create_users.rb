class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.references :number
      t.references :letter
 
      t.timestamps
    end
  end
end
