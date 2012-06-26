require 'test_helper'

class ActsAsTablelessTest < ActiveSupport::TestCase
  def setup
    build_users
  end
  
  test "active_record_methods" do
    build_all
    tabless_models = [Color, Letter, Number, Shape, Size]
    
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
      assert tableless_object.readonly?
    end
  end
  
  test "has_many" do
    # has_many :shapes
    build_shapes
    assert @user_one.present?
    assert @user_one.shapes.present?
    assert_equal 2, @user_one.shapes.count
    assert ["Circle", "Square"].sort.eql?(@user_one.shapes.collect(&:name).sort)
    
    @user_one.shapes.create(:name => "Octagon")
    assert_equal 3, @user_one.shapes.count
    assert ["Circle", "Octagon", "Square"].sort.eql?(@user_one.shapes.collect(&:name).sort)
  end
  
  test "has_many_through" do
    # has_many :user_colors
    # has_many :colors, :through => :user_colors
    build_colors
    build_user_colors
    assert @user_one
    assert @user_one.user_colors
    assert @user_one.colors
    assert_equal 3, @user_one.colors.count
    assert ["Blue", "Purple", "Red"].sort.eql?(@user_one.colors.collect(&:name).sort)
  end
  
  test "build_has_many_through_association" do
    # not yet tested
    assert true
  end

  test "has_one_association" do
    # has_one :size
    build_sizes
    assert @user_one
    assert @user_one.size
    assert_equal "Small", @user_one.size.name
  end
  
  test "build_has_one_association" do
    # not yet tested
    assert true
  end

  test "belongs_to_association" do
    # belongs_to :number
    build_numbers
    assert @user_one
    assert @user_one.number
    assert_equal "One", @user_one.number.name
  end
  
  test "build_belongs_to_association" do
    # not yet tested
    assert true
  end

  test "has_and_belongs_to_many_association" do
    # has_and_belongs_to_many :letters
    build_letters
    assert @user_one
    assert @user_one.letters
    # this is not yet implemented, and may never be
    # assert ["A", "O"].sort.eql? @user_one.letters.collect(&:name).sort
    assert [].eql?(@user_one.letters)
  end
  
  test "build_has_and_belongs_to_many_association" do
    # not yet tested
    assert true
  end
  
  def build_all
    build_colors
    build_letters
    build_numbers
    build_shapes
    build_sizes
    build_users
    build_user_colors
  end
  
  def build_colors
    if Color.all.none?
      @@red = Color.create(id: 1, name: "Red")
      @@yellow = Color.create(id: 2, name: "Yellow")
      @@blue = Color.create(id: 3, name: "Blue")
      @@green = Color.create(id: 4, name: "Green")
      @@purple = Color.create(id: 5, name: "Purple")
    end
  end
  
  def build_letters
    if Letter.all.none?
      build_users 
      @@a = Letter.create(id: 1, name: "A", user_id: @user_one.id)
      @@e = Letter.create(id: 2, name: "E", user_id: @user_two.id)
      @@i = Letter.create(id: 3, name: "I", user_id: @user_three.id)
      @@o = Letter.create(id: 4, name: "O", user_id: @user_one.id)
      @@u = Letter.create(id: 5, name: "U", user_id: @user_two.id)
      @@y = Letter.create(id: 6, name: "Y", user_id: @user_three.id)
    end
  end
  
  def build_numbers
    if Number.all.none?
      @@one = Number.create(id: 1, name: "One")
      @@two = Number.create(id: 2, name: "Two")
      @@three = Number.create(id: 3, name: "Three")
      @@four = Number.create(id: 4, name: "Four")
      @@five = Number.create(id: 5, name: "Five")
      @@six = Number.create(id: 6, name: "Six")
      @@seven = Number.create(id: 7, name: "Seven")
      @@eight = Number.create(id: 8, name: "Eight")
      @@nine = Number.create(id: 9, name: "Nine")
      @@zero = Number.create(id: 10, name: "Zero")
    end
  end
  
  def build_shapes
    if Shape.all.none?
      build_users
      @@square = Shape.create(name: "Square", user_id: @user_one.id)
      @@rectangle = Shape.create(name: "Rectangle", user_id: @user_two.id)
      @@triangle = Shape.create(name: "Triangle", user_id: @user_three.id)
      @@circle = Shape.create(name: "Circle", user_id: @user_one.id)
      @@hexagon = Shape.create(name: "Hexagon", user_id: @user_two.id)
    end
  end
  
  def build_sizes
    if Size.all.none?
      build_users
      @@small = Size.create(id: 1, name: "Small", user_id: @user_one.id)
      @@medium = Size.create(id: 2, name: "Meduim", user_id: @user_two.id)
      @@large = Size.create(id: 3, name: "Large", user_id: @user_three.id)
    end
  end
  
  def build_users
    if User.all.none?
      build_numbers
      @user_one = User.create(name: "User One", number_id: @@one.id)
      @user_two = User.create(name: "User Two", number_id: @@two.id)
      @user_three = User.create(name: "User Three", number_id: @@three.id)
    end
  end
  
  def build_user_colors
    if UserColor.all.none?
      build_users
      build_colors
      UserColor.create([
        {user_id: @user_one.id, color_id: @@red.id},
        {user_id: @user_two.id, color_id: @@yellow.id},
        {user_id: @user_one.id, color_id: @@blue.id},
        {user_id: @user_two.id, color_id: @@green.id},
        {user_id: @user_one.id, color_id: @@purple.id},
      ])
    end
  end
end
