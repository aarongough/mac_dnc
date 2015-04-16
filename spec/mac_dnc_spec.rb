require 'spec_helper'

# Normally I would write far more useful tests than this
# unfortunately though this system is so dependent on
# external files I have deemed it to be not worth the effort
# at least for the moment.

describe MacDNC do

  describe ".setup" do
    it "should not raise an error" do
      @dnc = MacDNC.new
      @dnc.setup()
    end
  end

  describe ".nc_file_list" do
    it "should not raise an error" do
      @dnc = MacDNC.new
      @dnc.nc_file_list()
    end
  end

  describe ".file_path_for_number" do
    it "should not raise an error" do
      @dnc = MacDNC.new
      @dnc.file_path_for_number(1)
    end
  end

  describe ".load_config" do
    it "should not raise an error" do
      @dnc = MacDNC.new
      @dnc.load_config()
    end
  end

  describe ".pretty_file_listing" do
    it "should not raise an error" do
      @dnc = MacDNC.new
      @dnc.pretty_file_listing()
    end
  end
end
