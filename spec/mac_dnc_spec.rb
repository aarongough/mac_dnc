require 'spec_helper'

describe MacDNC do
  describe ".setup" do
    it "should not raise an error" do
      MacDNC.setup()
    end
  end

  describe ".file_list" do
    it "should not raise an error" do
      MacDNC.file_list()
    end
  end
end
