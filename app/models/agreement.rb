class Agreement < ActiveRecord::Base
  has_one :job_listing
  belongs_to :company
  belongs_to :admin
end
