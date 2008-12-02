require File.dirname(__FILE__) + '/spec_helper.rb'

describe CsvMapper::RowMap do
  
  class TestMapToClass
    attr_accessor :foo, :bar, :baz
  end
  
  class TestMapContext
    def transform(row)
      :transform_success
    end
    
    def change_name(row, target)
      row[0] = :changed_name
    end
  end
  
  before(:each) do
    @row_map = CsvMapper::RowMap.new(TestMapContext.new)
    @csv_row = ['first_name', 'last_name']
  end

  it "should parse a CSV row" do
    @row_map.parse(@csv_row).should_not be_nil
  end

  it "should map to a OpenStruct by default" do
    @row_map.parse(@csv_row).should be_instance_of OpenStruct
  end
  
  it "should parse a CSV row returning the mapped result" do
    @row_map.fname
    @row_map.lname
    
    result = @row_map.parse(@csv_row)
    result.fname.should eql @csv_row[0]
    result.lname.should eql @csv_row[1]
  end

  it "should map to a ruby class with optional default attribute values" do
    @row_map.map_to TestMapToClass, :baz => :default_baz
    
    @row_map.foo
    @row_map.bar
    
    (result = @row_map.parse(@csv_row)).should be_instance_of TestMapToClass
    result.foo.should eql @csv_row[0]
    result.bar.should eql @csv_row[1]
    result.baz.should eql :default_baz
  end
    
  it "should start at the specified CSV row" do
    @row_map.start_at_row.should be 0
    @row_map.start_at_row 1
    @row_map.start_at_row.should be 1
  end
  
  it "should allow before row processing" do
    @row_map.before_row :change_name, lambda{|row, target| row[1] = 'bar'}
    
    @row_map.first_name
    @row_map.foo
    
    result = @row_map.parse(@csv_row)
    result.first_name.should eql :changed_name
    result.foo.should_not equal 'bar'
  end
  
  it "should allow after row processing" do
    @row_map.after_row lambda{|row, target| target.bam = :woot}
    
    @row_map.parse(@csv_row).bam.should eql :woot
  end
  
  it "should have a moveable cursor" do
    @row_map.cursor.should be 0
    @row_map.move_cursor
    @row_map.cursor.should be 1
    @row_map.move_cursor 3
    @row_map.cursor.should be 4
  end
  
  it "should skip indexes" do
    pre_cursor = @row_map.cursor
    @row_map._SKIP_
    @row_map.cursor.should be(pre_cursor + 1)
  end
  
  it "should maintain a collection of attribute mappings" do
    @row_map.attributes.should be_kind_of Enumerable
  end
  
  it "should lazy initialize attribute maps and move the cursor" do
    pre_cursor = @row_map.cursor
    (attr_map = @row_map.first_name).should be_instance_of CsvMapper::AttributeMap
    attr_map.index.should be pre_cursor
    @row_map.cursor.should be (pre_cursor + 1)
  end
  
  it "should lazy initialize attribute maps with optional cursor position" do
    pre_cursor = @row_map.cursor
    @row_map.last_name(1).index.should be 1
    @row_map.cursor.should be 1
  end
  
  it "should share it context with its mappings" do
    @row_map.first_name.map(:transform)
    @row_map.parse(@csv_row).first_name.should eql :transform_success
  end
end