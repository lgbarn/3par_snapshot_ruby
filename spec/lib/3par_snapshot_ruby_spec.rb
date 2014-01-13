require "spec_helper"
require "3par_snapshot_ruby"

describe Snapshot do
  before(:all) do
      @lvm = Snapshot.new
  end
  context "when performing snapshot" do
    describe "#initialize" do
      it "sets all initial values" do
        expect(@lvm.fstab).to eq '/etc/fstab'
      end
    end
    describe "#src" do
      it "sets source value" do
        expect(@lvm.src"test").to eq 'test'
      end
    end
    describe "#dst" do
      it "sets destination value" do
        expect(@lvm.dst"newtest").to eq 'newtest'
      end
    end
  end
  context "when parsing fstab" do
    describe "#src_mounts" do
      it "returns source mount points" do
        expect(@lvm.src_mounts("test")).to eq [["/pkg/test/u01"], ["/pkg/test/u02"], ["/pkg/test/u03"], ["/pkg/test/u04"], ["/pkg/test/u05"], ["/pkg/test/u06"]]
      end
    end
    describe "#dst_mounts" do
      it "returns destination mount points" do
        expect(@lvm.dst_mounts("newtest")).to eq [["/pkg/newtest/u01"], ["/pkg/newtest/u02"], ["/pkg/newtest/u03"], ["/pkg/newtest/u04"], ["/pkg/newtest/u05"], ["/pkg/newtest/u06"]]
      end
    end
    describe "#dst_busy_mounts" do
      it "returns busy destination mount points" do
        expect(@lvm.dst_busy_mounts("newtest")).to eq [["/pkg/newtest/u01"], ["/pkg/newtest/u02"], ["/pkg/newtest/u03"], ["/pkg/newtest/u04"], ["/pkg/newtest/u05"], ["/pkg/newtest/u06"]]
      end
    end
    describe "#dst_vgs" do
      it "returns destination volume groups" do
        expect(@lvm.dst_vgs("newtest")).to eq [["vg600"], ["vg601"]]
      end
    end
  end
  context "when looking for used dm devices" do
    describe "#dm_dst_devices" do
      it "returns dm devices" do
        @dst_vgs = @lvm.dst_vgs("newtest")
        expect(@lvm.dm_dst_devices(@dst_vgs)).to eq ["newtest_vg600_d002", "newtest_vg600_d001", "newtest_vg601_d002", "newtest_vg601_d001"]
      end
    end
    describe "#dm_dst_lvols" do
      it "returns dm lvols" do
        @dst_vgs = @lvm.dst_vgs("newtest")
        expect(@lvm.dm_dst_lvols(@dst_vgs)).to eq ["vg600-lvol2", "vg600-lvol1", "vg600-lvol0", "vg601-lvol2", "vg601-lvol1", "vg601-lvol0"]
      end
    end
    describe "#device" do
      it "sets device_file" do
        expect(@lvm.device("newtest_vg601_d001")).to eq "newtest_vg601_d001"
      end
    end
    describe "#get_paths" do
      it "parses @cmd_output and and gets individual paths" do
        expect(@lvm.get_paths("newtest_vg601_d001")).to eq [["1:0:0:5", "sdg"], ["1:0:1:5", "sdr"], ["2:0:0:5", "sdac"], ["2:0:1:5", "sdan"]]
      end
    end

  end
end
