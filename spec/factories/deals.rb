# -*- encoding : utf-8 -*-

FactoryGirl.define do

  # 単純な記入
  # デフォルトでは太郎の現金→食費
  factory :general_deal, :class => Deal::General do
    user_id Fixtures.identify(:taro)
    summary "ランチ"
    summary_mode 'unify'
    debtor_entries_attributes [:account_id => Fixtures.identify(:taro_food), :amount => 800]
    creditor_entries_attributes [:account_id => Fixtures.identify(:taro_cache), :amount => -800]
    date Date.today
  end

  # 複数記入
  factory :complex_deal, :class => Deal::General do
    user_id Fixtures.identify(:taro)
    summary '買い物'
    summary_mode 'unify'
    debtor_entries_attributes [{:account_id => Fixtures.identify(:taro_food), :amount => 800}, {:account_id => Fixtures.identify(:taro_other), :amount => 200}]
    creditor_entries_attributes [:account_id => Fixtures.identify(:taro_cache), :amount => -1000]
    date Date.today
  end

  # 残高記入
  factory :balance_deal, :class => Deal::Balance do
    user_id Fixtures.identify(:taro)
    account_id Fixtures.identify(:taro_cache)
    balance 5431
    date Date.today
  end

end
