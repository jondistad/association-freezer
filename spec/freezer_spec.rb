require File.dirname(__FILE__) + '/spec_helper'

describe Order do
  it "respond to enable_association_freezer" do
    Order.should respond_to(:enable_association_freezer)
  end
  
  describe "with freezer" do
    before(:each) do
      Order.enable_association_freezer
      @order = Order.new
    end
    
    it "should add a freeze association method" do
      @order.should respond_to(:freeze_ship_method)
    end
  
    it "should add an unfreeze association method" do
      @order.should respond_to(:unfreeze_ship_method)
    end
  
    it "should not add freeze/unfreeze methods to cart association since it doesn't have a frozen column" do
      @order.should_not respond_to(:freeze_cart)
      @order.should_not respond_to(:unfreeze_cart)
    end
    
    it "should not be frozen at first" do
      @order.ship_method = ShipMethod.create!
      @order.ship_method(true).should_not be_frozen
    end
    
    it "should freeze association in its current state" do
      ship_method = ShipMethod.create!(:price => 2)
      @order.ship_method = ship_method
      ship_method.price = 3
      @order.freeze_ship_method
      @order.ship_method.price.should == 3
    end
    
    it "should do nothing when attempting to freeze a nil association" do
      @order.ship_method.should be_nil
      lambda { @order.freeze_ship_method }.should_not raise_error
      @order.ship_method.should be_nil
    end
    
    describe "when freezing association" do
      before(:each) do
        @ship_method = ShipMethod.create!(:price => 5)
        @order.ship_method = @ship_method
        @order.freeze_ship_method
      end
      
      it "should freeze associated model" do
        @order.ship_method.should be_frozen
      end
      
      it "should not freeze original object" do
        @ship_method.should_not be_frozen
      end
      
      it "should still consider model frozen after reloading association" do
        @order.ship_method(true).should be_frozen
      end
      
      it "should ignore changes to associated model" do
        @ship_method.update_attribute(:price, 8)
        @order.ship_method.price.should == 5
        @order.ship_method(true).price.should == 5
      end
      
      it "should be frozen after reloading order" do
        @order.save!
        @order.reload
        @order.ship_method.should be_frozen
      end
      
      it "should not be frozen when unfreezing" do
        @order.unfreeze_ship_method
        @order.ship_method.should_not be_frozen
      end
      
      it "should restore original attributes when unfreezing" do
        @ship_method.update_attribute(:price, 8)
        @order.unfreeze_ship_method
        @order.ship_method.price.should == 8
      end
      
      it "should raise an exception when attempting to save associated model" do
        lambda { @order.ship_method.save }.should raise_error
        lambda { @order.ship_method.save! }.should raise_error
      end
      
      it "should raise an exception when attempting to replace association" do
        lambda { @order.ship_method = ShipMethod.new }.should raise_error
      end
      
      it "should keep id attribute for association" do
        @order.ship_method.id.should == @ship_method.id
      end
      
      it "should not consider association a new record" do
        @order.ship_method.should_not be_new_record
      end
    end

    describe "when loading the frozen association" do
      before do
        @ship_method = ShipMethod.new
        @ship_method.address = "123 Main St"
        @ship_method.save!
        @order = Order.create!(:ship_method => @ship_method)
      end

      it "should properly load protected attributes" do
        ShipMethod.instance_eval { attr_protected :address }
        @order.ship_method.address.should == "123 Main St"
        @order.freeze_ship_method
        @order.ship_method.address.should == "123 Main St"
      end

      it "should properly load implicitly protected attributes" do
        ShipMethod.write_inheritable_attribute(:attr_protected, nil)
        ShipMethod.instance_eval { attr_accessible :price }
        @order.ship_method.address.should == "123 Main St"
        @order.freeze_ship_method
        @order.ship_method.address.should == "123 Main St"
      end

      it "should skip invalid attributes" do
        @order.frozen_ship_method = Marshal.dump({ 'invalid_attribute' => 'foo' })
        lambda { @order.ship_method }.should_not raise_error
      end
    end

    describe "when loading a polymorphic association" do
      it "should derive the reflection class from the association_type column" do
        @person = Person.create!(:name => "Bob")
        @order = Order.create!(:recipient => @person)
        @order.recipient.should be_a(Person)
        @order.freeze_recipient
        @order.recipient.should be_a(Person)
        @order.recipient.name.should == "Bob"
      end
    end
  end
end
