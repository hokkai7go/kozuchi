# -*- encoding : utf-8 -*-
require 'spec_helper'
RSpec.configure do |config|
  config.use_transactional_fixtures = false
end

describe ProfitAndLossController, :js => true do
  fixtures :users, :accounts, :preferences
  set_fixture_class  :accounts => Account::Base

  include_context "太郎 logged in"

  let(:target_date) {Date.today >> 1}
  before do
    Deal::Base.destroy_all
    click_link '家計簿'
    click_link '収支表'
  end

  describe "カレンダー（翌月）のクリック" do
    before do
      click_link("#{target_date.month}月")
    end
    it do
      page.should have_content("#{target_date.year}年#{target_date.month}月末日の収支表")
    end
  end

end