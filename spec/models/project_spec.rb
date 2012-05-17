require 'spec_helper'

describe Project do

  context "validations" do
    before(:each) { Project.make }

    it { should belong_to(:account) }
    it { should have_many(:call_logs) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).scoped_to(:account_id) }
  end

  context "callbacks" do
    it "sets name to callback url if name is empty" do
      app = Project.make :name => nil, :callback_url => 'foo'
      app.name.should == app.callback_url
    end

    it "keeps name if name set" do
      app = Project.make :name => 'bar', :callback_url => 'foo'
      app.name.should == 'bar'
    end

    it "saves flow" do
      app = Project.make_unsaved
      app.flow = Compiler.make { PlayUrl 'foo' }
      app.save!

      app.reload
      app.flow.should == Compiler.make { PlayUrl 'foo' }
    end
  end

  context "commands" do
    before(:each) do
      @app = Project.make_unsaved
    end

    it "commands is flow when present" do
      @app.flow = Commands::AnswerCommand.new
      @app.commands.should == @app.flow
    end

    it "commands when callback url is present" do
      @app.callback_url = 'http://example.com'
      @app.commands.should == Compiler.make { |b| b.Answer; b.Callback(@app.callback_url) }
    end
  end

  context "config" do
    include ProjectConfigHelpers

    it "should be encrypted" do
      subject.config = {:some => :config}
      subject.encrypted_config.should_not == {:some => :config}
    end

    it "should propertly saved the encrypted config to the db" do
      app = Project.make
      with_callback_url_accessors do |accessor|
        app.send("#{accessor}=", accessor.to_s)
        app.save
        subject.class.find(app.id).send(accessor).should == accessor.to_s
      end
    end

    it "should have accessors for all configuration" do
      with_callback_url_accessors do |accessor|
        subject.send("#{accessor}=", accessor)
        subject.send(accessor).should == accessor
      end
    end
  end

  it "should update the flow when it's user flow get's updated" do
    project = Project.make id: 4
    project.flow.should be_nil
    project.user_flow = [
      {
        'id' => 1,
        'root' => 1,
        'type' => 'play',
        'name' => 'Play number one',
        'message' => {
          "name" => "Some explanation message",
          "type" => "text"
        }
      }
    ]

    project.save!
    project.reload.flow.should eq(
      Compiler.make do
        Answer()
        Assign "current_step", 1
        Trace project_id: 4, step_id: 1, step_name: 'Play number one', store: '"Message played."'
        Say "Some explanation message"
      end
    )

    project.error_flow.should eq(
      Compiler.make do
        Trace project_id: 4, step_id: 'current_step', step_name: '', store: '"User hanged up."'
      end
    )
  end
end