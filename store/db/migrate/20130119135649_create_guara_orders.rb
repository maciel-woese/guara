class CreateGuaraOrders < ActiveRecord::Migration
  def change
    create_table :guara_orders do |t|
      t.integer  :person_id
      t.integer  :order_type
      t.integer  :state
      t.datetime :date_init
      t.datetime :date_finish
      t.date     :state_date
      t.integer  :payment_type
      t.datetime :payment_date
      t.integer  :payment_state
      t.integer  :payment_parts

      t.timestamps
    end
    
    add_index :guara_orders, :state
    add_index :guara_orders, :order_type
    add_index :guara_orders, [:state, :order_type]
  end
end
