class Ticket < ActiveRecord::Base
  include Tickets::FromAddresses
  include Tickets::MessageProcess
  include Tickets::Overrides
  include Tickets::Validation

  belongs_to :tenant
  has_many :replies, dependent: :destroy
end
