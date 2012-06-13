class TipList < ActiveRecord::Base
  attr_accessible :name, :domain, :tip_list
  attr_accessor :tip_list

  has_many :tips

  before_save :save_tips

  def as_json
    {
      :id => id,
      :name => name,
      :tips => tips
    }
  end

  def save_tips
    return true unless tip_list

    TipList.transaction do
      tips.delete_all
      JSON.parse(tip_list).each do |t|
        self.tips.create(t)
      end
    end
  end
end
