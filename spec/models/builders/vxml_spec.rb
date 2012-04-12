require 'spec_helper'

describe Builders::Vxml do
  
  let(:vxml) { Builders::Vxml.new }
  
  it "builds an empty vxml" do
    xml = <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <vxml version="2.1"><form></form></vxml>
    XML
    
    vxml.build.should be_equivalent_to(xml)
  end
  
  it "builds a prompt block for says" do
    xml = <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <vxml version="2.1">
        <form>
          <block>
            <prompt>Hello World</prompt>
          </block>
        </form>
      </vxml>
    XML
    
    vxml.say("Hello World").build.should be_equivalent_to(xml)
  end
  
  it "build a prompt block for pause" do
    xml = <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <vxml version="2.1">
        <form>
          <block>
            <prompt>
              <break time="5s"/>
            </prompt>
          </block>
        </form>
      </vxml>
    XML
    
    vxml.pause(5).build.should be_equivalent_to(xml)
  end
  
  it "should hangup with exit within block" do
    xml = <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <vxml version="2.1">
        <form>
          <block>
            <exit/>
          </block>
        </form>
      </vxml>
    XML
    
    vxml.hangup.build.should be_equivalent_to(xml)
  end
  
  it "should play using audio within block" do
    xml = <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <vxml version="2.1">
        <form>
          <block>
            <audio src="foo.wav"/>
          </block>
        </form>
      </vxml>
    XML
    
    vxml.play("foo.wav").build.should be_equivalent_to(xml)
  end
  
  it "builds a callback using submit" do
    xml = <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <vxml version="2.1">
        <form>
          <block>
            <submit next="http://www.foo.com/bar" method="GET"/>
          </block>
        </form>
      </vxml>
    XML
    
    vxml.callback("http://www.foo.com/bar").build.should be_equivalent_to(xml)
  end
  
  it "builds a POST callback using submit" do
    xml = <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <vxml version="2.1">
        <form>
          <block>
            <submit next="http://www.foo.com/bar" method="POST"/>
          </block>
        </form>
      </vxml>
    XML
    
    vxml.callback("http://www.foo.com/bar", :post).build.should be_equivalent_to(xml)
  end
  
  context "capture" do
  
    it "should capture with say using field" do
      xml = <<-XML
        <?xml version="1.0" encoding="UTF-8"?>
        <vxml version="2.1">
          <form>
            <field name="digits" type="digits?minlength=1;maxlength=1">
              <grammar type="text/gsl">[dtmf-1 dtmf-2 dtmf-3 dtmf-4 dtmf-5 dtmf-6 dtmf-7 dtmf-8 dtmf-9 dtmf-0]</grammar>
              <property name="timeout" value="10s"/>
              <noinput/>
              <nomatch/>
              <prompt>This is a capture</prompt>
            </field>
          </form>
        </vxml>
      XML
    
      vxml.capture({:say => "This is a capture"}).build.should be_equivalent_to(xml)
    end
    
    it "should capture with play using field" do
      xml = <<-XML
        <?xml version="1.0" encoding="UTF-8"?>
        <vxml version="2.1">
          <form>
            <field name="digits" type="digits?minlength=1;maxlength=1">
              <grammar type="text/gsl">[dtmf-1 dtmf-2 dtmf-3 dtmf-4 dtmf-5 dtmf-6 dtmf-7 dtmf-8 dtmf-9 dtmf-0]</grammar>
              <property name="timeout" value="10s"/>
              <noinput/>
              <nomatch/>
              <audio src="capture.wav"/>
            </field>
          </form>
        </vxml>
      XML
    
      vxml.capture({:play => "capture.wav"}).build.should be_equivalent_to(xml)
    end
    
    it "should capture with options using field" do
      xml = <<-XML
        <?xml version="1.0" encoding="UTF-8"?>
        <vxml version="2.1">
          <form>
            <field name="digits" type="digits?minlength=5;maxlength=10">
              <grammar type="text/gsl">[dtmf-1 dtmf-2 dtmf-3 dtmf-4 dtmf-5 dtmf-6 dtmf-7 dtmf-8 dtmf-9 dtmf-0]</grammar>
              <property name="timeout" value="20s"/>
              <noinput/>
              <nomatch/>
              <prompt>This is a capture</prompt
            </field>
          </form>
        </vxml>
      XML
    
      vxml.capture(:say => "This is a capture", :min => 5, :max => 10, :timeout => 20).build.should be_equivalent_to(xml)
    end
  end
  
end