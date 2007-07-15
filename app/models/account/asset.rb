class Account::Asset < Account::Base
  type_order 1
  type_name '口座'
  short_name '口座'
  connectable_type self

  # ---------- 口座種別の静的属性を設定するためのメソッド群
  
  def self.type_name(name = nil)
    return Asset.type_name if self != Asset
    super
  end

  def self.short_name(short_name = nil)
    return Asset.short_name if self != Asset
    super
  end
  
  def self.connectable_type(clazz = nil)
    return Asset.connectable_type if self != Asset
    super
  end

  def self.asset_name(asset_name = nil)
    return @asset_name unless asset_name
    @asset_name = asset_name
  end
  
  def self.rule_applicable(flag)
    @rule_applicable = flag
  end
  def self.rule_applicable?
    !@rule_applicable.nil?
  end
  
  def self.rule_associatable(flag)
    @rule_associatable = flag
  end
  def self.rule_associatable?
    !@rule_associatable.nil?
  end

  def self.business_only(flag)
    @business_only = flag
  end
  def self.business_only?
    !@business_only.nil?
  end

  # ---------- 機能

  has_one :account_rule,
          :dependent => true,
          :foreign_key => 'account_id'
  has_many :associated_account_rules,
           :class_name => 'AccountRule',
           :foreign_key => 'associated_account_id'

  validate :validates_partner_account, :validates_rule_associated, :validates_rule_applicable
  before_destroy :assert_rule_not_associated


  # rule の親になっていない account (credit系) を探す
  def self.find_rule_free(user_id)
    rule_applicable_types = Account::Asset.types.select{|t| t.rule_applicable? } # TODO: User クラスにもっていく
    assets = User.find(user_id).accounts.types_in(rule_applicable_types.map{|t| t.to_sym}) # TODO: class でも受け入れてもらえるようにする
    assets.select{|a| a.associated_account_rules.empty? }
  
    # rule に紐づいた account_id のリストを得る
#    binded_accounts = AccountRule.find_by_sql("select account_id from account_rules where account_id is not null")
#    binded_account_ids = []
#    binded_accounts.each do |e|
#      binded_account_ids << e["account_id"]
#    end
#    not_in_binded_accounts = binded_account_ids.empty? ? "" : " and id not in(#{binded_account_ids.join(',')})"
#    
#    find(:all,
#     :conditions => ["user_id = ? and account_type_code = ? and asset_type_code in (?, ?)#{not_in_binded_accounts}",
#        user_id,
#        account_type[:asset][:code],
#        asset_type[:credit_card][:code],
#        asset_type[:credit][:code]],
#     :order => 'sort_key')
  end

  # account_type, asset_type, account_rule の整合性をあわせる
  def before_save
    # asset_type が credit 系でなければ、自分が適用対象として紐づいている rule があれば削除
    unless self.class.rule_applicable?
      self.account_rule = nil
    end
  end

  #TODO: 対応
  def asset_type_options
    asset_types = Account::Asset.types
    asset_types.delete_if{|t| !t.rule_applicable? } if self.account_rule
    asset_types.delete_if{|t| !t.rule_associatable? } unless associated_account_rules.empty?
    asset_types.delete_if{|t| t.business_only? } unless user.preferences(true).business_use?
    asset_types.map{|t| [t.asset_name, t.asset_name]}
  end
  
  def asset_name
    self.class.asset_name
  end

  protected
  # asset_type が金融機関でないのに、精算口座として使われていてはいけない。
  def validates_rule_associated
    # TODO: 属性化したい
    unless self.kind_of? BankingFacility
      errors.add(:type, "精算口座として精算ルールで使用されています。") unless AccountRule.find_associated_with(id).empty?
    end
  end
  # asset_type が債権でもクレジットカードでもないのに、精算ルールを持っていてはいけない。
  def validates_rule_applicable
    unless self.class.rule_applicable?
      errors.add(:asset_type_code, "精算ルールが適用されています。") unless AccountRule.find_binded_with(id).empty?
    end
  end
  def assert_rule_not_associated
    # 精算口座として使われていたら削除できない
    raise Account::RuleAssociatedAccountException.new("「#{name}」は精算口座として使われているため削除できません。") unless associated_account_rules.empty?
  end

end

class Account::RuleAssociatedAccountException < Exception
end