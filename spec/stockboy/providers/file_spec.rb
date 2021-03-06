require 'spec_helper'
require 'stockboy/providers/file'

module Stockboy
  describe Providers::File do
    subject(:provider) { Stockboy::Providers::File.new }

    it "should assign parameters" do
      provider.file_dir = "fixtures/files"
      provider.file_name = %r{import_20[1-9][0-9]-(0[1-9]|1[0-2])-([0-2][1-9]|3[0-1]).csv}
      provider.file_newer = Date.today
      provider.file_smaller = 1024**2
      provider.file_larger = 1024
      provider.pick = :first

      provider.file_dir.should == "fixtures/files"
      provider.file_name.should == %r{import_20[1-9][0-9]-(0[1-9]|1[0-2])-([0-2][1-9]|3[0-1]).csv}
      provider.file_newer.should == Date.today
      provider.file_smaller.should == 1024**2
      provider.file_larger.should == 1024
      provider.pick.should == :first
    end

    describe ".new" do
      it "has no errors" do
        provider.errors.should be_empty
      end

      it "accepts block initialization" do
        provider = Providers::File.new{ |f| f.file_dir 'fixtures/files' }
        provider.file_dir.should == 'fixtures/files'
      end
    end

    describe "#matching_file" do
      let(:provider) { Providers::File.new(file_dir: fixture_path("files")) }
      subject(:matching_file) { provider.matching_file }

      context "with a matching string" do
        before { provider.file_name = "test_data-*" }
        it "returns the full path to the matching file name" do
          should end_with "fixtures/files/test_data-20120202.csv"
        end
      end

      context "with a matching regex" do
        before { provider.file_name = /^test_data-\d+/ }
        it "returns the full path to the matching file name" do
          should end_with "fixtures/files/test_data-20120202.csv"
        end
      end

      context "with an unmatched string" do
        before { provider.file_name = "missing" }
        it { should be nil }
      end
    end

    describe "#data" do
      subject(:provider) { Providers::File.new(file_dir: fixture_path("files")) }

      it "fails with an error if the file doesn't exist" do
        provider.file_name = "missing-file.csv"
        provider.data.should be nil
        provider.valid?.should be false
        provider.errors.first.should match /not found/
      end

      it "finds last matching file from string glob" do
        provider.file_name = "test_data-*.csv"
        provider.data.should == "2012-02-02\n"
      end

      it "finds first matching file from string glob" do
        provider.file_name = "test_data-*.csv"
        provider.pick = :first
        provider.data.should == "2012-01-01\n"
      end

      it "finds last matching file from regex" do
        provider.file_name = /test_data/
        provider.data.should == "2012-02-02\n"
      end

      context "metadata validation" do
        before { provider.file_name = '*.csv' }
        let(:recently)  { Time.now - 60 }
        let(:last_week) { Time.now - 86400 }

        it "skips old files with :since" do
          expect_any_instance_of(::File).to receive(:mtime).and_return last_week
          provider.since = recently
          provider.data.should be nil
          provider.errors.first.should == "no new files since #{recently}"
        end

        it "skips large files with :file_smaller" do
          expect_any_instance_of(::File).to receive(:size).and_return 1001
          provider.file_smaller = 1000
          provider.data.should be nil
          provider.errors.first.should == "file size larger than 1000"
        end

        it "skips small files with :file_larger" do
          expect_any_instance_of(::File).to receive(:size).and_return 999
          provider.file_larger = 1000
          provider.data.should be nil
          provider.errors.first.should == "file size smaller than 1000"
        end
      end
    end

    describe ".delete_data" do
      let(:target)     { ::Tempfile.new(['delete', '.csv']) }
      let(:target_dir) { File.dirname(target) }
      let(:pick_same)  { ->(best, this) { this == target.path ? this : best } }

      subject(:provider) do
        Providers::File.new(file_name: 'delete*.csv', file_dir: target_dir, pick: pick_same)
      end

      it "should raise an error when called blindly" do
        expect { provider.delete_data }.to raise_error Stockboy::OutOfSequence
      end

      it "should call delete on the matched file" do
        provider.matching_file

        non_matching_duplicate = ::Tempfile.new(['delete', '.csv'])

        expect(::File).to receive(:delete).with(target.path)
        provider.delete_data
      end
    end

  end
end
