require 'spec_helper'

describe MacDNC do

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
end
