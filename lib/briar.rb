#$:.unshift File.dirname(__FILE__)

DEVICE_ENDPOINT = (ENV['DEVICE_ENDPOINT'] || 'http://localhost:37265')
TOUCH_TRANSITION_TIMEOUT = 30.0
TOUCH_TRANSITION_RETRY_FREQ = 0.5
BRIAR_STEP_PAUSE = (ENV['STEP_PAUSE'] || 0.4).to_f
ANIMATION_PAUSE = (ENV['ANIMATION_PAUSE'] || 0.6).to_f
AI = :accessibilityIdentifier
AL = :accessibilityLabel

require 'briar/version'
require 'briar/briar_core'

require 'briar/alerts_and_sheets/alert_view'
require 'briar/alerts_and_sheets/action_sheet'

require 'briar/bars/tabbar'
require 'briar/bars/navbar'
require 'briar/bars/toolbar'

require 'briar/control/button'
require 'briar/control/segmented_control'
require 'briar/control/slider'

require 'briar/picker/picker_shared'
require 'briar/picker/picker'
require 'briar/picker/date_picker_core'
require 'briar/picker/date_picker_manipulation'
require 'briar/picker/date_picker'

require 'briar/email'
require 'briar/image_view'
require 'briar/keyboard'
require 'briar/label'
require 'briar/scroll_view'

require 'briar/table'
require 'briar/text_field'
require 'briar/text_view'

#noinspection RubyDefParenthesesInspection
def device ()
  url = URI.parse(ENV['DEVICE_ENDPOINT']|| 'http://localhost:37265/')
  http = Net::HTTP.new(url.host, url.port)
  res = http.start do |sess|
    sess.request Net::HTTP::Get.new(ENV['CALABASH_VERSION_PATH'] || 'version')
  end
  status = res.code

  #noinspection RubyUnusedLocalVariable
  begin
    http.finish if http and http.started?
  rescue Exception => e
    # ignored
  end

  if status=='200'
    version_body = JSON.parse(res.body)
    Calabash::Cucumber::Device.new(url, version_body)
  end
end

#noinspection RubyDefParenthesesInspection
def gestalt ()
  pending("deprecated 0.0.8: replaced with Calabash::Cucumber::Device implementation - from now on use use 'device.*'")
end






