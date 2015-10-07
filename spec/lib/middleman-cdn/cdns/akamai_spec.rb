#Encoding: UTF-8
require 'spec_helper'
require 'lib/middleman-cdn/cdns/base_protocol'

describe Middleman::Cli::AkamaiCDN do
  it_behaves_like "BaseCDN"

  describe '.key' do
    it "should be 'akamai'" do
      expect(described_class.key).to eq("akamai")
    end
  end

  describe '.example_configuration_elements' do
    it "should contain these keys" do
      required_keys = [:username, :password, :base_url]
      expect(described_class.example_configuration_elements.keys).to eq(required_keys)
    end
  end

  describe '#invalidate' do
    let(:double_akamai) { double("AkamaiClient") }

    before do
      allow(double_akamai).to receive(:invalidate)
      allow(Middleman::Cli::AkamaiClient).to receive(:new).and_return(double_akamai)
    end

    let(:files) { [ "/index.html", "/", "/test/index.html", "/test/image.png" ] }

    let(:files_no_dirs) { files.reject { |file| file.end_with?("/") } }

    context "all options provided" do
      let(:options) do
        {
          username: "00000000000000000000",
          password: "11111111111111111111",
          base_url: "http://www.example.com",
        }
      end

      it "should instantiate akamai client with credentails" do
        expect(Middleman::Cli::AkamaiClient).to receive(:new).with("00000000000000000000", "11111111111111111111")
        subject.invalidate(options, files)
      end

      it "should not raise errors" do
        subject.invalidate(options, files)
      end

      it "should invalidate each files one at a time" do
        expect(double_akamai).to receive(:invalidate).once.ordered.with("222222", "333333", "/index.html", base_url: "http://www.example.com")
        expect(double_akamai).to receive(:invalidate).once.ordered.with("222222", "333333", "/test/index.html", base_url: "http://www.example.com")
        expect(double_akamai).to receive(:invalidate).once.ordered.with("222222", "333333", "/test/image.png", base_url: "http://www.example.com")
        expect(double_akamai).to_not receive(:invalidate).with(anything, anything, "/", anything)
        subject.invalidate(options, files)
      end

      it "should output saying invalidating each file" do
        files_escaped = files_no_dirs.map { |file| Regexp.escape(file) }
        expect { subject.invalidate(options, files) }.to output(/#{files_escaped.join(".+")}/m).to_stdout
      end

      it "should output saying success checkmarks" do
        expect { subject.invalidate(options, files) }.to output(/✔/).to_stdout
      end

      context "and errors occurs when purging" do
        before do
          allow(double_akamai).to receive(:invalidate).and_raise(StandardError)
        end

        it "should output saying error information" do
          expect { subject.invalidate(options, files) }.to output(/error: StandardError/).to_stdout
        end
      end
    end

    context "environment variables used for credentials" do
      before do
        allow(ENV).to receive(:[])
        allow(ENV).to receive(:[]).with("AKAMAI_USERNAME").and_return("00000000000000000000")
        allow(ENV).to receive(:[]).with("AKAMAI_PASSWORD").and_return("11111111111111111111")
        allow(ENV).to receive(:[]).with("AKAMAI_BASE_URL").and_return("http://www.example.com")
      end

      it "should instantiate with environment variable credentails" do
        expect(Middleman::Cli::AkamaiClient).to receive(:new).with("00000000000000000000", "11111111111111111111")
        subject.invalidate(options, files)
      end

      it "should not raise errors" do
        subject.invalidate(options, files)
      end
    end

    context "if username not provided" do
      before do
        allow(ENV).to receive(:[])
        allow(ENV).to receive(:[]).with("AKAMAI_USERNAME").and_return(nil)
      end

      let(:options) do
        {
          password: "11111111111111111111",
          base_url: "http://www.example.com"
        }
      end

      it "should raise error" do
        expect { subject.invalidate(options, files) }.to raise_error(RuntimeError)
      end

      it "should output saying error" do
        expect { subject.invalidate(options, files) rescue nil }.to output(/Error: Configuration key rackspace\[:username\] is missing\./).to_stdout
      end
    end

    context "if password key not provided" do
      before do
        allow(ENV).to receive(:[])
        allow(ENV).to receive(:[]).with("AKAMAI_PASSWORD").and_return(nil)
      end

      let(:options) do
        {
          username: "00000000000000000000",
          base_url: "http://www.example.com"
        }
      end

      it "should raise error" do
        expect { subject.invalidate(options, files) }.to raise_error(RuntimeError)
      end

      it "should output saying error" do
        expect { subject.invalidate(options, files) rescue nil }.to output(/Error: Configuration key akamai\[:password\] is missing\./).to_stdout
      end
    end

    context "if base url not provided" do
      let(:options) do
        {
          username: "00000000000000000000",
          password: "11111111111111111111"
        }
      end

      it "should output saying error" do
        expect { subject.invalidate(options, files) rescue nil }.to output(/Error: Configuration key akamai\[:base_url\] is missing\./).to_stdout
      end
    end

  end
end
