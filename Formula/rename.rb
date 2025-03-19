class Rename < Formula
  desc "A utility for renaming files and directories with content replacement"
  homepage "https://github.com/SweetRainGarden/homebrew-rename"
  url "https://github.com/SweetRainGarden/homebrew-rename/archive/refs/tags/v1.0.0.1.tar.gz"
  sha256 "6c5d30b040d207cf95daa9f132f935ae0fc3a27a23f07b7fbb2dae2a873269a3"
  license "MIT"

  def install
    bin.install "bin/rename"
  end

  test do
    # Create a test directory
    testpath.mkpath
    (testpath/"foo.txt").write("test content")
    system "#{bin}/rename", "--dry-run", "foo", "bar", testpath.to_s
  end
end 