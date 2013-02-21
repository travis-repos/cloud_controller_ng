# Copyright (c) 2009-2012 VMware, Inc.

require File.expand_path("../spec_helper", __FILE__)

module VCAP::CloudController
  describe VCAP::CloudController::DeaPool do
    let(:message_bus) { double(:message_bus) }

    let(:dea_msg) do
      {
        :id => "abc",
        :available_memory => 1024,
        :runtimes => ["ruby18", "java"]
      }
    end

    before do
      DeaPool.configure(config, message_bus)
    end

    describe "process_advertise_message" do

      it "should add a dea profile with a recent timestamp" do
        deas = DeaPool.send(:deas)
        deas.count.should == 0
        DeaPool.send(:process_advertise_message, dea_msg)
        deas.count.should == 1
        deas.should have_key("abc")

        dea = deas["abc"]
        dea[:advertisement].should == dea_msg
        dea[:last_update].should be_recent
      end
    end

    describe "subscription"  do
      it "should respond to dea.advertise" do
        message_bus.should_receive(:subscribe).and_yield(dea_msg)
        DeaPool.should_receive(:process_advertise_message).with(dea_msg)
        DeaPool.register_subscriptions
      end
    end

    describe "find_dea" do
      let(:dea_expired) do
        {
          :id => "expired",
          :available_memory => 1024,
          :runtimes => %w[ruby18 java ruby19]
        }
      end

      let(:dea_low_mem) do
        {
          :id => "mem_only",
          :available_memory => 512,
        }
      end

      let(:dea_buildpack) do
        {
          :id => "buildpack",
          :available_memory => 1024
        }
      end

      let(:deas) { deas = DeaPool.send(:deas) }

      before do
        DeaPool.send(:process_advertise_message, dea_expired)
        DeaPool.send(:process_advertise_message, dea_low_mem)
        DeaPool.send(:process_advertise_message, dea_buildpack)
        deas["expired"][:last_update] = Time.new(2011, 04, 11)
      end

      it "should find a non-expired dea with enough memory" do
        DeaPool.find_dea(1024).should == "buildpack"
      end
    end
  end
end
