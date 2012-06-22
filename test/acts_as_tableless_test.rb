require 'test_helper'

class ActsAsTablelessTest < ActiveSupport::TestCase
  def setup
    build_tableless_objects
  end
  
  test "acts_as_tableless_active_record_methods" do
    tabless_models = [HasManyTablelessObject]
    
    tabless_models.each do |tabless_model|
      assert tabless_model.table_name
      assert tabless_model.columns.any?
      assert tabless_model.columns_hash
      assert tabless_model.column_names
      assert tabless_model.column_defaults
      assert tabless_model.descends_from_active_record?
      assert tabless_model.all
      
      tableless_object = tabless_model.all.select{|object|object.id == 1}.first
      assert !tableless_object.persisted?
      assert !tableless_object.readonly?
      assert_equal "default", tableless_object.test
      tableless_object.test = "update"
      tableless_object.save!
      assert_equal "update", tableless_object.test
    end
  end
  
  test "acts_as_tableless_active_record_association_has_many" do
    assert_equal HasManyTablelessObject.all.select{|o|o.active_record_modle_with_association_id = @active_record_modle_with_association.id}.count, @active_record_modle_with_association.has_many_tableless_objects.count
  end
  
  test "acts_as_tableless_active_record_association_has_one" do
    # not yet tested
    assert true
  end
  
  test "acts_as_tableless_active_record_association_belongs_to" do
    # not yet tested
    assert true
  end
  
  test "acts_as_tableless_active_record_association_has_and_belongs_to_many" do
    # not yet tested
    assert true
  end
  
  test "acts_as_tableless_active_record_validations" do
    # not yet tested
    assert true
  end
  
  def build_tableless_objects
    @active_record_modle_with_association = ActiveRecordModleWithAssociation.create(id: 1, name: 'default')
    
    HasManyTablelessObject.create([
      {id: 1, test: 'default', active_record_modle_with_association_id: @active_record_modle_with_association.id},
      {id: 2, test: 'default', active_record_modle_with_association_id: @active_record_modle_with_association.id},
      {id: 3, test: 'default', active_record_modle_with_association_id: @active_record_modle_with_association.id},
      {id: 4, test: 'default', active_record_modle_with_association_id: @active_record_modle_with_association.id},
      {id: 5, test: 'default', active_record_modle_with_association_id: @active_record_modle_with_association.id}, 
    ])
  end
end
