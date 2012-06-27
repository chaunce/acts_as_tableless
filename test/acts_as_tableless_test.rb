require 'test_helper'

class ActsAsTablelessTest < ActiveSupport::TestCase
  def setup
    build_users
    
    @user = @user_one
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
    assert @user.present?
    assert @user.shapes.present?
    assert_equal 2, @user.shapes.count
    assert ["Circle", "Square"].sort.eql?(@user.shapes.collect(&:name).sort)
    
    @user.shapes.create(:name => "Octagon")
    assert_equal 3, @user.shapes.count
    assert ["Circle", "Octagon", "Square"].sort.eql?(@user.shapes.collect(&:name).sort)
  end
  
  test "has_many_through" do
    # has_many :user_colors
    # has_many :colors, :through => :user_colors
    build_colors
    build_user_colors
    assert @user
    assert @user.user_colors
    assert @user.colors
    assert_equal 3, @user.colors.count
    assert ["Blue", "Purple", "Red"].sort.eql?(@user.colors.collect(&:name).sort)
    
    @user.colors << Color.all.select{|c|c.name == "Green"}
    assert ["Blue", "Green", "Purple", "Red"].sort.eql?(@user.colors.collect(&:name).sort)
    
    @user.colors.create(:name => "Orange")
    assert ["Blue", "Green", "Orange", "Purple", "Red"].sort.eql?(@user.colors.collect(&:name).sort)
    
    @user.colors = Color.all.select{|c| ["Yellow", "Blue"].include?(c.name)}
    assert ["Blue", "Yellow"].sort.eql?(@user.colors.collect(&:name).sort)
  end

  test "has_one_association" do
    # has_one :size
    build_sizes
    assert @user
    assert @user.size
    assert_equal "Small", @user.size.name
    assert Size.all.collect(&:name).include?("Small")
    assert !Size.all.collect(&:name).include?("X-Large")
    
    @user.size.create(:name => "X-Large")
    assert_equal "X-Large", @user.size.name
    assert Size.all.collect(&:name).include?("X-Large")
    assert !Size.all.collect(&:name).include?("Small")
  end

  test "belongs_to_association" do
    # belongs_to :number
    build_numbers
    assert @user
    assert @user.number
    assert_equal "One", @user.number.name
    
    @user.number = @@two
    @user.save
    assert_equal "Two", @user.number.name
  end

  # this is not yet implemented, and may never be; use has_many
  test "has_and_belongs_to_many_association" do
    # has_and_belongs_to_many :letters
    build_letters
    assert @user
    assert @user.letters
    # assert_equal 2, @user.letters.count
    # assert ["A", "O"].sort.eql? @user.letters.collect(&:name).sort
    
    # @user.letters.create(:name => "Z")
    # assert_equal 3, @user.letters.count
    # assert ["A", "O", "Z"].sort.eql?(@user.letters.collect(&:name).sort)
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
      @@red     = Color.create(name: "Red")
      @@yellow  = Color.create(name: "Yellow")
      @@blue    = Color.create(name: "Blue")
      @@green   = Color.create(name: "Green")
      @@purple  = Color.create(name: "Purple")
    end
  end
  
  def build_letters
    if Letter.all.none?
      build_users 
      @@a = Letter.create(name: "A", user_id: @user_one.id)
      @@e = Letter.create(name: "E", user_id: @user_two.id)
      @@i = Letter.create(name: "I", user_id: @user_three.id)
      @@o = Letter.create(name: "O", user_id: @user_one.id)
      @@u = Letter.create(name: "U", user_id: @user_two.id)
      @@y = Letter.create(name: "Y", user_id: @user_three.id)
    end
  end
  
  def build_numbers
    if Number.all.none?
      @@one   = Number.create(name: "One")
      @@two   = Number.create(name: "Two")
      @@three = Number.create(name: "Three")
      @@four  = Number.create(name: "Four")
      @@five  = Number.create(name: "Five")
      @@six   = Number.create(name: "Six")
      @@seven = Number.create(name: "Seven")
      @@eight = Number.create(name: "Eight")
      @@nine  = Number.create(name: "Nine")
      @@zero  = Number.create(name: "Zero")
    end
  end
  
  def build_shapes
    if Shape.all.none?
      build_users
      @@square    = Shape.create(name: "Square",    user_id: @user_one.id)
      @@rectangle = Shape.create(name: "Rectangle", user_id: @user_two.id)
      @@triangle  = Shape.create(name: "Triangle",  user_id: @user_three.id)
      @@circle    = Shape.create(name: "Circle",    user_id: @user_one.id)
      @@hexagon   = Shape.create(name: "Hexagon",   user_id: @user_two.id)
    end
  end
  
  def build_sizes
    if Size.all.none?
      build_users
      @@small   = Size.create(name: "Small",  user_id: @user_one.id)
      @@medium  = Size.create(name: "Meduim", user_id: @user_two.id)
      @@large   = Size.create(name: "Large",  user_id: @user_three.id)
    end
  end
  
  def build_users
    if User.all.none?
      build_numbers
      @user_one   = User.create(name: "User One",   number_id: @@one.id)
      @user_two   = User.create(name: "User Two",   number_id: @@two.id)
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
