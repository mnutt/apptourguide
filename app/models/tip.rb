class Tip < ActiveRecord::Base
  attr_accessible :description, :direction, :num, :parent, :x_offset, :y_offset
end
