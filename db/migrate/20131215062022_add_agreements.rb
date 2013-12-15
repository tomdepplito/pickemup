class AddAgreements < ActiveRecord::Migration
  def change
    create_table :agreements, id: :uuid do |t|
      t.string  :company_id
      t.string  :job_listing_id
      t.string  :admin_id
      t.string  :contract_type
      t.string  :rate
      t.string  :documentation
      t.text    :description
      t.boolean :paid, default: false
      t.boolean :signed, default: false
      t.timestamps
    end
  end
end
