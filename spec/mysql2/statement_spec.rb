# encoding: UTF-8
require 'spec_helper'

describe Mysql2::Statement do
  before :each do
    @client = Mysql2::Client.new DatabaseCredentials['root']
  end

  it "should create a statement" do
    statement = nil
    lambda { statement = @client.prepare 'SELECT 1' }.should_not raise_error
    statement.should be_kind_of Mysql2::Statement
  end

  it "should raise an exception when server disconnects" do
    @client.close
    lambda { @client.prepare 'SELECT 1' }.should raise_error(Mysql2::Error)
  end

  it "should tell us the param count" do
    statement = @client.prepare 'SELECT ?, ?'
    statement.param_count.should == 2

    statement2 = @client.prepare 'SELECT 1'
    statement2.param_count.should == 0
  end

  it "should tell us the field count" do
    statement = @client.prepare 'SELECT ?, ?'
    statement.field_count.should == 2

    statement2 = @client.prepare 'SELECT 1'
    statement2.field_count.should == 1
  end

  it "should let us execute our statement" do
    statement = @client.prepare 'SELECT 1'
    statement.execute.should == statement
  end

  it "should raise an exception without a block" do
    statement = @client.prepare 'SELECT 1'
    statement.execute
    lambda { statement.each }.should raise_error
  end

  it "should let us iterate over results" do
    statement = @client.prepare 'SELECT 1'
    statement.execute
    rows = []
    statement.each { |row| rows << row }
    rows.should == [[1]]
  end

  it "should select dates" do
    statement = @client.prepare 'SELECT NOW()'
    statement.execute
    rows = []
    statement.each { |row| rows << row }
    rows.first.first.should be_kind_of Time
  end

  it "should tell us about the fields" do
    statement = @client.prepare 'SELECT 1 as foo, 2'
    statement.execute
    list = statement.fields
    list.length.should == 2
    list.first.should == 'foo'
    list[1].should == '2'
  end

  it "should pass in nil parameters" do
    statement = @client.prepare 'SELECT * FROM (SELECT 1 as foo, 2) bar WHERE foo = ?'
    statement.execute(nil).should == statement
  end

  it "should pass in Bignum parameters" do
    statement = @client.prepare 'SELECT * FROM (SELECT 1 as foo, 2) bar WHERE foo = ?'
    (lambda{ statement.execute(723623523423323223123) }).should raise_error(RangeError)
  end

  it "should pass in Float parameters" do
    statement = @client.prepare 'SELECT * FROM (SELECT 2.3 as foo, 2) bar WHERE foo = ?'
    statement.execute(2.4).should == statement
  end

  it "should pass in String parameters" do
    statement = @client.prepare 'SELECT * FROM (SELECT "foo" as foo, 2) bar WHERE foo = ?'
    statement.execute("blah").should == statement
  end

  it "should pass in Time parameters" do
    statement = @client.prepare 'SELECT * FROM (SELECT CURRENT_TIMESTAMP() as foo, 2) bar WHERE foo = ?'
    statement.execute(Time.now).should == statement
  end

  it "should pass in DateTime parameters" do
    statement = @client.prepare 'SELECT * FROM (SELECT CURRENT_TIMESTAMP() as foo, 2) bar WHERE foo = ?'
    statement.execute(DateTime.now).should == statement
  end

  it "should pass in Date parameters" do
    statement = @client.prepare 'SELECT * FROM (SELECT CURRENT_DATE() as foo, 2) bar WHERE foo = ?'
    statement.execute(Date.today)
  end
end
