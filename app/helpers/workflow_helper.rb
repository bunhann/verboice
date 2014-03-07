# Copyright (C) 2010-2012, InSTEDD
#
# This file is part of Verboice.
#
# Verboice is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Verboice is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Verboice.  If not, see <http://www.gnu.org/licenses/>.

module WorkflowHelper

  def store_value_tags
    content_tag(:input, '', :type => 'checkbox', 'data-bind' => 'checked: defines_store', :id => 'store-this-result-as') +\
    content_tag(:label, "Store this result as: ", :for => 'store-this-result-as') +\
    content_tag(:input, '', :type => 'text', 'data-bind' => 'value: store, enable: defines_store, initAutocomplete: {source: workflow.all_variables()}, initMask: {mask: $.mask.masks.token}', :style => "width: 108px")
  end

  def user_step_class(step_type)
    case step_type
    when "play" then "i48grad-sound"
    when "branch" then "i48grad-directions"
    when "input" then "i48grad-numeral"
    when "menu" then "i48grad-dial"
    when "impersonate" then "i48grad-users"
    when "hangup_and_callback" then "i48grad-callback"
    when "language" then "i48grad-language"
    when "record" then "i48grad-microphone"
    else "i48grad-cloud"
    end
  end

end
