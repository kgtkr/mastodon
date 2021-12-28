# frozen_string_literal: true
# == Schema Information
#
# Table name: appeals
#
#  id                :bigint(8)        not null, primary key
#  account_id        :bigint(8)        not null
#  account_strike_id :bigint(8)        not null
#  text              :text             default(""), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class Appeal < ApplicationRecord
  belongs_to :account
  belongs_to :account_strike, inverse_of: :appeal
end
