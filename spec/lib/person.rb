class Person < ActiveRecord::Base
  has_many :orders, :as => :recipient
end

class CreatePeople < ActiveRecord::Migration
  def self.up
    create_table :people do |t|
      t.string :name
    end
  end
  
  def self.down
    drop_table :people
  end
end
