class Order < ActiveRecord::Base
  belongs_to :ship_method
  belongs_to :cart
  belongs_to :recipient, :polymorphic => true
end

class CreateOrders < ActiveRecord::Migration
  def self.up
    create_table :orders do |t|
      t.integer :ship_method_id
      t.binary  :frozen_ship_method
      t.binary  :cart_id
      t.integer :recipient_id
      t.string  :recipient_type
      t.binary  :frozen_recipient
    end
  end
  
  def self.down
    drop_table :orders
  end
end
