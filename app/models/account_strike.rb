# frozen_string_literal: true
# == Schema Information
#
# Table name: account_strikes
#
#  id         :bigint(8)        not null, primary key
#  account_id :bigint(8)        not null
#  report_id  :bigint(8)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class AccountStrike < ApplicationRecord
  belongs_to :account
  belongs_to :report, optional: true

  has_one :appeal, dependent: :destroy
end
